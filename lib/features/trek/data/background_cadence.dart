/// LA CADENCE DE L'ISOLATE DE FOND (lot 671-01) : celui qui tient le GPS ecran
/// eteint, quand l'isolate de l'interface est gele.
///
/// Ce fichier sort de `_onServiceStart` tout ce qui decide QUAND le recepteur
/// travaille — moteur de cadence, sonde de vie, battement, changement de
/// profil — pour le rendre testable avec une fausse horloge. L'isolate de fond
/// n'y garde que la plomberie : greffons, tampon de points, notification.
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../core/services/gps_cadence.dart';
import 'gps_cadence_engine.dart';
import 'gps_settings_mapping.dart';

/// Delai avant de rouvrir un flux mort sur une erreur de la source.
const Duration kBgStreamRetryDelay = Duration(seconds: 5);

/// Ce que la cadence de fond rapporte : le journal de mesure s'y branche.
abstract interface class BackgroundCadenceObserver {
  /// Le suivi demarre avec [profile].
  Future<void> started(PositionProfile profile);

  /// Le profil change en cours de route : [profile] est le NOUVEAU.
  Future<void> switched(PositionProfile profile);

  /// Le recepteur demarre : ouverture d'un flux, ou tir.
  void sourceStarted();

  /// Une position est recue ([position] non nulle), ou un tir n'en a rendu
  /// aucune ([position] nulle). [timeToFix] est le temps du premier point.
  Future<void> received(Position? position, Duration? timeToFix);

  /// Le suivi s'arrete.
  Future<void> stopped();
}

/// Pilote la captation de l'isolate de fond au rythme du profil.
class BackgroundCadence {
  /// [onPosition] traite chaque position (filtre, tampon, interface) ;
  /// [keepAliveDue] dit si la sonde de vie doit prouver qu'on vit en flux ;
  /// [readStoredProfile] relit le canal du profil a chaque sonde, filet du
  /// message de changement de profil s'il se perd.
  BackgroundCadence({
    required PositionStreamFactory openStream,
    required ShotTaker takeShot,
    required int Function() distanceFilter,
    required Future<bool> Function(
      Position position, {
      required String via,
      required bool force,
    })
    onPosition,
    required bool Function() keepAliveDue,
    required void Function() onHeartbeat,
    Future<PositionProfile> Function()? readStoredProfile,
    BackgroundCadenceObserver? observer,
    void Function(String message)? log,
    TimerScheduler? schedule,
    DateTime Function()? now,
  }) : _takeShot = takeShot,
       _onPosition = onPosition,
       _keepAliveDue = keepAliveDue,
       _onHeartbeat = onHeartbeat,
       _readStoredProfile = readStoredProfile,
       _observer = observer,
       _log = log ?? ((_) {}),
       _schedule = schedule ?? Timer.new,
       _now = now ?? DateTime.now {
    engine = GpsCadenceEngine(
      openStream: openStream,
      takeShot: takeShot,
      streamSettings: (cadence) =>
          backgroundStreamSettings(cadence, distanceFilter: distanceFilter()),
      onFix: (position, timeToFix) =>
          unawaited(_receive(position, timeToFix, via: _viaOf(engine.cadence))),
      onShotMissed: (waited) {
        _log('[bg] tir sans position apres ${waited.inSeconds}s');
        unawaited(_observer?.received(null, waited));
      },
      onStreamError: (Object error, StackTrace _) {
        // NE PAS avaler : un flux errore est mort, il faut le recreer.
        _log('[bg] ERREUR flux Geolocator: $error -> re-abo dans 5s');
        engine.restartStreamAfter(kBgStreamRetryDelay);
      },
      onSourceStarted: () => _observer?.sourceStarted(),
      schedule: _schedule,
      now: _now,
    );
  }

  final ShotTaker _takeShot;
  final Future<bool> Function(
    Position position, {
    required String via,
    required bool force,
  })
  _onPosition;
  final bool Function() _keepAliveDue;
  final void Function() _onHeartbeat;
  final Future<PositionProfile> Function()? _readStoredProfile;
  final BackgroundCadenceObserver? _observer;
  final void Function(String message) _log;
  final TimerScheduler _schedule;
  final DateTime Function() _now;

