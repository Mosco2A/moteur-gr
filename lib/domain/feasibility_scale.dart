/// Le bareme de la faisabilite : saison, seuils, echelle et
/// conditions du trek.
///
/// Bibliotheque de la formule de faisabilite (lot 645-06b), re-exportee par
/// `feasibility_formula.dart` : les appelants n'importent que cette racine.
library;

import 'dart:math' as math;

import 'feasibility_stages.dart';
import 'feasibility_types.dart';

/// Saisons de depart reconnues par le moteur — memes cles stables que
/// `Season` cote Sac (`winter`/`spring`/`summer`/`autumn`).
abstract class FeasibilitySeason {
  static const String winter = 'winter';
  static const String spring = 'spring';
  static const String summer = 'summer';
  static const String autumn = 'autumn';
}

/// Seuils du feu tricolore — CONSTANTES PARAMETRABLES (reglage median valide
/// par Chris #100068, INCHANGES en V2). score = energie / capacite du jour.
class FeasibilityThresholds {
  const FeasibilityThresholds({
    this.green = defaultGreen,
    this.orange = defaultOrange,
  });

  /// score <= green  -> VERT.
  static const double defaultGreen = 0.85;

  /// green < score <= orange -> ORANGE ; score > orange -> ROUGE.
  static const double defaultOrange = 1.10;

  /// Seuil haut du vert (median valide Chris).
  final double green;

  /// Seuil haut de l'orange (median valide Chris).
  final double orange;

  /// Reglage median par defaut.
  static const FeasibilityThresholds median = FeasibilityThresholds();

  /// Classe un score energie/capacite en verdict tricolore.
  FeasibilityVerdict verdictFor(double score) {
    if (score <= green) return FeasibilityVerdict.green;
    if (score <= orange) return FeasibilityVerdict.orange;
    return FeasibilityVerdict.red;
  }
}

/// BAREME du moteur : l'unite d'energie ET les plafonds qui en decoulent.
///
/// POURQUOI LES DEUX ENSEMBLE, ET JAMAIS SEPAREMENT. Un plafond n'a de sens que
/// dans l'unite qui l'a produit : melanger l'unite de 42 m avec les plafonds
/// derives a 100 m donnerait des verdicts faux sans lever aucune erreur. Les
/// deux voyagent donc dans le meme objet, et [v1] existe pour une seule raison
/// legitime : permettre a la campagne personas de RECALCULER la colonne
/// « AVANT » de chaque bascule avec le moteur reel, au lieu de la recopier a la
/// main depuis un tableau que personne ne pourrait verifier (#10-f).
class FeasibilityScale {
  const FeasibilityScale({
    required this.metersOfGainPerFlatKm,
    required this.referenceDailyDistanceKm,
    required this.referenceDailyGainM,
  });

  /// BAREME V2 EN VIGUEUR (#1-a, #2-f). 1 km de plat vaut 42 m de D+.
  ///
  /// Plafonds re-derives sur les MEMES reperes BP que la V1 :
  /// debutant 18 km + 300 m -> 25,14 · intermediaire 22 + 700 -> 38,67 ·
  /// confirme 27 + 1200 -> 55,57 · expert 30 + 1500 -> 65,71.
  static const FeasibilityScale v2 = FeasibilityScale(
    metersOfGainPerFlatKm: 42,
    referenceDailyDistanceKm: {
      HikerLevel.beginner: 18,
      HikerLevel.intermediate: 22,
      HikerLevel.confirmed: 27,
      HikerLevel.expert: 30,
    },
    referenceDailyGainM: {
      HikerLevel.beginner: 300,
      HikerLevel.intermediate: 700,
      HikerLevel.confirmed: 1200,
      HikerLevel.expert: 1500,
    },
  );

  /// BAREME HISTORIQUE V1 (#100068) — 100 m de D+ pour 1 km, plafonds
  /// 21 / 29 / 39 / 45. N'est PLUS le bareme de l'application : il ne sert qu'a
  /// reconstituer la colonne « AVANT » des bascules de la campagne personas.
  static const FeasibilityScale v1 = FeasibilityScale(
    metersOfGainPerFlatKm: 100,
    referenceDailyDistanceKm: {
      HikerLevel.beginner: 18,
      HikerLevel.intermediate: 22,
      HikerLevel.confirmed: 27,
      HikerLevel.expert: 30,
    },
    referenceDailyGainM: {
      HikerLevel.beginner: 300,
      HikerLevel.intermediate: 700,
      HikerLevel.confirmed: 1200,
      HikerLevel.expert: 1500,
    },
  );

