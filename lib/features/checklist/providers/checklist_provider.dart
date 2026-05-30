import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/data/daos/checklist_dao.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../data/checklist_template.dart';

/// Etat de la checklist pour un sentier donne.
class ChecklistState {
  const ChecklistState({
    required this.items,
    required this.checkedCount,
    required this.totalCount,
    this.isLoading = false,
  });

  /// Liste des items avec leur etat coche/decoche
  final List<ChecklistItemState> items;

  /// Nombre d'items coches
  final int checkedCount;

  /// Nombre total d'items
  final int totalCount;

  /// Chargement en cours
  final bool isLoading;

  /// Progression en pourcentage (0.0 a 1.0)
  double get progress => totalCount > 0 ? checkedCount / totalCount : 0.0;

  /// Checklist complete
  bool get isComplete => checkedCount == totalCount && totalCount > 0;

  /// Etat initial vide
  static const empty = ChecklistState(
    items: [],
    checkedCount: 0,
    totalCount: 0,
    isLoading: true,
  );
}

/// Etat d'un item de checklist individuel.
class ChecklistItemState {
  const ChecklistItemState({
    required this.template,
    required this.isChecked,
  });

  /// Template de l'item (donnees statiques)
  final ChecklistTemplateItem template;

  /// Item coche ou non (etat persistant)
  final bool isChecked;
}

/// Provider de la checklist materiel pour le sentier actif.
///
/// Charge le template par defaut + l'etat persiste en DB.
/// Chaque toggle est sauvegarde immediatement en Drift.
final checklistProvider =
    NotifierProvider<ChecklistNotifier, ChecklistState>(ChecklistNotifier.new);

/// Notifier qui gere l'etat de la checklist materiel.
class ChecklistNotifier extends Notifier<ChecklistState> {
  @override
  ChecklistState build() {
    final db = ref.watch(databaseProvider);
    final trailId = ref.watch(trailIdProvider);
    _db = db;
    _trailId = trailId;
    _load();
    return ChecklistState.empty;
  }

  late AppDatabase _db;
  late String _trailId;

  /// Charge l'etat de la checklist depuis la DB.
  /// Si la DB est vide, initialise depuis le template.
  Future<void> _load() async {
    state = ChecklistState.empty;

    final dao = ChecklistDao(_db);
    var dbItems = await dao.getByTrailId(_trailId);

    // Premiere ouverture : initialiser depuis le template
    if (dbItems.isEmpty) {
      await _initFromTemplate(dao);
      dbItems = await dao.getByTrailId(_trailId);
    }

    // Construire l'etat combine (template + DB)
    final itemStates = <ChecklistItemState>[];
    for (final template in defaultChecklistTemplate) {
      final dbMatch = dbItems.where((i) => i.itemId == template.id);
      final isChecked = dbMatch.isNotEmpty && dbMatch.first.isChecked;
      itemStates.add(ChecklistItemState(
        template: template,
        isChecked: isChecked,
      ));
    }

    final checked = itemStates.where((i) => i.isChecked).length;
    state = ChecklistState(
      items: itemStates,
      checkedCount: checked,
      totalCount: itemStates.length,
    );
  }

  /// Initialise la checklist en DB depuis le template.
  Future<void> _initFromTemplate(ChecklistDao dao) async {
    final entries = defaultChecklistTemplate.map((item) {
      return ChecklistItemsCompanion(
        trailId: Value(_trailId),
        itemId: Value(item.id),
        category: Value(item.category),
        isChecked: const Value(false),
      );
    }).toList();
    await dao.insertAll(entries);
  }

  /// Coche ou decoche un item et persiste en DB.
  Future<void> toggle(String itemId) async {
    final dao = ChecklistDao(_db);
    final currentItem = state.items.firstWhere(
      (i) => i.template.id == itemId,
    );
    final newChecked = !currentItem.isChecked;

    await dao.toggleItem(_trailId, itemId, newChecked);

    // Mettre a jour l'etat local sans recharger
    final updatedItems = state.items.map((item) {
      if (item.template.id == itemId) {
        return ChecklistItemState(
          template: item.template,
          isChecked: newChecked,
        );
      }
      return item;
    }).toList();

    final checked = updatedItems.where((i) => i.isChecked).length;
    state = ChecklistState(
      items: updatedItems,
      checkedCount: checked,
      totalCount: updatedItems.length,
    );
  }

  /// Reinitialise toute la checklist (tout decocher).
  Future<void> resetAll() async {
    final dao = ChecklistDao(_db);
    await dao.deleteByTrailId(_trailId);
    await _load();
  }
}

/// Provider filtrant les items par categorie.
final checklistByCategoryProvider =
    Provider.family<List<ChecklistItemState>, String>((ref, category) {
  final checklistState = ref.watch(checklistProvider);
  return checklistState.items
      .where((item) => item.template.category == category)
      .toList();
});