  /// Le moteur des cadences, expose aux tests.
  late final GpsCadenceEngine engine;

  PositionProfile _profile = PositionProfile.map;
  Timer? _watchdog;
  Timer? _heartbeat;
  int _timersGeneration = 0;
  bool _running = false;

  /// Le profil servi.
  PositionProfile get profile => _profile;

  /// La cadence servie.
  GpsCadence get cadence => GpsCadence.of(_profile);

  /// Vrai entre [start] et [stop].
  bool get isRunning => _running;

  /// Demarre la captation avec [profile]. Sans effet si deja demarree.
  Future<void> start(PositionProfile profile) async {
    if (_running) return;
    _running = true;
    _profile = profile;
    _log('[bg] cadence ${profile.journalLabel} au demarrage');
    await _observer?.started(profile);
    engine.start(cadence);
    _armTimers();
  }

  /// Passe a [profile] sans redemarrer ni le trek ni l'isolate.
  Future<void> switchProfile(PositionProfile profile) async {
    if (!_running || profile == _profile) return;
    _profile = profile;
    _log('[bg] cadence ${profile.journalLabel} (changement de profil)');
    await _observer?.switched(profile);
    engine.switchTo(cadence);
    _armTimers();
  }

  /// Arrete la captation et ses minuteurs.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    engine.stop();
    _watchdog?.cancel();
    _heartbeat?.cancel();
    await _observer?.stopped();
  }

  /// Sonde de vie, au rythme du profil ([GpsCadence.watchdogPeriod]).
  ///
  /// En TIR UNIQUE, elle n'ouvre JAMAIS de flux et ne tire pas de point de
  /// secours : elle relance seulement le rythme des tirs si le silence a
  /// depasse le silence normal du profil. En FLUX, elle garde son role
  /// d'avant le lot : un point de secours si aucun point n'a ete retenu
  /// depuis longtemps.
  Future<void> watchdogTick() async {
    await _followStoredProfile();
    if (!_running) return;
    if (cadence.isSingleShot) {
      if (engine.isLate(_now())) {
        _log('[bg] SONDE DE VIE -> silence anormal, tir relance');
        engine.rearm();
      }
      return;
    }
    if (!_keepAliveDue()) return;
    _log('[bg] SONDE DE VIE -> point de secours');
    try {
      final position = await _takeShot(singleShotSettings(cadence));
      await _receive(position, null, via: 'filet', force: true);
    } catch (e) {
      _log('[bg] SONDE DE VIE point de secours ECHEC: $e');
    }
  }

  Future<void> _followStoredProfile() async {
    final read = _readStoredProfile;
    if (read == null) return;
    try {
      await switchProfile(await read());
    } catch (e) {
      _log('[bg] relecture du profil impossible: $e');
    }
  }

  Future<void> _receive(
    Position position,
    Duration? timeToFix, {
    required String via,
    bool force = false,
  }) async {
    await _observer?.received(position, timeToFix);
    await _onPosition(position, via: via, force: force);
  }

  static String _viaOf(GpsCadence? cadence) =>
      cadence?.isSingleShot ?? false ? 'tir' : 'stream';

  void _armTimers() {
    _watchdog?.cancel();
    _heartbeat?.cancel();
    // Une generation par armement : une boucle d'un profil precedent qui
    // finit son tour apres un changement ne se rearme pas.
    final generation = ++_timersGeneration;
    final armed = cadence;
    bool current() => _running && generation == _timersGeneration;

    void watchdogLoop() {
      _watchdog = _schedule(armed.watchdogPeriod, () async {
        await watchdogTick();
        if (current()) watchdogLoop();
      });
    }

    void heartbeatLoop() {
      _heartbeat = _schedule(armed.heartbeatPeriod, () {
        _onHeartbeat();
        if (current()) heartbeatLoop();
      });
    }

    watchdogLoop();
    heartbeatLoop();
  }
}
