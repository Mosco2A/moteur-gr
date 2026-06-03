import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/health_info_table.dart';

part 'health_info_dao.g.dart';

/// DAO pour les operations sur les informations de sante.
///
/// Fournit les methodes CRUD pour la table HealthInfoEntries.
/// Un seul profil sante par telephone (get first, deleteAll + insert).
@DriftAccessor(tables: [HealthInfoEntries])
class HealthInfoDao extends DatabaseAccessor<AppDatabase>
    with _$HealthInfoDaoMixin {
  HealthInfoDao(super.db);

  /// Recupere le premier (et unique) enregistrement sante.
  ///
  /// Retourne null si aucune donnee sauvegardee.
  Future<HealthInfoEntry?> getFirst() async {
    final entries = await select(healthInfoEntries).get();
    if (entries.isEmpty) return null;
    return entries.first;
  }

  /// Insere un nouvel enregistrement sante.
  Future<int> insertEntry(HealthInfoEntriesCompanion entry) {
    return into(healthInfoEntries).insert(entry);
  }

  /// Supprime tous les enregistrements sante.
  Future<int> deleteAll() {
    return delete(healthInfoEntries).go();
  }
}
