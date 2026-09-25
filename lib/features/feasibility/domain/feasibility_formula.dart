/// MOTEUR DE FAISABILITE V2 (StepWays) — spec finale
/// `data/apport_stepways/SPEC_FINALE_faisabilite_et_poids.md` (#SW-FINAL),
/// qui PRIME sur tout autre document. Arbitrages tranches par Chris le
/// 22/09/2026 (#100303 a #100320), synthese #100332.
///
/// Moteur PUR (zero dependance Flutter), entierement testable a l'unite. Il
/// croise l'ENERGIE de chaque etape a la CAPACITE journaliere du randonneur et
/// rend un verdict FEU TRICOLORE par etape, un SCORE DE CIRCUIT, et des
/// conseils de programme.
///
/// CE QUI CHANGE PAR RAPPORT A LA V1, ET POURQUOI.
///
///  1. L'UNITE (#1-a, #2-a). La V1 convertissait 100 m de D+ en 1 km de plat.
///     La mesure de Minetti 2002 (cout metabolique de la marche en pente, en
///     joules par kilo et par metre) donne 42 m, contre-verifiee par deux voies
///     convergentes (39-42). Les plafonds sont RE-DERIVES sur les memes reperes
///     BP, ils ne sont pas re-choisis : 25,1 / 38,7 / 55,6 / 65,7 au lieu de
///     21 / 29 / 39 / 45.
///
///  2. AUCUN TERME DE MASSE (#1-b, #3-d). Ni le sac, ni le poids du corps
///     n'entrent dans le score. Ce n'est pas un trou, c'est une propriete
///     assumee : le cout d'une etape vaut pente x distance x masse, la capacite
///     est deduite d'une performance geometrique passee du MEME corps, la masse
///     se simplifie exactement. Le meme homme a 65 ou 95 kg obtient le meme
///     verdict au chiffre pres. Le poids a sa place ailleurs, dans le dispositif
///     de charge ([BodyWeightReference]).
///
///  3. LE PLANCHER DEMONTRE (#2-g). On ne dit jamais a quelqu'un qu'il ne peut
///     pas faire ce qu'il a deja demontre faire : la capacite de base est le
///     MAXIMUM entre le plafond de son niveau et sa meilleure journee reelle.
///     L'ORDRE COMPTE (#2-e) : le plancher s'applique a la BASE, les conditions
///     ENSUITE — l'ordre inverse effacerait silencieusement l'altitude et la
///     chaleur pour tout randonneur dont le maximum demontre depasse son cran.
///
///  4. LES CONDITIONS (#2-h, #2-i, #2-j). Altitude (MOVE 2026) et chaleur
///     (Linsell 2020) multiplient la capacite. Printemps et automne : AUCUNE
///     source, donc neutres, et on le dit. Hiver : AUCUN coefficient, le verdict
///     est DECLARE NON VALIDE (les cotations du Club Alpin Suisse ne valent que
///     par bon temps et terrain sec).
///
///  5. LE SCORE DE CIRCUIT (#2-m a #2-t). On ne pondere rien : chaque contrainte
///     est normalisee par son propre seuil publie — elle vaut 1,0 a sa limite —
///     et le score est la contrainte qui mord. Aucun poids a choisir.
///
/// CE QUI N'EST PAS DANS LE MOTEUR, ET POURQUOI (trous declares, non combles) :
/// pas de terme de descente (#1-d, #M05 : aucun coefficient energetique publie —
/// l'alerte est portee par le dispositif poids) ; pas de terme de terrain
/// (#M02/#M03 : la conversion cotation -> facteur n'est pas publiee) ; pas de
/// coefficient de fatigue cumulative par jour (#M06).
library;

import 'dart:math' as math;

/// Niveau de randonneur deduit du profil (ordre croissant de capacite).
///
/// Cles i18n stables (`t.feasibility.formula.levels.*`). Les reperes BP D+/jour
/// qui bornent chaque niveau : <300 debutant, 300-700 intermediaire,
/// 700-1200 confirme, >1200 expert.
enum HikerLevel {
  beginner,
  intermediate,
  confirmed,
  expert,
}

/// Verdict FEU TRICOLORE d'une etape ou du circuit (cles i18n stables
/// `t.feasibility.formula.verdicts.*`).
enum FeasibilityVerdict {
  /// Vert : score <= [FeasibilityThresholds.green]. Faisable confortablement.
  green,

  /// Orange : entre les deux seuils. Faisable AVEC entrainement.
  orange,

  /// Rouge : score > [FeasibilityThresholds.orange]. Au-dessus des capacites.
  red,
}

