import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';
import 'package:moteur_gr/features/after/presentation/adventure_recap_screen.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20, LOT 3 (#99433), point 3.A / critere (c) — l'ecran Recap
/// « Mon aventure » affiche les stats de la SESSION REELLE et est accessible
/// aussi bien pour un FINISHER que pour un ABANDON ; verrouille sinon.
void main() {
  const trailId = 'test-trail-recap';

  const config = TrailConfig(
    id: trailId,
    name: 'Test Trail',
    displayName: 'Test Trail',
    tagline: 'tagline',
    totalStages: 4,
    totalDistanceKm: 999.0,
    totalElevationGain: 99999,
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

  TrekSession sess({
    required String status,
    List<String> completed = const [],
    bool fullyWalked = false,
    DateTime? finishedAt,
  }) =>
      TrekSession(
        id: 'sess-recap',
        trailId: trailId,
        startedAt: DateTime.utc(2026, 6, 15, 8),
        finishedAt: finishedAt,
        status: status,
        completedStages: completed,
        parcoursFullyWalked: fullyWalked,
      );

  Future<void> pumpRecap(
    WidgetTester tester, {
    bool showcase = false,
  }) async {
    LocaleSettings.setLocaleRaw('fr');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(config),
          currentTrailIdProvider.overrideWith((ref) => trailId),
          demoModeServiceProvider.overrideWithValue(
            DemoModeService(
              showcaseTrailIds: showcase ? {trailId} : <String>{},
            ),
          ),
        ],
        // AppHeader (Ph5/L6d) utilise GoRouter -> GoRouter minimal (+ /my-treks).
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/recap',
            routes: [
              GoRoute(
                  path: '/recap',
                  builder: (_, __) => const AdventureRecapScreen()),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
              // R10 (LOT L10) : cible du nouveau bouton « Voir mon journal ».
              GoRoute(
                path: '/journal',
                builder: (_, __) => const Text('ECRAN JOURNAL'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
  }

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('FINISHER : recap affiche stats reelles + bandeau finisher',
      (tester) async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
    await db.trekSessionsDao.upsertSession(sess(
      status: 'completed',
      completed: const ['1', '2', '3', '4'],
      fullyWalked: true,
      finishedAt: DateTime.utc(2026, 6, 18, 18),
    ));

    await pumpRecap(tester);

    // Titre de l'ecran.
    expect(find.text(t.recap.title), findsWidgets);
    // Bandeau finisher (parcours fini).
    expect(find.text(t.recap.finisherTitle), findsOneWidget);
    // Stats reelles : 4/4 etapes, 40 km, 2000 m D+ (pas les totaux config).
    expect(
      find.text(t.recap.stages
          .replaceAll('{done}', '4')
          .replaceAll('{total}', '4')),
      findsOneWidget,
    );
    expect(
      find.text(t.recap.distance.replaceAll('{km}', '40')),
      findsOneWidget,
    );
    expect(
      find.text(t.recap.elevation.replaceAll('{meters}', '2000')),
      findsOneWidget,
    );
    // Le bouton diplome est propose (finisher deverrouille).
    expect(find.text(t.recap.viewDiploma), findsOneWidget);
  });

  testWidgets('ABANDON : recap accessible + bandeau parcours partiel',
      (tester) async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
    await db.trekSessionsDao.upsertSession(sess(
      status: 'abandoned',
      completed: const ['1', '2'],
      fullyWalked: false,
      finishedAt: DateTime.utc(2026, 6, 16, 12),
    ));

    await pumpRecap(tester);

    // Accessible sur abandon (parite GR20 chantier C).
    expect(find.text(t.recap.partialTitle), findsOneWidget);
    // Stats reelles : 2/4 etapes marchees, 20 km.
    expect(
      find.text(t.recap.stages
          .replaceAll('{done}', '2')
          .replaceAll('{total}', '4')),
      findsOneWidget,
    );
    expect(
      find.text(t.recap.distance.replaceAll('{km}', '20')),
      findsOneWidget,
    );
    // Pas de bouton diplome sur un abandon non-vitrine (diplome verrouille).
    expect(find.text(t.recap.viewDiploma), findsNothing);
  });

  testWidgets('ACTIF (ni fini ni abandonne, hors vitrine) : etat verrouille',
      (tester) async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
    await db.trekSessionsDao.upsertSession(sess(status: 'active'));

    await pumpRecap(tester);

    // Etat verrouille (parite GR20) : titre « disponible a la fin » + cadenas.
    expect(find.text(t.recap.lockedTitle), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    // Pas de bandeau finisher/partiel.
    expect(find.text(t.recap.finisherTitle), findsNothing);
    expect(find.text(t.recap.partialTitle), findsNothing);
  });

  testWidgets('VITRINE : recap accessible meme sans session', (tester) async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
    // Aucune session persistee.
    await pumpRecap(tester, showcase: true);

    // Accessible (demo) : pas d'etat verrouille.
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text(t.recap.statsSection), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // R10 (retour Chris, LOT L10) — 2e PORTE D'ENTREE DU JOURNAL
  //
  // GR20 pousse vers le journal depuis « Mon aventure ». Cote StepWays cette
  // entree etait absente : une fois le trek termine, relire ses notes imposait
  // de repasser par le cockpit. Contrairement au diplome, elle n'est PAS
  // gardee : le journal appartient au randonneur, fini ou abandonne.
  // -------------------------------------------------------------------------
  group('R10 — entree JOURNAL depuis l\'ecran apres-trek', () {
    testWidgets('FINISHER : le bouton Journal est propose', (tester) async {
      await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
      await db.trekSessionsDao.upsertSession(sess(
        status: 'completed',
        completed: const ['1', '2', '3', '4'],
        fullyWalked: true,
        finishedAt: DateTime.utc(2026, 6, 18, 18),
      ));

      await pumpRecap(tester);

      expect(find.text(t.recap.viewJournal), findsOneWidget);
    });

    testWidgets('ABANDON : le Journal reste propose MEME sans diplome',
        (tester) async {
      await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
      await db.trekSessionsDao.upsertSession(sess(
        status: 'abandoned',
        completed: const ['1', '2'],
        fullyWalked: false,
        finishedAt: DateTime.utc(2026, 6, 16, 12),
      ));

      await pumpRecap(tester);

      // Le diplome, lui, reste verrouille : les deux boutons sont independants.
      expect(find.text(t.recap.viewDiploma), findsNothing);
      expect(find.text(t.recap.viewJournal), findsOneWidget);
    });

    testWidgets('le bouton Journal OUVRE bien l\'ecran journal', (tester) async {
      await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
      await db.trekSessionsDao.upsertSession(sess(
        status: 'completed',
        completed: const ['1', '2', '3', '4'],
        fullyWalked: true,
        finishedAt: DateTime.utc(2026, 6, 18, 18),
      ));

      await pumpRecap(tester);

      // Le bouton vit en BAS du scroll (sous la ligne de flottaison de la
      // surface de test 800x600) : on l'amene a l'ecran avant de taper.
      await tester.ensureVisible(find.text(t.recap.viewJournal));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.recap.viewJournal));
      await tester.pumpAndSettle();

      expect(find.text('ECRAN JOURNAL'), findsOneWidget);
    });
  });
}
