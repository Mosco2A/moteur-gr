import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_handler.dart';

/// Resultat de la demande de permission GPS.
///
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef GpsPermissionResult = String;

/// Valeurs connues pour GpsPermissionResult.
abstract class GpsPermissionResultValues {
  static const String granted = 'granted';
  static const String denied = 'denied';
  static const String deniedForever = 'deniedForever';
  static const String serviceDisabled = 'serviceDisabled';
  static const String fallback = denied;
  static const List<String> values = [
    granted,
    denied,
    deniedForever,
    serviceDisabled,
  ];

  static GpsPermissionResult fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Regime de precision GPS, pilote par le mouvement (E5.2b).
///
/// [resting] : utilisateur a l'arret -> precision basse (economie batterie).
/// [moving]  : utilisateur en mouvement -> precision haute (suivi fidele).
enum GpsAccuracyMode { resting, moving }

/// Service GPS : permissions et stream de positions a precision adaptative.
///
/// Responsabilites :
/// - Demander les permissions foreground (puis background si besoin)
/// - Fournir un Stream<Position> dont la `desiredAccuracy` s'ADAPTE au
///   mouvement (haute en deplacement, basse au repos) tout en conservant
///   un `distanceFilter` de 10 m
/// - ZERO catch silencieux — toute erreur est loggee via ErrorHandler
class GpsService {
  /// Wrapper Geolocator injecte pour testabilite.
  ///
  /// Par defaut utilise les methodes statiques de Geolocator.
  /// En test, on injecte un mock via le constructeur.
  GpsService({
    Future<bool> Function()? isLocationServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Stream<Position> Function({required LocationSettings locationSettings})?
        getPositionStream,
  })  : _isLocationServiceEnabled =
            isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _getPositionStream = getPositionStream ?? _defaultGetPositionStream;

  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Stream<Position> Function({required LocationSettings locationSettings})
      _getPositionStream;

  /// Filtre de distance conserve dans tous les regimes de precision.
  static const int distanceFilterMeters = 10;

  /// Seuil (m/s) au-dela duquel on passe en mouvement (~3.6 km/h).
  static const double movingSpeedThresholdMps = 1.0;

  /// Seuil (m/s) en deca duquel on repasse au repos (~1.4 km/h).
  ///
  /// L'ecart avec [movingSpeedThresholdMps] cree une hysteresis qui evite
  /// le battement (flapping) du regime autour d'une vitesse charniere.
  static const double restingSpeedThresholdMps = 0.4;

  static Stream<Position> _defaultGetPositionStream({
    required LocationSettings locationSettings,
  }) {
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Demande les permissions GPS : foreground d'abord, background ensuite si besoin.
  ///
  /// Retourne le resultat final de la demande.
  /// ZERO catch silencieux — chaque erreur est loggee via ErrorHandler.
  Future<GpsPermissionResult> requestPermission() async {
    try {
      // 1. Verifier que le service GPS est actif
      final serviceEnabled = await _isLocationServiceEnabled();
      if (!serviceEnabled) {
        ErrorHandler.log(
          StateError('Service GPS desactive'),
          context: 'GpsService.requestPermission',
        );
        return GpsPermissionResultValues.serviceDisabled;
      }

      // 2. Verifier les permissions actuelles
      var permission = await _checkPermission();

      // 3. Si denied, demander foreground
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
        if (permission == LocationPermission.denied) {
          ErrorHandler.log(
            StateError('Permission GPS refusee par utilisateur'),
            context: 'GpsService.requestPermission',
          );
          return GpsPermissionResultValues.denied;
        }
      }

      // 4. Si denied forever, on ne peut plus demander
      if (permission == LocationPermission.deniedForever) {
        ErrorHandler.log(
          StateError('Permission GPS refusee definitivement'),
          context: 'GpsService.requestPermission',
        );
        return GpsPermissionResultValues.deniedForever;
      }

      // 5. Permission accordee (whileInUse ou always)
      return GpsPermissionResultValues.granted;
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'GpsService.requestPermission');
      rethrow;
    }
  }

  /// Classe une vitesse en regime de precision, avec hysteresis.
  ///
  /// Fonction PURE (sans effet de bord) — testable directement. Depuis
  /// [current], on ne bascule en [GpsAccuracyMode.moving] qu'au-dela de
  /// [movingSpeedThresholdMps], et on ne revient au repos qu'en deca de
  /// [restingSpeedThresholdMps]. Une vitesse non finie est traitee comme
  /// nulle (repos).
  static GpsAccuracyMode classifyMovement(
    double speedMps,
    GpsAccuracyMode current,
  ) {
    final speed = speedMps.isFinite ? speedMps.abs() : 0.0;
    if (current == GpsAccuracyMode.resting) {
      return speed >= movingSpeedThresholdMps
          ? GpsAccuracyMode.moving
          : GpsAccuracyMode.resting;
    }
    return speed <= restingSpeedThresholdMps
        ? GpsAccuracyMode.resting
        : GpsAccuracyMode.moving;
  }

  /// Precision Geolocator correspondant a un [GpsAccuracyMode].
  static LocationAccuracy accuracyForMode(GpsAccuracyMode mode) {
    return mode == GpsAccuracyMode.moving
        ? LocationAccuracy.high
        : LocationAccuracy.low;
  }

  /// [LocationSettings] pour un regime donne (precision adaptative + filtre 10 m).
  static LocationSettings settingsForMode(GpsAccuracyMode mode) {
    return LocationSettings(
      accuracy: accuracyForMode(mode),
      distanceFilter: distanceFilterMeters,
    );
  }

  /// Stream de positions GPS a precision ADAPTATIVE et filtre 10 m.
  ///
  /// Demarre au repos (precision basse, economie batterie) puis bascule en
  /// haute precision des qu'un mouvement est detecte ([classifyMovement]),
  /// et inversement. Chaque changement de regime re-souscrit la source avec
  /// la nouvelle `desiredAccuracy` (Geolocator fixe la precision a la
  /// creation du stream). Le `distanceFilter` de 10 m est conserve partout.
  ///
  /// ZERO catch silencieux — les erreurs sont loggees ET propagees.
  Stream<Position> getPositionStream() {
    final controller = StreamController<Position>();
    var mode = GpsAccuracyMode.resting;
    StreamSubscription<Position>? sub;

    void subscribe() {
      sub = _getPositionStream(locationSettings: settingsForMode(mode)).listen(
        (position) {
          if (controller.isClosed) return;
          controller.add(position);

          final next = classifyMovement(position.speed, mode);
          if (next != mode) {
            mode = next;
            // Re-souscrire avec la nouvelle precision.
            sub?.cancel();
            subscribe();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          ErrorHandler.log(
            error,
            stackTrace: stackTrace,
            context: 'GpsService.getPositionStream',
          );
          // Propager l'erreur au lieu de l'avaler.
          if (!controller.isClosed) controller.addError(error, stackTrace);
        },
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
        cancelOnError: false,
      );
    }

    controller
      ..onListen = subscribe
      ..onCancel = () async {
        await sub?.cancel();
      };

    return controller.stream;
  }
}

/// Provider Riverpod pour GpsService.
///
/// Fournit une instance par defaut utilisant Geolocator.
/// Overridable dans les tests avec un mock.
final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService();
});
