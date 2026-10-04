/// La formule elle-meme : la source unique du verdict.
///
/// Bibliotheque de la formule de faisabilite (lot 645-06b), re-exportee par
/// `feasibility_formula.dart` : les appelants n'importent que cette racine.
/// Les regles de programme qu'elle appelle vivent a cote, dans
/// `feasibility_program_rules.dart`.
library;

import 'dart:math' as math;

import 'feasibility_assessment.dart';
import 'feasibility_program_rules.dart';
import 'feasibility_scale.dart';
import 'feasibility_stages.dart';
import 'feasibility_types.dart';

/// Moteur de la formule de faisabilite V2 (fonctions PURES).
class FeasibilityFormula {
  const FeasibilityFormula._();

  /// Seuil de monotonie de Foster (#S15, Foster 1998) : au-dela de 2,0, le
  /// profil de charge est trop monotone et la recuperation insuffisante.
  ///
  /// EXTRAPOLATION DECLAREE #M08 : ce seuil a ete etabli sur des athletes et
  /// transfere a l'itinerance. Il n'est pas invente — il est DEPLACE, et l'ecart
  /// est dit.
  static const double monotonyThreshold = 2.0;

  /// Largeur de la fenetre glissante de monotonie, en jours (#2-p).
  static const int monotonyWindowDays = 7;

  /// Zone de reference de l'ecart a l'habitude (#S16-a, Gabbett 2016) : 0,8-1,3.
  /// AFFICHEE, JAMAIS DECISIVE (#2-q).
  static const double habitGapLow = 0.8;
  static const double habitGapHigh = 1.3;

  /// Bornes d'entrainement recommandees (BP : sedentaire 12, actif 8-12,
  /// repris 6). On borne toute reco entre ces deux valeurs.
  static const int minTrainingWeeks = 6;
  static const int maxTrainingWeeks = 12;

  /// Deduit le niveau de randonneur a partir des reperes chiffres DEJA REALISES
  /// (D+/jour et distance/jour max des randos passees), CORRIGE par l'age et la
  /// condition declaree/testee.
  ///
  /// INCHANGE EN V2 : c'est de la classification de l'experience passee, elle ne
  /// depend d'aucune unite d'energie. Les bascules de verdict de la campagne
  /// viennent de l'unite, des plafonds et des conditions — pas d'ici (#9-f).
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

