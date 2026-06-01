/// Gestionnaire de feature flags pour le Moteur GR.
///
/// Controle l'activation/desactivation de fonctionnalites par sentier.
/// Par defaut, toutes les features experimentales sont OFF.
/// L'activation se fait via configuration serveur ou override local.
class FeatureFlags {
  /// Cache interne des overrides par sentier
  /// Cle: 'featureName:trailId', Valeur: etat du flag
  static final Map<String, bool> _overrides = {};

  /// Verifie si la boutique goodies est activee pour un sentier donne.
  ///
  /// Retourne false par defaut -- activation explicite requise.
  static bool isGoodiesEnabled(String trailId) {
    return _overrides['goodies:$trailId'] ?? false;
  }

  /// Definit un override pour un flag donne.
  ///
  /// Utilise pour les tests et la configuration dynamique.
  static void setOverride(String feature, String trailId, {required bool enabled}) {
    _overrides['$feature:$trailId'] = enabled;
  }

  /// Supprime tous les overrides (usage tests uniquement).
  static void clearOverrides() {
    _overrides.clear();
  }
}
