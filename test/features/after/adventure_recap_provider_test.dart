import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';
import 'package:moteur_gr/features/after/providers/adventure_recap_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';

/// PARITE GR20, LOT 3 (#99433) — tests du socle « Apres le trek » :
///   (a) diplome VERROUILLE sur un vrai trek non fini, DEVERROUILLE sur vitrine ;
///   (b) les stats/DiplomaData refletent la SESSION REELLE, pas les totaux
///       statiques du sentier ;
///   (d) libelle Integral/partiel derive du parcours reel.
///
/// Ces tests operent au niveau PROVIDER (rapides, deterministes) sur une base
/// Drift in-memory. Les tests d'ecran (Recap finisher/abandon, gate diplome)
/// sont dans adventure_recap_screen_test.dart / diploma_gate_test.dart.
void main() {
  const trailId = 'test-trail-lot3';

  // 4 etapes de 10 km / 500 m D+ chacune (totaux « statiques » differents des
  // valeurs reelles marchees, pour prouver qu'on lit bien la session).
  const config = TrailConfig(
    id: trailId,
    name: 'Test Trail',
    displayName: 'Test Trail',
    tagline: 'tagline',
    totalStages: 4,
    totalDistanceKm: 999.0, // volontairement absurde vs reel
    totalElevationGain: 99999, // volontairement absurde vs reel
    region: 'Region',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 4,
    availableDurations: [2, 4, 6],
  );

  late AppDatabase db;

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

  Future<void> seedStages() async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
  }

  Future<void> persistSession(TrekSession s) async {
    await db.trekSessionsDao.upsertSession(s);
  }

  TrekSession sess({
    String status = 'active',
    List<String> completed = const [],
    bool fullyWalked = false,
    DateTime? finishedAt,
  }) =>
      TrekSession(
        id: 'sess-lot3',
        trailId: trailId,
        startedAt: DateTime.utc(2026, 6, 15, 8),
        finishedAt: finishedAt,
        status: status,
        completedStages: completed,
        parcoursFullyWalked: fullyWalked,
      );

  /// Container avec vitrine ON/OFF (injection [DemoModeService.showcaseTrailIds]).
  ProviderContainer makeContainer({required bool showcase}) {
    return ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      trailConfigProvider.overrideWithValue(config),
      currentTrailIdProvider.overrideWith((ref) => trailId),
      demoModeServiceProvider.overrideWithValue(
        DemoModeService(showcaseTrailIds: showcase ? {trailId} : <String>{}),
      ),
    ]);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('DAO getLatestByTrailId', () {
    test('retourne la session la plus recente du sentier', () async {
      await persistSession(sess().copyWith(
        id: 'older',
        startedAt: DateTime.utc(2026, 6, 10),
      ));
      await persistSession(sess().copyWith(
        id: 'newer',
        startedAt: DateTime.utc(2026, 6, 20),
        status: 'completed',
      ));

      final latest = await db.trekSessionsDao.getLatestByTrailId(trailId);
      expect(latest, isNotNull);
      expect(latest!.id, 'newer');
    });

    test('null si aucune session pour le sentier', () async {
      final latest = await db.trekSessionsDao.getLatestByTrailId('autre');
      expect(latest, isNull);
    });
  });

  group('(a) Gate diplome finisher + exception vitrine', () {
    test('VRAI trek non fini (non-vitrine) -> diplome VERROUILLE', () async {
      await seedStages();
      // Session enregistree mais parcours non entierement marche.
      await persistSession(sess(
        status: 'completed',
        completed: const ['1', '2'],
        fullyWalked: false,
      ));

      final c = makeContainer(showcase: false);
      addTearDown(c.dispose);
      await c.read(latestTrekSessionProvider.future);

      expect(c.read(isShowcaseTrailProvider), isFalse);
      expect(c.read(isDiplomaUnlockedProvider), isFalse,
          reason: 'Hors vitrine, !parcoursFullyWalked => verrouille.');
    });

    test('VRAI trek FINI (fullyWalked) -> diplome DEVERROUILLE', () async {
      await seedStages();
      await persistSession(sess(
        status: 'completed',
        completed: const ['1', '2', '3', '4'],
        fullyWalked: true,
      ));

      final c = makeContainer(showcase: false);
      addTearDown(c.dispose);
      await c.read(latestTrekSessionProvider.future);

      expect(c.read(isDiplomaUnlockedProvider), isTrue,
          reason: 'parcoursFullyWalked => deverrouille.');
    });

    test('VITRINE sans session -> diplome DEVERROUILLE (demo)', () async {
      await seedStages();
      // Aucune session persistee : sur un vrai trek ce serait verrouille.
      final c = makeContainer(showcase: true);
      addTearDown(c.dispose);
      await c.read(latestTrekSessionProvider.future);

      expect(c.read(isShowcaseTrailProvider), isTrue);
      expect(c.read(isDiplomaUnlockedProvider), isTrue,
          reason: 'La vitrine deverrouille le diplome pour la demonstration.');
    });
  });

  group('(b) Stats REELLES (session, pas totaux statiques)', () {
    test('distance/D+/etapes = somme des etapes REELLEMENT marchees', () async {
      await seedStages();
      // 3 etapes marchees sur 4 : 30 km, 1500 m D+ (vs 999 km / 99999 config).
      await persistSession(sess(
        status: 'abandoned',
        completed: const ['1', '2', '3'],
        fullyWalked: false,
        finishedAt: DateTime.utc(2026, 6, 17, 18),
      ));

      final c = makeContainer(showcase: false);
      addTearDown(c.dispose);
      final stats = await c.read(adventureStatsProvider.future);

      expect(stats.stagesWalked, 3);
      expect(stats.totalStages, 4);
      expect(stats.distanceKm, 30.0);
      expect(stats.elevationGainM, 1500);
      // Duree reelle : 15 -> 17 juin = 3 jours entames.
      expect(stats.durationDays, 3);
      expect(stats.fullyWalked, isFalse);
      // La preuve « pas les totaux statiques » : ces valeurs ne sont PAS celles
      // du sentier (999 km / 99999 m / 4 jours).
      expect(stats.distanceKm, isNot(equals(config.totalDistanceKm)));
      expect(stats.elevationGainM, isNot(equals(config.totalElevationGain)));
    });

    test('aucune etape marchee -> stats a zero (hasWalkedStages=false)',
        () async {
      await seedStages();
      await persistSession(sess(status: 'abandoned'));

      final c = makeContainer(showcase: false);
      addTearDown(c.dispose);
      final stats = await c.read(adventureStatsProvider.future);

      expect(stats.stagesWalked, 0);
      expect(stats.hasWalkedStages, isFalse);
      expect(stats.distanceKm, 0.0);
      expect(stats.elevationGainM, 0);
    });
  });

  group('(c-support) Disponibilite du recap', () {
    test('TERMINE -> recap disponible', () async {
      await persistSession(sess(status: 'completed'));
      final c = makeContainer(showcase: false);
      addTearDown(c.dispose);
      await c.read(latestTrekSessionProvider.future);
      expect(c.read(isRecapAvailableProvider), isTrue);
    });

    test('ABANDONNE -> recap disponible', () async {
      await persistSession(sess(status: 'abandoned'));
      final c = makeContainer(showcase: false);
      addTearDown(c.dispose);
      await c.read(latestTrekSessionProvider.future);
      expect(c.read(isRecapAvailableProvider), isTrue);
    });

    test('ACTIF (ni fini ni abandonne, hors vitrine) -> recap indisponible',
        () async {
      await persistSession(sess(status: 'active'));
      final c = makeContainer(showcase: false);
      addTearDown(c.dispose);
      await c.read(latestTrekSessionProvider.future);
      expect(c.read(isRecapAvailableProvider), isFalse);
    });

    test('VITRINE -> recap disponible meme sans session', () async {
      final c = makeContainer(showcase: true);
      addTearDown(c.dispose);
      await c.read(latestTrekSessionProvider.future);
      expect(c.read(isRecapAvailableProvider), isTrue);
    });
  });

  group('(d) Libelle Integral / partiel (TrekCongratulations)', () {
    test('parcours ENTIER -> congratulations.isFull == true', () async {
      await seedStages();
      final c = makeContainer(showcase: false);
      addTearDown(c.dispose);
      // Laisser stagesProvider se charger (domainStages -> plan).
      await c.read(stagesProvider.future);
      final congrats = c.read(adventureCongratulationsProvider);
      expect(congrats, isNotNull);
      expect(congrats!.isFull, isTrue,
          reason: 'Parcours = sentier entier => Integral.');
    });
  });
}