/// Facteur DOMINANT nomme d'une etape ou du verdict global (#2-l) — cle i18n
/// `t.feasibility.formula.limitingFactors.*`.
///
/// Les quatre premiers sont les quatre termes de la decomposition EXACTE du
/// score d'etape (voir [StageVerdict.dominantFactor]) ; [chaining] reste le
/// facteur du verdict global quand plusieurs journees consecutives passent
/// au-dessus.
enum LimitingFactor {
  /// La distance de l'etape est le premier contributeur au score.
  distance,

  /// Le denivele positif est le premier contributeur au score.
  elevation,

  /// L'altitude rabote la capacite du jour plus que tout le reste.
  altitude,

  /// La chaleur de la saison de depart rabote la capacite du jour.
  heat,

  /// L'enchainement (plusieurs jours consecutifs au-dessus du plafond).
  chaining,

  /// Aucun facteur limitant (verdict vert global).
  none,
}

/// Les quatre contraintes du score de circuit (#2-n a #2-q), cles i18n
/// `t.feasibility.formula.circuit.constraints.*`.
enum CircuitConstraint {
  /// C1 — la pire etape.
  worstStage,

  /// C2 — la charge moyenne du circuit.
  averageLoad,

  /// C3 — le repos (monotonie de Foster). AFFICHE ET CONSEILLE, JAMAIS DECISIF
  /// depuis GO-61 — voir [CircuitScore.score].
  rest,

  /// C4 — l'ecart a l'habitude. AFFICHE, JAMAIS DECISIF (#2-q).
  habitGap,
}

/// Raison pour laquelle une dimension n'entre PAS dans le verdict (#8-b).
///
/// Une dimension neutre FAUTE DE DONNEE n'a pas le meme statut qu'une dimension
/// neutre FAUTE DE SOURCE : l'ecran doit pouvoir dire laquelle des deux.
enum NeutralReason {
  /// La donnee manque (ex. altitude absente de la trace).
  missingData,

  /// Aucune source publiee ne permet de chiffrer (ex. printemps, automne).
  noPublishedSource,

  /// La donnee est la, mais le seuil publie n'est pas atteint (ex. un trek qui
  /// culmine sous 1 500 m).
  belowThreshold,

  /// Par construction du modele (ex. la masse se simplifie exactement, #3-e).
  byDesign,
}

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
  double get heatFactor =>
      season == FeasibilitySeason.summer ? 0.93 : 1.0;

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

/// Geometrie d'une etape — DONNEE BRUTE, sans unite d'energie.
///
/// L'energie n'est PAS un attribut de l'etape : elle depend du bareme
/// ([FeasibilityScale]). Mettre `effortKm` ici, comme le faisait la V1, revenait
/// a graver l'unite dans la donnee et rendait toute comparaison AVANT/APRES
/// impossible.
class StageEffort {
  const StageEffort({
    required this.index,
    required this.name,
    required this.distanceKm,
    required this.elevationGainM,
    this.elevationLossM = 0,
  });

  /// Index 0-based de l'etape dans la sequence.
  final int index;

  /// Nom de l'etape (affichage).
  final String name;

  /// Distance de l'etape (km).
  final double distanceKm;

  /// Denivele positif de l'etape (m).
  final int elevationGainM;

  /// Denivele NEGATIF de l'etape (m). N'entre PAS dans le score (#1-d, #M05) :
  /// il sert au classement des etapes de l'alerte descente du dispositif poids
  /// (#4-l), qui n'invente aucun seuil.
  final int elevationLossM;
}

/// Verdict d'une etape : son energie, son score, sa couleur, son facteur
/// dominant.
class StageVerdict {
  const StageVerdict({
    required this.stage,
    required this.energyKm,
    required this.capacityKm,
    required this.score,
    required this.verdict,
    required this.distanceShare,
    required this.elevationShare,
    required this.altitudeShare,
    required this.heatShare,
  });

  /// L'etape evaluee (geometrie brute).
  final StageEffort stage;

  /// Energie de l'etape dans le bareme applique (km-energie).
  final double energyKm;

  /// Capacite du jour appliquee a cette etape (km-energie).
  final double capacityKm;

  /// score = energie_etape / capacite_jour (>= 0).
  final double score;

  /// Verdict tricolore de l'etape.
  final FeasibilityVerdict verdict;

  /// DECOMPOSITION EXACTE DU SCORE en quatre parts additives (#2-l).
  ///
  /// distance + denivele + chaleur + altitude = score, a l'exactitude machine
  /// pres. Demonstration : score = E/(B·ka·kh) avec E = d + g/u et B la base ;
  /// la part distance vaut d/B, la part denivele (g/u)/B, la part chaleur
  /// E/B·(1/kh − 1), la part altitude E/B·(1/(ka·kh) − 1/kh). Leur somme se
  /// telescope exactement en E/(B·ka·kh).
  final double distanceShare;

