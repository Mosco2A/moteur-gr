import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';
import 'package:moteur_gr/features/after/providers/adventure_recap_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';

/// CORRECTIF L5-5 — DETAIL JOUR PAR JOUR DE L'AVENTURE.
///
/// Rien de tel n'existait cote StepWays. L'ECART DE MODELE est le point
/// sensible : le journal de reference pose un jour = une etape en jours
/// calendaires. Un sentier generique connait les journees de repos, les
/// doubles etapes et les etapes a cheval sur deux jours ; recopier cet
/// algorithme casserait le modele StepWays. Une journee porte donc une
/// LISTE d'etapes, parfois vide, parfois multiple.
void main() {
  const trailId = 'test-trail-l5';

  const config = TrailConfig(
    id: trailId,
    name: 'Test Trail',
    displayName: 'Test Trail',
    tagline: 'tagline',
    totalStages: 4,
    totalDistanceKm: 40.0,
    totalElevationGain: 2000,
    region: 'Region',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 4,
    availableDurations: [2, 4, 6],
  );

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  StagesCompanion stage(int n) => StagesCompanion(
        trailId: const Value(trailId),
        stageNumber: Value(n),
        name: Value('Etape $n'),
        distanceKm: const Value(10.0),
        elevationGainM: const Value(500),
        elevationLossM: const Value(400),
        description: const Value('desc'),
        startLat: const Value(42.0),
        startLng: const Value(9.0),
        endLat: const Value(42.1),
        endLng: const Value(9.1),
        difficulty: const Value('moderate'),
      );

  Future<void> traceAt({
    required DateTime at,
    required double lat,
    int? dayIndex,
    String? stageId,
    double altitude = 900,
  }) {
    return db.sessionTrackPointsDao.insertPoint(
      trailId: trailId,
      sessionId: 'sess-l5',
      dayIndex: dayIndex,
      stageId: stageId,
      lat: lat,
      lng: 9.0,
      altitude: altitude,
      recordedAt: at,
    );
  }

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(config),
        currentTrailIdProvider.overrideWith((ref) => trailId),
        demoModeServiceProvider.overrideWithValue(
          DemoModeService(showcaseTrailIds: const <String>{}),
        ),
      ]);

  Future<void> seed() async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
    await db.trekSessionsDao.upsertSession(TrekSession(
      id: 'sess-l5',
      trailId: trailId,
      startedAt: DateTime.utc(2026, 6, 10, 8),
      finishedAt: DateTime.utc(2026, 6, 13, 18),
      status: 'completed',
      completedStages: const ['1', '2', '3'],
    ));
  }

  group('L5-5 — journees derivees de la trace', () {
    test('une journee par jour de marche, chiffres mesures', () async {
      await seed();
      final base = DateTime.utc(2026, 6, 10, 8);
      await traceAt(at: base, lat: 42.000, dayIndex: 1, stageId: '1');
      await traceAt(
          at: base.add(const Duration(hours: 3)),
          lat: 42.020,
          dayIndex: 1,
          stageId: '1',
          altitude: 1200);
      await traceAt(
          at: base.add(const Duration(days: 1)),
          lat: 43.000,
          dayIndex: 2,
          stageId: '2');
      await traceAt(
          at: base.add(const Duration(days: 1, hours: 4)),
          lat: 43.030,
          dayIndex: 2,
          stageId: '2');

      final c = makeContainer();
      addTearDown(c.dispose);
      final days = await c.read(adventureDaysProvider.future);

      expect(days.length, 2);
      expect(days.first.dayIndex, 1);
      expect(days.first.stageIds, ['1']);
      expect(days.first.stats.distanceKm, closeTo(2.22, 0.1));
      expect(days.first.stats.elevationGainM, 300);
      expect(days.first.stats.duration, const Duration(hours: 3));
      expect(days.last.dayIndex, 2);
    });

    test('DOUBLE ETAPE : une journee porte PLUSIEURS etapes', () async {
      await seed();
      final base = DateTime.utc(2026, 6, 10, 6);
      await traceAt(at: base, lat: 42.00, dayIndex: 1, stageId: '1');
      await traceAt(
          at: base.add(const Duration(hours: 4)),
          lat: 42.05,
          dayIndex: 1,
          stageId: '1');
      await traceAt(
          at: base.add(const Duration(hours: 5)),
          lat: 42.06,
          dayIndex: 1,
          stageId: '2');
      await traceAt(
          at: base.add(const Duration(hours: 9)),
          lat: 42.10,
          dayIndex: 1,
          stageId: '2');

      final c = makeContainer();
      addTearDown(c.dispose);
      final days = await c.read(adventureDaysProvider.future);

      expect(days.length, 1);
      // Copier l'algorithme « un jour = une etape » aurait scinde ce jour
      // en deux, ou en aurait perdu une.
      expect(days.single.stageIds, ['1', '2']);
    });

    test('JOURNEE DE REPOS : aucune etape, la journee existe quand meme',
        () async {
      await seed();
      final base = DateTime.utc(2026, 6, 10, 8);
      await traceAt(at: base, lat: 42.00, dayIndex: 1, stageId: '1');
      await traceAt(
          at: base.add(const Duration(hours: 2)),
          lat: 42.02,
          dayIndex: 1,
          stageId: '1');
      // Jour 2 : une balade autour du village, aucune etape terminee.
      await traceAt(at: base.add(const Duration(days: 1)), lat: 42.02, dayIndex: 2);
      await traceAt(
          at: base.add(const Duration(days: 1, hours: 1)),
          lat: 42.025,
          dayIndex: 2);

      final c = makeContainer();
      addTearDown(c.dispose);
      final days = await c.read(adventureDaysProvider.future);

      expect(days.length, 2);
      expect(days.last.stageIds, isEmpty);
      expect(days.last.stats.hasData, isTrue);
    });

    test('trace anterieure a la migration v26 : regroupement calendaire',
        () async {
      await seed();
      final base = DateTime.utc(2026, 6, 10, 8);
      // Aucun dayIndex : ces points sont des rescapes de l'ancien schema.
      await traceAt(at: base, lat: 42.00);
      await traceAt(at: base.add(const Duration(hours: 2)), lat: 42.02);
      await traceAt(at: base.add(const Duration(days: 1)), lat: 43.00);
      await traceAt(at: base.add(const Duration(days: 1, hours: 2)), lat: 43.02);

      final c = makeContainer();
      addTearDown(c.dispose);
      final days = await c.read(adventureDaysProvider.future);

      expect(days.length, 2);
      expect(days.every((d) => d.dayIndex == null), isTrue);
      expect(days.first.date, DateTime(2026, 6, 10));
    });

    test('aucune trace : liste vide, pas une journee fantome', () async {
      await seed();
      final c = makeContainer();
      addTearDown(c.dispose);
      expect(await c.read(adventureDaysProvider.future), isEmpty);
    });
  });
}
