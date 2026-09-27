import 'package:drift/drift.dart';

/// Table des metadonnees de sentier (Phase 4 Drift v7).
///
/// Chaque sentier a un code unique, une version de donnees
/// et un horodatage de derniere synchronisation.
class TrailMeta extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Code unique du sentier (ex: 'gr10', 'tmb')
  TextColumn get code => text().unique()();

  /// Version des donnees (incremente a chaque maj serveur)
  IntColumn get dataVersion => integer()();

  /// Date de derniere synchronisation (ISO 8601, nullable)
  TextColumn get lastSync => text().nullable()();

  /// Statut du sentier ('active', 'archived', 'draft')
  TextColumn get status => text().withDefault(const Constant('active'))();

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
