/// FORMULE DE FAISABILITE V1 (StepWays LOT 3a) — decision Chris #100068.
///
/// Moteur PUR (zero dependance Flutter), entierement testable a l'unite. Il
/// croise l'EFFORT de chaque etape a la CAPACITE journaliere du randonneur et
/// rend un verdict FEU TRICOLORE + un verdict global + des conseils de programme.
///
/// PERIMETRE V1 (arbitrage Chris) : distance + D+ SEULEMENT. La technicite
/// (T1-T6), l'altitude et l'IMC/VO2max fin sont explicitement reportes en V2
/// (BP `BP_faisabilite_entrainement.md` : aucune formule altitude fiable, ne
/// pas surpromettre). Des hooks TODO(V2) marquent les points d'extension SANS
/// les activer.
///
/// Sources BP : FFRandonnee, SAC/CAS, IBP Index, methode Karvonen
/// (`data/apport_stepways/BP_faisabilite_entrainement.md`).
library;

import 'dart:math' as math;

/// Niveau de randonneur deduit du profil (ordre croissant de capacite).
///
/// Cles i18n stables (`t.feasibility.formula.levels.*`). Les reperes BP D+/jour
/// qui bornent chaque niveau : <300 debutant, 300-700 intermediaire,
/// 700-1200 confirme, >1200 expert.
enum HikerLevel {
  beginner,
  intermediate,
  confirmed,
  expert,
}

/// Verdict FEU TRICOLORE d'une etape ou du trek (cles i18n stables
/// `t.feasibility.formula.verdicts.*`).
enum FeasibilityVerdict {
  /// Vert : ratio <= [FeasibilityThresholds.green]. Faisable confortablement.
  green,

  /// Orange : entre les deux seuils. Faisable AVEC entrainement.
  orange,

  /// Rouge : ratio > [FeasibilityThresholds.orange]. Au-dessus des capacites.
  red,
}

/// Facteur limitant nomme du verdict global (cle i18n
/// `t.feasibility.formula.limitingFactors.*`).
enum LimitingFactor {
  /// La distance des etapes est le principal contributeur a l'effort.
  distance,

  /// Le denivele positif est le principal contributeur a l'effort.
  elevation,

  /// L'enchainement (plusieurs jours consecutifs au-dessus du plafond).
  chaining,

  /// Aucun facteur limitant (verdict vert global).
  none,
}

/// Seuils du feu tricolore — CONSTANTES PARAMETRABLES (reglage median valide
/// par Chris, ni prudent ni permissif). ratio = effort_etape / plafond_jour.
///
/// Externalises dans un objet pour pouvoir les surcharger (tests, futur reglage
/// utilisateur) sans toucher a la logique.
class FeasibilityThresholds {
  const FeasibilityThresholds({
    this.green = defaultGreen,
    this.orange = defaultOrange,
  });

  /// ratio <= green  -> VERT.
  static const double defaultGreen = 0.85;

  /// green < ratio <= orange -> ORANGE ; ratio > orange -> ROUGE.
  static const double defaultOrange = 1.10;

  /// Seuil haut du vert (median valide Chris).
  final double green;

  /// Seuil haut de l'orange (median valide Chris).
  final double orange;

  /// Reglage median par defaut.
  static const FeasibilityThresholds median = FeasibilityThresholds();

  /// Classe un ratio effort/capacite en verdict tricolore.
  FeasibilityVerdict verdictFor(double ratio) {
    if (ratio <= green) return FeasibilityVerdict.green;
    if (ratio <= orange) return FeasibilityVerdict.orange;
    return FeasibilityVerdict.red;
  }
}

/// Plafonds journaliers de reference par niveau (km-effort/jour).
///
/// Le km-effort = distance_km + D+_m/100 (equivalence BP 100 m D+ = 1 km plat).
/// On derive un plafond km-effort COHERENT par niveau a partir des reperes BP :
///   - D+/jour de reference : 300 / 700 / 1200 / 1500 m
///   - distance/jour de reference : 18 / 22 / 27 / 30 km
///   - plafond km-effort = distance_ref + D+_ref/100
/// -> 21 / 29 / 39 / 45 km-effort. Ces valeurs sont le PLAFOND « soutenable au
/// quotidien » (le seuil vert 0.85 laisse la marge de confort en dessous).
class DailyCapacity {
  const DailyCapacity._();

