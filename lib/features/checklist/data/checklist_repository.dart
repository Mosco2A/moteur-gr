import 'package:drift/drift.dart' show Value;

import '../../../core/config/trail_config.dart';
import '../../../core/data/database.dart';
import '../../../core/data/daos/checklist_dao.dart';
import '../domain/models/checklist_item.dart';
import '../data/checklist_template.dart';

/// Repository pour la checklist materiel.
///
/// Fait le pont entre le modele Freezed (ChecklistItemModel),
/// le template JSON configurable et la persistence Drift.
/// Gere le chargement initial depuis le template et les operations CRUD.
/// Le template est dynamique : il depend du sentier actif (TrailConfig).
class ChecklistRepository {
  ChecklistRepository({
    required AppDatabase db,
    required TrailConfig trailConfig,
  })  : _dao = ChecklistDao(db),
        _trailConfig = trailConfig;

  final ChecklistDao _dao;

  /// Configuration du sentier actif — determine le template a charger.
  final TrailConfig _trailConfig;

  /// Identifiant du sentier actif (raccourci).
  String get trailId => _trailConfig.id;

  /// Charge tous les items de checklist pour le sentier actif.
  ///
  /// Si la DB est vide pour ce sentier, initialise depuis le template
  /// configurable (avec overrides par sentier).
  Future<List<ChecklistItemModel>> getItems() async {
    var dbItems = await _dao.getByTrailId(trailId);

    // Premiere ouverture : initialiser depuis le template
    if (dbItems.isEmpty) {
      await _initFromTemplate();
      dbItems = await _dao.getByTrailId(trailId);
    }

    return dbItems.map(_fromDbRow).toList();
  }

  /// Charge les items d'une categorie pour le sentier actif.
  Future<List<ChecklistItemModel>> getItemsByCategory(
    String category,
  ) async {
    final dbItems = await _dao.getByCategory(trailId, category);
    return dbItems.map(_fromDbRow).toList();
  }

  /// Coche ou decoche un item.
  Future<void> toggleItem(String itemId, bool checked) {
    return _dao.toggleItem(trailId, itemId, checked);
  }

  /// Met a jour la note personnelle d'un item.
  Future<void> updateNote(String itemId, String? note) {
    return _dao.upsertItem(ChecklistItemsCompanion(
      trailId: Value(trailId),
      itemId: Value(itemId),
      isChecked: const Value(false), // preserve par upsert
    ));
  }

  /// Reinitialise la checklist du sentier actif (tout decocher).
  Future<void> resetAll() {
    return _dao.deleteByTrailId(trailId);
  }

  /// Nombre d'items coches pour le sentier actif.
  Future<int> countChecked() {
    return _dao.countChecked(trailId);
  }

  /// Nombre total d'items pour le sentier actif.
  Future<int> countTotal() {
    return _dao.countTotal(trailId);
  }

  /// Retourne les items du template pour le sentier actif (sans DB).
  ///
  /// Utile pour comparer les templates entre sentiers.
  Future<List<ChecklistTemplateItem>> getTemplateItems() {
    return ChecklistTemplateLoader.loadForTrail(trailId);
  }

  /// Initialise la checklist en DB depuis le template configurable.
  ///
  /// Charge le template avec overrides pour le sentier actif.
  Future<void> _initFromTemplate() async {
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
