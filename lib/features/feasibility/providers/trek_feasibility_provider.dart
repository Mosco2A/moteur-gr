import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import '../../trek/providers/gps_providers.dart';
import '../../trek/providers/stage_providers.dart';
import '../domain/feasibility_formula.dart';
import '../domain/hiker_profile.dart';
import '../domain/objective_profile.dart';
import '../domain/walk_test_result.dart';
import 'hiker_profile_provider.dart';
import 'walk_test_provider.dart';

/// UN SEUL MOTEUR DE VERDICT (campagne personas 21/09, MAJEUR-4).
///
/// Il n'existe plus qu'une source de verdict dans l'application :
/// [feasibilityAssessmentProvider] (formule V1 #100068, feu tricolore). Le
/// croisement par seuils qui vivait ici (`trekRequirementsProvider` +
/// `trekFeasibilityResultProvider` + `TrekFeasibilityCalculator`) rendait, pour
/// LE MEME randonneur et LE MEME trek, un verdict OPPOSE a celui affiche par
/// l'ecran Faisabilite sur 3 profils sur 6 : il a ete SUPPRIME. Tout ecran qui
/// a besoin d'un verdict lit desormais [feasibilityAssessmentProvider].

/// Rang de forme de dépannage (questionnaire) quand le test 6 min manque.
///
/// Lit le dernier resultat SharedPreferences du questionnaire (0-24) et le
/// projette sur 0..3. Absent -> 1 (dépannage prudent, ni haut ni bas).
final _fallbackFitnessRankProvider = FutureProvider<int>((ref) async {
  // On reste tolerant : toute absence -> rang median bas (1).
  final result = await ref.watch(walkTestResultProvider.future);
  if (result != null) return 0; // ignore (le test prime, gere ailleurs)
  return 1;
});

/// Profil OBJECTIF deduit (fiche + test 6 min + 5 randos).
final objectiveProfileProvider =
    FutureProvider<ObjectiveProfile>((ref) async {
  final pastHikes = await ref.watch(pastHikesProvider.future);
  final WalkTestResult? walkTest =
      await ref.watch(walkTestResultProvider.future);
  final fallbackRank = await ref.watch(_fallbackFitnessRankProvider.future);
  return ObjectiveProfile.from(
    pastHikes: pastHikes,
    walkTest: walkTest,
    fallbackFitnessRank: fallbackRank,
  );
});

/// Vrai si le randonneur a saisi assez de donnees objectives pour un verdict
/// fiable (au moins une rando passee OU le test 6 min fait). Sinon l'UI
/// propose de completer le profil (et le questionnaire reste en dépannage).
final hasObjectiveProfileProvider = FutureProvider<bool>((ref) async {
  final pastHikes = await ref.watch(pastHikesProvider.future);
  final walkTest = await ref.watch(walkTestResultProvider.future);
  final profile = await ref.watch(hikerProfileProvider.future);
  return pastHikes.isNotEmpty || walkTest != null || !profile.isEmpty;
});

// ===========================================================================
// FORMULE DE FAISABILITE V1 (LOT 3a) — decision Chris #100068.
// Croise l'effort km-effort de chaque etape (distance + D+/100) au plafond
// journalier deduit du profil -> verdict FEU TRICOLORE + conseils programme.
// ===========================================================================

/// Etapes du sentier actif dans le SENS DE MARCHE choisi, converties en
/// [StageEffort] (une par jour de marche de reference).
///
/// Reprend la meme logique de sens que [itineraryProvider] (le sens inverse
/// inverse l'ordre des etapes) pour rester coherent avec le programme (LOT 2).
final stageEffortsProvider = FutureProvider<List<StageEffort>>((ref) async {
  final stages = await ref.watch(stagesProvider.future);
  if (stages.isEmpty) return const [];

  final sorted = List<StageModel>.of(stages)
    ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

  // Sens de marche : identique a itineraryProvider (direction-aware).
  final directions = ref.watch(trailConfigProvider.select((c) => c.directions));
  final forward = directions.isNotEmpty ? directions.first : null;
  final selected = ref.watch(selectedDirectionProvider);
  final reversed = forward != null && selected != null && selected != forward;
  final ordered = reversed ? sorted.reversed.toList() : sorted;

  return [
    for (var i = 0; i < ordered.length; i++)
      StageEffort(
        index: i,
        name: ordered[i].name,
        distanceKm: ordered[i].distanceKm,
        elevationGainM: ordered[i].elevationGainM,
      ),
  ];
});

/// Niveau de randonneur deduit du profil objectif (fiche + test 6 min + randos),
/// corrige age + condition — entree de la formule de faisabilite.
final hikerLevelProvider = FutureProvider<HikerLevel>((ref) async {
  final ObjectiveProfile objective =
      await ref.watch(objectiveProfileProvider.future);
  final HikerProfile profile = await ref.watch(hikerProfileProvider.future);
  return FeasibilityFormula.deriveLevel(
    maxElevationGainPerDayDone: objective.maxElevationGainPerDayDone,
    maxDistancePerDayDone: objective.maxDistancePerDayDone,
    age: profile.age,
    // Le rang de forme vient du test 6 min (0..3), sinon fallback median (1).
    fitnessRank: objective.fitnessLevelRank,
  );
});

/// Evaluation complete de faisabilite (feu tricolore + conseils) — formule V1.
///
/// Null si aucune etape (pas de sentier charge) -> l'UI retombe sur le
/// questionnaire de dépannage, comme le verdict objectif.
final feasibilityAssessmentProvider =
    FutureProvider<FeasibilityAssessment?>((ref) async {
  final stages = await ref.watch(stageEffortsProvider.future);
  if (stages.isEmpty) return null;
  final level = await ref.watch(hikerLevelProvider.future);
  final profile = await ref.watch(hikerProfileProvider.future);
  return FeasibilityFormula.evaluate(
    stages: stages,
    level: level,
    age: profile.age,
  );
});