  /// Plafond km-effort/jour de BASE pour un niveau (avant corrections).
  static double baseCeilingFor(HikerLevel level) {
    switch (level) {
      case HikerLevel.beginner:
        return 18 + 300 / 100; // 21
      case HikerLevel.intermediate:
        return 22 + 700 / 100; // 29
      case HikerLevel.confirmed:
        return 27 + 1200 / 100; // 39
      case HikerLevel.expert:
        return 30 + 1500 / 100; // 45
    }
  }
}

/// Effort d'une etape (km-effort) + sa decomposition, pour nommer le facteur
/// limitant sans recalculer.
class StageEffort {
  const StageEffort({
    required this.index,
    required this.name,
    required this.distanceKm,
    required this.elevationGainM,
  });

  /// Index 0-based de l'etape dans la sequence.
  final int index;

  /// Nom de l'etape (affichage).
  final String name;

  /// Distance de l'etape (km).
  final double distanceKm;

  /// Denivele positif de l'etape (m).
  final int elevationGainM;

  /// Contribution du D+ en equivalent km plat (D+_m / 100).
  double get elevationEffortKm => elevationGainM / 100.0;

  /// EFFORT total en km-effort = distance + D+/100 (formule Chris #100068).
  double get effortKm => distanceKm + elevationEffortKm;
}

/// Verdict tricolore d'une etape (etape + ratio + couleur).
class StageVerdict {
  const StageVerdict({
    required this.stage,
    required this.ratio,
    required this.verdict,
  });

  /// L'etape evaluee (effort + decomposition).
  final StageEffort stage;

  /// ratio = effort_etape / plafond_jour (>= 0).
  final double ratio;

  /// Verdict tricolore de l'etape.
  final FeasibilityVerdict verdict;

  /// Vrai si l'etape depasse le plafond (orange ou rouge -> « au-dessus »).
  bool get isOverCapacity => verdict != FeasibilityVerdict.green;
}

/// Un conseil de programme (cle i18n + parametres nommes pour l'affichage).
///
/// Le moteur ne fabrique PAS de phrase : il produit une cle stable + les
/// nombres. L'UI compose le texte via Slang (accents FR garantis cote i18n).
class ProgramAdvice {
  const ProgramAdvice({required this.key, this.params = const {}});

  /// Cle i18n stable (`t.feasibility.formula.advice.*`).
  final String key;

  /// Parametres nommes injectes dans le texte i18n (ex. {days: 8}).
  final Map<String, Object> params;
}

/// Resultat complet de la formule de faisabilite V1.
class FeasibilityAssessment {
  const FeasibilityAssessment({
    required this.level,
    required this.dailyCeilingKmEffort,
    required this.stageVerdicts,
    required this.globalVerdict,
    required this.hardestStageIndex,
    required this.daysOverCapacity,
    required this.limitingFactor,
    required this.recommendedTrainingWeeks,
    required this.advice,
    required this.suggestedDays,
  });

  /// Niveau retenu (corrige age + condition).
  final HikerLevel level;

  /// Plafond journalier applique (km-effort), apres corrections.
  final double dailyCeilingKmEffort;

  /// Verdict tricolore par etape (meme ordre que l'entree).
  final List<StageVerdict> stageVerdicts;

  /// Verdict global = pire etape (feu tricolore agrege).
  final FeasibilityVerdict globalVerdict;

  /// Index 0-based de l'etape la plus contraignante (ratio max), -1 si aucune.
  final int hardestStageIndex;

  /// Nombre de jours (etapes) au-dessus du plafond (orange + rouge).
  final int daysOverCapacity;

  /// Facteur limitant nomme du verdict global.
  final LimitingFactor limitingFactor;

  /// Reco d'entrainement en semaines (6-12 selon le profil), 0 si verdict vert.
  final int recommendedTrainingWeeks;

  /// Conseils de programme (nb de jours optimal, decoupe, repos).
  final List<ProgramAdvice> advice;

  /// Nombre de jours de MARCHE optimal propose (hors repos) pour rester sous le
  /// plafond. >= au nombre d'etapes d'entree.
  final int suggestedDays;

  /// Etape la plus contraignante (null si aucune etape).
  StageVerdict? get hardestStage =>
      hardestStageIndex >= 0 ? stageVerdicts[hardestStageIndex] : null;
}

