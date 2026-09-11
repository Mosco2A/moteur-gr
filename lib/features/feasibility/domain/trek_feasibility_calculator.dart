import 'past_hike.dart';
import 'walk_test_norms.dart';
import 'walk_test_result.dart';

/// Verdict global du croisement profil x trek (StepWays LOT 4, Ph5).
///
/// Cles i18n stables (`t.feasibility.levels.*`, reutilisees du questionnaire) :
/// - [go]      : faisable au vu du profil (aucun ecart bloquant).
/// - [caution] : faisable avec preparation (au moins un ecart modere).
/// - [danger]  : ecart majeur -> deconseille en l'etat.
abstract class TrekVerdict {
  static const String go = 'good';
  static const String caution = 'caution';
  static const String danger = 'danger';
}

/// Categories de points faibles POUR CE TREK (cles i18n `t.feasibility.gaps.*`).
abstract class FeasibilityGap {
  static const String elevationPerDay = 'elevationPerDay';
  static const String distancePerDay = 'distancePerDay';
  static const String consecutiveDays = 'consecutiveDays';
  static const String technicity = 'technicity';
  static const String risk = 'risk';
  static const String fitness = 'fitness';
  static const String effort = 'effort';
}

/// Severite d'un ecart : au-dela du seuil « alerte » => caution ; au-dela du
/// seuil « bloquant » => danger.
enum GapSeverity { none, warning, blocking }

/// Un point faible identifie pour CE trek (ecart chiffre -> alerte).
class FeasibilityGapResult {
  const FeasibilityGapResult({
    required this.category,
    required this.severity,
    required this.required_,
    required this.experienced,
  });

  /// Categorie (voir [FeasibilityGap]).
  final String category;

  /// Severite de l'ecart.
  final GapSeverity severity;

  /// Exigence du trek (valeur chiffree : D+/j, km/j, jours, note 1-5...).
  final double required_;

  /// Ce que le randonneur a DEJA fait / son niveau (meme unite).
  final double experienced;
}

/// Exigences chiffrees d'un trek pour la faisabilite (assemblees a partir des
/// donnees reelles : etapes/itineraire + cotation FFRando).
class TrekRequirements {
  const TrekRequirements({
    required this.maxElevationGainPerDay,
    required this.maxDistancePerDayKm,
    required this.totalDays,
    this.technicite,
    this.risque,
    this.effortLevel,
    this.maxAltitude,
  });

  /// D+ maximal exige sur la journee la plus dure (m).
  final double maxElevationGainPerDay;

  /// Distance maximale exigee sur la journee la plus dure (km).
  final double maxDistancePerDayKm;

  /// Nombre total de jours consecutifs du trek.
  final int totalDays;

  /// Technicite FFRando (1-5), null si non cotee.
  final int? technicite;

  /// Risque FFRando (1-5), null si non cote.
  final int? risque;

  /// Niveau d'effort (IBP) 1-5, null si non cote.
  final int? effortLevel;

  /// Altitude maximale du trek (m), null si inconnue.
  final double? maxAltitude;
}

/// Profil OBJECTIF deduit (fiche + test 6 min + 5 randos), consomme par le
/// croisement. Ce que le randonneur a DEJA fait / son niveau reel.
class ObjectiveProfile {
  const ObjectiveProfile({
    required this.maxElevationGainPerDayDone,
    required this.maxDistancePerDayDone,
    required this.maxConsecutiveDaysDone,
    required this.fitnessLevelRank,
    required this.hasWalkTest,
  });

  /// D+ max/jour deja realise (m), deduit des 5 randos.
  final double maxElevationGainPerDayDone;

  /// Distance max/jour deja realisee (km), deduite des 5 randos.
  final double maxDistancePerDayDone;

  /// Plus longue rando en jours consecutifs deja faite.
  final int maxConsecutiveDaysDone;

  /// Rang de forme 0..3 (test 6 min si fait, sinon fallback questionnaire).
  final int fitnessLevelRank;

  /// Vrai si le test 6 min a ete realise (sinon niveau = fallback).
  final bool hasWalkTest;

