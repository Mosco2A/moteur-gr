// Feature flags globaux de l'application GR20.
//
// Centralise tous les toggles features pour un controle
// granulaire des fonctionnalites en production.
// Convention : tout est FALSE par defaut, active par config Firestore.

/// Feature flags de l'application GR20.
///
/// Chaque flag controle l'activation d'une fonctionnalite.
/// Les valeurs par defaut sont toutes FALSE (securite).
/// L'activation se fait via Firestore Remote Config ou manuellement.
class FeatureFlags {
  FeatureFlags._();

  // --- Cache interne des flags ---
  static final Map<String, bool> _flags = {};

  // --- Booking ---

  /// Verifie si la reservation est activee pour un trail donne.
  ///
  /// Retourne FALSE par defaut -- la feature booking n'est activee
  /// que lorsque la config Firestore le specifie explicitement.
  static bool isBookingEnabled(String trailId) {
    return _flags['booking_$trailId'] ?? false;
  }

  /// Active ou desactive la reservation pour un trail.
  ///
  /// Usage interne : appele par le service de config au chargement
  /// des flags depuis Firestore.
  static void setBookingEnabled(String trailId, {required bool enabled}) {
    _flags['booking_$trailId'] = enabled;
  }

  // --- Methodes generiques ---

  /// Verifie un flag generique par cle.
  static bool isEnabled(String key) {
    return _flags[key] ?? false;
  }

  /// Definit un flag generique.
  static void setFlag(String key, {required bool enabled}) {
    _flags[key] = enabled;
  }

  /// Reinitialise tous les flags (utile pour les tests).
  static void resetAll() {
    _flags.clear();
  }

  /// Retourne une copie de tous les flags actifs (debug/logs).
  static Map<String, bool> get activeFlags =>
      Map.unmodifiable(
        Map.fromEntries(_flags.entries.where((e) => e.value)),
      );
}
