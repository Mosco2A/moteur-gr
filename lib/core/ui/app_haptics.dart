import 'package:flutter/services.dart';

/// Micro-interactions haptiques (E5.5a — polish UX).
///
/// Centralise les retours haptiques pour les actions importantes
/// (SOS/appel d'urgence, partage, generation de diplome). Un point
/// d'entree unique permet d'ajuster l'intensite globalement et de
/// stubber facilement les retours en test.
///
/// Les methodes sont non bloquantes et silencieuses si la plateforme
/// ne supporte pas le retour haptique (web, desktop sans moteur).
abstract final class AppHaptics {
  /// Retour fort — actions critiques (declenchement d'un appel d'urgence).
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Retour moyen — actions importantes confirmees (partage, export PDF).
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Retour leger — selection/confirmation discrete.
  static Future<void> light() => HapticFeedback.lightImpact();
}
