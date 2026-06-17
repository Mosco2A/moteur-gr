import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trail/presentation/trail_detail_screen.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget de l'écran TrailDetailScreen.
///
/// Vérifie le header sentier, le chargement des étapes,
/// l'affichage du bon nombre d'étapes et l'état vide.
void main() {
  group('TrailDetailScreen', () {
    testWidgets('affiche le loading pendant le chargement', (tester) async {
      // Completer qui ne se résout pas → reste en loading
      final completer = Completer<List<StageModel>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: TrailDetailScreen(trailId: 'test-trail'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Le nom du sentier doit être dans l'AppBar
      expect(find.text('Volcans Trail'), findsWidgets);
      // Le CircularProgressIndicator doit être visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('affiche le header avec les infos du sentier',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(<StageModel>[]),
            ),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: TrailDetailScreen(trailId: 'test-trail'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Informations du header
      expect(find.text('Auvergne'), findsOneWidget);
      expect(find.text('72.0 km'), findsOneWidget);
      expect(find.text('2420 m D+'), findsOneWidget);
    });

    testWidgets('affiche l\'état vide quand aucune étape', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(<StageModel>[]),
            ),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: TrailDetailScreen(trailId: 'test-trail'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucune étape disponible'), findsOneWidget);
    });

    testWidgets('affiche le bon nombre d\'étapes', (tester) async {
      final stages = [
        const StageModel(
          id: 1,
          trailId: 'test-trail',
          stageNumber: 1,
          name: 'Étape du Lac',
          distanceKm: 10.0,
          elevationGainM: 500,
          elevationLossM: 300,
          startLat: 42.0,
          startLng: 9.0,
          endLat: 42.1,
          endLng: 9.1,
          difficulty: 'easy',
        ),
        const StageModel(
          id: 2,
          trailId: 'test-trail',
          stageNumber: 2,
          name: 'Col du Vent',
          distanceKm: 15.0,
          elevationGainM: 800,
          elevationLossM: 600,
          startLat: 42.1,
          startLng: 9.1,
          endLat: 42.2,
          endLng: 9.2,
          difficulty: 'hard',
        ),
        const StageModel(
          id: 3,
          trailId: 'test-trail',
          stageNumber: 3,
          name: 'Vallée Secrète',
          distanceKm: 8.0,
          elevationGainM: 200,
          elevationLossM: 400,
          startLat: 42.2,
          startLng: 9.2,
          endLat: 42.3,
          endLng: 9.3,
          difficulty: 'moderate',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(stages),
            ),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: TrailDetailScreen(trailId: 'test-trail'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Les 3 noms d'étapes doivent être affichés
      expect(find.text('Étape du Lac'), findsOneWidget);
      expect(find.text('Col du Vent'), findsOneWidget);
      expect(find.text('Vallée Secrète'), findsOneWidget);
    });

    testWidgets('affiche une erreur quand le chargement échoue',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future<List<StageModel>>.error(
                Exception('Erreur de chargement'),
              ),
            ),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: TrailDetailScreen(trailId: 'test-trail'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger les étapes'),
        findsOneWidget,
      );
    });

    testWidgets('affiche le bouton "Voir la carte"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(<StageModel>[]),
            ),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: TrailDetailScreen(trailId: 'test-trail'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Voir la carte'), findsOneWidget);
    });

    testWidgets(
        'le bouton Entrer active le sentier et ouvre le shell sur /map (#88246)',
        (tester) async {
      // Container partage pour lire la selection apres l'action UI.
      final container = ProviderContainer(overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        selectedTrailIdProvider.overrideWith((ref) => 'autre-sentier'),
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value(<StageModel>[])),
      ]);
      addTearDown(container.dispose);

      // Routeur minimal : detail en racine + stub /map pour observer la nav.
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const TrailDetailScreen(trailId: 'test-trail'),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) =>
                const Scaffold(body: Text('STUB MAP SCREEN')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TranslationProvider(
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Taper le bouton primaire "Entrer".
      await tester.tap(find.byKey(const ValueKey('trail-detail-enter')));
      await tester.pumpAndSettle();

      // La selection pointe sur le sentier affiche -> moteur bascule.
      expect(container.read(selectedTrailIdProvider), 'test-trail');
      // On a navigue vers le shell (stub /map).
      expect(find.text('STUB MAP SCREEN'), findsOneWidget);
    });
  });
}
