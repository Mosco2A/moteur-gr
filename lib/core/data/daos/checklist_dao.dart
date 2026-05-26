import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/checklist_items_table.dart';

part 'checklist_dao.g.dart';

/// DAO pour les operations sur la checklist materiel.
///
/// Fournit les methodes CRUD pour la table ChecklistItems,
/// filtrees par sentier et/ou categorie.
@DriftAccessor(tables: [ChecklistItems])
class ChecklistDao extends DatabaseAccessor<AppDatabase>
    with _$ChecklistDaoMixin {
  ChecklistDao(super.db);

  /// Recupere tous les items de checklist pour un sentier
  Future<List<ChecklistItem>> getByTrailId(String trailId) {
    return (select(checklistItems)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([(t) => OrderingTerm.asc(t.category)]))
        .get();
  }

  /// Recupere les items d'une categorie pour un sentier
  Future<List<ChecklistItem>> getByCategory(
      String trailId, String category) {
    return (select(checklistItems)
          ..where((t) =>
              t.trailId.equals(trailId) & t.category.equals(category)))
        .get();
  }

  /// Insere ou met a jour un item (upsert par trailId + itemId)
  Future<void> upsertItem(ChecklistItemsCompanion entry) async {
    final existing = await (select(checklistItems)
          ..where((t) =>
              t.trailId.equals(entry.trailId.value) &
              t.itemId.equals(entry.itemId.value)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(checklistItems)
            ..where((t) => t.id.equals(existing.id)))
          .write(entry);
    } else {
      await into(checklistItems).insert(entry);
    }
  }

  /// Coche ou decoche un item
  Future<void> toggleItem(String trailId, String itemId, bool checked) {
    return (update(checklistItems)
          ..where(
              (t) => t.trailId.equals(trailId) & t.itemId.equals(itemId)))
        .write(ChecklistItemsCompanion(
      isChecked: Value(checked),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Insere une liste d'items en batch
  Future<void> insertAll(List<ChecklistItemsCompanion> entries) async {
    await batch((b) => b.insertAll(checklistItems, entries));
  }

  /// Supprime tous les items d'un sentier
  Future<int> deleteByTrailId(String trailId) {
    return (delete(checklistItems)
          ..where((t) => t.trailId.equals(trailId)))
        .go();
  }

  /// Compte les items coches pour un sentier
  Future<int> countChecked(String trailId) async {
    final items = await getByTrailId(trailId);
    return items.where((i) => i.isChecked).length;
  }

  /// Compte le total d'items pour un sentier
  Future<int> countTotal(String trailId) async {
    final items = await getByTrailId(trailId);
    return items.length;
  }
}
