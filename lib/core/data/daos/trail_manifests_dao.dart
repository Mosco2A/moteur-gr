import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_manifests_table.dart';

part 'trail_manifests_dao.g.dart';

/// DAO pour les manifestes de sentier.
///
/// Operations CRUD sur la table TrailManifests + detection
/// des mises a jour par comparaison version distante vs locale.
@DriftAccessor(tables: [TrailManifests])
class TrailManifestsDao extends DatabaseAccessor<AppDatabase>
    with _$TrailManifestsDaoMixin {
  TrailManifestsDao(super.db);

  /// Recupere toutes les entrees du manifeste local
  Future<List<TrailManifest>> getAll() {
    return select(trailManifests).get();
  }

  /// Recupere une entree par son trailId
  Future<TrailManifest?> getByTrailId(String trailId) {
    return (select(trailManifests)
          ..where((t) => t.trailId.equals(trailId)))
        .getSingleOrNull();
  }

  /// Insere ou remplace une entree du manifeste
  Future<void> insertOrReplace(TrailManifestsCompanion entry) {
    return into(trailManifests).insertOnConflictUpdate(entry);
  }

  /// Supprime une entree par son trailId
  Future<int> deleteByTrailId(String trailId) {
    return (delete(trailManifests)
          ..where((t) => t.trailId.equals(trailId)))
        .go();
  }

  /// Verifie si un sentier necessite une mise a jour.
  ///
  /// Compare la version distante (dataVersion) avec la version
  /// telechargee localement (localVersion). Retourne true si :
  /// - Le sentier n'existe pas en local
  /// - localVersion est null (jamais telecharge)
  /// - dataVersion > localVersion
  Future<bool> needsUpdate(String trailId) async {
    final entry = await getByTrailId(trailId);
    if (entry == null) return true;
    if (entry.localVersion == null) return true;
    return entry.dataVersion > entry.localVersion!;
  }
}