  /// Construit le profil objectif a partir des donnees brutes.
  ///
  /// [fallbackFitnessRank] : rang de forme de dépannage (questionnaire) quand
  /// le test 6 min n'a pas ete fait. Les randos donnent les maxima deja faits.
  factory ObjectiveProfile.from({
    required List<PastHike> pastHikes,
    required WalkTestResult? walkTest,
    int fallbackFitnessRank = 1,
  }) {
    double maxGain = 0;
    double maxDist = 0;
    int maxDays = 0;
    for (final h in pastHikes) {
      if (h.avgElevationGainPerDay > maxGain) {
        maxGain = h.avgElevationGainPerDay;
      }
      if (h.avgDistancePerDayKm > maxDist) maxDist = h.avgDistancePerDayKm;
      if (h.days > maxDays) maxDays = h.days;
    }
    final hasTest = walkTest != null;
    final rank =
        hasTest ? WalkTestLevel.rank(walkTest.level) : fallbackFitnessRank;
    return ObjectiveProfile(
      maxElevationGainPerDayDone: maxGain,
      maxDistancePerDayDone: maxDist,
      maxConsecutiveDaysDone: maxDays,
      fitnessLevelRank: rank,
      hasWalkTest: hasTest,
    );
  }
}

/// Resultat complet du croisement profil x trek.
class TrekFeasibilityResult {
  const TrekFeasibilityResult({
    required this.verdict,
    required this.gaps,
    required this.usedObjectiveProfile,
  });

  /// Verdict global (voir [TrekVerdict]).
  final String verdict;

  /// Points faibles POUR CE TREK (ecarts >= alerte), tries par severite.
  final List<FeasibilityGapResult> gaps;

  /// Vrai si le verdict s'appuie sur le profil objectif (fiche+test+randos),
  /// faux s'il a fallu retomber sur le questionnaire (dépannage).
  final bool usedObjectiveProfile;
}

/// Croisement profil x trek par SEUILS (StepWays LOT 4, Ph5) — fonction PURE.
///
/// Remplace l'auto-label du questionnaire par une confrontation chiffree des
/// EXIGENCES du trek ([TrekRequirements]) a ce que le randonneur a DEJA fait
/// ([ObjectiveProfile]) -> verdict + points faibles POUR CE TREK (spec §3.5).
/// Le questionnaire 8-questions devient un fallback leger (rang de forme de
/// dépannage) quand le profil objectif est incomplet.
///
/// Logique de seuils (ecart = exige / deja_fait) :
///   - ecart <= [warnRatio]      : OK (pas de point faible).
///   - [warnRatio] < ecart <= [blockRatio] : ALERTE (caution).
///   - ecart > [blockRatio]      : BLOQUANT (danger).
/// Les notes FFRando (technicite/risque/effort) et la forme (test 6 min) sont
/// confrontees a des seuils absolus (1-5 / rang) plutot qu'a un ratio.
class TrekFeasibilityCalculator {
  const TrekFeasibilityCalculator._();

  /// Au-dela de +30 % d'exigence vs deja-fait -> alerte.
  static const double warnRatio = 1.3;

  /// Au-dela de +80 % d'exigence vs deja-fait -> bloquant.
  static const double blockRatio = 1.8;

  /// Technicite/risque au-dessus de ce seuil sans experience -> alerte (>=),
  /// bloquant a partir de [ratingBlock].
  static const int ratingWarn = 3;
  static const int ratingBlock = 5;

