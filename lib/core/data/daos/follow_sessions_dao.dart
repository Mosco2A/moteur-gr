import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/follow_sessions_table.dart';

part 'follow_sessions_dao.g.dart';

/// DAO pour les sessions de suivi temps reel (E4.10).
///
/// Operations CRUD sur la table FollowSessions.
/// Le type de donnees genere par Drift est [FollowSessionRow]
/// (distinct du modele Freezed FollowSession).
@DriftAccessor(tables: [FollowSessions])
class FollowSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$FollowSessionsDaoMixin {
  FollowSessionsDao(super.db);

  /// Recupere toutes les sessions
  Future<List<FollowSessionRow>> getAll() {
    return select(followSessions).get();
  }

  /// Recupere une session par son id
  Future<FollowSessionRow?> getById(String id) {
    return (select(followSessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Recupere une session par son shareCode
  Future<FollowSessionRow?> getByShareCode(String code) {
    return (select(followSessions)..where((t) => t.shareCode.equals(code)))
        .getSingleOrNull();
  }

  /// Recupere les sessions actives d un randonneur
  Future<List<FollowSessionRow>> getActiveByUser(String userId) {
    return (select(followSessions)
          ..where(
              (t) => t.trekkerUserId.equals(userId) & t.isActive.equals(true)))
        .get();
  }

  /// Insere ou remplace une session
  Future<void> insertOrReplace(FollowSessionsCompanion entry) {
    return into(followSessions).insertOnConflictUpdate(entry);
  }

  /// Desactive une session
  Future<int> deactivate(String id) {
    return (update(followSessions)..where((t) => t.id.equals(id)))
        .write(const FollowSessionsCompanion(isActive: Value(false)));
  }

  /// Supprime une session par son id
  Future<int> deleteById(String id) {
    return (delete(followSessions)..where((t) => t.id.equals(id))).go();
  }
}
