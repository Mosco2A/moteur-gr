import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart' show UserProgressEntry;
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';

/// StepWays LOT 2, §1 — agregat derive [TrekSummary] : lastActivityAt + fraction
/// de progression, sans base ni provider.
void main() {
  const config = TrailConfig(
    id: 'gr20',
    name: 'GR20',
    displayName: 'GR20',
    tagline: 'tagline',
    totalStages: 10,
    totalDistanceKm: 180.0,
    totalElevationGain: 12000,
    region: 'Corse',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/gr20.gpx',
  );

  TrekSession session({
    String status = 'active',
    List<String> completed = const [],
    DateTime? startedAt,
    DateTime? finishedAt,
  }) =>
      TrekSession(
        id: 'sess-1',
        trailId: 'gr20',
        startedAt: startedAt ?? DateTime.utc(2026, 6, 15, 8),
        finishedAt: finishedAt,
        status: status,
        completedStages: completed,
      );

  UserProgressEntry progress({
    int currentStage = 1,
    DateTime? startedAt,
    DateTime? completedAt,
  }) =>
      UserProgressEntry(
        id: 1,
        trailId: 'gr20',
        currentStage: currentStage,
        totalDistanceWalkedKm: 0,
        totalElevationGainedM: 0,
        totalTimeMinutes: 0,
        isCompleted: completedAt != null,
        startedAt: startedAt,
        completedAt: completedAt,
      );

  group('progressFraction', () {
    test('completed -> 1.0 quelles que soient les etapes', () {
      const summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.completed,
      );
      expect(summary.progressFraction, 1.0);
    });

    test('etapes marchees de la session priment (5/10 -> 0.5)', () {
      final summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.inProgress,
        latestSession: session(completed: ['s1', 's2', 's3', 's4', 's5']),
      );
      expect(summary.progressFraction, 0.5);
    });

    test('a defaut, etape courante 1-based (currentStage 4 -> 3/10)', () {
      final summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.prepared,
        progress: progress(currentStage: 4),
      );
      expect(summary.progressFraction, closeTo(0.3, 1e-9));
    });

    test('currentStage 1 -> 0.0 (aucune etape terminee)', () {
      final summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.prepared,
        progress: progress(currentStage: 1),
      );
      expect(summary.progressFraction, 0.0);
    });

    test('rien -> 0.0', () {
      const summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.owned,
      );
      expect(summary.progressFraction, 0.0);
    });

    test('borne a 1.0 sur donnees incoherentes (etapes > total)', () {
      final summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.inProgress,
        latestSession: session(
          completed: List.generate(20, (i) => 's$i'),
        ),
      );
      expect(summary.progressFraction, 1.0);
    });
  });

  group('lastActivityAt', () {
    test('null si aucun signal (trek juste possede)', () {
      const summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.owned,
      );
      expect(summary.lastActivityAt, isNull);
    });

    test('prend la fin de session si presente (plus recent que le debut)', () {
      final summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.completed,
        latestSession: session(
          startedAt: DateTime.utc(2026, 6, 15, 8),
          finishedAt: DateTime.utc(2026, 6, 18, 17),
          status: 'completed',
        ),
      );
      expect(summary.lastActivityAt, DateTime.utc(2026, 6, 18, 17));
    });

    test('retombe sur le debut de session si pas de fin', () {
      final summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.inProgress,
        latestSession: session(startedAt: DateTime.utc(2026, 6, 15, 8)),
      );
      expect(summary.lastActivityAt, DateTime.utc(2026, 6, 15, 8));
    });

    test('utilise la progression si aucune session', () {
      final summary = TrekSummary(
        config: config,
        state: TrekLifecycleState.prepared,
        progress: progress(startedAt: DateTime.utc(2026, 5, 1, 9)),
      );
      expect(summary.lastActivityAt, DateTime.utc(2026, 5, 1, 9));
    });
  });

  test('trailId raccourci sur la config', () {
    const summary = TrekSummary(
      config: config,
      state: TrekLifecycleState.owned,
    );
    expect(summary.trailId, 'gr20');
  });
}
