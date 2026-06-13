import 'dart:async';
import 'dart:math' as math;

import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../error/error_handler.dart';

/// Service de fusion capteurs (F6A-02, Phase 6).
///
/// Expose, en Flutter pur (aucune app montre) :
/// - [altitudeRelativeStream] : altitude RELATIVE en metres, derivee de la
///   pression barometrique ([sensors_plus] `BarometerEvent`, en hPa) via la
///   formule barometrique internationale. La pression de reference est
///   capturee au demarrage puis RECALEE sur l'altitude GPS fiable de depart
///   ([recalibrate]) — corrige la derive du barometre (angle mort Themis
///   #86146 calibration/derive).
/// - [stepCountStream] : nombre de pas cumule ([pedometer]).
///
/// FALLBACK : si le barometre est indisponible (aucun `BarometerEvent` recu
/// sous [_barometerProbeTimeout]), [altitudeRelativeStream] bascule sur
/// l'altitude GPS fournie via [pushGpsAltitude] (capteur barometre optionnel,
/// audit capteurs A6-1).
///
/// ZERO catch silencieux — toute erreur est loggee via [ErrorHandler] avant
/// d'etre propagee.
class SensorFusionService {
  /// Injection des sources pour la testabilite. Par defaut, branche les
  /// streams reels [sensors_plus] / [pedometer]. Le podometre est expose en
  /// `Stream<int>` (pas en cumul DTO) pour decoupler du DTO `StepCount` (dont
  /// le constructeur est prive et non instanciable en test) : la fabrique par
  /// defaut mappe `StepCount.steps`.
  SensorFusionService({
    Stream<BarometerEvent> Function()? barometerStream,
    Stream<int> Function()? stepCountStream,
    Duration? barometerProbeTimeout,
  })  : _barometerStreamFactory =
            barometerStream ?? (() => barometerEventStream()),
        _stepCountStreamFactory = stepCountStream ??
            (() => Pedometer.stepCountStream.map((e) => e.steps)),
        _barometerProbeTimeout =
            barometerProbeTimeout ?? const Duration(seconds: 3);

  final Stream<BarometerEvent> Function() _barometerStreamFactory;
  final Stream<int> Function() _stepCountStreamFactory;
  final Duration _barometerProbeTimeout;

  /// Pression de reference au niveau de mer standard (hPa), formule ISA.
  static const double seaLevelPressureHPa = 1013.25;

  /// Pression de reference capturee au demarrage (1er echantillon barometre).
  /// Sert d'origine a l'altitude RELATIVE (= 0 m au point de depart).
  double? _referenceHPa;

  /// Offset d'altitude (m) applique apres recalage GPS : l'altitude relative
  /// barometrique est translatee pour coller a l'altitude GPS de depart.
  double _altitudeOffsetMetres = 0;

  /// Derniere altitude GPS poussee (fallback si pas de barometre).
  double? _lastGpsAltitude;

  /// Convertit une pression [hPa] en altitude (m) par rapport a la pression
  /// de reference [referenceHPa], via la formule barometrique internationale :
  ///
  ///   h = 44330 * (1 - (P / P0)^(1 / 5.255))
  ///
  /// Calculee a P0 = [seaLevelPressureHPa] puis on soustrait l'altitude de
  /// reference, pour obtenir une altitude RELATIVE au point ou [referenceHPa]
  /// a ete mesuree. Fonction PURE (sans effet de bord) — directement testable.
  static double pressureToAltitude(double hPa, double referenceHPa) {
    final hMesure = _altitudeFromSeaLevel(hPa);
    final hReference = _altitudeFromSeaLevel(referenceHPa);
    return hMesure - hReference;
  }

  /// Altitude absolue (m) par rapport au niveau de la mer standard.
  static double _altitudeFromSeaLevel(double hPa) {
    if (hPa <= 0) return 0;
    const exponent = 1 / 5.255;
    return 44330.0 * (1.0 - math.pow(hPa / seaLevelPressureHPa, exponent));
  }

