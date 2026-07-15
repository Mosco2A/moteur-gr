import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/itinerary_calculator.dart';
import 'package:moteur_gr/features/trek/domain/models/feasibility_profile.dart';
import 'package:moteur_gr/features/trek/domain/models/itinerary_config.dart';
import 'package:moteur_gr/features/trek/domain/models/itinerary_day.dart';
import 'package:moteur_gr/features/trail/domain/models/trail_feasibility_params.dart';

void main() {
  const stage1 = StageModel(
    trailId: 'sentier-bleu',
    stageNumber: 1,
    name: 'Calenzana - Ortu di u Piobbu',
    distanceKm: 12.0,
    elevationGainM: 1500,
    elevationLossM: 100,
    startLat: 42.5,
    startLng: 8.8,
    endLat: 42.45,
    endLng: 8.9,
  );

  const stage2 = StageModel(
    trailId: 'sentier-bleu',
    stageNumber: 2,
    name: 'Ortu di u Piobbu - Carrozzu',
    distanceKm: 8.0,
    elevationGainM: 800,
    elevationLossM: 700,
    startLat: 42.45,
    startLng: 8.9,
    endLat: 42.42,
    endLng: 8.95,
  );

  const stage3 = StageModel(
    trailId: 'sentier-bleu',
    stageNumber: 3,
    name: 'Carrozzu - Ascu Stagnu',
    distanceKm: 6.0,
    elevationGainM: 900,
    elevationLossM: 600,
    startLat: 42.42,
    startLng: 8.95,
    endLat: 42.4,
    endLng: 9.0,
  );

  const neutralParams = TrailFeasibilityParams(
    altitudeFactor: 1.0,
    technicalFactor: 1.0,
    heatFactor: 1.0,
    snowFactor: 1.0,
  );

  group('ItineraryCalculator - regroupement glouton', () {
    test('regroupe les etapes selon maxKmPerDay et maxHoursPerDay', () {
      final config = ItineraryConfig(
        maxKmPerDay: 20.0,
        maxHoursPerDay: 8.0,
        startDate: DateTime(2026, 6, 15),
        difficultyLevel: 'moderate',
      );

      const profile = FeasibilityProfile(
        fitnessLevel: 'intermediate',
        experience: 'experienced',
        maxKmPerDay: 25.0,
        maxHoursPerDay: 10.0,
      );

      final result = ItineraryCalculator.calculate(
        [stage1, stage2, stage3],
        config,
        profile,
        neutralParams,
      );

      // stage1 = 12km, ~6.75h (12/4 + 1500/400)
      // stage2 = 8km, ~4h (8/4 + 800/400)
      // stage1+stage2 = 20km, ~10.75h -> depasse maxHours(8h) -> jour 2
      expect(result.length, greaterThanOrEqualTo(2));

      expect(result[0].dayNumber, 1);
      expect(result[0].stages.length, 1);
      expect(result[0].stages[0].name, 'Calenzana - Ortu di u Piobbu');
      expect(result[0].totalDistance, 12.0);

      final totalStages = result.fold<int>(
        0,
        (sum, day) => sum + day.stageCount,
      );
      expect(totalStages, 3);
    });
  });

  group('ItineraryCalculator - mode groupe', () {
    test('utilise le profil le plus conservateur du groupe', () {
      final config = ItineraryConfig(
        maxKmPerDay: 30.0,
        maxHoursPerDay: 12.0,
        startDate: DateTime(2026, 6, 15),
        difficultyLevel: 'hard',
      );

      const mainProfile = FeasibilityProfile(
        fitnessLevel: 'advanced',
        experience: 'expert',
        maxKmPerDay: 25.0,
        maxHoursPerDay: 10.0,
        groupMode: true,
        groupProfiles: [
          FeasibilityProfile(
            fitnessLevel: 'advanced',
            experience: 'expert',
            maxKmPerDay: 25.0,
            maxHoursPerDay: 10.0,
          ),
          FeasibilityProfile(
            fitnessLevel: 'beginner',
            experience: 'novice',
            maxKmPerDay: 10.0,
            maxHoursPerDay: 5.0,
          ),
        ],
      );

      final resultGroupe = ItineraryCalculator.calculate(
        [stage1, stage2, stage3],
        config,
        mainProfile,
        neutralParams,
      );

      // Profil faible : maxKm=10, maxHours=5 -> 3 jours
      expect(resultGroupe.length, 3);

      const soloProfile = FeasibilityProfile(
        fitnessLevel: 'advanced',
        experience: 'expert',
        maxKmPerDay: 25.0,
        maxHoursPerDay: 10.0,
      );

      final resultSolo = ItineraryCalculator.calculate(
        [stage1, stage2, stage3],
        config,
        soloProfile,
        neutralParams,
      );

      expect(resultSolo.length, lessThan(resultGroupe.length));
    });
  });

  group('ItineraryCalculator - score faisabilite', () {
    test('score diminue avec les facteurs du sentier', () {
      const day = ItineraryDay(
        dayNumber: 1,
        stages: [stage1],
        totalDistance: 12.0,
        totalElevation: 1500,
        estimatedHours: 6.75,
      );

      final scoreNeutre = ItineraryCalculator.feasibilityScore(
        day,
        neutralParams,
      );

      const hardParams = TrailFeasibilityParams(
        altitudeFactor: 2.0,
        technicalFactor: 1.5,
        heatFactor: 1.5,
        snowFactor: 0.5,
      );

      final scoreHard = ItineraryCalculator.feasibilityScore(
        day,
        hardParams,
      );

      expect(scoreHard, lessThan(scoreNeutre));

      // Score neutre: 100 - 15 - 5 - 13.5 - 36 = 30.5
      expect(scoreNeutre, closeTo(30.5, 0.1));

      // Score hard: 100 - 30 - 7.5 - 20.25 - 18 = 24.25
      expect(scoreHard, closeTo(24.25, 0.1));

      const paramsWithTemplates = TrailFeasibilityParams(
        altitudeFactor: 1.0,
        technicalFactor: 1.5,
        heatFactor: 1.0,
        snowFactor: 1.5,
        recommendationTemplates: {
          'altitude': 'Prevoyez acclimatation altitude',
          'heat': 'Emportez 3L eau par personne',
          'snow': 'Crampons et piolet obligatoires',
          'technical': 'Casque recommande',
        },
      );

      final recs = ItineraryCalculator.generateRecommendations(
        day,
        paramsWithTemplates,
      );

      expect(recs, contains('Prevoyez acclimatation altitude'));
      expect(recs, contains('Emportez 3L eau par personne'));
      expect(recs, contains('Crampons et piolet obligatoires'));
      expect(recs, contains('Casque recommande'));
      expect(recs.length, 4);
    });
  });
}
