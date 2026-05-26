import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_gpx_tracks_table.dart';

part 'trail_gpx_tracks_dao.g.dart';

/// DAO pour les traces GPX par itineraire.
///
/// Operations CRUD sur la table TrailGpxTracks.
@DriftAccessor(tables: [TrailGpxTracks])
class TrailGpxTracksDao extends DatabaseAccessor<AppDatabase>
    with _$TrailGpxTracksDaoMixin {
  TrailGpxTracksDao(super.db);

  /// Recupere toutes les traces
  Future<List<TrailGpxTrack>> getAll() {
    return select(trailGpxTracks).get();
  }

  /// Recupere une trace par son id
  Future<TrailGpxTrack?> getById(String id) {
    return (select(trailGpxTracks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insere ou remplace une trace
  Future<void> insertOrReplace(TrailGpxTracksCompanion entry) {
    return into(trailGpxTracks).insertOnConflictUpdate(entry);
  }

  /// Supprime une trace par son id
  Future<int> deleteById(String id) {
    return (delete(trailGpxTracks)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime toutes les traces
  Future<int> deleteAll() {
    return delete(trailGpxTracks).go();
  }
}
