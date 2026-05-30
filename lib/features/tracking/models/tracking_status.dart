/// Etat du tracking de randonnee.
///
/// Represente les etats possibles du suivi GPS.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef TrackingStatus = String;

/// Valeurs connues pour TrackingStatus avec fallback generique.
abstract class TrackingStatusValues {
  /// Pas de tracking en cours
  static const String idle = 'idle';

  /// Enregistrement actif
  static const String recording = 'recording';

  /// Enregistrement en pause
  static const String paused = 'paused';

  /// Enregistrement termine
  static const String stopped = 'stopped';

  /// Valeur par defaut pour les statuts inconnus
  static const String fallback = idle;

  /// Toutes les valeurs connues
  static const List<String> values = [idle, recording, paused, stopped];

  /// Convertit une chaine en TrackingStatus avec fallback
  static TrackingStatus fromString(String value) =>
      values.contains(value) ? value : fallback;
}
