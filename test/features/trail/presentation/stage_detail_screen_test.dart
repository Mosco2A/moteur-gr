import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trail/presentation/stage_detail_screen.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// Tests widget de l'écran StageDetailScreen.
///
/// Vérifie l'affichage des infos de l'étape, des POIs
/// associés et la gestion des états loading/error/vide.
void main() {
  /// Étape de test
  const testStage = StageModel(
    id: 1,
    trailId: 'test-trail',
    stageNumber: 2,
    name: 'Col de la Brèche',
    distanceKm: 14.0,
    elevationGainM: 950,
    elevationLossM: 600,
    description: 'Traversée spectaculaire du col.',
    startLat: 42.12345,
    startLng: 9.06789,
    endLat: 42.23456,
    endLng: 9.17890,
    difficulty: 'hard',
  );

  /// POIs de test pour l'étape 2
  final testPois = [
    const PoiModel(
      id: 1,
      trailId: 'test-trail',
      stageNumber: 2,
      name: 'Source du Col',
      description: 'Point d\'eau potable',
      type: PoiType.water,
      lat: 42.15,
      lng: 9.10,
      altitudeM: 1850,
    ),
    const PoiModel(
      id: 2,
      trailId: 'test-trail',
      stageNumber: 2,
      name: 'Refuge du Sommet',
      description: 'Refuge gardé en saison',
      type: PoiType.shelter,
      lat: 42.18,
      lng: 9.12,
      altitudeM: 2100,
    ),
  ];

  /// POI d'une autre étape (ne doit pas apparaître)
  const otherPoi = PoiModel(
    id: 3,
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Belvédère',
    type: PoiType.viewpoint,
    lat: 42.20,
    lng: 9.15,
  );

  group('StageDetailScreen', () {
    testWidgets('affiche le nom de l\'étape', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(testPois),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Col de la Brèche'), findsOneWidget);
    });

    testWidgets('affiche la description de l\'étape', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(<PoiModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Traversée spectaculaire du col.'),
        findsOneWidget,
      );
    });

    testWidgets('affiche la distance et le dénivelé', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(<PoiModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('14.0 km'), findsOneWidget);
      expect(find.text('950m'), findsOneWidget);
      expect(find.text('600m'), findsOneWidget);
    });

    testWidgets('affiche le badge de difficulté', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(<PoiModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Difficile'), findsOneWidget);
    });

    testWidgets('affiche les POIs de l\'étape uniquement', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value([...testPois, otherPoi]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // POIs de l'étape 2 : présents
      expect(find.text('Source du Col'), findsOneWidget);
      expect(find.text('Refuge du Sommet'), findsOneWidget);
      // POI de l'étape 3 : absent
      expect(find.text('Belvédère'), findsNothing);
    });

    testWidgets('affiche message quand pas de POIs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(<PoiModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Aucun point d\'intérêt pour cette étape.'),
        findsOneWidget,
      );
    });

    testWidgets('affiche "Étape introuvable" pour un numéro invalide',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(<PoiModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 99,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Étape introuvable'), findsOneWidget);
    });

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
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(<PoiModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Résoudre pour éviter les fuites
      completer.complete([testStage]);
      await tester.pumpAndSettle();
    });

    testWidgets('affiche les coordonnées de l\'étape', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(<PoiModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Coordonnées de départ
      expect(find.text('42.12345, 9.06789'), findsOneWidget);
      // Coordonnées d'arrivée
      expect(find.text('42.23456, 9.17890'), findsOneWidget);
    });

    testWidgets('affiche le bouton "Voir sur la carte"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
            poisProvider('test-trail').overrideWith(
              (ref) => Future.value(<PoiModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(
              trailId: 'test-trail',
              stageNumber: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Voir sur la carte'), findsOneWidget);
    });
  });
}
