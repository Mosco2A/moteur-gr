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
}
