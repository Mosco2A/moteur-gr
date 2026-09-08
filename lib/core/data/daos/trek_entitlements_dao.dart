import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trek_entitlements_table.dart';

part 'trek_entitlements_dao.g.dart';

/// DAO des droits d'acces par sentier (StepWays LOT 1, wallet).
///
/// CRUD de base sur la table [TrekEntitlements] : lecture par [trailId],
/// lecture de l'ensemble, upsert et observation (`watch`). `owned` n'est cense
/// etre pose qu'a confirmation store (regle metier portee par
/// `MonetizationService`, ST4). La regle sans-pub #99404 derive de `owned`.
///
/// Upsert par cle primaire ([trailId]) via `insertOnConflictUpdate`
/// (idempotent : chaque ecriture ecrase la ligne de ce sentier).
@DriftAccessor(tables: [TrekEntitlements])
class TrekEntitlementsDao extends DatabaseAccessor<AppDatabase>
    with _$TrekEntitlementsDaoMixin {
  TrekEntitlementsDao(super.db);

  /// Relit le droit d'acces du sentier [trailId], ou null si absent.
  Future<TrekEntitlement?> getByTrailId(String trailId) {
    return (select(trekEntitlements)..where((t) => t.trailId.equals(trailId)))
        .getSingleOrNull();
  }

  /// Relit tous les droits d'acces connus.
  Future<List<TrekEntitlement>> getAll() {
    return select(trekEntitlements).get();
  }

  /// Observe le droit d'acces de [trailId] (emet a chaque modification).
  Stream<TrekEntitlement?> watchByTrailId(String trailId) {
    return (select(trekEntitlements)..where((t) => t.trailId.equals(trailId)))
        .watchSingleOrNull();
  }

  /// Cree ou met a jour le droit d'acces (upsert par [trailId]).
  Future<void> upsert(TrekEntitlementsCompanion entry) async {
    await into(trekEntitlements).insertOnConflictUpdate(entry);
  }

  /// Supprime le droit d'acces du sentier [trailId] (reset).
  Future<int> deleteByTrailId(String trailId) {
    return (delete(trekEntitlements)..where((t) => t.trailId.equals(trailId)))
        .go();
  }
}