/// Moteur de la formule de faisabilite V1 (fonction PURE) — decision #100068.
class FeasibilityFormula {
  const FeasibilityFormula._();

  /// Bornes d'entrainement recommandees (BP : sedentaire 12, actif 8-12,
  /// repris 6). On borne toute reco entre ces deux valeurs.
  static const int minTrainingWeeks = 6;
  static const int maxTrainingWeeks = 12;

  /// Deduit le niveau de randonneur a partir des reperes chiffres DEJA REALISES
  /// (D+/jour et distance/jour max des randos passees), CORRIGE par l'age et la
  /// condition declaree/testee.
  ///
  /// - [maxElevationGainPerDayDone] / [maxDistancePerDayDone] : maxima deja
  ///   realises (0 = jamais rien fait de comparable).
  /// - [age] : corrige la capacite (VO2max ~ -10 %/decennie au-dela de 40 ans,
  ///   BP). 0 = non renseigne (pas de correction).
  /// - [fitnessRank] : rang de forme 0..3 (test 6 min ou fallback). Un rang bas
  ///   plafonne le niveau vers le bas, un rang haut peut le remonter d'un cran.
  static HikerLevel deriveLevel({
    required double maxElevationGainPerDayDone,
    required double maxDistancePerDayDone,
    int age = 0,
    int fitnessRank = 1,
  }) {
    // 1. Niveau BRUT depuis le D+/jour deja realise (repere BP dominant).
    HikerLevel byElevation;
    if (maxElevationGainPerDayDone >= 1200) {
      byElevation = HikerLevel.expert;
    } else if (maxElevationGainPerDayDone >= 700) {
      byElevation = HikerLevel.confirmed;
    } else if (maxElevationGainPerDayDone >= 300) {
      byElevation = HikerLevel.intermediate;
    } else {
      byElevation = HikerLevel.beginner;
    }

    // 2. Niveau BRUT depuis la distance/jour deja realisee (repere BP 15-30).
    HikerLevel byDistance;
    if (maxDistancePerDayDone >= 27) {
      byDistance = HikerLevel.expert;
    } else if (maxDistancePerDayDone >= 22) {
      byDistance = HikerLevel.confirmed;
    } else if (maxDistancePerDayDone >= 15) {
      byDistance = HikerLevel.intermediate;
    } else {
      byDistance = HikerLevel.beginner;
    }

    // Niveau objectif = le plus PRUDENT des deux (on ne surestime jamais).
    var rank = math.min(byElevation.index, byDistance.index);

    // 3. Correction CONDITION : un rang de forme faible (0) redescend d'un cran,
    // un rang excellent (3) remonte d'un cran (borne aux extremes).
    if (fitnessRank <= 0) {
      rank = math.max(0, rank - 1);
    } else if (fitnessRank >= 3) {
      rank = math.min(HikerLevel.values.length - 1, rank + 1);
    }

    // 4. Correction AGE (VO2max -10 %/decennie au-dela de 40 ans) : -1 cran a
    // partir de 60 ans, -2 crans a partir de 75 ans. Ne descend pas sous 0.
    if (age >= 75) {
      rank = math.max(0, rank - 2);
    } else if (age >= 60) {
      rank = math.max(0, rank - 1);
    }

    return HikerLevel.values[rank];
  }

  /// Plafond journalier (km-effort) applique au niveau, apres corrections fines.
  ///
  /// Le niveau porte deja les corrections age/condition (via [deriveLevel]) ;
  /// on renvoie donc directement le plafond de base du niveau. Isole pour
  /// pouvoir affiner en V2 (moduler finement selon l'IMC/VO2max).
  static double dailyCeilingFor(HikerLevel level) {
    // TODO(V2): moduler par IMC/VO2max fin quand la donnee sera fiable.
    return DailyCapacity.baseCeilingFor(level);
  }