  /// Part du denivele positif dans le score (voir [distanceShare]).
  final double elevationShare;

  /// Part de l'altitude dans le score (voir [distanceShare]).
  final double altitudeShare;

  /// Part de la chaleur dans le score (voir [distanceShare]).
  final double heatShare;

  /// Vrai si l'etape depasse le plafond (orange ou rouge -> « au-dessus »).
  bool get isOverCapacity => verdict != FeasibilityVerdict.green;

  /// Facteur DOMINANT de l'etape : la plus grosse des quatre parts (#2-l).
  LimitingFactor get dominantFactor {
    var best = LimitingFactor.distance;
    var bestShare = distanceShare;
    if (elevationShare > bestShare) {
      best = LimitingFactor.elevation;
      bestShare = elevationShare;
    }
    if (altitudeShare > bestShare) {
      best = LimitingFactor.altitude;
      bestShare = altitudeShare;
    }
    if (heatShare > bestShare) {
      best = LimitingFactor.heat;
      bestShare = heatShare;
    }
    return best;
  }
}

/// SCORE DE CIRCUIT (#2-m a #2-t).
///
/// Chaque contrainte est normalisee par son PROPRE seuil publie et vaut 1,0 a
/// sa limite ; le score du circuit est la contrainte qui mord. Aucun poids
/// n'est choisi, donc aucun poids n'est a justifier.
class CircuitScore {
  const CircuitScore({
    required this.worstStage,
    required this.averageLoad,
    required this.rest,
    required this.habitGap,
    required this.monotony,
    required this.monotonyWindowStartDay,
    required this.monotonyWindowEndDay,
    required this.totalDays,
    required this.score,
    required this.dominant,
    required this.verdict,
  });

  /// C1 — le score de la pire etape (#2-n).
  final double worstStage;

  /// C2 — (Σ energie) ÷ (jours de marche × capacite du jour) (#2-o).
  ///
  /// AFFICHEE, JAMAIS DECISIVE — et ce n'est pas un choix de confort, c'est une
  /// demonstration. C2 est une MOYENNE et C1 le MAXIMUM de la meme serie
  /// normalisee par le meme plafond : `C2 <= C1` par construction, toujours.
  /// `max(C1 ; C2 ; C3)` valait donc identiquement `max(C1 ; C3)` ; C2 a ete
  /// sortie du maximum pour que l'ecriture soit honnete, sans que la sortie du
  /// moteur change d'un chiffre.
  ///
  /// ELLE RESTE CALCULEE PARCE QU'ELLE INFORME REELLEMENT : un trek a maximum
  /// 1,05 et moyenne 0,50 a UNE journee dure ; un trek a maximum 1,05 et
  /// moyenne 1,00 est dur TOUS LES JOURS. Aucune autre grandeur du modele ne
  /// porte cette distinction.
  final double averageLoad;

  /// C3 — monotonie ÷ 2,0 (#2-p). `null` quand elle N'EST PAS CALCULABLE : sur
  /// un sentier d'UNE etape, l'ecart-type d'une seule charge vaut zero et la
  /// monotonie diverge. Une contrainte non calculable est DECLAREE non
  /// applicable, elle n'est jamais remplacee par un chiffre (#10-e).
  ///
  /// AFFICHEE ET CONSEILLEE, JAMAIS DECISIVE depuis GO-61 (22/09). Elle rejoint
  /// C2 et C4 dans les grandeurs informatives : le seuil de 2,0 est une
  /// EXTRAPOLATION declaree (#M08, athletes en entrainement), et la regle du
  /// projet est que ce qui n'est pas source s'affiche mais ne decide pas. Voir
  /// [score] pour la demonstration complete.
  final double? rest;

  /// C4 — charge journaliere du trek ÷ charge journaliere deja realisee
  /// (#2-q). AFFICHE, JAMAIS DECISIF (#S16-b Impellizzeri 2020 : aucune preuve
  /// causale). `null` si aucune habitude chiffree n'est connue.
  final double? habitGap;

  /// Monotonie de Foster brute (moyenne ÷ ecart-type de population) de la PIRE
  /// fenetre. `null` si non calculable.
  final double? monotony;

  /// Premier jour (1-based) de la fenetre de monotonie retenue, `null` si non
  /// calculable.
  final int? monotonyWindowStartDay;

  /// Dernier jour (1-based) de la fenetre de monotonie retenue.
  final int? monotonyWindowEndDay;

  /// Nombre TOTAL de jours du programme (marche + repos) : c'est lui qui dit si
  /// la fenetre retenue couvre le trek entier ou seulement une de ses semaines.
  final int totalDays;

