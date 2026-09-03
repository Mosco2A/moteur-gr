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

  /// Met a jour le poids unitaire (grammes) d'un item (parite GR20 « Sac »).
  Future<void> setWeight(String trailId, String itemId, int weightGrams) {
    return (update(checklistItems)
          ..where(
              (t) => t.trailId.equals(trailId) & t.itemId.equals(itemId)))
        .write(ChecklistItemsCompanion(
      weightGrams: Value(weightGrams),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Met a jour la quantite d'un article (parite GR20). Persiste aussi l'etat
  /// coche (la logique GR20 coche/decoche selon la quantite).
  Future<void> setQuantityAndChecked(
    String trailId,
    String itemId,
    int quantity,
    bool isChecked,
  ) {
    return (update(checklistItems)
          ..where(
              (t) => t.trailId.equals(trailId) & t.itemId.equals(itemId)))
        .write(ChecklistItemsCompanion(
      quantity: Value(quantity),
      isChecked: Value(isChecked),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Ajoute ou retire un article de la liste de courses (parite GR20).
  Future<void> setInShoppingList(
    String trailId,
    String itemId,
    bool inShoppingList,
  ) {
    return (update(checklistItems)
          ..where(
              (t) => t.trailId.equals(trailId) & t.itemId.equals(itemId)))
        .write(ChecklistItemsCompanion(
      inShoppingList: Value(inShoppingList),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Met a jour le nom d'un article personnalise (parite GR20).
  Future<void> setCustomName(String trailId, String itemId, String name) {
    return (update(checklistItems)
          ..where(
              (t) => t.trailId.equals(trailId) & t.itemId.equals(itemId)))
        .write(ChecklistItemsCompanion(
      customName: Value(name),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Insere un article personnalise (parite GR20 « Ajouter un item »).
  ///
  /// L'article est coche a la creation (comme GR20).
  Future<void> insertCustomItem({
    required String trailId,
    required String itemId,
    required String category,
    required String name,
    required int weightGrams,
  }) async {
    await into(checklistItems).insert(ChecklistItemsCompanion(
      trailId: Value(trailId),
      itemId: Value(itemId),
      category: Value(category),
      isChecked: const Value(true),
      weightGrams: Value(weightGrams),
      quantity: const Value(1),
      isCustom: const Value(true),
      customName: Value(name),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Supprime un article personnalise (parite GR20). Ne touche jamais aux
  /// articles du template (garde-fou : filtre sur isCustom).
  Future<int> deleteCustomItem(String trailId, String itemId) {
    return (delete(checklistItems)
          ..where((t) =>
              t.trailId.equals(trailId) &
              t.itemId.equals(itemId) &
              t.isCustom.equals(true)))
        .go();
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