  /// Reco d'entrainement (semaines) selon le niveau et la severite du verdict.
  ///
  /// BP : sedentaire 12, actif 8-12, repris 6. On mappe le niveau (proxy de la
  /// condition) puis on rallonge si le verdict global est rouge.
  static int trainingWeeksFor(HikerLevel level, FeasibilityVerdict global) {
    if (global == FeasibilityVerdict.green) return 0;
    int base;
    switch (level) {
      case HikerLevel.beginner:
        base = maxTrainingWeeks; // 12 (proche sedentaire)
        break;
      case HikerLevel.intermediate:
        base = 8;
        break;
      case HikerLevel.confirmed:
        base = 6;
        break;
      case HikerLevel.expert:
        base = minTrainingWeeks; // 6 (entretien)
        break;
    }
    // Un verdict ROUGE ajoute une marge (au-dessus des capacites actuelles).
    if (global == FeasibilityVerdict.red) {
      base = math.min(maxTrainingWeeks, base + 2);
    }
    return base.clamp(minTrainingWeeks, maxTrainingWeeks);
  }

  /// EVALUE la faisabilite d'une sequence d'etapes pour un randonneur.
  ///
  /// [stages] : etapes DANS L'ORDRE de marche (une par « jour de marche »).
  /// [level] : niveau du randonneur (via [deriveLevel]).
  /// [thresholds] : seuils tricolores (median par defaut, parametrable).
  static FeasibilityAssessment evaluate({
    required List<StageEffort> stages,
    required HikerLevel level,
    int age = 0,
    FeasibilityThresholds thresholds = FeasibilityThresholds.median,
  }) {
    final ceiling = dailyCeilingFor(level);

    // 1. Verdict tricolore de chaque etape (ratio = effort / plafond).
    final verdicts = <StageVerdict>[];
    for (final s in stages) {
      final ratio = ceiling > 0 ? s.effortKm / ceiling : double.infinity;
      verdicts.add(StageVerdict(
        stage: s,
        ratio: ratio,
        verdict: thresholds.verdictFor(ratio),
      ));
    }

    // 2. Etape la plus contraignante (ratio max) + verdict global = sa couleur.
    var hardestIndex = -1;
    var hardestRatio = -1.0;
    for (var i = 0; i < verdicts.length; i++) {
      if (verdicts[i].ratio > hardestRatio) {
        hardestRatio = verdicts[i].ratio;
        hardestIndex = i;
      }
    }
    final globalVerdict = hardestIndex >= 0
        ? verdicts[hardestIndex].verdict
        : FeasibilityVerdict.green;

    // 3. Nombre de jours au-dessus du plafond (orange + rouge).
    final daysOver = verdicts.where((v) => v.isOverCapacity).length;

    // 4. Facteur limitant nomme.
    final limiting = _computeLimitingFactor(
      verdicts: verdicts,
      daysOver: daysOver,
      hardestIndex: hardestIndex,
    );

    // 5. Reco entrainement.
    final trainingWeeks = trainingWeeksFor(level, globalVerdict);

    // 6. Conseils de programme (nb de jours optimal + decoupe + repos).
    final suggestedDays = _suggestedWalkingDays(stages, ceiling);
    final advice = _buildAdvice(
      verdicts: verdicts,
      globalVerdict: globalVerdict,
      hardestIndex: hardestIndex,
      suggestedDays: suggestedDays,
      currentDays: stages.length,
      trainingWeeks: trainingWeeks,
    );

    return FeasibilityAssessment(
      level: level,
      dailyCeilingKmEffort: ceiling,
      stageVerdicts: verdicts,
      globalVerdict: globalVerdict,
      hardestStageIndex: hardestIndex,
      daysOverCapacity: daysOver,
      limitingFactor: limiting,
      recommendedTrainingWeeks: trainingWeeks,
      advice: advice,
      suggestedDays: suggestedDays,
    );
  }

  /// Determine le facteur limitant : d'abord l'ENCHAINEMENT (>=2 jours au-dessus
  /// du plafond), sinon, sur l'etape la plus dure, le plus gros contributeur
  /// entre la distance et le D+.
  static LimitingFactor _computeLimitingFactor({
    required List<StageVerdict> verdicts,
    required int daysOver,
    required int hardestIndex,
  }) {
    if (hardestIndex < 0) return LimitingFactor.none;
    final hardest = verdicts[hardestIndex];
    if (hardest.verdict == FeasibilityVerdict.green) {
      // Meme la pire etape est verte -> rien ne limite.
      return LimitingFactor.none;
    }
    // Enchainement : plusieurs jours consecutifs au-dessus = c'est LA contrainte.
    if (daysOver >= 2 && _hasConsecutiveOver(verdicts)) {
      return LimitingFactor.chaining;
    }
    // Sinon : sur l'etape la plus dure, distance vs D+ (part dominante).
    final s = hardest.stage;
    return s.elevationEffortKm >= s.distanceKm
        ? LimitingFactor.elevation
        : LimitingFactor.distance;
  }

