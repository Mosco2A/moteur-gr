import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trail/widgets/stage_list_tile.dart';

/// Tests du widget StageListTile.
///
/// Vérifie l'affichage du nom, de la distance, du dénivelé,
/// de la durée estimée et le calcul de durée.
void main() {
  /// Étape de test fictive
  const testStage = StageModel(
    id: 1,
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Col des Nuages',
    distanceKm: 12.5,
    elevationGainM: 800,
    elevationLossM: 450,
    description: 'Belle traversée en altitude',
    startLat: 42.0,
    startLng: 9.0,
    endLat: 42.1,
    endLng: 9.1,
    difficulty: 'hard',
  );

  group('StageListTile', () {
    testWidgets('affiche le nom de l\'étape', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageListTile(stage: testStage),
          ),
        ),
      );

      expect(find.text('Col des Nuages'), findsOneWidget);
    });

    testWidgets('affiche la distance en km', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageListTile(stage: testStage),
          ),
        ),
      );

      expect(find.text('12.5 km'), findsOneWidget);
    });

    testWidgets('affiche le dénivelé positif et négatif', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageListTile(stage: testStage),
          ),
        ),
      );

      expect(find.text('800m'), findsOneWidget);
      expect(find.text('450m'), findsOneWidget);
    });

    testWidgets('affiche le numéro de l\'étape', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageListTile(stage: testStage),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('affiche le badge de difficulté', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageListTile(stage: testStage),
          ),
        ),
      );

      expect(find.text('Difficile'), findsOneWidget);
    });

    testWidgets('affiche la durée estimée formatée', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageListTile(stage: testStage),
          ),
        ),
      );

      // 12.5/4 + 800/400 = 3.125 + 2 = 5.125 → 5h08
      expect(find.text('5h08'), findsOneWidget);
    });

    testWidgets('appelle onTap quand on tape', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageListTile(
              stage: testStage,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Col des Nuages'));
      expect(tapped, isTrue);
    });
  });

  group('StageListTile calculs', () {
    test('estimatedHours calcule distance/4 + D+/400', () {
      const stage = StageModel(
        trailId: 't',
        stageNumber: 1,
        name: 'Test',
        distanceKm: 8.0,
        elevationGainM: 400,
        elevationLossM: 200,
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      );

      // 8/4 + 400/400 = 2 + 1 = 3
      expect(StageListTile.estimatedHours(stage), 3.0);
    });

    test('formatDuration retourne "3h" pour 3.0', () {
      expect(StageListTile.formatDuration(3.0), '3h');
    });

    test('formatDuration retourne "2h30" pour 2.5', () {
      expect(StageListTile.formatDuration(2.5), '2h30');
    });

    test('formatDuration retourne "1h05" pour 1.083', () {
      expect(StageListTile.formatDuration(1.083), '1h05');
    });
  });
}
