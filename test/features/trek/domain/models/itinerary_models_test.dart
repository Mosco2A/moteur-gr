import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/itinerary_day.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/feasibility_profile.dart';
import 'package:moteur_gr/features/trek/domain/models/trail_feasibility_params.dart';

void main() {
  group('ItineraryDay', () {
    test('totalDistance correspond a la somme des distances des stages', () {
      final stages = [
        Stage(
          id: 'stage-001',
          nameFr: 'Calenzana - Ortu',
          nameEn: 'Calenzana - Ortu',
          distance: 12.5,
          elevationGain: 1500,
          elevationLoss: 200,
          estimatedDurationMinutes: 420,
          difficulty: 'hard',
          orderIndex: 0,
          startLat: 42.5075,
          startLng: 8.8553,
          endLat: 42.4631,
          endLng: 8.9375,
        ),
        Stage(
          id: 'stage-002',
          nameFr: 'Ortu - Carozzu',
          nameEn: 'Ortu - Carozzu',
          distance: 7.5,
          elevationGain: 800,
          elevationLoss: 700,
          estimatedDurationMinutes: 300,
          difficulty: 'moderate',
          orderIndex: 1,
          startLat: 42.4631,
          startLng: 8.9375,
          endLat: 42.4500,
          endLng: 8.9600,
        ),
      ];

      final day = ItineraryDay(
        dayNumber: 1,
        stages: stages,
        totalDistance: 20.0,
        totalElevation: 2300,
        estimatedHours: 12.0,
      );

      // totalDistance = 20.0 (somme 12.5 + 7.5)
      expect(day.totalDistance, 20.0);
      expect(day.dayNumber, 1);
      expect(day.stages.length, 2);
      expect(day.stageCount, 2);
      expect(day.totalElevation, 2300);
      expect(day.estimatedHours, 12.0);

      // Verifier la somme reelle des stages
      final sumDist = day.stages.fold(0.0, (s, e) => s + e.distance);
      expect(sumDist, day.totalDistance);
    });
  });

  group('FeasibilityProfile', () {
    test('groupMode active avec liste de profils', () {
      final member1 = FeasibilityProfile(
        fitnessLevel: 'fit',
        experience: 'experienced',
        maxKmPerDay: 20.0,
        maxHoursPerDay: 8.0,
      );
      final member2 = FeasibilityProfile(
        fitnessLevel: 'sedentary',
        experience: 'beginner',
        maxKmPerDay: 10.0,
        maxHoursPerDay: 5.0,
      );

      final group = FeasibilityProfile(
        fitnessLevel: 'average',
        experience: 'intermediate',
        maxKmPerDay: 10.0,
        maxHoursPerDay: 5.0,
        groupMode: true,
        groupProfiles: [member1, member2],
      );

      expect(group.groupMode, isTrue);
      expect(group.groupProfiles, isNotNull);
      expect(group.groupProfiles!.length, 2);
      expect(group.groupSize, 2);

      // String libre pour fitnessLevel et experience (#81752)
      expect(group.fitnessLevel, 'average');
      expect(group.experience, 'intermediate');
      expect(group.groupProfiles![0].fitnessLevel, 'fit');
      expect(group.groupProfiles![1].fitnessLevel, 'sedentary');

      // Solo: groupMode false par defaut, groupSize = 1
      final solo = FeasibilityProfile(
        fitnessLevel: 'athletic',
        experience: 'expert',
        maxKmPerDay: 25.0,
        maxHoursPerDay: 10.0,
      );
      expect(solo.groupMode, isFalse);
      expect(solo.groupProfiles, isNull);
      expect(solo.groupSize, 1);

      // Valeur String inconnue ne crash pas (#81752)
      final exotic = FeasibilityProfile(
        fitnessLevel: 'ultra_marathon_2027',
        experience: 'alien_level',
        maxKmPerDay: 50.0,
        maxHoursPerDay: 16.0,
      );
      expect(exotic.fitnessLevel, 'ultra_marathon_2027');
      expect(exotic.experience, 'alien_level');
    });
  });

  group('TrailFeasibilityParams', () {
    test('serialisation JSON roundtrip avec customConditions', () {
      final params = TrailFeasibilityParams(
        altitudeFactor: 1.3,
        technicalFactor: 1.5,
        heatFactor: 1.1,
        snowFactor: 0.8,
        customConditions: {
          'wind': 1.2,
          'rain': 1.4,
        },
        recommendationTemplates: {
          'high': 'Sentier tres difficile, preparation indispensable',
          'low': 'Sentier accessible, bonne condition physique recommandee',
        },
      );

      // Verifier les valeurs
      expect(params.altitudeFactor, 1.3);
      expect(params.technicalFactor, 1.5);
      expect(params.heatFactor, 1.1);
      expect(params.snowFactor, 0.8);
      expect(params.customConditions['wind'], 1.2);
      expect(params.customConditions['rain'], 1.4);
      expect(params.recommendationTemplates['high'],
          'Sentier tres difficile, preparation indispensable');

      // combinedFactor = produit de tous les facteurs
      final expected = 1.3 * 1.5 * 1.1 * 0.8;
      expect(params.combinedFactor, closeTo(expected, 0.0001));

      // Roundtrip JSON
      final jsonStr = jsonEncode(params.toJson());
      final restored = TrailFeasibilityParams.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
      expect(restored.altitudeFactor, params.altitudeFactor);
      expect(restored.technicalFactor, params.technicalFactor);
      expect(restored.heatFactor, params.heatFactor);
      expect(restored.snowFactor, params.snowFactor);
      expect(restored.customConditions, params.customConditions);
      expect(restored.recommendationTemplates, params.recommendationTemplates);
      expect(restored, equals(params));

      // Valeurs par defaut (tous a 1.0, maps vides)
      const defaults = TrailFeasibilityParams();
      expect(defaults.altitudeFactor, 1.0);
      expect(defaults.technicalFactor, 1.0);
      expect(defaults.heatFactor, 1.0);
      expect(defaults.snowFactor, 1.0);
      expect(defaults.combinedFactor, 1.0);
      expect(defaults.customConditions, isEmpty);
      expect(defaults.recommendationTemplates, isEmpty);
    });
  });
}
