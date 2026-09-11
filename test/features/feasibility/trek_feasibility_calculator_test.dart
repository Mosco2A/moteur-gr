import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/trek_feasibility_calculator.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_norms.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';

/// Profil objectif « confirme » : grosses randos deja faites, test excellent.
ObjectiveProfile _strongProfile() => const ObjectiveProfile(
      maxElevationGainPerDayDone: 1200,
      maxDistancePerDayDone: 25,
      maxConsecutiveDaysDone: 10,
      fitnessLevelRank: 3,
      hasWalkTest: true,
    );

/// Profil objectif « debutant » : peu de randos, forme faible.
ObjectiveProfile _weakProfile() => const ObjectiveProfile(
      maxElevationGainPerDayDone: 300,
      maxDistancePerDayDone: 12,
      maxConsecutiveDaysDone: 2,
      fitnessLevelRank: 0,
      hasWalkTest: true,
    );

void main() {
  group('TrekFeasibilityCalculator — verdict', () {
    test('GO : profil confirme sur un trek dans ses cordes', () {
      final r = TrekFeasibilityCalculator.evaluate(
        profile: _strongProfile(),
        trek: const TrekRequirements(
          maxElevationGainPerDay: 900,
          maxDistancePerDayKm: 20,
          totalDays: 7,
          technicite: 2,
          risque: 2,
          effortLevel: 3,
        ),
      );
      expect(r.verdict, TrekVerdict.go);
      expect(r.gaps, isEmpty);
      expect(r.usedObjectiveProfile, isTrue);
    });

    test('CAUTION : exigence D+/jour 40 % au-dessus du deja-fait', () {
      // deja fait 300 D+/j ; trek 450/j -> ratio 1.5 (>1.3, <=1.8) -> warning.
      final r = TrekFeasibilityCalculator.evaluate(
        profile: _weakProfile(),
        trek: const TrekRequirements(
          maxElevationGainPerDay: 450,
          maxDistancePerDayKm: 12,
          totalDays: 2,
        ),
      );
      expect(r.verdict, TrekVerdict.caution);
      expect(
        r.gaps.any((g) =>
            g.category == FeasibilityGap.elevationPerDay &&
            g.severity == GapSeverity.warning),
        isTrue,
      );
    });

    test('DANGER : exigence D+/jour double du deja-fait (ratio > 1.8)', () {
      final r = TrekFeasibilityCalculator.evaluate(
        profile: _weakProfile(), // 300 D+/j
        trek: const TrekRequirements(
          maxElevationGainPerDay: 900, // ratio 3.0
          maxDistancePerDayKm: 12,
          totalDays: 2,
        ),
      );
      expect(r.verdict, TrekVerdict.danger);
      expect(
        r.gaps.first.severity,
        GapSeverity.blocking,
        reason: 'les bloquants sont tries en tete',
      );
    });

    test('DANGER : aucune experience comparable (deja-fait = 0)', () {
      const noExperience = ObjectiveProfile(
        maxElevationGainPerDayDone: 0,
        maxDistancePerDayDone: 0,
        maxConsecutiveDaysDone: 0,
        fitnessLevelRank: 1,
        hasWalkTest: false,
      );
      final r = TrekFeasibilityCalculator.evaluate(
        profile: noExperience,
        trek: const TrekRequirements(
          maxElevationGainPerDay: 600,
          maxDistancePerDayKm: 18,
          totalDays: 5,
        ),
      );
      expect(r.verdict, TrekVerdict.danger);
      // D+/j et distance/j bloquants (rien fait de comparable).
      expect(
        r.gaps.where((g) => g.severity == GapSeverity.blocking).length,
        greaterThanOrEqualTo(2),
      );
    });
  });

  group('TrekFeasibilityCalculator — cotations FFRando', () {
    test('technicite 5 -> bloquant ; risque 3 -> alerte', () {
      final r = TrekFeasibilityCalculator.evaluate(
        profile: _strongProfile(),
        trek: const TrekRequirements(
          maxElevationGainPerDay: 900,
          maxDistancePerDayKm: 20,
          totalDays: 5,
          technicite: 5,
          risque: 3,
        ),
      );
      expect(r.verdict, TrekVerdict.danger);
      expect(
        r.gaps.any((g) =>
            g.category == FeasibilityGap.technicity &&
            g.severity == GapSeverity.blocking),
        isTrue,
      );
      expect(
        r.gaps.any((g) =>
            g.category == FeasibilityGap.risk &&
            g.severity == GapSeverity.warning),
        isTrue,
      );
    });

    test('notes FFRando faibles (<=2) -> aucun point faible', () {
      final r = TrekFeasibilityCalculator.evaluate(
        profile: _strongProfile(),
        trek: const TrekRequirements(
          maxElevationGainPerDay: 900,
          maxDistancePerDayKm: 20,
          totalDays: 5,
          technicite: 2,
          risque: 1,
          effortLevel: 2,
        ),
      );
      expect(r.gaps, isEmpty);
      expect(r.verdict, TrekVerdict.go);
    });

    test('effort eleve (4) + forme faible -> alerte forme', () {
      final r = TrekFeasibilityCalculator.evaluate(
        profile: _weakProfile(), // rank 0
        trek: const TrekRequirements(
          maxElevationGainPerDay: 300, // dans ses cordes
          maxDistancePerDayKm: 12,
          totalDays: 2,
          effortLevel: 4,
        ),
      );
      expect(
        r.gaps.any((g) => g.category == FeasibilityGap.fitness),
        isTrue,
      );
    });
  });

  group('TrekFeasibilityCalculator — jours consecutifs', () {
    test('trek 12 j vs 2 j deja faits -> bloquant (ratio 6)', () {
      final r = TrekFeasibilityCalculator.evaluate(
        profile: _weakProfile(),
        trek: const TrekRequirements(
          maxElevationGainPerDay: 300,
          maxDistancePerDayKm: 12,
          totalDays: 12,
        ),
      );
      expect(
        r.gaps.any((g) =>
            g.category == FeasibilityGap.consecutiveDays &&
            g.severity == GapSeverity.blocking),
        isTrue,
      );
    });

    test('trek 1 jour -> aucun enjeu multi-jours', () {
      final r = TrekFeasibilityCalculator.evaluate(
        profile: _weakProfile(),
        trek: const TrekRequirements(
          maxElevationGainPerDay: 300,
          maxDistancePerDayKm: 12,
          totalDays: 1,
        ),
      );
      expect(
        r.gaps.any((g) => g.category == FeasibilityGap.consecutiveDays),
        isFalse,
      );
    });
  });

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