  /// Recale l'origine de l'altitude relative sur une altitude GPS fiable.
  ///
  /// A appeler avec l'altitude GPS de depart (quand l'accuracy GPS est bonne) :
  /// l'altitude relative barometrique sera translatee pour valoir
  /// [altitudeGpsMetres] a l'instant du recalage. Corrige la derive lente du
  /// barometre (meteo) sans repartir de zero.
  void recalibrate(double altitudeGpsMetres) {
    final reference = _referenceHPa;
    if (reference == null) {
      // Pas encore de reference barometre : on memorise l'altitude GPS comme
      // offset initial, applique des que la reference sera capturee.
      _altitudeOffsetMetres = altitudeGpsMetres;
      return;
    }
    _altitudeOffsetMetres = altitudeGpsMetres;
  }

  /// Pousse une altitude GPS courante (utilisee en fallback si le barometre
  /// est absent). N'altere pas la calibration barometre.
  void pushGpsAltitude(double altitudeGpsMetres) {
    _lastGpsAltitude = altitudeGpsMetres;
  }

  /// Stream d'altitude RELATIVE (m). Emet depuis le barometre apres
  /// calibration ; bascule sur l'altitude GPS si aucun echantillon barometre
  /// n'arrive sous [_barometerProbeTimeout].
  Stream<double> altitudeRelativeStream() {
    final controller = StreamController<double>();
    StreamSubscription<BarometerEvent>? sub;
    Timer? probe;
    var barometerSeen = false;

    void emitGpsFallback() {
      final gps = _lastGpsAltitude;
      if (gps != null && !controller.isClosed) {
        controller.add(gps);
      }
    }

    void start() {
      // Sonde : si aucun BarometerEvent sous le timeout, on documente l'absence
      // de barometre et on bascule en fallback GPS.
      probe = Timer(_barometerProbeTimeout, () {
        if (!barometerSeen) {
          ErrorHandler.log(
            StateError('Barometre indisponible — fallback altitude GPS'),
            context: 'SensorFusionService.altitudeRelativeStream',
          );
          emitGpsFallback();
        }
      });

      sub = _barometerStreamFactory().listen(
        (event) {
          barometerSeen = true;
          probe?.cancel();
          _referenceHPa ??= event.pressure;
          final relative =
              pressureToAltitude(event.pressure, _referenceHPa!) +
                  _altitudeOffsetMetres;
          if (!controller.isClosed) controller.add(relative);
        },
        onError: (Object error, StackTrace stackTrace) {
          ErrorHandler.log(
            error,
            stackTrace: stackTrace,
            context: 'SensorFusionService.altitudeRelativeStream',
          );
          // Barometre en erreur -> fallback GPS, sans avaler l'erreur du log.
          emitGpsFallback();
        },
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
        cancelOnError: false,
      );
    }

    controller
      ..onListen = start
      ..onCancel = () async {
        probe?.cancel();
        await sub?.cancel();
      };

    return controller.stream;
  }

  /// Stream du nombre de pas cumule (podometre).
  ///
  /// ZERO catch silencieux — les erreurs sont loggees ET propagees.
  Stream<int> stepCountStream() {
    final controller = StreamController<int>();
    StreamSubscription<int>? sub;

    controller
      ..onListen = () {
        sub = _stepCountStreamFactory().listen(
          (steps) {
            if (!controller.isClosed) controller.add(steps);
          },
          onError: (Object error, StackTrace stackTrace) {
            ErrorHandler.log(
              error,
              stackTrace: stackTrace,
              context: 'SensorFusionService.stepCountStream',
            );
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
          cancelOnError: false,
        );
      }
      ..onCancel = () async {
        await sub?.cancel();
      };

    return controller.stream;
  }

  /// Vrai si une reference barometrique a deja ete capturee (barometre actif).
  bool get hasBarometerReference => _referenceHPa != null;
}
