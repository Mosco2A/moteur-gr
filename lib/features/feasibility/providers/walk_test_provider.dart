import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../notifications/providers/notification_provider.dart';
import '../../trek/data/gps_service.dart';
import '../data/hiker_profile_repository.dart';
import '../domain/hiker_profile.dart';
import '../domain/walk_test_norms.dart';
import '../domain/walk_test_result.dart';
import '../domain/walk_test_session.dart';

/// Phase du test de marche 6 minutes.
enum WalkTestPhase {
  /// Ecran d'accueil (consignes + bouton demarrer).
  idle,

  /// Compte a rebours avant le depart.
  countdown,

  /// Test en cours (chrono + distance live).
  running,

  /// Test termine : resultat date disponible.
  done,

  /// GPS refuse / indisponible : impossible de mesurer.
  gpsDenied,
}

/// Etat immuable du test 6 minutes.
class WalkTestState {
  const WalkTestState({
    this.phase = WalkTestPhase.idle,
    this.remaining = kWalkTestDuration,
    this.countdownRemaining = kWalkTestCountdown,
    this.distanceMeters = 0,
    this.result,
  });

  final WalkTestPhase phase;

  /// Temps restant du test (6:00 -> 0).
  final Duration remaining;

  /// Temps restant du compte a rebours (3 -> 0).
  final Duration countdownRemaining;

  /// Distance parcourue en direct (m).
  final double distanceMeters;

  /// Resultat date (non-null en phase [WalkTestPhase.done]).
  final WalkTestResult? result;

  WalkTestState copyWith({
    WalkTestPhase? phase,
    Duration? remaining,
    Duration? countdownRemaining,
    double? distanceMeters,
    WalkTestResult? result,
  }) {
    return WalkTestState(
      phase: phase ?? this.phase,
      remaining: remaining ?? this.remaining,
      countdownRemaining: countdownRemaining ?? this.countdownRemaining,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      result: result ?? this.result,
    );
  }
}

/// Controleur du test de marche 6 minutes (StepWays LOT 4, Ph2).
///
/// Orchestration : compte a rebours -> chrono 6 min avec distance live via le
/// stream GPS (mode chrono LIBRE, sans trace de reference — reutilise
/// `GpsService`, sans conflit avec la navigation). Arret AUTO a 6:00. A la fin :
/// niveau objectif via `WalkTestNorms` (age/sexe/morpho), resultat DATE stocke,
/// rappel mensuel planifie.
///
/// La logique de mesure (`WalkTestSession`) et de barème (`WalkTestNorms`) est
/// PURE et testee separement ; ce controleur ne fait que le cablage temps reel.
class WalkTestController extends Notifier<WalkTestState> {
  Timer? _ticker;
  Timer? _countdownTicker;
  StreamSubscription<Position>? _gpsSub;
  final WalkTestSession _session = WalkTestSession();
  DateTime? _startedAt;
  String? _reminderTitle;
  String? _reminderBody;

  HikerProfileRepository get _repo =>
      ref.read(hikerProfileRepositoryProvider);

  @override
  WalkTestState build() {
    ref.onDispose(_teardown);
    return const WalkTestState();
  }

  /// Demarre : demande le GPS, lance le compte a rebours puis le chrono.
  ///
  /// [reminderTitle]/[reminderBody] (fournis par l'UI, i18n) servent a planifier
  /// le rappel MENSUEL a la fin du test. Optionnels : sans eux, aucun rappel
  /// n'est planifie (mais le test fonctionne).
  Future<void> start({String? reminderTitle, String? reminderBody}) async {
    _reminderTitle = reminderTitle;
    _reminderBody = reminderBody;
    final gps = ref.read(gpsServiceProvider);
    final permission = await gps.requestPermission();
    if (permission != GpsPermissionResultValues.granted) {
      state = state.copyWith(phase: WalkTestPhase.gpsDenied);
      return;
    }

    _session.reset();
    state = const WalkTestState(phase: WalkTestPhase.countdown);

    // Compte a rebours de preparation.
    var cd = kWalkTestCountdown;
    _countdownTicker =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      cd -= const Duration(seconds: 1);
      if (cd <= Duration.zero) {
        timer.cancel();
        _beginRun(gps);
      } else {
        state = state.copyWith(countdownRemaining: cd);
      }
    });
  }

  void _beginRun(GpsService gps) {
    _startedAt = DateTime.now();
    state = state.copyWith(
      phase: WalkTestPhase.running,
      remaining: kWalkTestDuration,
      distanceMeters: 0,
    );

    // Distance live depuis le flux GPS (mode chrono libre).
    _gpsSub = gps.getPositionStream().listen((pos) {
      final started = _startedAt;
      if (started == null) return;
      final elapsed = DateTime.now().difference(started);
      final counted = _session.addPosition(
        lat: pos.latitude,
        lng: pos.longitude,
        elapsed: elapsed,
      );
      if (counted) {
        state = state.copyWith(distanceMeters: _session.distanceMeters);
      }
    });

    // Chrono : decremente chaque seconde, arret AUTO a 0.
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.remaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        state = state.copyWith(remaining: Duration.zero);
        _finish();
      } else {
        state = state.copyWith(remaining: next);
      }
    });
  }

  Future<void> _finish() async {
    await _gpsSub?.cancel();
    _gpsSub = null;
    _ticker?.cancel();

    final distance = _session.distanceMeters;
    final profile = await _repo.getProfile();
    final level = WalkTestNorms.levelFor(profile, distance);
    final result = WalkTestResult(
      distanceMeters: distance,
      level: level,
      takenAt: DateTime.now(),
    );
    await _repo.saveWalkTestResult(result);
    // Rafraichit le provider de resultat consomme par la faisabilite.
    ref.invalidate(walkTestResultProvider);

    // Rappel mensuel (recurrent ~1x/mois) si l'UI a fourni les libelles.
    final title = _reminderTitle;
    final body = _reminderBody;
    if (title != null && body != null) {
      await ref
          .read(notificationServiceProvider)
          .scheduleWalkTestReminder(title: title, body: body);
    }

    state = state.copyWith(phase: WalkTestPhase.done, result: result);
  }

  /// Annule un test en cours (retour a l'accueil, rien n'est enregistre).
  void cancel() {
    _teardown();
    state = const WalkTestState();
  }

  /// Repart pour un nouveau test.
  void reset() {
    _teardown();
    state = const WalkTestState();
  }

  void _teardown() {
    _ticker?.cancel();
    _countdownTicker?.cancel();
    _gpsSub?.cancel();
    _gpsSub = null;
    _session.reset();
    _startedAt = null;
  }
}

/// Provider du controleur de test 6 minutes.
final walkTestControllerProvider =
    NotifierProvider<WalkTestController, WalkTestState>(
        WalkTestController.new);

/// Dernier resultat DATE du test 6 min (null = jamais fait -> fallback).
final walkTestResultProvider = FutureProvider<WalkTestResult?>((ref) {
  return ref.watch(hikerProfileRepositoryProvider).getWalkTestResult();
});

/// Profil courant expose de facon synchrone pour le barème (lecture directe).
final _walkTestProfileProvider = FutureProvider<HikerProfile>((ref) {
  return ref.watch(hikerProfileRepositoryProvider).getProfile();
});

/// Distance PREDITE (m) pour le profil courant (null si morpho absente).
///
/// Utile a l'UI pour montrer l'objectif de reference avant/apres le test.
final walkTestPredictedDistanceProvider = FutureProvider<double?>((ref) async {
  final profile = await ref.watch(_walkTestProfileProvider.future);
  return WalkTestNorms.predictedFor(profile);
});