  /// Evalue la faisabilite du trek pour ce profil.
  static TrekFeasibilityResult evaluate({
    required ObjectiveProfile profile,
    required TrekRequirements trek,
  }) {
    final gaps = <FeasibilityGapResult>[];

    // 1. D+/jour : exige vs deja fait (0 deja-fait = tout ecart est bloquant).
    _addRatioGap(
      gaps,
      category: FeasibilityGap.elevationPerDay,
      required_: trek.maxElevationGainPerDay,
      experienced: profile.maxElevationGainPerDayDone,
    );

    // 2. Distance/jour.
    _addRatioGap(
      gaps,
      category: FeasibilityGap.distancePerDay,
      required_: trek.maxDistancePerDayKm,
      experienced: profile.maxDistancePerDayDone,
    );

    // 3. Jours consecutifs (endurance multi-jours).
    _addDaysGap(
      gaps,
      requiredDays: trek.totalDays,
      doneDays: profile.maxConsecutiveDaysDone,
    );

    // 4. Technicite (note FFRando absolue).
    _addRatingGap(gaps, FeasibilityGap.technicity, trek.technicite);

    // 5. Risque (note FFRando absolue).
    _addRatingGap(gaps, FeasibilityGap.risk, trek.risque);

    // 6. Effort IBP eleve + forme insuffisante -> alerte forme.
    _addFitnessGap(
      gaps,
      effortLevel: trek.effortLevel,
      fitnessRank: profile.fitnessLevelRank,
    );

    // Verdict = pire severite rencontree.
    final hasBlocking = gaps.any((g) => g.severity == GapSeverity.blocking);
    final hasWarning = gaps.any((g) => g.severity == GapSeverity.warning);
    final verdict = hasBlocking
        ? TrekVerdict.danger
        : (hasWarning ? TrekVerdict.caution : TrekVerdict.go);

    // Tri : bloquants d'abord.
    gaps.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return TrekFeasibilityResult(
      verdict: verdict,
      gaps: gaps,
      usedObjectiveProfile: profile.hasWalkTest ||
          profile.maxConsecutiveDaysDone > 0,
    );
  }

  static void _addRatioGap(
    List<FeasibilityGapResult> gaps, {
    required String category,
    required double required_,
    required double experienced,
  }) {
    if (required_ <= 0) return;
    // Jamais rien fait de comparable : l'exigence non nulle est un vrai risque.
    if (experienced <= 0) {
      gaps.add(FeasibilityGapResult(
        category: category,
        severity: GapSeverity.blocking,
        required_: required_,
        experienced: experienced,
      ));
      return;
    }
    final ratio = required_ / experienced;
    final severity = ratio > blockRatio
        ? GapSeverity.blocking
        : (ratio > warnRatio ? GapSeverity.warning : GapSeverity.none);
    if (severity != GapSeverity.none) {
      gaps.add(FeasibilityGapResult(
        category: category,
        severity: severity,
        required_: required_,
        experienced: experienced,
      ));
    }
  }

  static void _addDaysGap(
    List<FeasibilityGapResult> gaps, {
    required int requiredDays,
    required int doneDays,
  }) {
    if (requiredDays <= 1) return; // une journee : pas d'enjeu multi-jours
    if (doneDays <= 0) {
      gaps.add(FeasibilityGapResult(
        category: FeasibilityGap.consecutiveDays,
        severity: GapSeverity.warning,
        required_: requiredDays.toDouble(),
        experienced: 0,
      ));
      return;
    }
    final ratio = requiredDays / doneDays;
    final severity = ratio > blockRatio
        ? GapSeverity.blocking
        : (ratio > warnRatio ? GapSeverity.warning : GapSeverity.none);
    if (severity != GapSeverity.none) {
      gaps.add(FeasibilityGapResult(
        category: FeasibilityGap.consecutiveDays,
        severity: severity,
        required_: requiredDays.toDouble(),
        experienced: doneDays.toDouble(),
      ));
    }
  }

  static void _addRatingGap(
    List<FeasibilityGapResult> gaps,
    String category,
    int? rating,
  ) {
    if (rating == null) return;
    if (rating >= ratingBlock) {
      gaps.add(FeasibilityGapResult(
        category: category,
        severity: GapSeverity.blocking,
        required_: rating.toDouble(),
        experienced: 0,
      ));
    } else if (rating >= ratingWarn) {
      gaps.add(FeasibilityGapResult(
        category: category,
        severity: GapSeverity.warning,
        required_: rating.toDouble(),
        experienced: 0,
      ));
    }
  }

  static void _addFitnessGap(
    List<FeasibilityGapResult> gaps, {
    required int? effortLevel,
    required int fitnessRank,
  }) {
    if (effortLevel == null) return;
    // Effort eleve (>=4) exige une bonne forme (rang >=2). Sinon alerte, et
    // bloquant si effort 5 avec forme faible (rang 0).
    if (effortLevel >= 4 && fitnessRank <= 1) {
      final severity = (effortLevel >= 5 && fitnessRank == 0)
          ? GapSeverity.blocking
          : GapSeverity.warning;
      gaps.add(FeasibilityGapResult(
        category: FeasibilityGap.fitness,
        severity: severity,
        required_: effortLevel.toDouble(),
        experienced: fitnessRank.toDouble(),
      ));
    }
  }
}
