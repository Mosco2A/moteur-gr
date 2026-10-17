/// Repartit N etapes sur D jours en equilibrant la CHARGE, score de difficulte
/// par etape a l'appui — pas la seule distance.
library;

import '../../../core/models/stage_duration.dart';
import '../../../core/models/stage_row.dart';
import '../../../domain/repartition_equilibree.dart';
import '../models/day_plan.dart';

/// Calculateur de planning : répartit N étapes sur D jours.
///
/// Il equilibre la charge entre les jours sur un score de difficulte par etape
/// (distance + denivele positif / 100), par [RepartitionEquilibree] : autant de
/// journees que demande, et la journee la plus chargee aussi legere que
/// possible. L'algorithme « greedy » qui vivait ici rendait MOINS de journees
/// qu'on en demandait (tache 848, cf. [_regrouperEnJournees]).
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

  /// Calcule le score de difficulté d'une étape, pour le REGROUPEMENT.
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
  /// applique LE modèle de temps de marche du dépôt ([walkingSeconds]) :
  /// 4 km/h à plat, 400 m de montée à l'heure, et depuis la tâche 839 la
  /// descente PAYÉE à 1,67 s par mètre.
  static double estimatedHours(StageModel stage) =>
      stageDurationMinutes(stage) / 60.0;

  /// Répartit les [stages] sur [days] jours de manière équilibrée.
  ///
  /// - Si jours < étapes : REGROUPEMENT d'etapes existantes, en rendant
  ///   EXACTEMENT [days] journees (tache 848) ;
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
      return _regrouperEnJournees(stages, days);
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

  /// Regroupement quand il y a plus d'étapes que de jours.
  ///
  /// ANCIEN NOM : `_distributeGreedy`. Il ne reste plus rien de « greedy » dans
  /// ce calcul, et garder le mot aurait decrit l'algorithme qui vient d'etre
  /// retire.
  ///
  /// TACHE 848 — IL RENDAIT MOINS DE JOURNEES QU'ON EN DEMANDAIT, ET C'EST
  /// MESURE. Le calcul vivant ici accumulait le score et coupait des qu'il
  /// franchissait la cible. Une etape entiere fait souvent DEPASSER cette
  /// cible : les premieres journees prenaient donc plus que leur part, les
  /// dernieres n'atteignaient plus la leur, et la coupe s'arretait. Sur les
  /// seize etapes du GR20, SEPT jours demandes rendaient SIX journees, neuf en
  /// rendaient six, dix en rendaient sept, douze en rendaient huit (mesure de
  /// la tache 846, #102125). Ce n'est pas un arrondi depuis que le nombre de
  /// jours est un CHOIX DU CLIENT (Christophe, 17/10 : « le client le fait dans
  /// le nombre de jours qu'il veut ») : rendre huit journees pour douze
  /// demandees, c'est corriger son choix en silence.
  ///
  /// LE COMPTE EST DESORMAIS GARANTI PAR [RepartitionEquilibree], partagee avec
  /// le decoupage sur les nuits relevees — UN seul algorithme de repartition
  /// dans le depot, comme il n'y a qu'un seul modele de temps de marche depuis
  /// la tache 839. Le score de regroupement ne change pas : c'est toujours
  /// [stageScore].
  static List<DayPlan> _regrouperEnJournees(List<StageModel> stages, int days) {
    final n = stages.length;
    final scores = stages.map(stageScore).toList(growable: false);
    final cutPoints = RepartitionEquilibree.coupes(scores, days);

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
