/// B83: Constantes centralisees pour les noms de Hive boxes.
/// Evite les strings en dur eparpilles dans le code.
abstract final class HiveBoxes {
  /// Settings generaux de l'application (profil, preferences).
  static const String appSettings = 'app_settings';

  /// Sessions de trek (historique + session active).
  static const String trekSessions = 'trek_sessions';

  /// Points GPS enregistres pendant le trek.
  static const String trekTrackPoints = 'trek_track_points';

  /// Entrees du journal de bord.
  static const String trekJournal = 'trek_journal';

  /// Donnees offline (cartes, refuges telecharges).
  static const String trekOffline = 'trek_offline';

  /// F7: IDs de messages testeurs lus (persistance locale).
  static const String readTesterMessages = 'read_tester_messages';

  /// B7: Entrees locales du journal (notes + photos hors session).
  static const String localJournalEntries = 'local_journal_entries';

  /// B0: Cache des donnees distantes (Firebase Storage JSON).
  static const String remoteData = 'remote_data';

  /// B5: File d'attente offline pour les feedbacks en echec reseau.
  static const String feedbackQueue = 'feedback_queue';

  /// E5.17: Flag review_requested par trailId — 1 seule demande par trek.
  static const String reviewRequested = 'review_requested';
}