  /// S_circuit = C1, LA PIRE ETAPE, ET ELLE SEULE (GO-61 du 22/09).
  ///
  /// C2, C3 et C4 sont TOUTES EN INFORMATION. Le chemin jusque-la, en deux
  /// temps : C2 est sortie du maximum parce qu'une moyenne ne peut pas depasser
  /// le maximum de la meme serie (elle ne decidait donc jamais) ; C3 en est
  /// sortie a son tour parce qu'elle etait la SEULE contrainte EXTRAPOLEE du
  /// modele (#M08 : seuil de Foster etabli sur des athletes EN ENTRAINEMENT,
  /// transfere a l'itinerance) et la seule a laquelle on avait laisse le droit
  /// de mettre au rouge — en contradiction avec la regle du projet, ce qui
  /// n'est pas source s'affiche mais ne decide pas.
  ///
  /// CE QUI A EMPORTE LA DECISION, MESURE SUR LE PRODUIT REEL : 24 cellules sur
  /// 24 au rouge par le seul fait qu'aucun jour de repos n'etait pose, DONT un
  /// profil confirme dont la pire etape est a 0,68 — vert franc. Et un defaut
  /// mathematique par-dessus : la monotonie vaut moyenne ÷ ecart-type, donc
  /// PLUS LES ETAPES SONT REGULIERES PLUS ELLE GRIMPE ; un randonneur qui
  /// enchaine sept jours bien calibres etait puni PARCE QUE son itineraire
  /// etait regulier.
  ///
  /// CONTREPARTIE ASSUMEE, ET ELLE EST REELLE : plus aucun mecanisme ne rend un
  /// circuit plus severe que sa pire etape. ARB-004 (#2-s) n'a plus rien pour
  /// le porter, et l'exemple des dix-sept jours d'affilee est DIT a l'ecran
  /// (constat de duree) et non JUGE. C'est le prix de n'inventer aucun chiffre
  /// sur un sujet de securite en montagne : aucune source publiee ne chiffre la
  /// fatigue cumulee en randonnee itinerante (trou #M15).
  final double score;

  /// La contrainte qui porte [score].
  ///
  /// VAUT DESORMAIS TOUJOURS [worstStage] : depuis GO-61, S_circuit = C1 et
  /// aucune autre contrainte n'entre dans le maximum. Le champ est CONSERVE
  /// parce qu'il rend la propriete VERIFIABLE — la campagne et les tests
  /// verrouillent « la dominante ne peut etre que C1 », ce qui casserait au
  /// premier recablage d'une contrainte informative dans le verdict.
  final CircuitConstraint dominant;

  /// Verdict tricolore du circuit (memes seuils que les etapes).
  final FeasibilityVerdict verdict;

  /// Vrai si la contrainte repos n'a pas pu etre calculee (#10-e).
  bool get isRestApplicable => rest != null;

  /// Vrai si la fenetre de monotonie couvre le trek ENTIER (programme de 7 jours
  /// ou moins) — et non une semaine choisie parmi d'autres.
  bool get monotonyCoversWholeTrek =>
      monotonyWindowStartDay == 1 && monotonyWindowEndDay == totalDays;
}

/// Un conseil de programme (cle i18n + parametres nommes pour l'affichage).
///
/// Le moteur ne fabrique PAS de phrase : il produit une cle stable + les
/// nombres. L'UI compose le texte via Slang (accents FR garantis cote i18n).
class ProgramAdvice {
  const ProgramAdvice({required this.key, this.params = const {}});

  /// Cle i18n stable (`t.feasibility.formula.advice.*`).
  final String key;

  /// Parametres nommes injectes dans le texte i18n (ex. {days: 8}).
  final Map<String, Object> params;
}

/// Resultat complet du moteur de faisabilite V2.
class FeasibilityAssessment {
  const FeasibilityAssessment({
    required this.scale,
    required this.level,
    required this.levelCeilingEnergyKm,
    required this.demonstratedFloorEnergyKm,
    required this.baseCapacityEnergyKm,
    required this.dailyCapacityEnergyKm,
    required this.conditions,
    required this.stageVerdicts,
    required this.circuit,
    required this.globalVerdict,
    required this.hardestStageIndex,
    required this.daysOverCapacity,
    required this.limitingFactor,
    required this.recommendedTrainingWeeks,
    required this.advice,
    required this.suggestedDays,
    required this.restDaysPlanned,
    required this.recommendedRestAfterStageIndex,
    required this.walkingDays,
    required this.longestConsecutiveDaysDone,
  });

  /// Bareme applique (V2 en production, V1 pour la colonne AVANT).
  final FeasibilityScale scale;

  /// Niveau retenu (corrige age + condition).
  final HikerLevel level;

  /// Plafond journalier du NIVEAU seul (km-energie), avant plancher demontre.
  final double levelCeilingEnergyKm;

