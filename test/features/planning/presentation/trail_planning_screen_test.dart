import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/presentation/trail_planning_screen.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests de l'ecran PROGRAMME (parite GR20 `PlanningScreen`).
///
/// Couvre :
///   - le titre « Programme » et l'en-tete de statistiques (distance, D+,
///     jours, etapes) ;
///   - le contenu PAR ETAPE de chaque jour (nom, distance, D+, D-) et la
///     legende des difficultes ;
///   - l'ACCES au DETAIL d'une etape (tap sur une carte jour -> /stages/:num) ;
///   - l'EDITION : ajout d'un jour de repos (parite GR20) ;
///   - PART A : la carte HUB « Programme » ouvre bien CET ecran riche (et non
///     l'ancien ecran pauvre), via /trail/:id/planning, avec retour propre.
void main() {
  StageModel makeStage(int num, double km, int gain,
      {String difficulty = 'moderate'}) {
    return StageModel(
      trailId: 'test-trail',
      stageNumber: num,
      name: 'Etape $num - Refuge $num',
      distanceKm: km,
      elevationGainM: gain,
      elevationLossM: (gain * 0.8).round(),
      startLat: 42.0,
      startLng: 9.0,
      endLat: 42.1,
      endLng: 9.1,
      difficulty: difficulty,
    );
  }

  final testStages = [
    makeStage(1, 12.0, 800, difficulty: 'hard'),
    makeStage(2, 15.0, 600, difficulty: 'moderate'),
    makeStage(3, 10.0, 1000, difficulty: 'extreme'),
    makeStage(4, 8.0, 400, difficulty: 'easy'),
    makeStage(5, 14.0, 700, difficulty: 'moderate'),
  ];

  List<Override> baseOverrides() => [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value(testStages)),
      ];

  group('PROGRAMME — parite GR20', () {
    testWidgets('affiche le titre Programme et l en-tete de stats',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(
            home: TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Titre de l'ecran (parite GR20 : « Programme », plus « Planning »).
      expect(find.text(t.programme.title), findsOneWidget);

      // En-tete de stats (recalcul depuis les etapes reelles, parite GR20) :
      // distance = 12+15+10+8+14 = 59 km ; D+ = 800+600+1000+400+700 = 3500 m.
      expect(find.text('59 km'), findsOneWidget);
      expect(find.text('3500 m'), findsOneWidget);

      // Legende des difficultes presente (parite GR20).
      expect(find.text(t.programme.legend.easy), findsOneWidget);
      expect(find.text(t.programme.legend.extreme), findsOneWidget);
    });

    testWidgets('affiche le contenu par etape (nom, distance, D+, D-)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(
            home: TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 etapes -> 5 jours (duree defaut 5). Nom de la 1re etape visible.
      expect(find.text('Etape 1 - Refuge 1'), findsOneWidget);

      // Infos par etape du jour 1 : distance + D+ + D-.
      expect(find.text('12.0 km'), findsOneWidget);
      expect(find.text('800 m D+'), findsOneWidget);
      expect(find.text('640 m D-'), findsOneWidget); // 800 * 0.8

      // Bouton de validation (parite GR20).
      expect(find.text(t.programme.validate), findsOneWidget);
    });

    testWidgets('tap sur une carte jour ouvre le detail de l etape',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/trail/test-trail/planning',
        routes: [
          GoRoute(
            path: '/trail/:id/planning',
            builder: (context, state) =>
                const TrailPlanningScreen(trailId: 'test-trail'),
          ),
          // Cible : detail d'etape (parite GR20 : acces au detail depuis le jour).
          GoRoute(
            path: '/stages/:num',
            builder: (context, state) => Scaffold(
              body: Text('DETAIL ${state.pathParameters['num']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap sur la carte du jour 1 (via son nom d'etape).
      await tester.tap(find.text('Etape 1 - Refuge 1'));
      await tester.pumpAndSettle();

      // On a bien ouvert le detail de l'etape 1 (stageNumber = 1).
      expect(find.text('DETAIL 1'), findsOneWidget);
    });

    testWidgets('edition : ajouter un jour de repos (parite GR20)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(
            home: TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pas de jour de repos au depart (5 jours = 5 etapes).
      expect(find.text(t.programme.restDay), findsNothing);

      // Ajouter un jour de repos via la 1re action « Repos » visible.
      await tester.tap(find.text(t.programme.actions.rest).first);
      await tester.pumpAndSettle();

      // Un jour de repos est apparu (carte dediee).
      expect(find.text(t.programme.restDay), findsWidgets);
    });
  });

  group('PART A — la carte HUB « Programme » ouvre l ecran riche', () {
    testWidgets(
        'push /trail/:id/planning ouvre le PROGRAMME riche puis retour propre',
        (tester) async {
      // Router minimal reproduisant le chemin du HUB : la carte « Programme »
      // fait `context.push('/trail/:id/planning')`.
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('HUB-HOME')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      context.push('/trail/test-trail/planning'),
                  child: Text(t.hub.cards.programme),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/planning',
            builder: (context, state) =>
                const TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HUB-HOME'), findsOneWidget);

      // Ouvrir le PROGRAMME depuis la carte HUB.
      await tester.tap(find.text(t.hub.cards.programme));
      await tester.pumpAndSettle();

      // On est bien sur l'ecran RICHE (titre Programme + stats + contenu etape),
      // preuve que la carte n'ouvre plus l'ancien ecran pauvre « Planning ».
      expect(find.text(t.programme.title), findsOneWidget);
      expect(find.text('Etape 1 - Refuge 1'), findsOneWidget);

      // Retour propre vers le HUB (pas d'exception).
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('HUB-HOME'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
