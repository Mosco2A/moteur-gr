import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_meta_table.dart';

part 'trail_meta_dao.g.dart';

/// DAO pour les metadonnees de sentier.
///
/// Operations CRUD sur la table TrailMeta.
@DriftAccessor(tables: [TrailMeta])
class TrailMetaDao extends DatabaseAccessor<AppDatabase>
    with _$TrailMetaDaoMixin {
  TrailMetaDao(super.db);

  /// Recupere tous les sentiers
  Future<List<TrailMetaData>> getAll() {
    return select(trailMeta).get();
  }

  /// Recupere un sentier par son id
  Future<TrailMetaData?> getById(String id) {
    return (select(trailMeta)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insere ou remplace un sentier
  Future<void> insertOrReplace(TrailMetaCompanion entry) {
    return into(trailMeta).insertOnConflictUpdate(entry);
  }

  /// Supprime un sentier par son id
  Future<int> deleteById(String id) {
    return (delete(trailMeta)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime tous les sentiers
  Future<int> deleteAll() {
    return delete(trailMeta).go();
  }
}
