import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trek_recorder.dart';
import '../domain/models/trek_session.dart';
import '../domain/trek_stats.dart';

/// Etat immutable du tracking expose a l'UI.
///
/// Contient les stats temps reel (distance, duree, D+, vitesse)
/// et l'etat de la session (idle, recording, paused, stopped).
class TrackingSessionState {
  const TrackingSessionState({
    this.status = TrackingSessionStatus.idle,
    this.distanceKm = 0.0,
    this.elevationGainM = 0.0,
    this.elapsedDuration = Duration.zero,
    this.currentSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.session,
  });

  /// Etat de la session.
  final TrackingSessionStatus status;

  /// Distance parcourue en kilometres.
  final double distanceKm;

  /// Denivele positif cumule en metres.
  final double elevationGainM;

  /// Duree ecoulee active (hors pauses).
  final Duration elapsedDuration;

  /// Vitesse instantanee en km/h.
  final double currentSpeedKmh;

  /// Vitesse moyenne en km/h.
  final double avgSpeedKmh;

  /// Session active (null si idle/stopped).
  final TrekSession? session;

  TrackingSessionState copyWith({
    TrackingSessionStatus? status,
    double? distanceKm,
    double? elevationGainM,
    Duration? elapsedDuration,
    double? currentSpeedKmh,
    double? avgSpeedKmh,
    TrekSession? session,
  }) {
    return TrackingSessionState(
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      session: session ?? this.session,
    );
  }
}

/// Etats possibles d'une session de tracking.
enum TrackingSessionStatus {
  idle,
  recording,
  paused,
  stopped,
}

/// Provider du TrekRecorder (E2.8a).
///
/// Fournit une instance de TrekRecorder avec callbacks no-op.
/// Les callbacks sont overrides au moment du start pour brancher
/// sur Drift via les DAOs.
/// Overridable dans les tests.
final trekRecorderProvider = Provider<TrekRecorder>((ref) {
  return TrekRecorder(
    onFlush: (sessionId, points) async {},
    onSessionPersist: (session) async {},
  );
});

/// Provider du TrekStats (E2.8b).
///
/// Fournit une instance de TrekStats parametree avec la distance
/// totale du sentier. Par defaut 0 km (overridable).
/// Overridable dans les tests.
final trekStatsProvider = Provider<TrekStats>((ref) {
  return TrekStats(totalDistanceKm: 0.0);
});

/// Notifier de la session de tracking orchestrant TrekRecorder + TrekStats.
///
/// Responsabilites :
/// - Coordonner start / pause / resume / stop
/// - Mettre a jour l'etat expose a l'UI
/// - Deleguer l'enregistrement a TrekRecorder
/// - Deleguer les stats a TrekStats
class TrekSessionManagerNotifier extends Notifier<TrackingSessionState> {
  @override
  TrackingSessionState build() {
    return const TrackingSessionState();
  }

  /// Demarre une session de tracking sur le sentier [trailId].
  ///
  /// Cree la session via TrekRecorder.start() et passe en mode recording.
  /// Ne fait rien si une session est deja active.
  Future<void> start(String trailId) async {
    if (state.status == TrackingSessionStatus.recording ||
        state.status == TrackingSessionStatus.paused) {
      return;
    }

    final recorder = ref.read(trekRecorderProvider);
    final stats = ref.read(trekStatsProvider);
    stats.reset();

    final session = await recorder.start(trailId);
    state = TrackingSessionState(
      status: TrackingSessionStatus.recording,
      session: session,
    );
  }

  /// Met en pause le tracking.
  void pause() {
    if (state.status != TrackingSessionStatus.recording) {
      return;
    }

    final recorder = ref.read(trekRecorderProvider);
    recorder.pause();
    state = state.copyWith(status: TrackingSessionStatus.paused);
  }

  /// Reprend le tracking apres une pause.
  void resume() {
    if (state.status != TrackingSessionStatus.paused) {
      return;
    }

    final recorder = ref.read(trekRecorderProvider);
    recorder.resume();
    state = state.copyWith(status: TrackingSessionStatus.recording);
  }

  /// Arrete le tracking et finalise la session.
  Future<void> stop() async {
    if (state.status != TrackingSessionStatus.recording &&
        state.status != TrackingSessionStatus.paused) {
      return;
    }

    final recorder = ref.read(trekRecorderProvider);
    await recorder.stop();

    final stats = ref.read(trekStatsProvider);
    final finalState = TrackingSessionState(
      status: TrackingSessionStatus.stopped,
      distanceKm: stats.distanceKm,
      elevationGainM: stats.elevationGain,
      elapsedDuration: stats.elapsedDuration,
      currentSpeedKmh: 0.0,
      avgSpeedKmh: stats.avgSpeedKmh,
    );
    state = finalState;
  }

  /// Met a jour les stats depuis TrekStats.
  ///
  /// Appelee periodiquement par le pipeline GPS pour rafraichir
  /// les valeurs affichees dans l'overlay.
  void updateStats() {
    if (state.status != TrackingSessionStatus.recording) {
      return;
    }

    final stats = ref.read(trekStatsProvider);
    state = state.copyWith(
      distanceKm: stats.distanceKm,
      elevationGainM: stats.elevationGain,
      elapsedDuration: stats.elapsedDuration,
      currentSpeedKmh: stats.currentSpeedKmh,
      avgSpeedKmh: stats.avgSpeedKmh,
    );
  }
}

/// Provider principal du session manager de tracking.
///
/// Orchestre TrekRecorder (E2.8a) + TrekStats (E2.8b).
/// Expose un [TrackingSessionState] immutable a l'UI.
final trekSessionManagerProvider =
    NotifierProvider<TrekSessionManagerNotifier, TrackingSessionState>(
  TrekSessionManagerNotifier.new,
);
