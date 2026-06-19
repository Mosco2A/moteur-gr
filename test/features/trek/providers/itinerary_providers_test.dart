import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/stage_accommodation.dart';
import 'package:moteur_gr/features/trek/domain/trail_data_provider.dart';
import 'package:moteur_gr/features/trek/providers/itinerary_providers.dart';
import 'package:moteur_gr/features/trek/providers/seed_provider.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';
import 'package:moteur_gr/features/trek/providers/trail_providers.dart';

/// Fake TrailDataProvider pour les tests.
class FakeTrailDataProvider implements TrailDataProvider {
  FakeTrailDataProvider({required this.stages, required this.config});

  final List<StageModel> stages;
  final TrailConfig config;

  @override
  Future<List<StageModel>> getStages(String trailId) async => stages;

  @override
  Future<List<TrackPoint>> getTrackPoints(String stageId) async => [];

  @override
  Future<List<StageAccommodation>> getAccommodations(
    String trailId, {
    int? stageNumber,
  }) async =>
      [];

  @override
  TrailConfig getTrailConfig() => config;
}

void main() {
  const testConfig = TrailConfig(
    id: 'test-trail',
    name: 'Test Trail',
    displayName: 'Sentier Test',
    tagline: 'Un sentier de test',
    totalStages: 3,
    totalDistanceKm: 26.0,
    totalElevationGain: 3200,
    region: 'Test',
    country: 'France',
    primaryColorValue: 0xFF2196F3,
    secondaryColorValue: 0xFF03A9F4,
    gpxAssetPath: 'assets/gpx/test.gpx',
  );

  const stage1 = StageModel(
    trailId: 'test-trail',
    stageNumber: 1,
    name: 'Depart - Refuge A',
    distanceKm: 12.0,
    elevationGainM: 1500,
    elevationLossM: 100,
    startLat: 42.5,
    startLng: 8.8,
    endLat: 42.45,
    endLng: 8.9,
  );

  const stage2 = StageModel(
    trailId: 'test-trail',
    stageNumber: 2,
    name: 'Refuge A - Refuge B',
    distanceKm: 8.0,
    elevationGainM: 800,
    elevationLossM: 700,
    startLat: 42.45,
    startLng: 8.9,
    endLat: 42.42,
    endLng: 8.95,
  );

  const stage3 = StageModel(
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Refuge B - Arrivee',
    distanceKm: 6.0,
    elevationGainM: 900,
    elevationLossM: 600,
    startLat: 42.42,
    startLng: 8.95,
    endLat: 42.4,
    endLng: 9.0,
  );

  // stagesProvider (non-famille) attend desormais trailSeedProvider, qui lit
  // sharedPreferencesProvider : on l'override avec un mock. testConfig n'a pas
  // de seedAssetsBase -> seedIfNeeded() est un no-op et le FakeTrailDataProvider
  // reste la seule source des 3 etapes.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('itineraryProvider', () {
    test('retourne des ItineraryDays corrects avec 3 etapes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeDataProvider = FakeTrailDataProvider(
        stages: [stage1, stage2, stage3],
        config: testConfig,
      );

      final container = ProviderContainer(
        overrides: [
          trailDataProvider.overrideWithValue(fakeDataProvider),
          trailConfigProvider.overrideWithValue(testConfig),
          currentTrailIdProvider.overrideWith((ref) => 'test-trail'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Attendre le resultat de itineraryProvider
      final result = await container.read(itineraryProvider.future);

      // Verifier que le resultat n'est pas vide
      expect(result, isNotEmpty);

      // Verifier que chaque jour a un dayNumber correct (1-indexed)
      for (var i = 0; i < result.length; i++) {
        expect(result[i].dayNumber, i + 1);
      }

      // Verifier que toutes les etapes sont distribuees
      final totalStages = result.fold<int>(
        0,
        (sum, day) => sum + day.stageCount,
      );
      expect(totalStages, 3);

      // Verifier que chaque jour a une distance > 0
      for (final day in result) {
        expect(day.totalDistance, greaterThan(0));
        expect(day.estimatedHours, greaterThan(0));
        expect(day.totalElevation, greaterThan(0));
        expect(day.stages, isNotEmpty);
      }

      // Avec maxKmPerDay=20 et maxHoursPerDay=8 (defauts) :
      // stage1 = 12km, ~6.75h -> jour 1 (OK)
      // stage2 = 8km, ~4h -> jour 1 cumul 20km ~10.75h -> depasse 8h -> jour 2
      // stage3 = 6km, ~3.75h -> jour 2 cumul 14km ~7.75h -> OK
      // Resultat attendu : 2 jours minimum
      expect(result.length, greaterThanOrEqualTo(2));

      // Jour 1 : stage1 seule (12km)
      expect(result[0].stages.length, 1);
      expect(result[0].totalDistance, 12.0);
      expect(result[0].stages[0].name, 'Depart - Refuge A');
    });
  });
}