  /// E_max_realise : meilleure journee DEMONTREE (km-energie), 0 si inconnue.
  final double demonstratedFloorEnergyKm;

  /// Capacite de BASE = max(plafond du niveau ; plancher demontre) (#2-d).
  final double baseCapacityEnergyKm;

  /// Capacite du jour de REFERENCE = base × k_altitude × k_chaleur (#2-d/#2-e).
  final double dailyCapacityEnergyKm;

  /// Conditions appliquees (altitude, saison) — l'ecran doit pouvoir les dire.
  final TrekConditions conditions;

  /// Verdict par etape (meme ordre que l'entree).
  final List<StageVerdict> stageVerdicts;

  /// Score de circuit (C1 a C4) — `null` si aucune etape.
  final CircuitScore? circuit;

  /// Verdict global = verdict du CIRCUIT (et non plus la seule pire etape).
  final FeasibilityVerdict globalVerdict;

  /// Index 0-based de l'etape la plus contraignante (score max), -1 si aucune.
  final int hardestStageIndex;

  /// Nombre de jours (etapes) au-dessus du plafond (orange + rouge).
  final int daysOverCapacity;

  /// Facteur limitant nomme du verdict global.
  final LimitingFactor limitingFactor;

  /// Reco d'entrainement en semaines (6-12 selon le profil), 0 si verdict vert.
  final int recommendedTrainingWeeks;

  /// Conseils de programme (nb de jours optimal, decoupe, repos).
  final List<ProgramAdvice> advice;

  /// Nombre de jours de MARCHE optimal propose (hors repos).
  final int suggestedDays;

  /// Nombre de jours de REPOS pris en compte dans la contrainte C3.
  final int restDaysPlanned;

  /// REPOS CONSEILLES : index 0-based des etapes APRES lesquelles poser un jour
  /// de repos pour que la monotonie repasse sous son seuil.
  ///
  /// UN CONSEIL, PLUS UN VERDICT (GO-61). C'est aussi ce que le programme par
  /// defaut POSE : le randonneur part d'un itineraire tenable et voit le
  /// chiffre du repos bouger s'il les retire, au lieu de partir d'un itineraire
  /// qu'il devrait reparer sans savoir comment.
  final Set<int> recommendedRestAfterStageIndex;

  /// Nombre de jours de repos conseilles (= taille de
  /// [recommendedRestAfterStageIndex]).
  int get recommendedRestDays => recommendedRestAfterStageIndex.length;

  /// Vrai si le repos merite d'etre CONSEILLE : la monotonie depasse son seuil
  /// (C3 > 1) et le programme courant ne porte pas encore ce qu'il faudrait.
  ///
  /// Ne conditionne AUCUNE couleur : c'est le declencheur d'une phrase, pas
  /// d'un verdict.
  bool get isRestAdvised {
    final c = circuit;
    final r = c?.rest;
    return r != null && r > 1 && recommendedRestAfterStageIndex.isNotEmpty;
  }

  /// Nombre de jours de MARCHE du trek (= nombre d'etapes evaluees).
  ///
  /// ENONCE, JAMAIS SCORE. Voir [longestConsecutiveDaysDone].
  final int walkingDays;

  /// Plus longue sortie ENCHAINEE deja realisee, en jours. 0 = inconnue.
  ///
  /// POURQUOI CE CONSTAT EXISTE, ET POURQUOI IL N'EST PAS UNE COULEUR.
  /// Le modele ne capte la DUREE CUMULEE nulle part. C3 mesure l'absence de
  /// recuperation, c'est-a-dire une forme de REGULARITE, pas une LONGUEUR : sur
  /// des etapes regulieres sans repos, C3 rend exactement le meme chiffre pour
  /// trois jours et pour dix-sept. Aucun seuil publie n'existe pour combler ce
  /// trou (#M06), donc on ne l'invente pas : on ENONCE LE FAIT — « ce trek dure
  /// dix-sept jours de marche, ta plus longue sortie enchainee est de trois
  /// jours » — et le randonneur juge. Un constat, pas un verdict.
  final int longestConsecutiveDaysDone;

  /// Vrai si le constat de duree peut etre enonce (les deux chiffres existent).
  bool get hasDurationStatement =>
      walkingDays > 0 && longestConsecutiveDaysDone > 0;

  /// Etape la plus contraignante (null si aucune etape).
  StageVerdict? get hardestStage =>
      hardestStageIndex >= 0 ? stageVerdicts[hardestStageIndex] : null;

  /// LE VERDICT EST-IL VALIDE (#1-e / #2-j).
  ///
  /// En hiver, on ne durcit pas le verdict : ON DIT QU'IL NE TIENT PLUS. Les
  /// chiffres restent calcules et visibles — les masquer reviendrait a cacher
  /// ce sur quoi la declaration porte — mais l'ecran DOIT afficher la
  /// non-validite (#8-d).
  bool get isVerdictValid => !conditions.isWinterDeparture;

