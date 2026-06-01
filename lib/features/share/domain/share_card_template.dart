/// Templates de carte de partage disponibles.
///
/// Chaque template affiche les données du trek
/// avec un layout et un focus différent.
/// Les labels viennent de Slang (share.templateXxx).
enum ShareCardTemplate {
  /// Template "Statistiques" : km, D+, date, nom du sentier
  stats,

  /// Template "Parcours" : carte miniature + stats résumées
  journey,

  /// Template "Étape" : focus sur une étape spécifique
  stage;
}
