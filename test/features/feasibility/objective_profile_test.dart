import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_norms.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';

/// Profil OBJECTIF : ce que le randonneur a DEJA fait, chiffre.
///
/// Ces tests etaient portes par `trek_feasibility_calculator_test.dart`, dont
/// le sujet (le SECOND moteur de verdict) a ete supprime : deux moteurs
/// rendaient des verdicts opposes pour le meme randonneur (campagne personas
/// 21/09, MAJEUR-4). Le profil objectif, lui, reste : il alimente l'UNIQUE
/// moteur ([FeasibilityFormula]) via `hikerLevelProvider`.
void main() {
  group('ObjectiveProfile.from — deduction depuis randos + test', () {
    test('deduit les maxima/jour et jours consecutifs des randos', () {
      final hikes = [
        PastHike(
          date: DateTime(2026, 6, 1),
          days: 4,
          totalDistanceKm: 80, // 20 km/j
          totalElevationGain: 3200, // 800 D+/j
        ),
        PastHike(
          date: DateTime(2026, 5, 1),
          days: 2,
          totalDistanceKm: 30, // 15 km/j
          totalElevationGain: 1000, // 500 D+/j
        ),
      ];
      final profile = ObjectiveProfile.from(
        pastHikes: hikes,
        walkTest: WalkTestResult(
          distanceMeters: 650,
          level: WalkTestLevel.good,
          takenAt: DateTime(2026, 9, 1),
        ),
      );
      expect(profile.maxDistancePerDayDone, 20);
      expect(profile.maxElevationGainPerDayDone, 800);
      expect(profile.maxConsecutiveDaysDone, 4);
      expect(profile.fitnessLevelRank, WalkTestLevel.rank(WalkTestLevel.good));
      expect(profile.hasWalkTest, isTrue);
    });

    test('sans test 6 min -> rang de dépannage (fallback questionnaire)', () {
      final profile = ObjectiveProfile.from(
        pastHikes: const [],
        walkTest: null,
        fallbackFitnessRank: 2,
      );
      expect(profile.hasWalkTest, isFalse);
      expect(profile.fitnessLevelRank, 2);
      expect(profile.maxConsecutiveDaysDone, 0);
    });
  });
}
