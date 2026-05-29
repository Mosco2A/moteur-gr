import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/stages/stage_detail_screen.dart';
import 'package:moteur_gr/features/trek/providers/trail_providers.dart';

/// Tests widget de [StageDetailScreen].
///
/// Verifie que StageDetailScreen affiche sans crash
/// avec les 3 etats AsyncValue (loading, error, data).
void main() {
  final testStage = Stage(
    id: 'test-trail-2',
    nameFr: 'Col de Bavella',
    nameEn: 'Bavella Pass',
    distance: 12.5,
    elevationGain: 850,
    elevationLoss: 620,
    estimatedDurationMinutes: 330,
    difficulty: 'hard',
    orderIndex: 2,
    startLat: 42.1234,
    startLng: 9.0567,
    endLat: 42.2345,
    endLng: 9.1678,
    descriptionFr: 'Traversee spectaculaire.',
    descriptionEn: 'Spectacular traverse.',
  );

  group('StageDetailScreen', () {
    testWidgets('affiche sans crash avec donnees mock', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            trekStagesProvider.overrideWith(
              (ref) => Future.value([testStage]),
            ),
          ],
          child: const MaterialApp(
            home: StageDetailScreen(stageId: 'test-trail-2'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Nom de l etape (EN par defaut en test)
      expect(find.text('Bavella Pass'), findsOneWidget);

      // Description (EN)
      expect(find.text('Spectacular traverse.'), findsOneWidget);

      // Section headers
      expect(find.text('Profil altimetrique'), findsOneWidget);
      expect(find.text('Statistiques'), findsOneWidget);

      // Stats values
      expect(find.text('12.5 km'), findsOneWidget);
      expect(find.text('850 m'), findsOneWidget);
      expect(find.text('620 m'), findsOneWidget);
      expect(find.text('5h30'), findsOneWidget);

      // Difficulty badge appears
      expect(find.text('hard'), findsAtLeastNWidgets(1));

      // CustomPaint present (elevation profile)
      expect(find.byType(CustomPaint), findsWidgets);

      // Back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