  /// ARB-004 (#2-s) : le circuit est-il PLUS SEVERE que toutes ses etapes ?
  ///
  /// STRUCTURELLEMENT FAUX DEPUIS GO-61, et c'est exactement pour cela que ce
  /// getter reste : S_circuit vaut C1, donc le verdict du circuit EST celui de
  /// sa pire etape, et cette propriete doit pouvoir etre VERIFIEE plutot que
  /// supposee. Un test la verrouille ; le jour ou une contrainte informative
  /// rentrerait a nouveau dans le verdict, il rougirait au lieu de laisser
  /// passer un randonneur devant des etapes vertes surmontees d'un circuit
  /// rouge, sans explication.
  bool get isCircuitHarsherThanStages {
    final c = circuit;
    if (c == null || stageVerdicts.isEmpty) return false;
    return c.verdict.index > worstStageVerdict.index;
  }

  /// Verdict de la PIRE etape (C1 seule), pour l'explication d'ARB-004.
  FeasibilityVerdict get worstStageVerdict => hardestStageIndex >= 0
      ? stageVerdicts[hardestStageIndex].verdict
      : FeasibilityVerdict.green;

  /// Vrai si le plancher demontre a REELLEMENT releve la capacite (#2-g) :
  /// le randonneur a deja fait mieux que le plafond de son cran.
  bool get isDemonstratedFloorActive =>
      demonstratedFloorEnergyKm > levelCeilingEnergyKm;

