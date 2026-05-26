/// Etat du tracking de randonnee.
///
/// Represente les 4 etats possibles du suivi GPS.
enum TrackingStatus {
  /// Pas de tracking en cours
  idle,

  /// Enregistrement actif
  recording,

  /// Enregistrement en pause
  paused,

  /// Enregistrement termine
  stopped,
}
