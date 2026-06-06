import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/follower_slots_table.dart';

part 'follower_slots_dao.g.dart';

/// DAO pour les slots de suiveur (E4.10).
///
/// Operations CRUD sur la table FollowerSlots.
/// Le type de donnees genere par Drift est [FollowerSlotRow]
/// (distinct du modele Freezed FollowerSlot).
@DriftAccessor(tables: [FollowerSlots])
class FollowerSlotsDao extends DatabaseAccessor<AppDatabase>
    with _$FollowerSlotsDaoMixin {
  FollowerSlotsDao(super.db);

  /// Recupere tous les slots d une session
  Future<List<FollowerSlotRow>> getBySession(String sessionId) {
    return (select(followerSlots)..where((t) => t.sessionId.equals(sessionId)))
        .get();
  }

  /// Compte les slots d une session
  Future<int> countBySession(String sessionId) async {
    final slots = await getBySession(sessionId);
    return slots.length;
  }

  /// Insere ou remplace un slot
  Future<void> insertOrReplace(FollowerSlotsCompanion entry) {
    return into(followerSlots).insertOnConflictUpdate(entry);
  }

  /// Supprime un slot par son id
  Future<int> deleteById(String id) {
    return (delete(followerSlots)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime tous les slots d une session
  Future<int> deleteBySession(String sessionId) {
    return (delete(followerSlots)..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }
}
