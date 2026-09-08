import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/wallet_balance_table.dart';

part 'wallet_dao.g.dart';

/// DAO du solde du compte-etapes (StepWays LOT 1, wallet).
///
/// CRUD de base sur la table [WalletBalance] : lecture, upsert et observation
/// (`watch`) du solde d'un [userId] (hash SHA-256 deterministe). Le schema
/// Drift est CANONIQUE ; la persistance durable reste SharedPreferences
/// (hydratation au boot par la couche `WalletStore`, ST2).
///
/// Upsert par cle primaire ([userId]) via `insertOnConflictUpdate`
/// (idempotent : chaque ecriture ecrase la ligne de cet utilisateur).
@DriftAccessor(tables: [WalletBalance])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  /// Relit le solde de [userId], ou null si absent.
  Future<WalletBalanceData?> getByUserId(String userId) {
    return (select(walletBalance)..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Observe le solde de [userId] (emet a chaque modification, null si absent).
  Stream<WalletBalanceData?> watchByUserId(String userId) {
    return (select(walletBalance)..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull();
  }

  /// Cree ou met a jour le solde (upsert par [userId]).
  Future<void> upsert(WalletBalanceCompanion entry) async {
    await into(walletBalance).insertOnConflictUpdate(entry);
  }

  /// Supprime le solde de [userId] (reset).
  Future<int> deleteByUserId(String userId) {
    return (delete(walletBalance)..where((t) => t.userId.equals(userId))).go();
  }
}
