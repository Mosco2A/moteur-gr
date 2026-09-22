import 'feasibility_formula.dart';
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
    required this.maxDailyEnergyKmDone,
    required this.habitualDailyEnergyKm,
    required this.fitnessLevelRank,
    required this.hasWalkTest,
  });

  /// D+ max/jour deja realise (m), deduit des 5 randos.
  final double maxElevationGainPerDayDone;

  /// Distance max/jour deja realisee (km), deduite des 5 randos.
  final double maxDistancePerDayDone;

  /// Plus longue rando en jours consecutifs deja faite.
  final int maxConsecutiveDaysDone;

  /// E_max_realise (#2-g) : la MEILLEURE journee reellement tenue, en
  /// km-energie, sur les 5 dernieres randos. 0 si aucune rando saisie.
  ///
  /// POURQUOI UN MAXIMUM PAR RANDO, ET NON LE CROISEMENT DES DEUX MAXIMA. Les
  /// maxima de distance et de D+ ci-dessus sont pris INDEPENDAMMENT : ils
  /// peuvent venir de deux randos differentes, et les additionner fabriquerait
  /// une journee que personne n'a faite. L'energie maximale, elle, est calculee
  /// rando par rando puis maximisee — elle correspond donc a une journee qui a
  /// vraiment eu lieu.
  ///
  /// CE QUE CE CHIFFRE INTERDIT AU MOTEUR : dire a quelqu'un qu'il ne peut pas
  /// faire ce qu'il a demontre faire. C'est une contrainte de coherence, pas un
  /// coefficient — aucune source n'est requise pour l'etablir.
  final double maxDailyEnergyKmDone;

  /// Charge journaliere HABITUELLE (km-energie) : moyenne des journees des
  /// randos saisies. Alimente C4, l'ecart a l'habitude (#2-q) — AFFICHE, JAMAIS
  /// DECISIF. `null` si aucune rando saisie.
  final double? habitualDailyEnergyKm;

  /// Rang de forme 0..3 (test 6 min si fait, sinon fallback questionnaire).
  final int fitnessLevelRank;

  /// Vrai si le test 6 min a ete realise (sinon niveau = fallback).
  final bool hasWalkTest;

  /// Construit le profil objectif a partir des donnees brutes.
  ///
  /// [fallbackFitnessRank] : rang de forme de dépannage (questionnaire) quand
  /// le test 6 min n'a pas ete fait. Les randos donnent les maxima deja faits.
  /// [scale] : bareme d'energie applique (V2 en production).
  factory ObjectiveProfile.from({
    required List<PastHike> pastHikes,
    required WalkTestResult? walkTest,
    int fallbackFitnessRank = 1,
    FeasibilityScale scale = FeasibilityScale.v2,
  }) {
    double maxGain = 0;
    double maxDist = 0;
    int maxDays = 0;
    double maxEnergy = 0;
    double energySum = 0;
    var energyCount = 0;
    for (final h in pastHikes) {
      if (h.avgElevationGainPerDay > maxGain) {
        maxGain = h.avgElevationGainPerDay;
      }
      if (h.avgDistancePerDayKm > maxDist) maxDist = h.avgDistancePerDayKm;
      if (h.days > maxDays) maxDays = h.days;
      final energy = scale.energyOf(
        distanceKm: h.avgDistancePerDayKm,
        elevationGainM: h.avgElevationGainPerDay,
      );
      if (!energy.isFinite) continue;
      if (energy > maxEnergy) maxEnergy = energy;
      energySum += energy;
      energyCount++;
    }
    final hasTest = walkTest != null;
    final rank =
        hasTest ? WalkTestLevel.rank(walkTest.level) : fallbackFitnessRank;
    return ObjectiveProfile(
      maxElevationGainPerDayDone: maxGain,
      maxDistancePerDayDone: maxDist,
      maxConsecutiveDaysDone: maxDays,
      maxDailyEnergyKmDone: maxEnergy,
      habitualDailyEnergyKm:
          energyCount > 0 ? energySum / energyCount : null,
      fitnessLevelRank: rank,
      hasWalkTest: hasTest,
    );
  }
}