  /// Metres de D+ equivalents a 1 km de plat (42 en V2, source Minetti 2002).
  final double metersOfGainPerFlatKm;

  /// Distance/jour de reference par niveau (repere BP), en km.
  final Map<HikerLevel, double> referenceDailyDistanceKm;

  /// D+/jour de reference par niveau (repere BP), en metres.
  final Map<HikerLevel, double> referenceDailyGainM;

  /// Energie (km-energie) d'une geometrie : distance + D+ / unite.
  double energyOf({required double distanceKm, required num elevationGainM}) =>
      distanceKm + elevationGainM / metersOfGainPerFlatKm;

  /// Energie (km-energie) d'une etape.
  double energyOfStage(StageEffort stage) => energyOf(
    distanceKm: stage.distanceKm,
    elevationGainM: stage.elevationGainM,
  );

  /// Part du D+ dans l'energie d'une etape, en km-energie.
  double elevationEnergyOf(StageEffort stage) =>
      stage.elevationGainM / metersOfGainPerFlatKm;

  /// Plafond journalier de BASE du niveau (km-energie), avant plancher demontre
  /// et avant conditions.
  double levelCeilingFor(HikerLevel level) =>
      referenceDailyDistanceKm[level]! +
      referenceDailyGainM[level]! / metersOfGainPerFlatKm;
}

/// CONDITIONS du trek qui rabotent la capacite journaliere (#2-h a #2-j).
///
/// Aucun coefficient invente : chaque facteur cite sa source, et l'absence de
/// source produit un facteur NEUTRE qui est DIT, pas un facteur devine.
class TrekConditions {
  const TrekConditions({this.maxAltitudeM, this.season});

  /// Rien de connu : altitude absente, saison inconnue. Tout est neutre, et
  /// l'ecran le declare (#2-h, #8-b).
  static const TrekConditions unknown = TrekConditions();

  /// Altitude MAXIMALE du trek (m), derivee de la trace GPX. `null` quand la
  /// trace ne porte pas d'altitude : le facteur vaut alors 1,00 ET ON LE DIT
  /// (#2-h) — on ne devine pas une altitude.
  final double? maxAltitudeM;

  /// Saison du DEPART (cles [FeasibilitySeason]). `null` = pas de date de
  /// depart posee.
  final String? season;

  /// k_altitude = 1 − 0,01 × max(0 ; A_max − 1500) ÷ 100 (#2-h).
  ///
  /// Source #S8-e (MOVE, *Eur Heart J Digit Health* 2026) : 1 % de capacite en
  /// moins par tranche de 100 m au-dessus de 1 500 m. Altitude absente -> 1,00.
  double get altitudeFactor {
    final a = maxAltitudeM;
    if (a == null) return 1.0;
    return 1 - 0.01 * math.max(0.0, a - 1500) / 100;
  }

  /// k_chaleur = 0,93 si le depart tombe en ETE, 1,00 sinon (#2-i).
  ///
  /// Source #S10-d (Linsell 2020, −7 % de capacite aerobie). AUCUNE source pour
  /// le printemps et l'automne : neutres, et on le dit.
  double get heatFactor => season == FeasibilitySeason.summer ? 0.93 : 1.0;

  /// Vrai si le depart tombe en HIVER (#2-j) : le verdict est DECLARE NON
  /// VALIDE, sans aucun coefficient de durcissement.
  bool get isWinterDeparture => season == FeasibilitySeason.winter;

  /// Pourquoi l'altitude n'a rien change, quand elle n'a rien change.
  NeutralReason? get altitudeNeutralReason {
    if (maxAltitudeM == null) return NeutralReason.missingData;
    if (altitudeFactor >= 1.0) return NeutralReason.belowThreshold;
    return null;
  }

  /// Pourquoi la saison n'a rien change, quand elle n'a rien change.
  NeutralReason? get seasonNeutralReason {
    if (season == null) return NeutralReason.missingData;
    if (season == FeasibilitySeason.summer) return null;
    if (season == FeasibilitySeason.winter) return null;
    // Printemps et automne : aucune source publiee (#2-i).
    return NeutralReason.noPublishedSource;
  }
}
