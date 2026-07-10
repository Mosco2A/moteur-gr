import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../shared/services/location_permission_service.dart';
import '../../map/providers/track_position_provider.dart';
import '../data/background_gps_service.dart';
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
/// Fournit une instance de TrekRecorder. La persistence Drift des
/// points est branchee au moment du start (DAOs).
/// E5.19a : chaque flush met a jour les donnees du widget Home
/// Screen (WidgetDataService) avec la progression courante.
/// Overridable dans les tests.
final trekRecorderProvider = Provider<TrekRecorder>((ref) {
  return TrekRecorder(
    onFlush: (sessionId, points) async {
      // E5.19a — MAJ widget Home Screen a chaque flush (10 positions).
      final config = ref.read(trailConfigProvider);
      final widgetData = ref.read(widgetDataServiceProvider);
      final tracking = ref.read(trekSessionManagerProvider);

      final totalKm = config.totalDistanceKm;
      // Coherence accueil<->carte (correctif build 117, spec AM-5/RM-2) :
      // le « parcouru » et la progression du widget Home lisent la source
      // PROJETEE sur le trace (stageDistanceCoveredProvider), JAMAIS le cumul
      // GPS brut (tracking.distanceKm) qui gonfle sur un aller-retour.
      final doneKm = ref.read(stageDistanceCoveredProvider) / 1000;
      final progress = totalKm > 0 ? (doneKm / totalKm) : 0.0;
      final remainingKm =
          (totalKm - doneKm) < 0 ? 0.0 : (totalKm - doneKm);
      final etaMinutes = tracking.avgSpeedKmh > 0.5
          ? (remainingKm / tracking.avgSpeedKmh * 60).round()
          : 0;
      final altitude = points.isNotEmpty ? points.last.elevation : 0.0;

      await widgetData.updateWidgetData(
        trailName: config.name,
        // Le nom d'etape detaille arrive avec la detection d'etape ;
        // en attendant, le widget affiche le sentier + progression.
        stageName: config.name,
        stageProgress: progress,
        distanceRemaining: remainingKm * 1000,
        etaMinutes: etaMinutes,
        altitude: altitude,
        stageIndex: 0,
        totalStages: config.totalStages,
        themeColorValue: config.primaryColorValue,
      );
    },
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
  /// Abonnement aux points captes par l'isolate de fond (ecran eteint), pour
  /// les persister dans la trace de session (sessionTrackPoints).
  StreamSubscription<BgTrackPoint>? _bgPointsSub;

  @override
  TrackingSessionState build() {
    ref.onDispose(() {
      _bgPointsSub?.cancel();
    });
    return const TrackingSessionState();
  }

  /// Persiste un point capte de fond dans la table de trace (sessionTrackPoints)
  /// via le DAO Drift, en dedupliquant implicitement par la source (l'isolate de
  /// fond applique deja son filtre de distance). Best-effort.
  Future<void> _persistBgPoint(BgTrackPoint p) async {
    final trailId = p.trailId.isNotEmpty ? p.trailId : _activeTrailId;
    if (trailId == null || trailId.isEmpty) return;
    final dao = ref.read(databaseProvider).sessionTrackPointsDao;
    await dao.insertPoint(
      trailId: trailId,
      lat: p.latitude,
      lng: p.longitude,
      altitude: p.altitude,
      recordedAt: p.timestamp,
    );
  }

  /// Draine le tampon de points captes ecran eteint (rempli par l'isolate de
  /// fond) et les insere dans la trace. Appele au demarrage et au retour d'app.
  Future<void> _drainBackgroundBuffer() async {
    final service = ref.read(backgroundGpsServiceProvider);
    final points = await service.drainBackgroundPoints();
    for (final p in points) {
      await _persistBgPoint(p);
    }
  }

  /// Sentier de la session active (pour rattacher les points de fond).
  String? _activeTrailId;

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
    _activeTrailId = trailId;
    state = TrackingSessionState(
      status: TrackingSessionStatus.recording,
      session: session,
    );

    // Capture GPS de fond fiabilisee (re-portage socle) : la trace ne doit pas
    // se couper ecran eteint. On (1) escalade les permissions de fond
    // (Toujours + notifications + exemption batterie) AU LANCEMENT du trek,
    // (2) demarre l'isolate de fond, (3) draine tout point deja tamponne, et
    // (4) persiste les points captes de fond dans la trace. Best-effort et NON
    // bloquant pour le premier plan (le tracking UI marche deja) : une escalade
    // de fond ratee ne casse jamais le demarrage.
    unawaited(_startBackgroundCapture(session.id, trailId));
  }

  /// Demarre la capture de fond + branche la persistance des points. Isole du
  /// chemin de demarrage principal (fire-and-forget) : ne jette jamais.
  Future<void> _startBackgroundCapture(String sessionId, String trailId) async {
    try {
      // Escalade permissions de fond (Toujours) + notifications + exemption
      // batterie (cas Samsung), demandee AU LANCEMENT du trek.
      await ref
          .read(locationPermissionServiceProvider)
          .ensureBackgroundTracking();

      final service = ref.read(backgroundGpsServiceProvider);

      // Brancher la persistance AVANT le start pour ne perdre aucun point.
      await _bgPointsSub?.cancel();
      _bgPointsSub = service.trackPointStream.listen((p) {
        unawaited(_persistBgPoint(p));
      });

      await service.start(
        sessionId: sessionId,
        trailId: trailId,
        stageInfo: ref.read(trailConfigProvider).displayName,
      );

      // Draine un eventuel reliquat tamponne (session precedente interrompue).
      await _drainBackgroundBuffer();
    } catch (_) {
      // Best-effort : la capture de fond ne doit jamais casser le trek.
    }
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

    // Arreter la capture de fond, draîner le reliquat et couper l'abonnement.
    try {
      final service = ref.read(backgroundGpsServiceProvider);
      await service.stop();
      await _drainBackgroundBuffer();
    } catch (_) {
      // Best-effort : l'arret du service ne doit pas empecher la finalisation.
    }
    await _bgPointsSub?.cancel();
    _bgPointsSub = null;
    _activeTrailId = null;

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

  /// Termine le trek suite a la **detection d'arrivee a la derniere etape**
  /// (evenement `trailEnd`, direction-aware). Finalise comme [stop] (statut
  /// `completed` via TrekRecorder), mais declenche par la detection et non par
  /// l'appui manuel sur « Terminer ». Idempotent : ne fait rien hors session
  /// active. La completion n'a lieu qu'a la vraie derniere etape du parcours
  /// dans le sens de marche.
  Future<void> completeOnArrival() async {
    if (state.status != TrackingSessionStatus.recording &&
        state.status != TrackingSessionStatus.paused) {
      return;
    }
    await stop();
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
