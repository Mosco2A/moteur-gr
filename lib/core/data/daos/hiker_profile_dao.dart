import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/hiker_profile_table.dart';

part 'hiker_profile_dao.g.dart';

/// DAO du profil randonneur (StepWays LOT 4, faisabilite Ph1).
///
/// CRUD de base sur la table SENSIBLE [HikerProfile] : lecture, upsert et
/// observation (`watch`) du profil d'un [userId] (hash SHA-256 deterministe).
/// Un seul profil par utilisateur — upsert par cle primaire ([userId]) via
/// `insertOnConflictUpdate` (idempotent : chaque ecriture ecrase la ligne).
///
/// Le schema Drift est CANONIQUE ; la SOURCE DURABLE reste SharedPreferences
/// (DB volatile en memoire ; hydratation au boot par la couche repository, cf.
/// `HikerProfileRepository`), comme le wallet.
@DriftAccessor(tables: [HikerProfile])
class HikerProfileDao extends DatabaseAccessor<AppDatabase>
    with _$HikerProfileDaoMixin {
  HikerProfileDao(super.db);

  /// Relit le profil de [userId], ou null si absent.
  Future<HikerProfileData?> getByUserId(String userId) {
    return (select(hikerProfile)..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Observe le profil de [userId] (emet a chaque modification, null si absent).
  Stream<HikerProfileData?> watchByUserId(String userId) {
    return (select(hikerProfile)..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull();
  }

  /// Cree ou met a jour le profil (upsert par [userId]).
  Future<void> upsert(HikerProfileCompanion entry) async {
    await into(hikerProfile).insertOnConflictUpdate(entry);
  }

  /// Supprime le profil de [userId] (droit a l'effacement RGPD).
  Future<int> deleteByUserId(String userId) {
    return (delete(hikerProfile)..where((t) => t.userId.equals(userId))).go();
  }
}
