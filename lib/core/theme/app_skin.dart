/// Peaux visuelles de StepWays (SW-SKIN-L2).
///
/// Une "peau" (skin) est un jeu de decisions visuelles NON couleur-sentier
/// (typo de titres, traitement des en-tetes, style de carte, usage de l'image,
/// scrim). Elle ne change NI la navigation, NI les fonctionnalites, NI les
/// donnees — uniquement le rendu (cf. CCO `data/cco_stepways_peaux.md` §2.1).
///
/// L'accent couleur reste injecte par le sentier (`TrailConfig`) : peau et
/// couleur-sentier sont orthogonaux (CCO §2.4).
///
/// Cet enum identifie la peau active ; le porteur technique des valeurs est
/// [SkinTheme] (voir `skin_theme.dart`), injecte dans `ThemeData.extensions`.
enum AppSkin {
  /// Peau par defaut, sans photo, deployable sur TOUS les sentiers.
  /// La couleur-sentier est le heros graphique (degrades, halos). CCO §3 peau A.
  sentierVivant,

  /// Peau "instrument de terrain" (carte IGN / GPS), sans photo : papier/bistre,
  /// en-tetes a filet de lignes de niveau, valeurs en mono. CCO §3 peau B.
  topographique,

  /// Peau premium "carnet d'aventure" : photo plein ecran + scrim, activable
  /// PAR SENTIER (si photos disponibles), fallback auto vers [sentierVivant]
  /// sinon. CCO §3 peau C.
  grandAir,
}
