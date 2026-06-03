import 'package:drift/drift.dart';

/// Table de tracking des demandes d'avis store par trek — E5.17.
///
/// Stocke un flag par trailId pour garantir 1 seule demande de review
/// par trek termine. Remplace le HiveBoxes.reviewRequested du GR20.
/// Ajoutee en migration v11 (E5.17).
class ReviewRequests extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier (ex: 'gr20-2026-001')
  TextColumn get trailId => text().withLength(min: 1, max: 128)();

  /// Date de la demande de review
  DateTimeColumn get requestedAt => dateTime()();
}
