/// Repartit N etapes sur D jours en equilibrant la CHARGE, score de difficulte
/// par etape a l'appui — pas la seule distance.
library;

import '../../../core/models/stage_row.dart';
import '../../../core/models/stage_duration.dart';
import '../models/day_plan.dart';

/// Calculateur de planning : répartit N étapes sur D jours.
///
/// Algorithme greedy qui équilibre la charge entre les jours
/// en se basant sur un score de difficulté par étape
/// (distance + dénivelé positif / 100).
///
/// TACHE 634 — LE DECOUPAGE D'ETAPE EST RETIRE (DEM-260929-1327).
///
/// CE QUI A ETE RETIRE, ET POURQUOI. La tache 558 (25/09) avait ajoute ici un
/// mecanisme qui COUPAIT une etape en deux demi-journees quand le randonneur
/// poussait le curseur de duree : `maxDaysPerStage`, `splitStage`,
/// `_splitHeaviestFirst`, et une borne haute de curseur a deux journees par
/// etape. Christophe l'a refuse le 29/09, verbatim : « Decouper les etapes en
/// deux est une mauvaise idee... il n'y a pas de refuge et surtout JE N AI
/// JAMAIS DEMANDE CA ».
///
/// LES DEUX GRIEFS SONT FONDES, ET MESURES.
///  1. C'ETAIT DANGEREUX. Le point de coupe etait une INTERPOLATION LINEAIRE
///     entre le depart et l'arrivee de l'etape — pas un lieu releve, pas un
///     hebergement verifie. Sur le Mare a Mare comme sur le GR20, les etapes
///     sont calees sur les refuges. Couper une etape proposait donc au
///     randonneur de s'arreter la ou il n'y a ni refuge, ni eau, ni abri, et le
///     lot 558 le savait : il l'avait ecrit noir sur blanc dans ce qu'il
///     laissait ouvert (« le point de coupe n'est pas un lieu releve »).
///  2. PERSONNE NE L'AVAIT DEMANDE. Recherche faite en base avant de retirer :
///     AUCUNE decision de Christophe ne soutient le decoupage. Trois traces
///     disent le contraire, dont DEUX ANTERIEURES au lot 558 — #100549 du 26/09
///     10:02, verbatim « decoupe la journee 1 en 2 === comment on fait???? pas
///     une solution » ; #100649 du 26/09 17:51, verbatim « couper une journer
///     c est dormir ou? » ; #100812 du 29/09, le present retour. Le lot 558
///     avait lui-meme note que Christophe « ne l'a jamais vu a l'ecran : a lui
///     faire valider ». Il l'a vu, il a repondu non.
///
/// CE QUI RESTE. Le REGROUPEMENT (moins de jours que d'etapes) est intact : il
/// reunit des etapes existantes sur une journee, il n'invente aucun point
/// d'arret. Et le surplus de jours redevient ce qu'il a toujours du etre : du
/// REPOS.
///
/// CE QUE CE RETRAIT COUTE, ET IL FAUT LE DIRE. Le curseur de duree ne peut
/// plus alleger le verdict — parce que le verdict vaut C1, la pire journee et
/// elle seule (GO-61), et que le repos ne change rien a une journee de marche.
/// C'etait le probleme que le lot 558 cherchait a resoudre. La reponse honnete
/// n'est pas de couper l'etape : c'est de DIRE que cette etape-la depasse le
/// plafond du randonneur. L'ecran de faisabilite le dit deja
/// (`hardStageAlert`).
class PlanningCalculator {
  const PlanningCalculator._();

  /// Calcule le score de difficulté d'une étape (répartition greedy).
  ///
  /// Formule historique : distanceKm + elevationGainM / 100. Elle sert au
  /// REGROUPEMENT d'étapes, dont elle équilibre les paquets ; elle n'est PAS
  /// l'unité du verdict — c'est le score de REGROUPEMENT, rien d'autre.
  static double stageScore(StageModel stage) {
    return stage.distanceKm + stage.elevationGainM / 100.0;
  }

  /// Calcule la durée estimée en heures pour une étape.
  ///
  /// Source unique [stageDurationMinutes] : privilégie la durée RICHE du sentier
  /// ([StageModel.estimatedDurationMinutes]) quand elle est fournie, sinon
  /// applique la règle de marche Naismith (distance / 4 km/h + D+ / 400 m/h).
  static double estimatedHours(StageModel stage) =>
      stageDurationMinutes(stage) / 60.0;

  /// Répartit les [stages] sur [days] jours de manière équilibrée.
  ///
  /// - Si jours < étapes : distribution greedy qui REGROUPE des étapes
  ///   existantes, en minimisant l'écart de score entre les jours ;
  /// - Si jours >= étapes : une étape par jour, les jours restants deviennent
  ///   des jours de REPOS ;
  /// - Les étapes conservent leur ordre séquentiel (pas de mélange).
  ///
  /// AUCUNE ETAPE N'EST JAMAIS COUPEE (tache 634, DEM-260929-1327). Le
  /// parametre `maxRestDays` du lot 558, qui plafonnait le repos pour convertir
  /// le reste en decoupages, a disparu avec le decoupage : au-dela du nombre
  /// d'etapes, TOUT jour de plus est un jour de repos, sans plafond. Voir
  /// l'en-tete de la classe.
  static List<DayPlan> distribute(List<StageModel> stages, int days) {
    if (stages.isEmpty || days <= 0) return [];

    if (days < stages.length) {
      return _distributeGreedy(stages, days);
    }

    return _assemble([
      for (final stage in stages) [stage],
    ], days - stages.length);
  }

