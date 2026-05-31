import 'package:drift/drift.dart' show Value;

import '../../../core/data/database.dart';
import '../../../core/data/daos/checklist_dao.dart';
import '../domain/models/checklist_item.dart';
import '../data/checklist_template.dart';

/// Repository pour la checklist materiel.
///
/// Fait le pont entre le modele Freezed (ChecklistItemModel),
/// le template JSON configurable et la persistence Drift.
/// Gere le chargement initial depuis le template et les operations CRUD.
class ChecklistRepository {
  ChecklistRepository({
    required AppDatabase db,
  }) : _dao = ChecklistDao(db);

  final ChecklistDao _dao;

  /// Charge tous les items de checklist pour un sentier.
  ///
  /// Si la DB est vide pour ce sentier, initialise depuis le template
  /// configurable (avec overrides par sentier).
  Future<List<ChecklistItemModel>> getItems(String trailId) async {
    var dbItems = await _dao.getByTrailId(trailId);

    // Premiere ouverture : initialiser depuis le template
    if (dbItems.isEmpty) {
      await _initFromTemplate(trailId);
      dbItems = await _dao.getByTrailId(trailId);
    }

    return dbItems.map(_fromDbRow).toList();
  }

  /// Charge les items d'une categorie pour un sentier.
  Future<List<ChecklistItemModel>> getItemsByCategory(
    String trailId,
    String category,
  ) async {
    final dbItems = await _dao.getByCategory(trailId, category);
    return dbItems.map(_fromDbRow).toList();
  }

  /// Coche ou decoche un item.
  Future<void> toggleItem(String trailId, String itemId, bool checked) {
    return _dao.toggleItem(trailId, itemId, checked);
  }

  /// Met a jour la note personnelle d'un item.
  Future<void> updateNote(String trailId, String itemId, String? note) {
    return _dao.upsertItem(ChecklistItemsCompanion(
      trailId: Value(trailId),
      itemId: Value(itemId),
      isChecked: const Value(false), // preserve par upsert
    ));
  }

  /// Reinitialise la checklist d'un sentier (tout decocher).
  Future<void> resetAll(String trailId) {
    return _dao.deleteByTrailId(trailId);
  }

  /// Nombre d'items coches pour un sentier.
  Future<int> countChecked(String trailId) {
    return _dao.countChecked(trailId);
  }

  /// Nombre total d'items pour un sentier.
  Future<int> countTotal(String trailId) {
    return _dao.countTotal(trailId);
  }

  /// Initialise la checklist en DB depuis le template configurable.
  ///
  /// Charge le template avec overrides pour le sentier donne.
  Future<void> _initFromTemplate(String trailId) async {
    final templateItems = await ChecklistTemplateLoader.loadForTrail(trailId);

    final entries = templateItems.map((item) {
      return ChecklistItemsCompanion(
        trailId: Value(trailId),
        itemId: Value(item.id),
        category: Value(item.category),
        isChecked: const Value(false),
      );
    }).toList();

    await _dao.insertAll(entries);
  }

  /// Convertit une ligne DB en modele Freezed.
  ChecklistItemModel _fromDbRow(ChecklistItem row) {
    return ChecklistItemModel(
      id: row.id,
      templateId: row.itemId,
      name: row.itemId, // Resolu en i18n par la couche presentation
      category: row.category,
      isChecked: row.isChecked,
      customNote: null, // Pas encore de colonne note en DB
    );
  }
}