  /// Vrai s'il existe au moins DEUX etapes consecutives au-dessus du plafond.
  static bool _hasConsecutiveOver(List<StageVerdict> verdicts) {
    for (var i = 1; i < verdicts.length; i++) {
      if (verdicts[i].isOverCapacity && verdicts[i - 1].isOverCapacity) {
        return true;
      }
    }
    return false;
  }

  /// Nombre de jours de MARCHE optimal pour que la charge moyenne tienne sous le
  /// plafond, en lissant les pics : max(nb d'etapes, ceil(effort_total /
  /// plafond), nb d'etapes rouges * 2 pour permettre le decoupage des pires).
  static int _suggestedWalkingDays(List<StageEffort> stages, double ceiling) {
    if (stages.isEmpty) return 0;
    final totalEffort = stages.fold<double>(0, (sum, s) => sum + s.effortKm);
    final byLoad = ceiling > 0 ? (totalEffort / ceiling).ceil() : stages.length;
    // Chaque etape ROUGE (> plafond large) merite au moins d'etre coupee en 2.
    final redCount =
        stages.where((s) => ceiling > 0 && s.effortKm > ceiling).length;
    final byRed = stages.length + redCount;
    return math.max(stages.length, math.max(byLoad, byRed));
  }

  /// Construit les conseils de programme (cles i18n + parametres). Coherent avec
  /// l'ecran Programme (LOT 2) : jours + repos + decoupe.
  static List<ProgramAdvice> _buildAdvice({
    required List<StageVerdict> verdicts,
    required FeasibilityVerdict globalVerdict,
    required int hardestIndex,
    required int suggestedDays,
    required int currentDays,
    required int trainingWeeks,
  }) {
    final advice = <ProgramAdvice>[];

    // Tout vert : le programme actuel tient, on encourage a garder des marges.
    if (globalVerdict == FeasibilityVerdict.green) {
      advice.add(const ProgramAdvice(key: 'balancedOk'));
      return advice;
    }

    // 1. Nombre de jours optimal (si plus que le decoupage actuel).
    if (suggestedDays > currentDays) {
      advice.add(ProgramAdvice(
        key: 'optimalDays',
        params: {'days': suggestedDays, 'current': currentDays},
      ));
    } else {
      advice.add(const ProgramAdvice(key: 'balanced'));
    }

    // 2. Ou decouper : l'etape la plus dure (1-based pour l'affichage).
    if (hardestIndex >= 0 &&
        verdicts[hardestIndex].verdict == FeasibilityVerdict.red) {
      advice.add(ProgramAdvice(
        key: 'split',
        params: {'stage': hardestIndex + 1},
      ));
    }

    // 3. Ou poser les repos : apres chaque bloc d'etapes au-dessus du plafond.
    final restAfter = _restDaySuggestions(verdicts);
    if (restAfter.isNotEmpty) {
      advice.add(ProgramAdvice(
        key: 'rest',
        params: {'stages': restAfter.map((i) => i + 1).join(', ')},
      ));
    }

    // 4. Entrainement (renvoi vers la prepa physique).
    if (trainingWeeks > 0) {
      advice.add(ProgramAdvice(
        key: 'training',
        params: {'weeks': trainingWeeks},
      ));
    }

    return advice;
  }

  /// Index (0-based) des etapes APRES lesquelles poser un jour de repos : la
  /// derniere etape de chaque bloc consecutif au-dessus du plafond (hors toute
  /// derniere etape du trek, ou un repos n'a pas de sens).
  static List<int> _restDaySuggestions(List<StageVerdict> verdicts) {
    final suggestions = <int>[];
    for (var i = 0; i < verdicts.length; i++) {
      final over = verdicts[i].isOverCapacity;
      final nextOver =
          i + 1 < verdicts.length && verdicts[i + 1].isOverCapacity;
      // Fin d'un bloc « au-dessus » suivi d'une autre etape -> repos utile.
      if (over && !nextOver && i + 1 < verdicts.length) {
        suggestions.add(i);
      }
    }
    return suggestions;
  }
}
