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

  // LE DRAPEAU DE LA RESERVATION EST PARTI AVEC SA ROUTE (lot produit P1,
  // #101255). `isBookingEnabled` ne gardait qu'une chose : la route /booking,
  // retiree faute de porte, de donnee et de test. Un drapeau que plus aucun
  // code de production ne lit est du code mort (regle du lot 645-02), et un
  // drapeau conserve « au cas ou » donne l'illusion qu'une fonction attend
  // derriere. Le jour ou la reservation reelle arrivera, son drapeau viendra
  // AVEC elle, en trois lignes.

  /// Verifie si le premium est debloque pour un sentier donne (E4.17).
  ///
  /// Retourne false par defaut (mode gratuit demo + pub, #81774). Cache
  /// synchrone alimente par MonetizationService (`owned` ou vitrine) pour les
  /// gardes de routes synchrones (StepWays LOT 1, ST4).
  static bool isPremiumEnabled(String trailId) {
    return _overrides['premium:$trailId'] ?? false;
  }

  /// Definit un override pour un flag donne.
  ///
  /// Utilise pour les tests et la configuration dynamique.
  static void setOverride(
    String feature,
    String trailId, {
    required bool enabled,
  }) {
    _overrides['$feature:$trailId'] = enabled;
  }

  /// Supprime tous les overrides (usage tests uniquement).
  static void clearOverrides() {
    _overrides.clear();
  }
}
