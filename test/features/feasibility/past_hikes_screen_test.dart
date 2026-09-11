import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/presentation/past_hikes_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget de l'ecran « 5 dernieres randos » (StepWays LOT 4, Ph3).
/// Rendu i18n + non-regression overflow mobile + affichage des randos seedees.
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap() {
    final repo = HikerProfileRepository(db: db, prefs: prefs);
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hikerProfileRepositoryProvider.overrideWithValue(repo),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home/past-hikes',
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: SizedBox()),
                routes: [
                  GoRoute(
                    path: 'past-hikes',
                    builder: (_, __) => const PastHikesScreen(),
                  ),
                ],
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  group('PastHikesScreen', () {
    testWidgets('rendu i18n + etat vide + champ difficultes', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(t.pastHikes.title), findsWidgets);
      expect(find.text(t.pastHikes.intro), findsOneWidget);
      expect(find.text(t.pastHikes.empty), findsOneWidget);
      expect(find.text(t.pastHikes.addHike), findsOneWidget);
      expect(find.text(t.pastHikes.difficultiesTitle), findsOneWidget);
    });

    testWidgets('affiche les randos deja saisies (seed prefs)',
        (tester) async {
      // Seed 2 randos via le repo (prefs = source durable).
      final repo = HikerProfileRepository(db: db, prefs: prefs);
      await repo.savePastHikes([
        PastHike(
          date: DateTime(2026, 7, 1),
          days: 3,
          totalDistanceKm: 42,
          totalElevationGain: 2100,
          avgWalkHoursPerDay: 6,
        ),
        PastHike(
          date: DateTime(2026, 5, 10),
          days: 1,
          totalDistanceKm: 18,
          totalElevationGain: 800,
          avgWalkHoursPerDay: 5,
        ),
      ]);

      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Etat vide absent, 2 cartes rendues (dates affichees).
      expect(find.text(t.pastHikes.empty), findsNothing);
      expect(find.text('01/07/2026'), findsOneWidget);
      expect(find.text('10/05/2026'), findsOneWidget);
    });
  });
}
