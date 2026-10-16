import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
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
          home: Scaffold(body: StageListTile(stage: testStage)),
        ),
      );

      expect(find.text('Col des Nuages'), findsOneWidget);
    });

    testWidgets('affiche la distance en km', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StageListTile(stage: testStage)),
        ),
      );

      expect(find.text('12.5 km'), findsOneWidget);
    });

    testWidgets('affiche le dénivelé positif et négatif', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StageListTile(stage: testStage)),
        ),
      );

      expect(find.text('800m'), findsOneWidget);
      expect(find.text('450m'), findsOneWidget);
    });

    testWidgets('affiche le numéro de l\'étape', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StageListTile(stage: testStage)),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('affiche le badge de difficulté', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StageListTile(stage: testStage)),
        ),
      );

      expect(find.text('Difficile'), findsOneWidget);
    });

    testWidgets('affiche la durée estimée formatée', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StageListTile(stage: testStage)),
        ),
      );

      // TACHE 839 — LA DESCENTE EST PAYEE, ET LA DUREE VIENT DE LA SOURCE
      // UNIQUE. 12,5 km a 4 km/h = 11 250 s, + 800 m x 9 s/m = 7 200 s,
      // + 450 m x 1,67 s/m = 750 s, soit 19 200 s = 320 min = 5h20.
      // Cette etape affichait 5h08 : ses 450 m de descente ne coutaient
      // rien, et cette ligne de liste portait sa PROPRE arithmetique.
      expect(find.text('5h20'), findsOneWidget);
    });

    testWidgets('appelle onTap quand on tape', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageListTile(stage: testStage, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.text('Col des Nuages'));
      expect(tapped, isTrue);
    });
  });

  group('StageListTile calculs', () {
    test('la duree vient de la SOURCE UNIQUE, descente comprise', () {
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

      // TACHE 839 : 8 km a 4 km/h = 7 200 s, + 400 m x 9 s/m = 3 600 s,
      // + 200 m x 1,67 s/m = 333 s, soit 11 133 s = 186 min = 3h06.
      // Ce fichier verifiait 3,0 h : la descente etait gratuite ici.
      expect(StageListTile.durationMinutes(stage), 186);
      expect(StageListTile.durationMinutes(stage), stageDurationMinutes(stage));
    });

    test('UNE DUREE FOURNIE PAR LE SENTIER FAIT AUTORITE', () {
      // C'EST LE SECOND DEFAUT CORRIGE PAR LA TACHE 839, et il se voyait a
      // l'ecran : cette ligne de liste IGNORAIT la duree de la donnee du
      // sentier, que la fiche de la MEME etape affichait pourtant. Deux
      // durees pour une etape, selon l'ecran ou on la regardait.
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
        estimatedDurationMinutes: 300,
      );
      expect(StageListTile.durationMinutes(stage), 300);
    });

    test('formatDuration delegue au formateur maison', () {
      expect(StageListTile.formatDuration(180), '3h');
      expect(StageListTile.formatDuration(150), '2h30');
      expect(StageListTile.formatDuration(65), '1h05');
    });
  });
}
