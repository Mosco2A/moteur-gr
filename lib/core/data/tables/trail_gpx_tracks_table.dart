import 'package:drift/drift.dart';

/// Table des traces GPX par itineraire (Phase 4 Drift v7).
///
/// Chaque itineraire peut avoir une ou plusieurs traces GPX.
class TrailGpxTracks extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Reference vers trail_itineraries.id
  TextColumn get itineraryId => text()();

  /// Nom de la trace
  TextColumn get name => text()();

  /// URL source du fichier GPX (nullable)
  TextColumn get sourceUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
