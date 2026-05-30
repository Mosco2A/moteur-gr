import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/itinerary_day.dart';
import 'package:moteur_gr/features/trek/presentation/planning/planning_screen.dart';
import 'package:moteur_gr/features/trek/providers/itinerary_providers.dart';

/// Tests du TrekPlanningScreen (Phase 2 E2.7c).
///
/// Verifie que le planning affiche N jours avec les
/// bonnes etapes dans chaque ExpansionTile.
void main() {
  // Etapes de test (StageModel du core)
  const stageA = StageModel(
    trailId: 'test-trail',
    stageNumber: 1,
    name: 'Refuge A - Refuge B',
    distanceKm: 14.5,
    elevationGainM: 850,
    elevationLossM: 620,
    startLat: 42.10,
    startLng: 9.05,
    endLat: 42.15,
    endLng: 9.10,
  );

  const stageB = StageModel(
    trailId: 'test-trail',
    stageNumber: 2,
    name: 'Refuge B - Refuge C',
    distanceKm: 12.0,
    elevationGainM: 600,
    elevationLossM: 500,
    startLat: 42.15,
    startLng: 9.10,
    endLat: 42.20,
    endLng: 9.15,
  );

  const stageC = StageModel(
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Refuge C - Village D',
    distanceKm: 18.0,
    elevationGainM: 900,
    elevationLossM: 1100,
    startLat: 42.20,
    startLng: 9.15,
    endLat: 42.28,
    endLng: 9.22,
  );

  // Itineraire de test : 2 jours
  final mockDays = [
    const ItineraryDay(
      dayNumber: 1,
      stages: [stageA, stageB],
      totalDistance: 26.5,
      totalElevation: 1450,
      estimatedHours: 7.5,
    ),
    const ItineraryDay(
      dayNumber: 2,
      stages: [stageC],
      totalDistance: 18.0,
      totalElevation: 900,
      estimatedHours: 5.0,
    ),
  ];

  group('TrekPlanningScreen E2.7c', () {
    testWidgets('affiche N jours avec les bonnes etapes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itineraryProvider.overrideWith(
              (ref) => Future.value(mockDays),
            ),
          ],
          child: const MaterialApp(
            home: TrekPlanningScreen(),
          ),
        ),
      );

      // Attendre le chargement
      await tester.pumpAndSettle();

      // Verifier que les 2 jours sont affiches
      expect(find.text('Jour 1'), findsOneWidget);
      expect(find.text('Jour 2'), findsOneWidget);

      // Verifier les sous-titres des jours
      expect(find.text('2 etapes  -  26.5 km'), findsOneWidget);
      expect(find.text('1 etape  -  18.0 km'), findsOneWidget);

      // Expand jour 1 pour voir les etapes
      await tester.tap(find.text('Jour 1'));
      await tester.pumpAndSettle();

      // Les StageCards du jour 1 doivent etre visibles
      expect(find.text('Refuge A - Refuge B'), findsOneWidget);
      expect(find.text('Refuge B - Refuge C'), findsOneWidget);
    });
  });
}
