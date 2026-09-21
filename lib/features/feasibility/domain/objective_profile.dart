import 'past_hike.dart';
import 'walk_test_norms.dart';
import 'walk_test_result.dart';

/// Profil OBJECTIF du randonneur : ce qu'il a DEJA fait, chiffre.
///
/// Deduit de la fiche d'info, du test 6 minutes et des 5 dernieres randos. Il
/// alimente l'UNIQUE moteur de verdict ([FeasibilityFormula], decision Chris
/// #100068) via `hikerLevelProvider` : maxima deja realises + rang de forme
/// donnent le NIVEAU, le niveau donne le plafond journalier, le plafond donne
/// le feu tricolore.
///
/// Un SECOND moteur de verdict (croisement par seuils 1.3/1.8) a vecu ici
/// jusqu'a la campagne personas du 21/09 : il rendait un verdict OPPOSE a celui
/// de l'ecran Faisabilite pour 3 profils sur 6. Il a ete SUPPRIME, pas corrige
/// — un seul moteur fait foi dans toute l'application.
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
