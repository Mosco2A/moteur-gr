import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_itineraries_table.dart';

part 'trail_itineraries_dao.g.dart';

/// DAO pour les itineraires de sentier.
///
/// Operations CRUD sur la table TrailItineraries.
@DriftAccessor(tables: [TrailItineraries])
class TrailItinerariesDao extends DatabaseAccessor<AppDatabase>
    with _$TrailItinerariesDaoMixin {
  TrailItinerariesDao(super.db);

  /// Recupere tous les itineraires
  Future<List<TrailItinerary>> getAll() {
    return select(trailItineraries).get();
  }

  /// Recupere un itineraire par son id
  Future<TrailItinerary?> getById(String id) {
    return (select(trailItineraries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Recupere les itineraires d'un sentier
  Future<List<TrailItinerary>> getByTrailId(String trailId) {
    return (select(trailItineraries)
          ..where((t) => t.trailId.equals(trailId)))
        .get();
  }

  /// Insere ou remplace un itineraire
  Future<void> insertOrReplace(TrailItinerariesCompanion entry) {
    return into(trailItineraries).insertOnConflictUpdate(entry);
  }

  /// Supprime un itineraire par son id
  Future<int> deleteById(String id) {
    return (delete(trailItineraries)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime tous les itineraires
  Future<int> deleteAll() {
    return delete(trailItineraries).go();
  }
}
