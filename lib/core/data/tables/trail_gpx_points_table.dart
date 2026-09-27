import 'package:drift/drift.dart';

/// Table des points GPX d'une trace (Phase 4 Drift v7).
///
/// Points ordonnes par sequenceIndex pour reconstituer le trace.
class TrailGpxPoints extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Reference vers trail_gpx_tracks.id
  TextColumn get trackId => text()();

  /// Latitude
  RealColumn get lat => real()();

  /// Longitude
  RealColumn get lng => real()();

  /// Altitude en metres
  RealColumn get elevation => real()();

  /// Index de sequence pour l'ordre des points
  IntColumn get sequenceIndex => integer()();
  /// REVISION de cet enregistrement : le numero de la revision ou il a ete
  /// modifie pour la derniere fois (StepWays tache 605).
  ///
  /// Nullable : les lignes anterieures a la migration v27, et les donnees
  /// embarquees qui ne declarent pas de numero, n en ont pas. Le modele complet
  /// — et pourquoi les suppressions exigent un marqueur — est explique dans
  /// `lib/core/data/revision_de_donnee.dart`.
  IntColumn get rev => integer().nullable()();
}
