/// LE MOTEUR DES TROIS CADENCES (lot 671-01) : flux continu ou tir unique,
/// pilote par le [GpsCadence] du profil, partage par le controleur de
/// l'interface et par l'isolate de fond.
///
/// LE TIR UNIQUE RELACHE LE RECEPTEUR ENTRE DEUX POINTS, ET CE N'EST PAS UNE
/// PRECAUTION DE STYLE. Le greffon geolocator ne garde qu'UN flux natif par
/// isolate, regle par le premier qui l'ouvre (mesure du lot 671-00) : un tir
/// demande pendant qu'une souscription vit dans le meme isolate recoit les
/// reglages de cette souscription, pas les siens. Entre deux tirs, ce moteur ne
/// garde donc AUCUNE souscription, et un tir sans reponse au bout du delai
/// maximum n'est ni retente ni remplace : le suivant viendra a son heure.
///
/// NI VERROU DE REVEIL, NI ALARME EXACTE : un simple minuteur Dart. Si le
/// systeme retarde un tir, l'heure reelle du tir le dira ; c'est une mesure.
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../core/services/gps_cadence.dart';
import 'gps_settings_mapping.dart';

/// Fabrique du flux de positions : la signature de
/// `Geolocator.getPositionStream`, injectable pour les tests.
typedef PositionStreamFactory =
    Stream<Position> Function({required LocationSettings locationSettings});

/// Un tir unique avec les reglages donnes (`Geolocator.getCurrentPosition`).
typedef ShotTaker = Future<Position> Function(LocationSettings settings);

/// Arme un minuteur : `Timer.new` en production, une fausse horloge en test.
typedef TimerScheduler = Timer Function(Duration delay, void Function() run);

/// Ouvre le flux ou tire, au rythme d'un [GpsCadence].
class GpsCadenceEngine {
  /// [onFix] recoit chaque position et son temps de premier point : la duree
  /// d'un tir, ou, en flux, celle entre l'ouverture et la premiere position
  /// (nulle pour les suivantes). [onShotMissed] recoit l'attente d'un tir
  /// sans position. [onSourceStarted] est appele a CHAQUE demarrage du
  /// recepteur : ouverture d'un flux, ou tir.
  GpsCadenceEngine({
    required PositionStreamFactory openStream,
    required ShotTaker takeShot,
    required LocationSettings Function(GpsCadence cadence) streamSettings,
    required void Function(Position position, Duration? timeToFix) onFix,
    void Function(Duration waited)? onShotMissed,
    void Function(Object error, StackTrace stackTrace)? onStreamError,
    void Function()? onStreamDone,
    void Function()? onSourceStarted,
    TimerScheduler? schedule,
    DateTime Function()? now,
  }) : _openStream = openStream,
       _takeShot = takeShot,
       _streamSettings = streamSettings,
       _onFix = onFix,
       _onShotMissed = onShotMissed,
       _onStreamError = onStreamError,
       _onStreamDone = onStreamDone,
       _onSourceStarted = onSourceStarted,
       _schedule = schedule ?? Timer.new,
       _now = now ?? DateTime.now;

  final PositionStreamFactory _openStream;
  final ShotTaker _takeShot;
  final LocationSettings Function(GpsCadence cadence) _streamSettings;
  final void Function(Position position, Duration? timeToFix) _onFix;
  final void Function(Duration waited)? _onShotMissed;
  final void Function(Object error, StackTrace stackTrace)? _onStreamError;
  final void Function()? _onStreamDone;
  final void Function()? _onSourceStarted;
  final TimerScheduler _schedule;
  final DateTime Function() _now;

  GpsCadence? _cadence;
  StreamSubscription<Position>? _subscription;
  DateTime? _streamOpenedAt;
  Timer? _nextShot;
  Timer? _shotDeadline;
  Timer? _streamRetry;
  DateTime? _lastShotAt;

  /// Numero du tir en cours : un resultat qui arrive pour un tir perime
  /// (delai depasse, profil change, arret) est ignore.
  int _shotToken = 0;
  bool _shotInFlight = false;

  /// La cadence servie, nulle a l'arret.
  GpsCadence? get cadence => _cadence;

  /// Vrai si une souscription au flux est vivante.
  bool get hasLiveSubscription => _subscription != null;

