import 'package:drift/drift.dart';

/// Table des metadonnees de sentier (Phase 4 Drift v7).
///
/// Chaque sentier a un code unique, une version de donnees
/// et un horodatage de derniere synchronisation.
class TrailMeta extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Code unique du sentier (ex: 'gr20', 'mare_a_mare')
  TextColumn get code => text().unique()();

  /// Version des donnees (incremente a chaque maj serveur)
  IntColumn get dataVersion => integer()();

  /// Date de derniere synchronisation (ISO 8601, nullable)
  TextColumn get lastSync => text().nullable()();

  /// Statut du sentier ('active', 'archived', 'draft')
  TextColumn get status => text().withDefault(const Constant('active'))();

  @override
  Set<Column> get primaryKey => {id};
}
