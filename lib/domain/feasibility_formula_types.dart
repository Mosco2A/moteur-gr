/// Les vocabulaires de la faisabilite : niveau, verdict, facteur
/// limitant, contrainte de circuit et raison de neutralite.
///
/// Morceau de `feasibility_formula.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'feasibility_formula.dart';

/// Niveau de randonneur deduit du profil (ordre croissant de capacite).
///
/// Cles i18n stables (`t.feasibility.formula.levels.*`). Les reperes BP D+/jour
/// qui bornent chaque niveau : <300 debutant, 300-700 intermediaire,
/// 700-1200 confirme, >1200 expert.
enum HikerLevel { beginner, intermediate, confirmed, expert }

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
