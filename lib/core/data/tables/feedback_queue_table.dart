import 'package:drift/drift.dart';

/// Table de file d'attente des feedbacks offline.
///
/// Les feedbacks sont stockés localement et envoyés
/// quand la connexion est rétablie. Ajoutée en migration v6.
class FeedbackQueue extends Table {
  /// Clé primaire auto-incrémentée
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier (ex: 'gr10')
  TextColumn get trailId => text()();

  /// Type de feedback ('bug', 'suggestion', 'question', 'other')
  TextColumn get feedbackType => text()();

  /// Contenu du feedback
  TextColumn get content => text()();

  /// Note de satisfaction (1-5, nullable)
  IntColumn get rating => integer().nullable()();

  /// Statut d'envoi ('pending', 'sent', 'failed')
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// Date de création
  DateTimeColumn get createdAt => dateTime()();

  /// Date d'envoi effectif (null si pas encore envoyé)
  DateTimeColumn get sentAt => dateTime().nullable()();
}
