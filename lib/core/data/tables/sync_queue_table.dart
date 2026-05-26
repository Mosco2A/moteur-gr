import 'package:drift/drift.dart';

/// Table de file de synchronisation pour le telechargement avec reprise (Phase 4 Drift v9).
///
/// Chaque ligne represente une action de telechargement a executer.
/// Permet la reprise en cas de coupure reseau en trackant
/// l'etat d'insertion de chaque table pour un sentier.
class SyncQueue extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier concerne
  TextColumn get trailId => text()();

  /// Action a executer ('insert_trail_meta', 'insert_stages', etc.)
  TextColumn get action => text()();

  /// Statut de l'action ('pending', 'completed', 'failed')
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// Donnees JSON de l'action (nullable, contenu a inserer)
  TextColumn get payload => text().nullable()();

  /// Date de creation (ISO 8601)
  TextColumn get createdAt => text()();

  /// Date de completion (ISO 8601, nullable)
  TextColumn get completedAt => text().nullable()();

  /// Nombre de tentatives echouees
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();
}