  /// Etapes triees par denivele NEGATIF decroissant (#4-l) : le dispositif
  /// poids enonce sa charge excedentaire sur les premieres, sans inventer de
  /// seuil de declenchement.
  List<StageVerdict> get stagesByDescentDesc {
    final sorted = List<StageVerdict>.of(stageVerdicts)
      ..sort((a, b) => b.stage.elevationLossM.compareTo(a.stage.elevationLossM));
    return sorted;
  }
}

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
  ///   programme (= nombre d'etapes a repartir). Plafonne le nombre de jours
  ///   CONSEILLE : une etape ne se coupe pas en deux, donc conseiller plus de
  ///   jours qu'il n'y a d'etapes serait un conseil inapplicable. 0 = inconnu,
  ///   aucun plafond.
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
      verdicts.add(StageVerdict(
        stage: s,
        energyKm: energy,
        capacityKm: capacity,
        score: score,
        verdict: thresholds.verdictFor(score),
        distanceShare: base > 0 ? s.distanceKm / base : double.infinity,
        elevationShare:
            base > 0 ? scale.elevationEnergyOf(s) / base : double.infinity,
        heatShare: perBase * (1 / kh - 1),
        altitudeShare: perBase * (1 / (ka * kh) - 1 / kh),
      ));
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
        : _circuitScore(
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
    final limiting = _computeLimitingFactor(
      verdicts: verdicts,
      daysOver: daysOver,
      hardestIndex: hardestIndex,
      globalVerdict: globalVerdict,
    );

    // 7. Reco entrainement + conseils de programme.
    final trainingWeeks = trainingWeeksFor(level, globalVerdict);
    final suggestedDays = _suggestedWalkingDays(
      verdicts,
      capacity,
      maxWalkingDays: maxWalkingDays,
    );
    // Le repos CONSEILLE (GO-61) : calcule sur les memes energies que C3, donc
    // sur le meme chiffre que celui affiche.
    final recommendedRest = recommendedRestAfterStageIndex(
      verdicts.map((v) => v.energyKm).toList(),
    );
    final advice = _buildAdvice(
      verdicts: verdicts,
      circuit: circuit,
      globalVerdict: globalVerdict,
      hardestIndex: hardestIndex,
      suggestedDays: suggestedDays,
      currentDays: stages.length,
      trainingWeeks: trainingWeeks,
      recommendedRest: recommendedRest,
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
      List<double> loads) {
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
      final rest =
          restAfterStageIndexFor(stageCount: n, restDays: restDays);
      // Un repos demande mais non placable (avant la premiere etape, ou apres
      // la derniere) ne compte pas : on passe au nombre suivant.
      if (restDays > 0 && rest.length < restDays) continue;
      final m = worstMonotonyWindow(dailyLoads(
        stageEnergies: stageEnergies,
        restAfterStageIndex: rest,
      )).monotony;
      if (m == null || m <= monotonyThreshold) return rest;
    }
    return const {};
  }

  /// Calcule C1 a C4 et le score de circuit.
  static CircuitScore _circuitScore({
    required List<StageVerdict> verdicts,
    required double capacity,
    required Set<int> restAfterStageIndex,
    required double? habitualDailyEnergyKm,
    required FeasibilityThresholds thresholds,
  }) {
    // C1 — la pire etape (#2-n).
    final c1 = verdicts.map((v) => v.score).reduce(math.max);

    // C2 — la charge moyenne (#2-o).
    final totalEnergy =
        verdicts.map((v) => v.energyKm).reduce((a, b) => a + b);
    final c2 = capacity > 0
        ? totalEnergy / (verdicts.length * capacity)
        : double.infinity;

    // C3 — le repos (#2-p) : PIRE fenetre glissante de 7 jours, jours de repos
    // comptes comme charge nulle.
    final loads = dailyLoads(
      stageEnergies: verdicts.map((v) => v.energyKm).toList(),
      restAfterStageIndex: restAfterStageIndex,
    );
    final window = worstMonotonyWindow(loads);
    final monotony = window.monotony;
    final windowStart = window.startDay;
    final windowEnd = window.endDay;
    final c3 = monotony == null ? null : monotony / monotonyThreshold;

    // C4 — l'ecart a l'habitude (#2-q). AFFICHE, JAMAIS DECISIF.
    final habitual = habitualDailyEnergyKm;
    final c4 = (habitual == null || !habitual.isFinite || habitual <= 0)
        ? null
        : (totalEnergy / verdicts.length) / habitual;

    // S_circuit = C1, ET RIEN D'AUTRE (GO-61). C2, C3 et C4 sont calculees,
    // affichees, et pour C3 conseillee — aucune n'entre dans le verdict. La
    // demonstration complete est portee par [CircuitScore.score] : elle tient
    // en une phrase, ce qui n'est pas source s'affiche mais ne decide pas, et
    // C3 etait la derniere contrainte extrapolee a avoir garde ce droit.
    final score = c1;
    const dominant = CircuitConstraint.worstStage;

    return CircuitScore(
      worstStage: c1,
      averageLoad: c2,
      rest: c3,
      habitGap: c4,
      monotony: monotony,
      monotonyWindowStartDay: windowStart,
      monotonyWindowEndDay: windowEnd,
      totalDays: loads.length,
      score: score,
      dominant: dominant,
      verdict: thresholds.verdictFor(score),
    );
  }

  /// Determine le facteur limitant du verdict global : d'abord l'ENCHAINEMENT
  /// (>=2 jours consecutifs au-dessus du plafond), sinon le facteur dominant de
  /// l'etape la plus dure (distance, denivele, altitude ou chaleur).
  static LimitingFactor _computeLimitingFactor({
    required List<StageVerdict> verdicts,
    required int daysOver,
    required int hardestIndex,
    required FeasibilityVerdict globalVerdict,
  }) {
    if (hardestIndex < 0) return LimitingFactor.none;
    if (globalVerdict == FeasibilityVerdict.green) return LimitingFactor.none;
    // Enchainement : plusieurs jours consecutifs au-dessus = c'est LA contrainte.
    if (daysOver >= 2 && _hasConsecutiveOver(verdicts)) {
      return LimitingFactor.chaining;
    }
    return verdicts[hardestIndex].dominantFactor;
  }

  /// Vrai s'il existe au moins DEUX etapes consecutives au-dessus du plafond.
  static bool _hasConsecutiveOver(List<StageVerdict> verdicts) {
    for (var i = 1; i < verdicts.length; i++) {
      if (verdicts[i].isOverCapacity && verdicts[i - 1].isOverCapacity) {
        return true;
      }
    }
    return false;
  }

  /// Nombre de jours de MARCHE optimal pour que la charge moyenne tienne sous la
  /// capacite, en lissant les pics : max(nb de journees, ceil(energie totale /
  /// capacite), nb de journees au-dessus de la capacite * 2 pour permettre le
  /// decoupage des pires).
  ///
  /// [maxWalkingDays] plafonne le resultat au nombre de journees REELLEMENT
  /// atteignable (une etape ne se coupe pas en deux dans le programme). Le
  /// plafond ne descend jamais sous le decoupage courant : conseiller MOINS de
  /// jours que ce qui est deja pose n'a aucun sens ici, la fonction cherchant
  /// toujours a etaler l'effort.
  static int _suggestedWalkingDays(
    List<StageVerdict> verdicts,
    double capacity, {
    int maxWalkingDays = 0,
  }) {
    if (verdicts.isEmpty) return 0;
    final total = verdicts.map((v) => v.energyKm).reduce((a, b) => a + b);
    final byLoad =
        capacity > 0 ? (total / capacity).ceil() : verdicts.length;
    // Chaque journee au-dessus de la capacite merite au moins d'etre coupee en 2.
    final overCount =
        verdicts.where((v) => capacity > 0 && v.energyKm > capacity).length;
    final byOver = verdicts.length + overCount;
    final raw = math.max(verdicts.length, math.max(byLoad, byOver));
    if (maxWalkingDays <= 0) return raw;
    return math.min(raw, math.max(maxWalkingDays, verdicts.length));
  }

  /// Construit les conseils de programme (cles i18n + parametres). Coherent avec
  /// l'ecran Programme (LOT 2) : jours + repos + decoupe.
  static List<ProgramAdvice> _buildAdvice({
    required List<StageVerdict> verdicts,
    required CircuitScore? circuit,
    required FeasibilityVerdict globalVerdict,
    required int hardestIndex,
    required int suggestedDays,
    required int currentDays,
    required int trainingWeeks,
    required Set<int> recommendedRest,
  }) {
    final advice = <ProgramAdvice>[];

    // 0. LE REPOS, EN CONSEIL (GO-61). Il ne decide plus rien, donc il ne
    // depend plus de la couleur : un programme dont toutes les etapes sont
    // vertes peut parfaitement n'offrir aucune recuperation, et c'est encore
    // plus vrai quand il est vert — personne ne pensera a souffler. La phrase
    // dit COMBIEN et OU, parce qu'un conseil qu'on ne peut pas appliquer n'en
    // est pas un.
    final c3 = circuit?.rest;
    final restAdvised = c3 != null && c3 > 1 && recommendedRest.isNotEmpty;
    final restAdvice = ProgramAdvice(
      key: 'restAdvised',
      params: {
        'days': recommendedRest.length,
        'stages':
            (recommendedRest.toList()..sort()).map((i) => i + 1).join(', '),
      },
    );

    // Tout vert : le programme actuel tient, on encourage a garder des marges.
    // Le conseil de repos vient APRES — il nuance, il ne contredit pas.
    if (globalVerdict == FeasibilityVerdict.green) {
      advice.add(const ProgramAdvice(key: 'balancedOk'));
      if (restAdvised) advice.add(restAdvice);
      return advice;
    }

    // Hors du vert, le repos passe DEVANT : conseiller « decoupe l'etape N »
    // quand c'est la recuperation qui manque enverrait dans le mur, lisser les
    // pics et poser des repos etant deux leviers OPPOSES (#2-t).
    if (restAdvised) advice.add(restAdvice);

    // 1. Nombre de jours optimal (si plus que le decoupage actuel).
    if (suggestedDays > currentDays) {
      advice.add(ProgramAdvice(
        key: 'optimalDays',
        params: {'days': suggestedDays, 'current': currentDays},
      ));
    } else {
      advice.add(const ProgramAdvice(key: 'balanced'));
    }

    // 2. Ou decouper : l'etape la plus dure (1-based pour l'affichage).
    if (hardestIndex >= 0 &&
        verdicts[hardestIndex].verdict == FeasibilityVerdict.red) {
      advice.add(ProgramAdvice(
        key: 'split',
        params: {'stage': hardestIndex + 1},
      ));
    }

    // 3. Ou poser les repos : apres chaque bloc d'etapes au-dessus du plafond.
    //
    // SAUTE si le conseil de rythme a deja parle : deux phrases de repos qui
    // designent des etapes differentes — l'une sur les blocs durs, l'autre sur
    // la regularite — se contrediraient a l'ecran. Le conseil de rythme est
    // alors le plus complet des deux (il dit combien ET ou).
    final restAfter = restAdvised
        ? const <int>[]
        : _restDaySuggestions(verdicts);
    if (restAfter.isNotEmpty) {
      advice.add(ProgramAdvice(
        key: 'rest',
        params: {'stages': restAfter.map((i) => i + 1).join(', ')},
      ));
    }

    // 4. Entrainement (renvoi vers la prepa physique).
    if (trainingWeeks > 0) {
      advice.add(ProgramAdvice(
        key: 'training',
        params: {'weeks': trainingWeeks},
      ));
    }

    return advice;
  }

  /// Index (0-based) des etapes APRES lesquelles poser un jour de repos : la
  /// derniere etape de chaque bloc consecutif au-dessus du plafond (hors toute
  /// derniere etape du trek, ou un repos n'a pas de sens).
  static List<int> _restDaySuggestions(List<StageVerdict> verdicts) {
    final suggestions = <int>[];
    for (var i = 0; i < verdicts.length; i++) {
      final over = verdicts[i].isOverCapacity;
      final nextOver =
          i + 1 < verdicts.length && verdicts[i + 1].isOverCapacity;
      // Fin d'un bloc « au-dessus » suivi d'une autre etape -> repos utile.
      if (over && !nextOver && i + 1 < verdicts.length) {
        suggestions.add(i);
      }
    }
    return suggestions;
  }
}
