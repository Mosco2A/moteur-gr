import 'package:drift/drift.dart';

/// Table locale des manifestes de sentier (Phase 4 Drift v8).
///
/// Stocke les entrees du manifeste distant avec la version locale
/// pour detecter les mises a jour necessaires.
class TrailManifests extends Table {
  /// Identifiant unique du sentier (cle primaire)
  TextColumn get trailId => text()();

  /// Version des donnees distantes
  IntColumn get dataVersion => integer()();

  /// Hash SHA-256 du fichier distant
  TextColumn get hash => text()();

  /// Chemin du fichier sur le serveur
  TextColumn get filePath => text()();

  /// Taille du fichier en octets
  IntColumn get fileSize => integer()();

  /// Statut du sentier ('active', 'draft', 'archived')
  TextColumn get status => text()();

  /// Date de derniere mise a jour (ISO 8601)
  TextColumn get lastUpdated => text()();

  /// Version telechargee localement (null = jamais telecharge)
  IntColumn get localVersion => integer().nullable()();

  @override
  Set<Column> get primaryKey => {trailId};
}
