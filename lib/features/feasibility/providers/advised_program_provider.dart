/// LE PROGRAMME CONSEILLE — CABLAGE DE L'INVARIANTE DU LOT R (tache 569, R1).
///
/// DECISION DE CHRIS DU 26/09, VERBATIM : « OK mais le curseur est celui
/// conseille et il n'est jamais en rouge quand il est conseille en orange max ».
///
/// CE QUE CE FICHIER BRANCHE. [ProgramPlanSearch.firstNonRed] essaie chaque
/// valeur atteignable du curseur, construit le vrai programme avec le moteur de
/// repartition de l'ecran et le colore avec le moteur de verdict de l'ecran. Le
/// resultat part vers deux endroits, et c'est tout l'interet :
///   * [feasibilityAssessmentProvider], qui n'a donc plus a deviner un nombre de
///     jours — il porte celui qui a ETE ESSAYE ;
///   * [selectedDurationProvider], pour que le curseur S'OUVRE sur cette valeur
///     (R1-a) au lieu d'ouvrir sur la duree du topo.
///
/// POURQUOI LE CONSEIL EST CONDITIONNE A UN PROFIL COMPLET. Le conseil est une
/// SORTIE du moteur de verdict : il n'existe que la ou le verdict existe. Tant
/// qu'un critere obligatoire manque ([feasibilityCriteriaProvider], regle D1 du
/// correctif N2), le niveau retombe mecaniquement sur « debutant » quel que soit
/// le randonneur, et conseiller une duree calculee sur ce vide reviendrait a
/// poser un chiffre sur rien. On ne conseille alors AUCUNE duree, et le sentier
/// garde son decoupage de reference.
///
/// IMPORT CROISE ASSUME. `planning_provider.dart` lit ce fichier (pour le
/// curseur) et ce fichier lit `planning_provider.dart` (pour les bornes du
/// curseur). Dart l'autorise et rien ne s'initialise au chargement : un provider
/// n'est qu'un objet, construit a la demande. L'alternative — recopier les
/// bornes du curseur ici — creerait deux definitions de la meme plage, donc le
/// genre d'ecart exact que ce lot corrige.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import '../../planning/providers/planning_provider.dart';
import '../../trail/providers/stages_provider.dart';
import '../../trek/providers/gps_providers.dart';
import '../domain/feasibility_formula.dart';
import '../domain/program_plan_search.dart';
import 'trek_feasibility_provider.dart';

/// Les etapes du sentier courant DANS LE SENS DE MARCHE choisi, telles que le
/// Programme les repartira.
///
/// Meme tri et meme regle de sens que [plannedDaysProvider] : la recherche doit
/// juger la sequence reelle, sinon elle jugerait un autre itineraire.
final _advisedSearchStagesProvider =
    Provider<List<StageModel>>((ref) {
  final trailId = ref.watch(trailIdProvider);
  final sorted = ref.watch(stagesProvider(trailId)).maybeWhen(
        data: (list) => List<StageModel>.of(list)
          ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber)),
        orElse: () => const <StageModel>[],
      );
  if (sorted.isEmpty) return const [];
  final directions = ref.watch(trailConfigProvider.select((c) => c.directions));
  final forward = directions.isNotEmpty ? directions.first : null;
  final selected = ref.watch(selectedDirectionProvider);
  final reversed = forward != null && selected != null && selected != forward;
  return reversed ? sorted.reversed.toList() : sorted;
});

/// LE PROGRAMME CONSEILLE, trouve par essai reel.
///
/// `null` quand aucune recherche n'est possible (etapes pas chargees, profil
/// incomplet) : le moteur retombe alors sur son estimation de lissage et
/// l'application ne pretend rien avoir verifie.
///
/// [SuggestedProgram] non nul : une duree est conseillee, et son verdict est
/// vert ou orange. Aucun moyen de rendre cette valeur rouge : elle a ete
/// colorée avant d'etre retenue.
final advisedSuggestedProgramProvider =
    FutureProvider<SuggestedProgram?>((ref) async {
  final stages = ref.watch(_advisedSearchStagesProvider);
  if (stages.isEmpty) return null;

  // Le conseil n'existe que la ou le verdict existe (regle D1).
  final criteria = await ref.watch(feasibilityCriteriaProvider.future);
  if (!criteria.isComplete) return null;

  final trailId = ref.watch(trailIdProvider);
  final bounds = ref.watch(durationBoundsProvider(trailId));
  final level = await ref.watch(hikerLevelProvider.future);
  final objective = await ref.watch(objectiveProfileProvider.future);
  final conditions = await ref.watch(trekConditionsProvider.future);

  return ProgramPlanSearch.firstNonRed(
    stages: stages,
    level: level,
    bounds: bounds,
    demonstratedFloorEnergyKm: objective.maxDailyEnergyKmDone,
    habitualDailyEnergyKm: objective.habitualDailyEnergyKm,
    longestConsecutiveDaysDone: objective.maxConsecutiveDaysDone,
    conditions: conditions,
  );
});

/// LE CONSEIL DE DUREE tel que le moteur de verdict le consomme.
///
/// Trois valeurs, trois sens differents, et l'ecran doit pouvoir les distinguer :
///   * `null` — AUCUNE RECHERCHE n'a eu lieu (profil incomplet, etapes absentes).
///     L'absence de recherche n'est pas une preuve d'impossibilite : l'ecran ne
///     doit surtout pas annoncer que rien ne marche ;
///   * [ProgramDurationAdvice.impossible] — la recherche a essaye TOUTES les
///     valeurs du curseur et aucune ne fait mieux que rouge. L'application ne
///     conseille alors aucune duree et le dit franchement ;
///   * un conseil viable — ses trois nombres (marche, repos, total).
final advisedProgramProvider =
    FutureProvider<ProgramDurationAdvice?>((ref) async {
  final stages = ref.watch(_advisedSearchStagesProvider);
  if (stages.isEmpty) return null;
  final criteria = await ref.watch(feasibilityCriteriaProvider.future);
  if (!criteria.isComplete) return null;
  final found = await ref.watch(advisedSuggestedProgramProvider.future);
  return found?.toAdvice() ?? ProgramDurationAdvice.impossible;
});

/// LE TOTAL DE JOURS SUR LEQUEL LE CURSEUR S'OUVRE (tache 569, R1-a).
///
/// `null` quand aucune duree n'est conseillee — le sentier garde alors son
/// decoupage de reference, repos conseilles compris
/// ([defaultDurationWithRestProvider]).
final advisedTotalDaysProvider = FutureProvider<int?>((ref) async {
  final found = await ref.watch(advisedSuggestedProgramProvider.future);
  return found?.totalDays;
});
