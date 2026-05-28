import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';
import 'package:moteur_gr/features/trek/domain/trail_data_provider.dart';
import 'package:moteur_gr/features/trek/presentation/stages/stage_list_screen.dart';
import 'package:moteur_gr/features/trek/presentation/widgets/stage_card.dart';
import 'package:moteur_gr/features/trek/providers/trail_providers.dart';

/// Fake TrailDataProvider pour les tests du StageListScreen.
class _FakeTrailDataProvider implements TrailDataProvider {
  _FakeTrailDataProvider({required this.stages});

  final List<Stage> stages;

  @override
  Future<List<Stage>> getStages() async => stages;

  @override
  Future<List<TrackPoint>> getTrackPoints(String stageId) async => [];

  @override
  Future<TrailConfigData?> getTrailConfig() async => null;
}

void main() {
  group('StageListScreen', () {
    testWidgets('affiche N StageCards pour N etapes', (tester) async {
      final stages = [
        const Stage(
          id: 'stage-1',
          nameFr: 'Calenzana - Ortu',
          nameEn: 'Calenzana - Ortu',
          distance: 12.5,
          elevationGain: 1500,
          elevationLoss: 200,
          estimatedDurationMinutes: 420,
          difficulty: 'hard',
          orderIndex: 0,
          startLat: 42.50,
          startLng: 8.85,
          endLat: 42.46,
          endLng: 8.93,
        ),
        const Stage(
          id: 'stage-2',
          nameFr: 'Ortu - Carrozzu',
          nameEn: 'Ortu - Carrozzu',
          distance: 7.0,
          elevationGain: 800,
          elevationLoss: 700,
          estimatedDurationMinutes: 300,
          difficulty: 'hard',
          orderIndex: 1,
          startLat: 42.46,
          startLng: 8.93,
          endLat: 42.43,
          endLng: 8.95,
        ),
        const Stage(
          id: 'stage-3',
          nameFr: 'Carrozzu - Ascu',
          nameEn: 'Carrozzu - Ascu',
          distance: 8.0,
          elevationGain: 900,
          elevationLoss: 650,
          estimatedDurationMinutes: 360,
          difficulty: 'extreme',
          orderIndex: 2,
          startLat: 42.43,
          startLng: 8.95,
          endLat: 42.40,
          endLng: 9.00,
        ),
      ];

      final fake = _FakeTrailDataProvider(stages: stages);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            trailDataProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            home: StageListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifie qu'il y a exactement 3 StageCards
      expect(find.byType(StageCard), findsNWidgets(3));

      // Verifie que les noms sont affiches
      expect(find.text('Calenzana - Ortu'), findsOneWidget);
      expect(find.text('Ortu - Carrozzu'), findsOneWidget);
      expect(find.text('Carrozzu - Ascu'), findsOneWidget);
    });

    testWidgets('les etapes sont triees par orderIndex', (tester) async {
      // Etapes fournies dans le desordre volontairement
      final stages = [
        const Stage(
          id: 'stage-c',
          nameFr: 'Etape C',
          nameEn: 'Stage C',
          distance: 5.0,
          elevationGain: 300,
          elevationLoss: 200,
          estimatedDurationMinutes: 180,
          difficulty: 'easy',
          orderIndex: 2,
          startLat: 42.30,
          startLng: 9.10,
          endLat: 42.25,
          endLng: 9.15,
        ),
        const Stage(
          id: 'stage-a',
          nameFr: 'Etape A',
          nameEn: 'Stage A',
          distance: 10.0,
          elevationGain: 500,
          elevationLoss: 400,
          estimatedDurationMinutes: 240,
          difficulty: 'moderate',
          orderIndex: 0,
          startLat: 42.50,
          startLng: 8.85,
          endLat: 42.46,
          endLng: 8.93,
        ),
        const Stage(
          id: 'stage-b',
          nameFr: 'Etape B',
          nameEn: 'Stage B',
          distance: 8.0,
          elevationGain: 600,
          elevationLoss: 500,
          estimatedDurationMinutes: 300,
          difficulty: 'hard',
          orderIndex: 1,
          startLat: 42.46,
          startLng: 8.93,
          endLat: 42.40,
          endLng: 9.00,
        ),
      ];

      final fake = _FakeTrailDataProvider(stages: stages);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            trailDataProvider.overrideWithValue(fake),
          ],
          child: const MaterialApp(
            home: StageListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Recupere tous les StageCards dans l'ordre d'affichage
      final cards = tester.widgetList<StageCard>(find.byType(StageCard)).toList();

      // Verifie l'ordre par orderIndex : A (0), B (1), C (2)
      expect(cards[0].stage.orderIndex, 0);
      expect(cards[0].stage.nameFr, 'Etape A');
      expect(cards[1].stage.orderIndex, 1);
      expect(cards[1].stage.nameFr, 'Etape B');
      expect(cards[2].stage.orderIndex, 2);
      expect(cards[2].stage.nameFr, 'Etape C');
    });
  });
}