  /// Assemble les journees de marche et [restDays] jours de repos repartis.
  static List<DayPlan> _assemble(
    List<List<StageModel>> walkingDays,
    int restDays,
  ) {
    final result = <DayPlan>[];
    final safeRest = restDays < 0 ? 0 : restDays;
    final restPositions = _computeRestPositions(walkingDays.length, safeRest);

    DayPlan restDay(int dayNumber) => DayPlan(
      dayNumber: dayNumber,
      stages: const [],
      totalDistanceKm: 0,
      totalElevationGainM: 0,
      estimatedDurationHours: 0,
      isRestDay: true,
    );

    var dayNumber = 1;
    for (var i = 0; i < walkingDays.length; i++) {
      for (var r = 0; r < restPositions[i]; r++) {
        result.add(restDay(dayNumber));
        dayNumber++;
      }

      final group = walkingDays[i];
      result.add(
        DayPlan(
          dayNumber: dayNumber,
          stages: group,
          totalDistanceKm: group.fold<double>(
            0,
            (sum, s) => sum + s.distanceKm,
          ),
          totalElevationGainM: group.fold<int>(
            0,
            (sum, s) => sum + s.elevationGainM,
          ),
          estimatedDurationHours: group.fold<double>(
            0,
            (sum, s) => sum + estimatedHours(s),
          ),
          isRestDay: false,
        ),
      );
      dayNumber++;
    }

    final total = walkingDays.length + safeRest;
    while (result.length < total) {
      result.add(restDay(dayNumber));
      dayNumber++;
    }

    return result;
  }

  /// Calcule combien de jours de repos placer avant chaque étape.
  static List<int> _computeRestPositions(int stageCount, int restDays) {
    final positions = List.filled(stageCount, 0);
    if (restDays <= 0) return positions;

    final interval = stageCount / (restDays + 1);
    for (var r = 0; r < restDays; r++) {
      final pos = ((r + 1) * interval).round().clamp(0, stageCount - 1);
      positions[pos]++;
    }

    return positions;
  }

  /// Distribution greedy quand il y a plus d'étapes que de jours.
  ///
  /// Approche DP simplifiée : calcule les points de coupure optimaux
  /// pour répartir les étapes séquentiellement en [days] groupes,
  /// minimisant l'écart de score maximum entre groupes.
  static List<DayPlan> _distributeGreedy(List<StageModel> stages, int days) {
    final n = stages.length;
    final scores = stages.map((s) => stageScore(s)).toList();

    // Calculer les sommes de préfixes pour accès O(1)
    final prefix = List.filled(n + 1, 0.0);
    for (var i = 0; i < n; i++) {
      prefix[i + 1] = prefix[i] + scores[i];
    }
    final totalScore = prefix[n];
    final targetPerDay = totalScore / days;

    // Trouver les points de coupure greedy en visant la cible
    final cutPoints = <int>[]; // indices de début de chaque groupe
    cutPoints.add(0);

    var accumulated = 0.0;
    for (var i = 0; i < n && cutPoints.length < days; i++) {
      accumulated += scores[i];
      final remainingCuts = days - cutPoints.length;
      final remainingStages = n - i - 1;

      // Si le score accumulé dépasse la cible et qu'il reste
      // assez d'étapes pour les jours restants
      if (accumulated >= targetPerDay && remainingStages >= remainingCuts) {
        cutPoints.add(i + 1);
        accumulated = 0;
      }
    }

    // Construire les groupes à partir des points de coupure
    final groups = <List<StageModel>>[];
    for (var g = 0; g < cutPoints.length; g++) {
      final start = cutPoints[g];
      final end = g + 1 < cutPoints.length ? cutPoints[g + 1] : n;
      groups.add(stages.sublist(start, end));
    }

    // Construire les DayPlan
    return groups.asMap().entries.map((entry) {
      final stageList = entry.value;
      final totalDist = stageList.fold<double>(
        0,
        (sum, s) => sum + s.distanceKm,
      );
      final totalGain = stageList.fold<int>(
        0,
        (sum, s) => sum + s.elevationGainM,
      );
      final totalHours = stageList.fold<double>(
        0,
        (sum, s) => sum + estimatedHours(s),
      );

      return DayPlan(
        dayNumber: entry.key + 1,
        stages: stageList,
        totalDistanceKm: totalDist,
        totalElevationGainM: totalGain,
        estimatedDurationHours: totalHours,
        isRestDay: false,
      );
    }).toList();
  }
}