  /// Vrai si un tir attend sa position.
  bool get isShotInFlight => _shotInFlight;

  /// Heure du dernier tir lance.
  DateTime? get lastShotAt => _lastShotAt;

  /// Demarre la captation au rythme de [cadence].
  void start(GpsCadence cadence) {
    _halt();
    _cadence = cadence;
    if (cadence.isSingleShot) {
      _shoot();
    } else {
      _openSubscription();
    }
  }

  /// Passe a [cadence] sans arret : un flux est annule proprement avant le
  /// premier tir, un tir en vol est abandonne avant l'ouverture d'un flux.
  void switchTo(GpsCadence cadence) {
    if (identical(cadence, _cadence)) return;
    start(cadence);
  }

  /// Arrete tout : flux, tir en vol, minuteurs.
  void stop() {
    _halt();
    _cadence = null;
  }

  /// Rouvre le flux apres [delay] (une erreur de source l'a rendu muet).
  void restartStreamAfter(Duration delay) {
    final cadence = _cadence;
    if (cadence == null || cadence.isSingleShot) return;
    _cancelSubscription();
    _streamRetry?.cancel();
    _streamRetry = _schedule(delay, () {
      if (identical(_cadence, cadence)) _openSubscription();
    });
  }

  /// Vrai si le profil de tir a laisse passer plus que son silence normal
  /// depuis le dernier tir : le minuteur a ete perdu ou tres retarde.
  bool isLate(DateTime at) {
    final silence = _cadence?.normalSilence;
    final last = _lastShotAt;
    if (silence == null || last == null || _shotInFlight) return false;
    return at.difference(last) > silence;
  }

  /// Relance le rythme des tirs par un tir immediat. Ne fait rien en flux, ni
  /// si un tir est deja en vol : la sonde de vie n'ouvre jamais de flux.
  void rearm() {
    final cadence = _cadence;
    if (cadence == null || !cadence.isSingleShot || _shotInFlight) return;
    _nextShot?.cancel();
    _shoot();
  }

  void _openSubscription() {
    final cadence = _cadence!;
    _onSourceStarted?.call();
    _streamOpenedAt = _now();
    _subscription = _openStream(locationSettings: _streamSettings(cadence))
        .listen(
          (position) {
            final opened = _streamOpenedAt;
            _streamOpenedAt = null;
            _onFix(position, opened == null ? null : _now().difference(opened));
          },
          onError: (Object error, StackTrace stackTrace) =>
              _onStreamError?.call(error, stackTrace),
          onDone: () {
            _subscription = null;
            _onStreamDone?.call();
          },
          cancelOnError: false,
        );
  }

  void _shoot() {
    final cadence = _cadence!;
    final token = ++_shotToken;
    final startedAt = _now();
    _lastShotAt = startedAt;
    _shotInFlight = true;
    _onSourceStarted?.call();
    // Le tir suivant part une periode apres CE tir, qu'il reussisse ou non.
    _nextShot = _schedule(cadence.period!, _shoot);
    _shotDeadline = _schedule(cadence.maxDelay!, () {
      if (!_settle(token)) return;
      _onShotMissed?.call(cadence.maxDelay!);
    });
    _takeShot(singleShotSettings(cadence)).then(
      (position) {
        if (!_settle(token)) return;
        _onFix(position, _now().difference(startedAt));
      },
      onError: (Object error) {
        if (!_settle(token)) return;
        _onShotMissed?.call(
          error is TimeoutException
              ? cadence.maxDelay!
              : _now().difference(startedAt),
        );
      },
    );
  }

  /// Clot le tir [token] s'il est encore celui qu'on attend.
  bool _settle(int token) {
    if (token != _shotToken || !_shotInFlight) return false;
    _shotInFlight = false;
    _shotDeadline?.cancel();
    _shotDeadline = null;
    return true;
  }

  void _cancelSubscription() {
    final subscription = _subscription;
    _subscription = null;
    _streamOpenedAt = null;
    unawaited(subscription?.cancel());
  }

  void _halt() {
    _cancelSubscription();
    _streamRetry?.cancel();
    _nextShot?.cancel();
    _shotDeadline?.cancel();
    _streamRetry = null;
    _nextShot = null;
    _shotDeadline = null;
    _shotInFlight = false;
    _shotToken++;
  }
}
