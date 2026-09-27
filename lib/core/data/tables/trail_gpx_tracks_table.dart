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

  /// REVISION de cet enregistrement : le numero de la revision ou il a ete
  /// modifie pour la derniere fois (StepWays tache 605).
  ///
  /// Nullable : les lignes anterieures a la migration v27, et les donnees
  /// embarquees qui ne declarent pas de numero, n en ont pas. Le modele complet
  /// — et pourquoi les suppressions exigent un marqueur — est explique dans
  /// `lib/core/data/revision_de_donnee.dart`.
  IntColumn get rev => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
