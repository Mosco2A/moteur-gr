import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';
import 'package:moteur_gr/features/trek/domain/trail_data_provider.dart';
import 'package:moteur_gr/features/trek/providers/trail_providers.dart';

/// Implementation fake pour les tests.
///
/// Retourne des donnees fictives sans toucher a Drift.
class FakeTrailDataProvider implements TrailDataProvider {
  final List<Stage> _stages;

  FakeTrailDataProvider({List<Stage>? stages})
      : _stages = stages ??
            [
              const Stage(
                id: 'fake-1',
                nameFr: 'Etape Fake',
                nameEn: 'Fake Stage',
                distance: 10.0,
                elevationGain: 500,
                elevationLoss: 300,
                estimatedDurationMinutes: 200,
                orderIndex: 0,
                startLat: 42.0,
                startLng: 9.0,
                endLat: 42.1,
                endLng: 9.1,
              ),
            ];

  @override
  Future<List<Stage>> getStages() async => _stages;

  @override
  Future<List<TrackPoint>> getTrackPoints(String stageId) async => [];

  @override
  Future<TrailConfigData?> getTrailConfig() async => const TrailConfigData(
        id: 'fake-trail',
        name: 'Fake Trail',
        totalStages: 1,
        totalDistanceKm: 10.0,
        totalElevationGain: 500,
      );
}

/// Tests des providers Riverpod.
void main() {
  group('trailDataProvider', () {
    test('override avec FakeTrailDataProvider fonctionne', () async {
      final fake = FakeTrailDataProvider();

      final container = ProviderContainer(
        overrides: [
          trailDataProvider.overrideWithValue(fake),
        ],
      );

      // Lire le provider
      final provider = container.read(trailDataProvider);

      // Le provider est bien le fake injecte
      expect(provider, isA<FakeTrailDataProvider>());
      expect(provider, same(fake));

      // Appeler getStages via le provider
      final stages = await provider.getStages();
      expect(stages.length, 1);
      expect(stages[0].id, 'fake-1');
      expect(stages[0].nameFr, 'Etape Fake');

      container.dispose();
    });

    test('override avec stages custom', () async {
      final customStages = [
        const Stage(
          id: 'custom-1',
          nameFr: 'Calenzana - Ortu',
          nameEn: 'Calenzana - Ortu',
          distance: 12.5,
          elevationGain: 1500,
          elevationLoss: 200,
          estimatedDurationMinutes: 420,
          difficulty: 'hard',
          orderIndex: 0,
          startLat: 42.50,
          startLng: 8.85,
          endLat: 42.46,
          endLng: 8.93,
        ),
        const Stage(
          id: 'custom-2',
          nameFr: 'Ortu - Carrozzu',
          nameEn: 'Ortu - Carrozzu',
          distance: 7.0,
          elevationGain: 800,
          elevationLoss: 700,
          estimatedDurationMinutes: 300,
          difficulty: 'hard',
          orderIndex: 1,
          startLat: 42.46,
          startLng: 8.93,
          endLat: 42.43,
          endLng: 8.95,
        ),
      ];

      final fake = FakeTrailDataProvider(stages: customStages);

      final container = ProviderContainer(
        overrides: [
          trailDataProvider.overrideWithValue(fake),
        ],
      );

      final stages = await container.read(trailDataProvider).getStages();
      expect(stages.length, 2);
      expect(stages[0].nameFr, 'Calenzana - Ortu');
      expect(stages[1].nameFr, 'Ortu - Carrozzu');

      container.dispose();
    });

    test('trailConfigProvider sans override lance UnimplementedError', () {
      final container = ProviderContainer();

      expect(
        () => container.read(trailConfigProvider),
        throwsA(isA<UnimplementedError>()),
      );

      container.dispose();
    });

    test('trailConfigProvider avec override retourne la config', () {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );

      final config = container.read(trailConfigProvider);
      expect(config.id, 'test-trail');
      expect(config.name, 'Sentier des Volcans');

      container.dispose();
    });
  });
}
