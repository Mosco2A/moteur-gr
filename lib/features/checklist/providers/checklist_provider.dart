import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/data/daos/checklist_dao.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../data/checklist_template.dart';

/// Poids corporel de reference par defaut (kg), parite GR20 « Materiel & Sac ».
///
/// Sert de denominateur au ratio sac/corps tant que l'utilisateur ne l'a pas
/// personnalise. Valeur neutre, non liee a un sentier (moteur generique).
const double kDefaultBodyWeightKg = 70.0;

/// Etat de la checklist pour un sentier donne.
class ChecklistState {
  const ChecklistState({
    required this.items,
    required this.checkedCount,
    required this.totalCount,
    this.bodyWeightKg = kDefaultBodyWeightKg,
    this.isLoading = false,
  });

  /// Liste des items avec leur etat coche/decoche
  final List<ChecklistItemState> items;

  /// Nombre d'items coches
  final int checkedCount;

  /// Nombre total d'items
  final int totalCount;

  /// Poids corporel de l'utilisateur en kg (jauge sac/corps, parite GR20).
  final double bodyWeightKg;

  /// Chargement en cours
  final bool isLoading;

  /// Progression en pourcentage (0.0 a 1.0)
  double get progress => totalCount > 0 ? checkedCount / totalCount : 0.0;

  /// Checklist complete
  bool get isComplete => checkedCount == totalCount && totalCount > 0;

  /// Poids total du sac en grammes = somme des items COCHES (parite GR20).
  int get checkedWeightGrams => items
      .where((i) => i.isChecked)
      .fold(0, (sum, i) => sum + i.weightGrams);

  /// Poids total du sac en kg.
  double get checkedWeightKg => checkedWeightGrams / 1000.0;

  /// Ratio poids du sac / poids corporel (0 si poids corporel invalide).
  double get backpackRatio =>
      bodyWeightKg > 0 ? checkedWeightKg / bodyWeightKg : 0.0;

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
    required this.weightGrams,
  });

  /// Template de l'item (donnees statiques)
  final ChecklistTemplateItem template;

  /// Item coche ou non (etat persistant)
  final bool isChecked;

  /// Poids unitaire courant en grammes (persistant, editable, parite GR20).
  final int weightGrams;
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
    final db = ref.read(databaseProvider);
    final trailId = ref.read(trailIdProvider);
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
      final hasRow = dbMatch.isNotEmpty;
      final isChecked = hasRow && dbMatch.first.isChecked;
      // Poids courant = valeur persistee si la ligne existe, sinon le poids de
      // reference du template (parite GR20 : le sac est pre-rempli des poids
      // moyens, l'utilisateur ajuste ensuite).
      final weightGrams =
          hasRow ? dbMatch.first.weightGrams : template.weightGrams;
      itemStates.add(ChecklistItemState(
        template: template,
        isChecked: isChecked,
        weightGrams: weightGrams,
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
        // Poids de reference du template (parite GR20). Editable ensuite.
        weightGrams: Value(item.weightGrams),
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
          weightGrams: item.weightGrams,
        );
      }
      return item;
    }).toList();

    final checked = updatedItems.where((i) => i.isChecked).length;
    state = ChecklistState(
      items: updatedItems,
      checkedCount: checked,
      totalCount: updatedItems.length,
      bodyWeightKg: state.bodyWeightKg,
    );
  }

  /// Met a jour le poids unitaire d'un item (grammes) et persiste (parite GR20).
  ///
  /// Le poids est borne a [0, 50000] g (garde-fou de saisie). Recalcule le
  /// total via l'etat derive [ChecklistState.checkedWeightGrams].
  Future<void> setItemWeight(String itemId, int weightGrams) async {
    final clamped = weightGrams.clamp(0, 50000);
    final dao = ChecklistDao(_db);
    await dao.setWeight(_trailId, itemId, clamped);

    final updatedItems = state.items.map((item) {
      if (item.template.id == itemId) {
        return ChecklistItemState(
          template: item.template,
          isChecked: item.isChecked,
          weightGrams: clamped,
        );
      }
      return item;
    }).toList();

    state = ChecklistState(
      items: updatedItems,
      checkedCount: state.checkedCount,
      totalCount: state.totalCount,
      bodyWeightKg: state.bodyWeightKg,
    );
  }

  /// Met a jour le poids corporel (kg) pour la jauge sac/corps (parite GR20).
  ///
  /// Session courante uniquement (comme GR20 : non persiste). Ignore les
  /// valeurs <= 0 (garde-fou).
  void setBodyWeight(double kg) {
    if (kg <= 0) return;
    state = ChecklistState(
      items: state.items,
      checkedCount: state.checkedCount,
      totalCount: state.totalCount,
      bodyWeightKg: kg,
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
