import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/presentation/stages/stage_list_screen.dart';

/// Tests du StageListScreen (Phase 2 E2.4a).
///
/// (1) Affiche N StageCards pour N etapes.
/// (2) Les etapes sont triees par stageNumber (orderIndex).
void main() {
  // Etapes de test dans le desordre (pour verifier le tri)
  final mockStages = [
    const StageModel(
      trailId: 'test-trail',
      stageNumber: 3,
      name: 'Col de Bavella',
      distanceKm: 18.0,
      elevationGainM: 800,
      elevationLossM: 600,
      startLat: 41.80,
      startLng: 9.22,
      endLat: 41.82,
      endLng: 9.24,
    ),
    const StageModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Vizzavona - Capanelle',
      distanceKm: 14.5,
      elevationGainM: 650,
      elevationLossM: 300,
      startLat: 42.12,
      startLng: 9.11,
      endLat: 42.10,
      endLng: 9.13,
    ),
    const StageModel(
      trailId: 'test-trail',
      stageNumber: 2,
      name: 'Capanelle - Prati',
      distanceKm: 16.0,
      elevationGainM: 700,
      elevationLossM: 450,
      startLat: 42.10,
      startLng: 9.13,
      endLat: 41.95,
      endLng: 9.18,
    ),
  ];

  group('StageListScreen E2.4a', () {
    testWidgets('affiche N StageCards pour N etapes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(mockStages),
            ),
          ],
          child: const MaterialApp(
            home: StageListScreen(trailId: 'test-trail'),
          ),
        ),
      );

      // Attendre le chargement
      await tester.pumpAndSettle();

      // Verifier que les 3 cartes sont presentes
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('Vizzavona - Capanelle'), findsOneWidget);
      expect(find.text('Capanelle - Prati'), findsOneWidget);
      expect(find.text('Col de Bavella'), findsOneWidget);
    });

    testWidgets('etapes triees par stageNumber (orderIndex)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value(mockStages),
            ),
          ],
          child: const MaterialApp(
            home: StageListScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Recuperer les textes des CircleAvatar (numeros d etape)
      // dans l ordre d affichage
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsNWidgets(3));

      // Les numeros dans les CircleAvatar doivent etre 1, 2, 3 (tries)
      final avatarTexts = tester
          .widgetList<Text>(find.descendant(
            of: find.byType(CircleAvatar),
            matching: find.byType(Text),
          ))
          .map((t) => t.data)
          .toList();

      expect(avatarTexts, ['1', '2', '3']);
    });
  });
}
