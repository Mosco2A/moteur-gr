/// LE DECOUPAGE SUR LEQUEL LE VERDICT PORTE (lot A, tache 551 — deplace ici par
/// la tache 569).
///
/// POURQUOI CE FICHIER EXISTE, ET POURQUOI IL EST DANS LE DOMAINE. Jusqu'a la
/// tache 569, la conversion « programme du randonneur -> charges journalieres »
/// vivait dans `trek_feasibility_provider.dart`, donc derriere Riverpod. Le lot R
/// a besoin de la MEME conversion hors de tout provider : pour garantir que la
/// duree CONSEILLEE n'est jamais rouge, il faut construire le programme a chaque
/// valeur du curseur ([ProgramPlanSearch]) et le passer au moteur de verdict. Si
/// cette conversion existait en deux exemplaires — un pour l'ecran, un pour le
/// conseil — le conseil finirait par porter sur un decoupage different de celui
/// affiche : c'est EXACTEMENT le defaut que le lot R corrige. Elle est donc
/// ecrite ICI, une seule fois, et les deux chemins l'appellent.
library;

import '../../../core/models/stage.dart';
import '../../planning/domain/planning_calculator.dart';
import '../../planning/models/day_plan.dart';
import '../../planning/models/planned_day.dart';
import 'feasibility_formula.dart';

/// Le decoupage REEL evalue : une charge par jour de marche + les repos.
class FeasibilityProgram {
  const FeasibilityProgram({
    required this.dayEfforts,
    required this.restAfterDayIndex,
    required this.stageCount,
    required this.fromProgram,
  });

  /// Aucun decoupage evaluable (ni programme, ni etape brute).
  static const empty = FeasibilityProgram(
    dayEfforts: [],
    restAfterDayIndex: {},
    stageCount: 0,
    fromProgram: false,
  );

  /// Une entree par JOUR DE MARCHE, dans l'ordre de marche. Les etapes d'un
  /// jour regroupe y sont deja sommees (distance, D+, D−).
  final List<StageEffort> dayEfforts;

  /// Index 0-based des JOURS DE MARCHE apres lesquels un repos est pose.
  ///
  /// Exprime en JOURS, et non en etapes : c'est la sequence des charges
  /// journalieres que la monotonie de Foster consomme (#2-p), et un jour
  /// regroupe n'y compte que pour une charge.
  final Set<int> restAfterDayIndex;

  /// Nombre d'etapes DISTINCTES portees par ce decoupage.
  ///
  /// TACHE 558 : une etape PEUT se couper en deux demi-journees, donc elle peut
  /// apparaitre sur deux jours de marche — elle ne compte ici qu'une fois. Le
  /// plafond du conseil n'est plus ce nombre mais [maxWalkingDays].
  final int stageCount;

  /// PLAFOND du nombre de jours de marche REELLEMENT atteignable (tache 558).
  int get maxWalkingDays => PlanningCalculator.maxWalkingDaysFor(stageCount);

  /// Vrai si la source est le PROGRAMME du randonneur, faux si c'est le repli
  /// sur les etapes brutes du sentier.
  ///
  /// CE DRAPEAU N'EST PAS DECORATIF (tache 569, R2). Les conseils qui NUMEROTENT
  /// des journees — « pose un repos apres la journee 3 » — ne designent pas la
  /// meme chose selon sa valeur : sur un programme choisi, la journee 3 est
  /// celle du randonneur ; sur le repli, c'est la troisieme ligne du topo, que
  /// personne n'a retenue. L'ecran DOIT donc pouvoir dire laquelle des deux il
  /// numerote, et ne jamais ecrire « au lieu de N » quand rien n'a ete choisi.
  final bool fromProgram;

  /// Nombre de jours de MARCHE du decoupage.
  int get walkingDays => dayEfforts.length;

  /// Nombre de jours de REPOS du decoupage.
  int get restDays => restAfterDayIndex.length;

  /// Nombre TOTAL de jours (marche + repos) — L'UNITE DU CURSEUR.
  int get totalDays => walkingDays + restDays;

  /// Vrai quand il n'y a rien a evaluer (aucun jour de marche).
  bool get isEmpty => dayEfforts.isEmpty;

  /// Construit le decoupage depuis le PROGRAMME editable du randonneur.
  factory FeasibilityProgram.fromPlannedDays(List<PlannedDay> days) =>
      FeasibilityProgram._fromDays(
        [
          for (final d in days)
            (stages: d.stages, isRestDay: d.isRestDay),
        ],
        fromProgram: true,
      );

  /// Construit le decoupage depuis une repartition CALCULEE
  /// ([PlanningCalculator.distribute]) — le chemin que suit la recherche du
  /// conseil, pour qu'elle juge exactement ce que l'ecran affichera.
  factory FeasibilityProgram.fromDayPlans(List<DayPlan> plans) =>
      FeasibilityProgram._fromDays(
        [
          for (final p in plans)
            (stages: p.stages, isRestDay: p.isRestDay),
        ],
        fromProgram: true,
      );

  /// Construit le decoupage depuis les etapes BRUTES du sentier (repli : une
  /// etape par jour, c'est le decoupage de REFERENCE du topo).
  factory FeasibilityProgram.fromRawStages(
    List<StageEffort> stages, {
    Set<int> restAfterStageIndex = const {},
  }) =>
      FeasibilityProgram(
        dayEfforts: stages,
        restAfterDayIndex: restAfterStageIndex,
        stageCount: stages.length,
        fromProgram: false,
      );

  /// LA conversion, ecrite une seule fois.
  ///
  /// Un jour de repos est enregistre APRES le dernier jour de MARCHE qui le
  /// precede ; un repos pose avant la premiere journee ne repose de rien et est
  /// ignore, comme le fait deja le moteur.
  static FeasibilityProgram _fromDays(
    List<({List<StageModel> stages, bool isRestDay})> days, {
    required bool fromProgram,
  }) {
    final efforts = <StageEffort>[];
    final restAfterDay = <int>{};
    final stageNumbers = <int>{};
    for (final day in days) {
      if (day.isRestDay || day.stages.isEmpty) {
        if (efforts.isNotEmpty) restAfterDay.add(efforts.length - 1);
        continue;
      }
      stageNumbers.addAll(day.stages.map((s) => s.stageNumber));
      efforts.add(StageEffort(
        index: efforts.length,
        // Le nom de la JOURNEE : celui de son etape, ou les deux noms quand
        // elle en regroupe deux. C'est ce que le randonneur marche ce jour-la.
        name: day.stages.map((s) => s.name).join(' + '),
        distanceKm: day.stages.fold<double>(0, (s, e) => s + e.distanceKm),
        elevationGainM: day.stages.fold<int>(0, (s, e) => s + e.elevationGainM),
        // Le D− n'entre PAS dans le score (#1-d) : il classe les journees de
        // l'alerte descente du dispositif poids (#4-l).
        elevationLossM: day.stages.fold<int>(0, (s, e) => s + e.elevationLossM),
      ));
    }
    if (efforts.isEmpty) return FeasibilityProgram.empty;
    return FeasibilityProgram(
      dayEfforts: efforts,
      restAfterDayIndex: restAfterDay,
      stageCount: stageNumbers.length,
      fromProgram: fromProgram,
    );
  }
}
