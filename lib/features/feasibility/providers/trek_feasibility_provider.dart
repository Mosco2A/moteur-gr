import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trek/domain/models/itinerary_day.dart';
import '../../trek/providers/itinerary_providers.dart';
import '../../trek/providers/stage_providers.dart';
import '../domain/trek_feasibility_calculator.dart';
import '../domain/walk_test_result.dart';
import 'hiker_profile_provider.dart';
import 'walk_test_provider.dart';

/// Exigences chiffrees du trek actif, derivees des donnees reelles.
///
/// Reutilise l'itineraire calcule ([itineraryProvider], via
/// `ItineraryCalculator`) : la journee la plus dure donne le D+/jour et la
/// distance/jour maximaux ; le nombre de jours = endurance multi-jours exigee.
/// Les notes FFRando (technicite/risque/effort) proviennent du modele sentier
/// (non cablees ici tant que la donnee sentier ne les fournit pas -> null).
final trekRequirementsProvider = FutureProvider<TrekRequirements?>((ref) async {
  final stages = await ref.watch(stagesProvider.future);
  if (stages.isEmpty) return null;

  final List<ItineraryDay> days = await ref.watch(itineraryProvider.future);
  if (days.isEmpty) return null;

  double maxGainPerDay = 0;
  double maxDistPerDay = 0;
  for (final d in days) {
    if (d.totalElevation > maxGainPerDay) {
      maxGainPerDay = d.totalElevation.toDouble();
    }
    if (d.totalDistance > maxDistPerDay) maxDistPerDay = d.totalDistance;
  }

  // Effort IBP : derive du barème itineraire si dispo (approche prudente :
  // on laisse null si non calcule cote sentier, la garde reste sur D+/km/jours).
  return TrekRequirements(
    maxElevationGainPerDay: maxGainPerDay,
    maxDistancePerDayKm: maxDistPerDay,
    totalDays: days.length,
  );
});

/// Rang de forme de dépannage (questionnaire) quand le test 6 min manque.
///
/// Lit le dernier resultat SharedPreferences du questionnaire (0-24) et le
/// projette sur 0..3. Absent -> 1 (dépannage prudent, ni haut ni bas).
final _fallbackFitnessRankProvider = FutureProvider<int>((ref) async {
  // Le questionnaire persiste son resultat via feasibility_result (prefs).
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

/// Verdict de faisabilite profil x trek (croisement par seuils).
///
/// Null si les exigences du trek ne sont pas disponibles (pas d'etapes) ->
/// l'UI retombe alors sur le questionnaire de dépannage.
final trekFeasibilityResultProvider =
    FutureProvider<TrekFeasibilityResult?>((ref) async {
  final trek = await ref.watch(trekRequirementsProvider.future);
  if (trek == null) return null;
  final profile = await ref.watch(objectiveProfileProvider.future);
  return TrekFeasibilityCalculator.evaluate(profile: profile, trek: trek);
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
