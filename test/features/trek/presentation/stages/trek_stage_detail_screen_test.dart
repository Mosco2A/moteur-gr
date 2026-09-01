import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/presentation/stages/trek_stage_detail_screen.dart';

/// Tests widget de TrekStageDetailScreen (Phase 2 E2.4c).
///
/// Verifie que TrekStageDetailScreen affiche sans crash
/// avec les donnees de test (nom, description, stats, profil).
void main() {
  // Etape de test avec toutes les valeurs remplies
  const testStage = StageModel(
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Col de Vergio',
    distanceKm: 14.5,
    elevationGainM: 850,
    elevationLossM: 620,
    description: 'Traversee spectaculaire avec vue panoramique.',
    startLat: 42.28,
    startLng: 9.07,
    endLat: 42.30,
    endLng: 9.10,
    difficulty: 'hard',
  );

  group('TrekStageDetailScreen E2.4c', () {
    testWidgets('affiche sans crash avec donnees completes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([testStage]),
            ),
          ],
          child: const MaterialApp(
            home: TrekStageDetailScreen(
              trailId: 'test-trail',
              stageId: 3,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Nom affiche DEUX fois par design : dans le titre de l'AppBar et dans le
      // titre de l'en-tete a degrade (AppGradientHeader, SW-SKIN-L5).
      expect(find.text('Col de Vergio'), findsNWidgets(2));

      // Description affichee
      expect(
        find.text('Traversee spectaculaire avec vue panoramique.'),
        findsOneWidget,
      );

      // Stats presentes — SW-SKIN-L5 : rangee d'AppDataStat (valeur + unite
      // separees, role data tabular). Distance 14.5 km, D+ +850 m, D- -620 m.
      expect(find.text('14.5'), findsOneWidget);
      expect(find.text('+850'), findsOneWidget);
      expect(find.text('-620'), findsOneWidget);
      // Unites "km"/"m" presentes (m apparait 2x : D+ et D-).
      expect(find.text('km'), findsOneWidget);
      expect(find.text('m'), findsNWidgets(2));

      // Badge difficulte — SW-SKIN-L5 : desormais UNE seule occurrence (le chip
      // semantique ; l'ancienne ligne de stat "Difficulte" a ete retiree, la
      // difficulte n'est jamais un gros chiffre data).
      expect(find.text('Difficile'), findsOneWidget);

      // Profil altimetrique section
      expect(find.text('Profil altimetrique'), findsOneWidget);

      // Statistiques section
      expect(find.text('Statistiques'), findsOneWidget);

      // CustomPaint present (profil altimetrique)
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