  /// Capacite journaliere de REFERENCE (#2-d, #2-e) — L'ORDRE COMPTE.
  ///
  /// `C_jour = max(C_niveau ; E_max_realise) × k_altitude × k_chaleur`.
  ///
  /// Le plancher demontre s'applique a la BASE, les conditions ENSUITE.
  /// L'ordre inverse effacerait silencieusement l'altitude et la chaleur pour
  /// tout randonneur dont le maximum demontre depasse le plafond de son cran :
  /// c'etait l'erreur de la premiere spec, elle est corrigee ici.
  static double dailyCapacityFor({
    required HikerLevel level,
    double demonstratedFloorEnergyKm = 0,
    TrekConditions conditions = TrekConditions.unknown,
    FeasibilityScale scale = FeasibilityScale.v2,
  }) {
    final base = math.max(
      scale.levelCeilingFor(level),
      demonstratedFloorEnergyKm.isFinite && demonstratedFloorEnergyKm > 0
          ? demonstratedFloorEnergyKm
          : 0.0,
    );
    return base * conditions.altitudeFactor * conditions.heatFactor;
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
  /// [demonstratedFloorEnergyKm] : E_max_realise (#2-g), 0 si inconnu.
  /// [habitualDailyEnergyKm] : charge journaliere deja realisee (C4), 0/null si
  ///   inconnue — C4 est alors non calculable et n'est pas affiche.
  /// [longestConsecutiveDaysDone] : plus longue sortie enchainee deja faite, en
  ///   jours. ENONCEE, jamais scoree — voir
  ///   [FeasibilityAssessment.longestConsecutiveDaysDone].
  /// [restAfterStageIndex] : index 0-based des etapes APRES lesquelles un jour
  ///   de repos est pose. Les jours de repos comptent comme CHARGE NULLE dans
  ///   la monotonie de Foster (#2-p).
  /// [conditions] : altitude et saison du depart.
  /// [maxWalkingDays] : nombre MAXIMAL de jours de marche atteignable par le
  ///   programme. Plafonne le nombre de jours CONSEILLE : un conseil que
  ///   l'application n'est pas capable d'executer est PIRE que pas de conseil.
  ///   TACHE 639 — cette documentation decrivait encore la mecanique du lot 558
  ///   (« une etape se coupe en deux portions de meme energie, donc ce plafond
  ///   vaut deux journees par etape »), retiree par le lot 634. Le plafond vaut
  ///   UNE journee par etape : une etape reste une etape du sentier.
  ///   0 = inconnu, aucun plafond.
  /// [durationAdvice] — LE CONSEIL DE DUREE (tache 569, R1). `null` = aucune
  ///   recherche n'a eu lieu : le moteur retombe alors sur son estimation de
  ///   lissage historique ([suggestWalkingDays]), qui ne garantit RIEN sur la
  ///   couleur — c'est pourquoi le chemin de production en fournit toujours un
  ///   ([advisedProgramProvider]). [ProgramDurationAdvice.impossible] = la
  ///   recherche a eu lieu et AUCUNE valeur du curseur n'est meilleure que
  ///   rouge : on ne conseille alors aucune duree.
  /// [fromProgram] : le programme evalue est-il celui CHOISI par le randonneur
  ///   (vrai) ou le programme de REFERENCE du sentier (faux) ? Pilote la
  ///   formulation des conseils qui numerotent des journees (R2).
  /// [scale] : bareme applique. V2 par defaut ; V1 uniquement pour reconstituer
  ///   la colonne « AVANT » des bascules de la campagne personas.
  static FeasibilityAssessment evaluate({
    required List<StageEffort> stages,
    required HikerLevel level,
    double demonstratedFloorEnergyKm = 0,
    double? habitualDailyEnergyKm,
    int longestConsecutiveDaysDone = 0,
    Set<int> restAfterStageIndex = const {},
    TrekConditions conditions = TrekConditions.unknown,
    int maxWalkingDays = 0,
    ProgramDurationAdvice? durationAdvice,
    bool fromProgram = true,
    FeasibilityThresholds thresholds = FeasibilityThresholds.median,
    FeasibilityScale scale = FeasibilityScale.v2,
  }) {
    final levelCeiling = scale.levelCeilingFor(level);
    final floor =
        demonstratedFloorEnergyKm.isFinite && demonstratedFloorEnergyKm > 0
        ? demonstratedFloorEnergyKm
        : 0.0;
    final base = math.max(levelCeiling, floor);
    final ka = conditions.altitudeFactor;
    final kh = conditions.heatFactor;
    final capacity = base * ka * kh;

    // 1. Verdict de chaque etape + decomposition exacte du score (#2-l).
    //
    // LA CAPACITE DU JOUR EST LA MEME POUR TOUTES LES ETAPES, et c'est voulu.
    // La spec definit UN C_jour (#2-d), derive de l'altitude MAXIMALE du trek :
    // une capacite qui changerait d'une etape a l'autre ferait varier le
    // denominateur sous les pieds du randonneur, et deux etapes de meme effort
    // recevraient deux couleurs differentes sans que l'ecran puisse l'expliquer
    // simplement.
    final verdicts = <StageVerdict>[];
    for (final s in stages) {
      final energy = scale.energyOfStage(s);
      final score = capacity > 0 ? energy / capacity : double.infinity;
      // Parts additives : distance + denivele + chaleur + altitude = score.
      final perBase = base > 0 ? energy / base : double.infinity;
      verdicts.add(
        StageVerdict(
          stage: s,
          energyKm: energy,
          capacityKm: capacity,
          score: score,
          verdict: thresholds.verdictFor(score),
          distanceShare: base > 0 ? s.distanceKm / base : double.infinity,
          elevationShare: base > 0
              ? scale.elevationEnergyOf(s) / base
              : double.infinity,
          heatShare: perBase * (1 / kh - 1),
          altitudeShare: perBase * (1 / (ka * kh) - 1 / kh),
        ),
      );
    }

    // 2. Etape la plus contraignante (score max).
    var hardestIndex = -1;
    var hardestScore = -1.0;
    for (var i = 0; i < verdicts.length; i++) {
      if (verdicts[i].score > hardestScore) {
        hardestScore = verdicts[i].score;
        hardestIndex = i;
      }
    }

    // 3. Score de circuit (C1 a C4).
    final circuit = verdicts.isEmpty
        ? null
        : computeCircuitScore(
            verdicts: verdicts,
            capacity: capacity,
            restAfterStageIndex: restAfterStageIndex,
            habitualDailyEnergyKm: habitualDailyEnergyKm,
            thresholds: thresholds,
          );

    // 4. Verdict global = verdict du CIRCUIT (#2-r), et non plus la pire etape.
    final globalVerdict = circuit?.verdict ?? FeasibilityVerdict.green;

    // 5. Nombre de jours au-dessus du plafond (orange + rouge).
    final daysOver = verdicts.where((v) => v.isOverCapacity).length;

    // 6. Facteur limitant nomme du verdict global.
    final limiting = computeLimitingFactor(
      verdicts: verdicts,
      daysOver: daysOver,
      hardestIndex: hardestIndex,
      globalVerdict: globalVerdict,
    );

    // 7. Reco entrainement + conseils de programme.
    final trainingWeeks = trainingWeeksFor(level, globalVerdict);
    // Le repos CONSEILLE (GO-61) : calcule sur les memes energies que C3, donc
    // sur le meme chiffre que celui affiche.
    final recommendedRest = recommendedRestAfterStageIndex(
      verdicts.map((v) => v.energyKm).toList(),
    );

    // LE CONSEIL DE DUREE (tache 569, R1) — trois cas, et un seul conseille.
    final searched = durationAdvice != null;
    final advised = durationAdvice?.isViable ?? true;
    final int suggestedDays;
    final int suggestedRestDays;
    if (durationAdvice != null) {
      // Recherche faite : on porte SON resultat, viable ou non. Quand rien
      // n'est viable, les nombres retombent sur le programme courant — ils ne
      // sont pas affiches, et surtout pas appliques.
      suggestedDays = advised ? durationAdvice.walkingDays : stages.length;
      suggestedRestDays = advised
          ? durationAdvice.restDays
          : restAfterStageIndex.length;
    } else {
      // Aucune recherche : estimation de lissage historique. Elle ne garantit
      // pas la couleur — voir [durationAdvice].
      suggestedDays = suggestWalkingDays(
        verdicts,
        capacity,
        maxWalkingDays: maxWalkingDays,
      );
      suggestedRestDays = recommendedRest.length;
    }

    final advice = programAdviceFor(
      verdicts: verdicts,
      circuit: circuit,
      globalVerdict: globalVerdict,
      hardestIndex: hardestIndex,
      suggestedTotalDays: suggestedDays + suggestedRestDays,
      suggestedWalkingDays: suggestedDays,
      suggestedRestDays: suggestedRestDays,
      currentTotalDays: stages.length + restAfterStageIndex.length,
      trainingWeeks: trainingWeeks,
      recommendedRest: recommendedRest,
      durationAdvised: advised,
      durationSearched: searched,
      fromProgram: fromProgram,
    );

    return FeasibilityAssessment(
      scale: scale,
      level: level,
      levelCeilingEnergyKm: levelCeiling,
      demonstratedFloorEnergyKm: floor,
      baseCapacityEnergyKm: base,
      dailyCapacityEnergyKm: capacity,
      conditions: conditions,
      stageVerdicts: verdicts,
      circuit: circuit,
      globalVerdict: globalVerdict,
      hardestStageIndex: hardestIndex,
      daysOverCapacity: daysOver,
      limitingFactor: limiting,
      recommendedTrainingWeeks: trainingWeeks,
      advice: advice,
      suggestedDays: suggestedDays,
      suggestedRestDays: suggestedRestDays,
      isDurationSearched: searched,
      isDurationAdvised: advised,
      fromProgram: fromProgram,
      restDaysPlanned: restAfterStageIndex.length,
      recommendedRestAfterStageIndex: recommendedRest,
      walkingDays: stages.length,
      longestConsecutiveDaysDone: longestConsecutiveDaysDone,
    );
  }

  /// Construit la sequence des charges JOURNALIERES : l'energie de chaque etape
  /// dans l'ordre de marche, plus un 0 apres chaque etape suivie d'un repos.
  ///
  /// Les jours de repos comptent comme CHARGE NULLE (#2-p) : c'est precisement
  /// ce qui fait chuter la monotonie, puisqu'ils creusent l'ecart-type.
  static List<double> dailyLoads({
    required List<double> stageEnergies,
    Set<int> restAfterStageIndex = const {},
  }) {
    final loads = <double>[];
    for (var i = 0; i < stageEnergies.length; i++) {
      loads.add(stageEnergies[i]);
      if (restAfterStageIndex.contains(i) && i < stageEnergies.length - 1) {
        loads.add(0);
      }
    }
    return loads;
  }

  /// Monotonie de Foster d'une serie de charges : moyenne ÷ ecart-type (#S15).
  ///
  /// ECART-TYPE DE POPULATION (diviseur n), pas d'echantillon : la serie n'est
  /// pas un tirage dans une population plus large, c'est la semaine ELLE-MEME.
  /// Le choix est robuste — sur les jeux de la campagne, l'estimateur
  /// d'echantillon donne 3,74 au lieu de 4,04, meme cote du seuil.
  ///
  /// `null` quand la monotonie DIVERGE : moins de deux jours, ou ecart-type nul
  /// (toutes les charges identiques). Une contrainte non calculable est
  /// DECLAREE non applicable, jamais remplacee par un chiffre (#10-e).
  static double? monotonyOf(List<double> loads) {
    if (loads.length < 2) return null;
    final mean = loads.reduce((a, b) => a + b) / loads.length;
    final variance =
        loads.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        loads.length;
    final sd = math.sqrt(variance);
    if (sd <= 0) return null;
    return mean / sd;
  }

  /// Monotonie RETENUE par C3 : celle de la PIRE fenetre de [monotonyWindowDays]
  /// jours, ou celle du trek entier s'il est plus court, avec les bornes de la
  /// fenetre retenue (1-based).
  ///
  /// Extraite pour une raison precise : le calcul du repos CONSEILLE
  /// ([recommendedRestAfterStageIndex]) doit mesurer EXACTEMENT ce que mesure
  /// C3, sinon le conseil viserait un autre chiffre que celui affiche.
  static ({double? monotony, int? startDay, int? endDay}) worstMonotonyWindow(
    List<double> loads,
  ) {
    if (loads.length <= monotonyWindowDays) {
      final m = monotonyOf(loads);
      if (m == null) return (monotony: null, startDay: null, endDay: null);
      return (monotony: m, startDay: 1, endDay: loads.length);
    }
    double? worst;
    int? start;
    int? end;
    for (var i = 0; i + monotonyWindowDays <= loads.length; i++) {
      final m = monotonyOf(loads.sublist(i, i + monotonyWindowDays));
      if (m == null) continue;
      if (worst == null || m > worst) {
        worst = m;
        start = i + 1;
        end = i + monotonyWindowDays;
      }
    }
    return (monotony: worst, startDay: start, endDay: end);
  }

  /// Index 0-based des etapes APRES lesquelles le PLANIFICATEUR pose ses repos
  /// quand il doit en repartir [restDays] sur [stageCount] etapes.
  ///
  /// MIROIR EXACT de `PlanningCalculator._computeRestPositions`, et la
  /// traduction d'une convention a l'autre est ecrite ICI, une seule fois : le
  /// planificateur raisonne en « repos AVANT l'etape i », le moteur en « repos
  /// APRES l'etape i-1 ». Les deux decrivent le meme jour de repos. Sans cette
  /// traduction commune, le programme genere porterait ses repos ailleurs que
  /// la ou le moteur les compte, et l'ecran afficherait deux chiffres qui se
  /// contredisent.
  ///
  /// Un repos AVANT la premiere etape ne repose de rien : il est ignore, comme
  /// le fait deja le moteur.
  static Set<int> restAfterStageIndexFor({
    required int stageCount,
    required int restDays,
  }) {
    final result = <int>{};
    if (restDays <= 0 || stageCount <= 1) return result;
    final interval = stageCount / (restDays + 1);
    for (var r = 0; r < restDays; r++) {
      final pos = ((r + 1) * interval).round().clamp(0, stageCount - 1);
      if (pos >= 1) result.add(pos - 1);
    }
    return result;
  }

  /// REPOS CONSEILLES : le plus PETIT nombre de jours de repos qui ramene la
  /// monotonie de la pire fenetre SOUS son seuil, et ou les poser.
  ///
  /// C'EST UN CONSEIL, PLUS UN VERDICT (GO-61). Depuis que S_circuit vaut C1
  /// seul, le repos ne condamne plus rien : il est calcule, affiche, et il sert
  /// a POSER LE PROGRAMME PAR DEFAUT. Le randonneur part alors d'un itineraire
  /// tenable et voit le chiffre du repos remonter s'il les retire, au lieu de
  /// partir d'un itineraire intenable qu'il devrait reparer sans savoir
  /// comment.
  ///
  /// COMMENT LE NOMBRE EST TROUVE, SANS RIEN INVENTER : on essaie 0, 1, 2 …
  /// jours de repos, places comme le planificateur les placerait, et on garde
  /// le PREMIER qui ramene la monotonie sous le seuil deja publie (#S15). Aucun
  /// nouveau seuil n'est cree ; le seul seuil du dispositif est celui qui vient
  /// de perdre le droit de decider, et qui garde celui de conseiller.
  ///
  /// Rend un ensemble VIDE quand aucun repos n'est necessaire, ou quand la
  /// contrainte n'est pas calculable : on ne conseille rien sur un chiffre qui
  /// n'existe pas.
  ///
  /// TROU CONNU ET DECLARE, plutot que corrige en douce. Des charges
  /// STRICTEMENT egales donnent un ecart-type nul : la monotonie diverge, la
  /// contrainte est declaree non applicable (#10-e) et aucun repos n'est donc
  /// conseille — alors que c'est mathematiquement le cas le plus monotone qui
  /// soit. Deux etapes reelles n'ont jamais exactement la meme energie, c'est
  /// donc un cas de laboratoire ; le combler demanderait de decider ce que vaut
  /// une division par zero, ce qui serait un chiffre invente.
  static Set<int> recommendedRestAfterStageIndex(List<double> stageEnergies) {
    final n = stageEnergies.length;
    if (n < 2) return const {};
    for (var restDays = 0; restDays < n; restDays++) {
      final rest = restAfterStageIndexFor(stageCount: n, restDays: restDays);
      // Un repos demande mais non placable (avant la premiere etape, ou apres
      // la derniere) ne compte pas : on passe au nombre suivant.
      if (restDays > 0 && rest.length < restDays) continue;
      final m = worstMonotonyWindow(
        dailyLoads(stageEnergies: stageEnergies, restAfterStageIndex: rest),
      ).monotony;
      if (m == null || m <= monotonyThreshold) return rest;
    }
    return const {};
  }
}
