import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/feasibility_profile.dart';
import 'package:moteur_gr/features/trek/domain/models/itinerary_day.dart';
import 'package:moteur_gr/features/trail/domain/models/trail_feasibility_params.dart';

/// Tests E2.1b — modeles Itinerary + Feasibility Freezed.
void main() {
  const testStage = StageModel(
    trailId: 'test',
    stageNumber: 1,
    name: 'Etape 1',
    distanceKm: 12.0,
    elevationGainM: 800,
    elevationLossM: 600,
    startLat: 42.0,
    startLng: 9.0,
    endLat: 42.1,
    endLng: 9.1,
  );

  group('ItineraryDay', () {
    test('totalDistance calcule depuis les stages', () {
      const day = ItineraryDay(
        dayNumber: 1,
        stages: [testStage, testStage],
        totalDistance: 24.0,
        totalElevation: 1600,
        estimatedHours: 7.0,
      );
      expect(day.totalDistance, 24.0);
      expect(day.stageCount, 2);
      expect(day.dayNumber, 1);
      expect(day.totalElevation, 1600);
      expect(day.estimatedHours, 7.0);
    });
  });

  group('FeasibilityProfile', () {
    test('groupMode avec profils de groupe', () {
      const solo = FeasibilityProfile(
        fitnessLevel: 'intermediate',
        experience: 'experienced',
        maxKmPerDay: 20.0,
        maxHoursPerDay: 8.0,
      );

      const weak = FeasibilityProfile(
        fitnessLevel: 'beginner',
        experience: 'novice',
        maxKmPerDay: 12.0,
        maxHoursPerDay: 5.0,
      );

      const group = FeasibilityProfile(
        fitnessLevel: 'intermediate',
        experience: 'experienced',
        maxKmPerDay: 20.0,
        maxHoursPerDay: 8.0,
        groupMode: true,
        groupProfiles: [solo, weak],
      );

      expect(group.groupMode, true);
      expect(group.groupProfiles, isNotNull);
      expect(group.groupProfiles!.length, 2);
      expect(group.groupProfiles![1].fitnessLevel, 'beginner');

      // Solo par defaut
      expect(solo.groupMode, false);
      expect(solo.groupProfiles, isNull);
    });
  });

  group('TrailFeasibilityParams', () {
    test('serialization aller-retour JSON', () {
      const params = TrailFeasibilityParams(
        altitudeFactor: 1.3,
        technicalFactor: 1.1,
        heatFactor: 1.2,
        snowFactor: 0.8,
        customConditions: ['vent_fort', 'brouillard'],
        recommendationTemplates: {
          'heat': 'Prevoyez 3L eau/jour',
          'snow': 'Crampons recommandes',
        },
      );

      final jsonStr = jsonEncode(params.toJson());
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = TrailFeasibilityParams.fromJson(decoded);

      expect(restored.altitudeFactor, 1.3);
      expect(restored.technicalFactor, 1.1);
      expect(restored.heatFactor, 1.2);
      expect(restored.snowFactor, 0.8);
      expect(restored.customConditions, ['vent_fort', 'brouillard']);
      expect(restored.recommendationTemplates['heat'], 'Prevoyez 3L eau/jour');
      expect(restored.recommendationTemplates['snow'], 'Crampons recommandes');
    });
  });
}
