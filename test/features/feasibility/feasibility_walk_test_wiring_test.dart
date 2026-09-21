import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_norms.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';

/// CABLAGE TEST 6 MIN -> CALCUL (LOT 4, retour R2b : « le test doit changer le
/// resultat »). Ces tests reproduisent — de facon PURE et deterministe — la
/// chaine des providers de prod :
///   objectiveProfileProvider  = ObjectiveProfile.from(pastHikes, walkTest)
///   hikerLevelProvider        = FeasibilityFormula.deriveLevel(..., fitnessRank
///                               = objective.fitnessLevelRank)
///   feasibilityAssessment     = FeasibilityFormula.evaluate(stages, level)
/// On prouve qu'un MEME jeu d'etapes + de randos passees, evalue avec un TEST
/// 6 min different, produit un NIVEAU (donc un plafond, donc un verdict)
/// different. La formule #100068 n'est pas modifiee : on teste son CABLAGE.
void main() {
  // Rando « intermediaire » de reference (repere BP : D+/jour 300-700,
  // distance/jour 15-22) -> niveau BRUT intermediaire avant correction forme.
  final baselineHikes = <PastHike>[
    PastHike(
      date: DateTime(2026, 1, 1),
      days: 1,
      avgWalkHoursPerDay: 6,
      totalElevationGain: 450, // 450 m/jour -> intermediaire
      totalDistanceKm: 18, // 18 km/jour -> intermediaire
    ),
  ];

  /// Reproduit la chaine des providers : profil objectif -> niveau derive.
  HikerLevel deriveLevelFor(WalkTestResult? walkTest) {
    final objective = ObjectiveProfile.from(
      pastHikes: baselineHikes,
      walkTest: walkTest,
      // Fallback median (comme _fallbackFitnessRankProvider quand pas de test).
      fallbackFitnessRank: 1,
    );
    return FeasibilityFormula.deriveLevel(
      maxElevationGainPerDayDone: objective.maxElevationGainPerDayDone,
      maxDistancePerDayDone: objective.maxDistancePerDayDone,
      age: 30, // adulte, aucune correction age
      fitnessRank: objective.fitnessLevelRank,
    );
  }

  WalkTestResult testOfLevel(String level) => WalkTestResult(
        distanceMeters: 500,
        level: level,
        takenAt: DateTime(2026, 1, 2),
      );

  test('le niveau derive depend du test 6 min (rank consomme)', () {
    // Sans test : rang de forme fallback median (1) -> intermediaire brut.
    final noTest = deriveLevelFor(null);
    // Test EXCELLENT (rang 3) -> remonte d'un cran -> confirme.
    final excellent = deriveLevelFor(testOfLevel(WalkTestLevel.excellent));
    // Test FAIBLE (rang 0) -> redescend d'un cran -> debutant.
    final low = deriveLevelFor(testOfLevel(WalkTestLevel.low));

    expect(noTest, HikerLevel.intermediate,
        reason: 'baseline intermediaire sans test');
    expect(excellent.index, greaterThan(noTest.index),
        reason: 'un excellent test 6 min remonte le niveau');
    expect(low.index, lessThan(noTest.index),
        reason: 'un faible test 6 min redescend le niveau');
  });

  test('le VERDICT change quand le test 6 min change (meme etapes)', () {
    // Etape unique calee pour etre ORANGE en intermediaire (plafond 29
    // km-effort) et VERTE en confirme (plafond 39). effort = 20 + 800/100 = 28.
    final stages = [
      const StageEffort(
        index: 0,
        name: 'Etape test',
        distanceKm: 20,
        elevationGainM: 800,
      ),
    ];

    FeasibilityAssessment evalWith(WalkTestResult? t) =>
        FeasibilityFormula.evaluate(
          stages: stages,
          level: deriveLevelFor(t),
        );

    final withoutTest = evalWith(null); // intermediaire
    final withExcellent =
        evalWith(testOfLevel(WalkTestLevel.excellent)); // confirme

    // Le plafond journalier augmente avec un excellent test -> le ratio baisse.
    expect(withExcellent.dailyCeilingKmEffort,
        greaterThan(withoutTest.dailyCeilingKmEffort));
    // Concretement : orange (28/29 ~ 0.97) sans test -> vert (28/39 ~ 0.72)
    // avec un excellent test. Le verdict global DOIT changer.
    expect(withoutTest.globalVerdict, FeasibilityVerdict.orange);
    expect(withExcellent.globalVerdict, FeasibilityVerdict.green);
    expect(withExcellent.globalVerdict,
        isNot(equals(withoutTest.globalVerdict)),
        reason: 'le test 6 min change bien le verdict (R2b)');
  });

  test('WalkTestLevel.rank mappe bien les 4 niveaux (0..3)', () {
    // Garde-fou du cablage : ObjectiveProfile.from lit ce rang.
    expect(WalkTestLevel.rank(WalkTestLevel.low), 0);
    expect(WalkTestLevel.rank(WalkTestLevel.moderate), 1);
    expect(WalkTestLevel.rank(WalkTestLevel.good), 2);
    expect(WalkTestLevel.rank(WalkTestLevel.excellent), 3);
  });

  test('ObjectiveProfile expose le rang du test quand present', () {
    final withTest = ObjectiveProfile.from(
      pastHikes: baselineHikes,
      walkTest: testOfLevel(WalkTestLevel.good),
    );
    expect(withTest.hasWalkTest, isTrue);
    expect(withTest.fitnessLevelRank, WalkTestLevel.rank(WalkTestLevel.good));

    final withoutTest = ObjectiveProfile.from(
      pastHikes: baselineHikes,
      walkTest: null,
      fallbackFitnessRank: 2,
    );
    expect(withoutTest.hasWalkTest, isFalse);
    expect(withoutTest.fitnessLevelRank, 2,
        reason: 'sans test -> le fallback fournit le rang');
  });
}
