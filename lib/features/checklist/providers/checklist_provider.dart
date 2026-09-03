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
    this.bagValidated = false,
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

  /// Sac valide par l'utilisateur (« SAC OK », parite GR20). Session courante.
  final bool bagValidated;

  /// Progression en pourcentage (0.0 a 1.0)
  double get progress => totalCount > 0 ? checkedCount / totalCount : 0.0;

  /// Checklist complete
  bool get isComplete => checkedCount == totalCount && totalCount > 0;

  /// Poids total du sac en grammes = somme des articles COCHES, quantite
  /// comprise (parite GR20 : total = poids unitaire * quantite).
  int get checkedWeightGrams => items
      .where((i) => i.isChecked)
      .fold(0, (sum, i) => sum + i.totalWeightGrams);

  /// Poids total du sac en kg.
  double get checkedWeightKg => checkedWeightGrams / 1000.0;

  /// Ratio poids du sac / poids corporel (0 si poids corporel invalide).
  double get backpackRatio =>
      bodyWeightKg > 0 ? checkedWeightKg / bodyWeightKg : 0.0;

  /// Nombre d'articles dans la liste de courses (parite GR20).
  int get shoppingListCount =>
      items.where((i) => i.inShoppingList).length;

  /// Nombre d'articles obligatoires (requirement == required, parite GR20).
  int get requiredCount => items
      .where((i) => i.template.requirement == ChecklistRequirement.required)
      .length;

  /// Nombre d'articles obligatoires COCHES (parite GR20 « SAC OK »).
  int get requiredCheckedCount => items
      .where((i) =>
          i.template.requirement == ChecklistRequirement.required &&
          i.isChecked)
      .length;

  /// Tous les articles obligatoires sont coches (parite GR20).
  bool get allRequiredChecked =>
      requiredCount > 0 && requiredCheckedCount == requiredCount;

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
    this.quantity = 1,
    this.isCustom = false,
    this.inShoppingList = false,
    this.customName,
  });

  /// Template de l'item (donnees statiques : id, categorie, exigence...).
  final ChecklistTemplateItem template;

  /// Item coche ou non (etat persistant)
  final bool isChecked;

  /// Poids unitaire courant en grammes (persistant, editable, parite GR20).
  final int weightGrams;

  /// Quantite courante (min 1, parite GR20).
  final int quantity;

  /// Article personnalise (ajoute par l'utilisateur), parite GR20.
  final bool isCustom;

  /// Article present dans la liste de courses (parite GR20).
  final bool inShoppingList;

  /// Nom d'un article personnalise (null pour un article du template : le nom
  /// est alors resolu via i18n depuis [template.nameKey]).
  final String? customName;

  /// Poids total de l'article = poids unitaire * quantite (parite GR20).
  int get totalWeightGrams => weightGrams * quantity;

  ChecklistItemState copyWith({
    bool? isChecked,
    int? weightGrams,
    int? quantity,
    bool? inShoppingList,
    String? customName,
  }) {
    return ChecklistItemState(
      template: template,
      isChecked: isChecked ?? this.isChecked,
      weightGrams: weightGrams ?? this.weightGrams,
      quantity: quantity ?? this.quantity,
      isCustom: isCustom,
      inShoppingList: inShoppingList ?? this.inShoppingList,
      customName: customName ?? this.customName,
    );
  }
}

/// Provider de la checklist materiel pour le sentier actif.
///
/// Charge le template par defaut + l'etat persiste en DB.
/// Chaque toggle est sauvegarde immediatement en Drift.
final checklistProvider =
    NotifierProvider<ChecklistNotifier, ChecklistState>(ChecklistNotifier.new);

/// Notifier qui gere l'etat de la checklist materiel (parite GR20).
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

    final itemStates = _buildItemStates(dbItems);

    final checked = itemStates.where((i) => i.isChecked).length;
    state = ChecklistState(
      items: itemStates,
      checkedCount: checked,
      totalCount: itemStates.length,
      bodyWeightKg: state.bodyWeightKg,
      bagValidated: state.bagValidated,
    );
  }

  /// Fusionne template (articles standard, ordre GR20) + articles personnalises
  /// (lignes DB avec isCustom), parite GR20.
  List<ChecklistItemState> _buildItemStates(List<ChecklistItem> dbItems) {
    final itemStates = <ChecklistItemState>[];

    // Articles du template, dans l'ordre du template (= ordre GR20).
    for (final template in defaultChecklistTemplate) {
      final dbMatch = dbItems.where((i) => i.itemId == template.id);
      final hasRow = dbMatch.isNotEmpty;
      final row = hasRow ? dbMatch.first : null;
      itemStates.add(ChecklistItemState(
        template: template,
        isChecked: row?.isChecked ?? false,
        // Poids courant = valeur persistee si la ligne existe, sinon le poids
        // de reference du template (parite GR20 : sac pre-rempli).
        weightGrams: row?.weightGrams ?? template.weightGrams,
        quantity: (row?.quantity ?? template.quantity).clamp(1, 999),
        inShoppingList: row?.inShoppingList ?? false,
      ));
    }

    // Articles personnalises (isCustom en DB, non presents dans le template).
    final templateIds =
        defaultChecklistTemplate.map((t) => t.id).toSet();
    for (final row in dbItems) {
      if (!row.isCustom || templateIds.contains(row.itemId)) continue;
      final customTemplate = ChecklistTemplateItem(
        id: row.itemId,
        category: row.category,
        nameKey: row.itemId,
        weightGrams: row.weightGrams,
        quantity: row.quantity,
      );
      itemStates.add(ChecklistItemState(
        template: customTemplate,
        isChecked: row.isChecked,
        weightGrams: row.weightGrams,
        quantity: row.quantity.clamp(1, 999),
        isCustom: true,
        inShoppingList: row.inShoppingList,
        customName: row.customName ?? row.itemId,
      ));
    }

    return itemStates;
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
        quantity: Value(item.quantity),
      );
    }).toList();
    await dao.insertAll(entries);
  }

  /// Recalcule les compteurs et pousse un nouvel etat a partir d'items donnes.
  void _emit(List<ChecklistItemState> items) {
    final checked = items.where((i) => i.isChecked).length;
    state = ChecklistState(
      items: items,
      checkedCount: checked,
      totalCount: items.length,
      bodyWeightKg: state.bodyWeightKg,
      bagValidated: state.bagValidated,
    );
  }

  List<ChecklistItemState> _mapItem(
    String itemId,
    ChecklistItemState Function(ChecklistItemState) transform,
  ) {
    return state.items
        .map((i) => i.template.id == itemId ? transform(i) : i)
        .toList();
  }

  /// Coche ou decoche un item et persiste en DB (parite GR20).
  Future<void> toggle(String itemId) async {
    final dao = ChecklistDao(_db);
    final currentItem =
        state.items.firstWhere((i) => i.template.id == itemId);
    final newChecked = !currentItem.isChecked;

    await dao.toggleItem(_trailId, itemId, newChecked);
    _emit(_mapItem(itemId, (i) => i.copyWith(isChecked: newChecked)));
  }

  /// Force le decochage d'un article (parite GR20 : apres confirmation du
  /// garde-fou sur un article obligatoire).
  Future<void> forceUncheck(String itemId) async {
    final dao = ChecklistDao(_db);
    await dao.toggleItem(_trailId, itemId, false);
    _emit(_mapItem(itemId, (i) => i.copyWith(isChecked: false)));
  }

  /// Met a jour le poids unitaire d'un item (grammes) et persiste (parite GR20).
  ///
  /// Borne a [0, 50000] g. Recalcule le total via l'etat derive.
  Future<void> setItemWeight(String itemId, int weightGrams) async {
    final clamped = weightGrams.clamp(0, 50000);
    final dao = ChecklistDao(_db);
    await dao.setWeight(_trailId, itemId, clamped);
    _emit(_mapItem(itemId, (i) => i.copyWith(weightGrams: clamped)));
  }

  /// Met a jour la quantite d'un article et persiste (parite GR20).
  ///
  /// Regles GR20 :
  ///  - quantite < 1 -> decocher l'article et remettre la quantite a 1
  ///    (B-06a) ;
  ///  - article non coche et on augmente -> selectionner a quantite 1 sans
  ///    incrementer (B143) ;
  ///  - sinon -> appliquer la nouvelle quantite.
  Future<void> setItemQuantity(String itemId, int newQuantity) async {
    final item = state.items.firstWhere((i) => i.template.id == itemId);

    int quantity;
    bool isChecked;
    if (newQuantity < 1) {
      isChecked = false;
      quantity = 1;
    } else if (!item.isChecked) {
      isChecked = true;
      quantity = 1;
    } else {
      isChecked = true;
      quantity = newQuantity;
    }

    final dao = ChecklistDao(_db);
    await dao.setQuantityAndChecked(_trailId, itemId, quantity, isChecked);
    _emit(_mapItem(
        itemId, (i) => i.copyWith(quantity: quantity, isChecked: isChecked)));
  }

  /// Ajoute / retire un article de la liste de courses et persiste (parite
  /// GR20).
  Future<void> toggleShoppingList(String itemId) async {
    final item = state.items.firstWhere((i) => i.template.id == itemId);
    final next = !item.inShoppingList;
    final dao = ChecklistDao(_db);
    await dao.setInShoppingList(_trailId, itemId, next);
    _emit(_mapItem(itemId, (i) => i.copyWith(inShoppingList: next)));
  }

  /// Ajoute un article personnalise dans une categorie et persiste (parite
  /// GR20 « Ajouter un item »). L'article est coche a la creation.
  Future<void> addCustomItem(
    String category,
    String name,
    int weightGrams,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final clampedWeight = weightGrams.clamp(0, 50000);
    final customId = 'custom_${DateTime.now().microsecondsSinceEpoch}';

    final dao = ChecklistDao(_db);
    await dao.insertCustomItem(
      trailId: _trailId,
      itemId: customId,
      category: category,
      name: trimmed,
      weightGrams: clampedWeight,
    );

    final customTemplate = ChecklistTemplateItem(
      id: customId,
      category: category,
      nameKey: customId,
      weightGrams: clampedWeight,
    );
    final newItem = ChecklistItemState(
      template: customTemplate,
      isChecked: true,
      weightGrams: clampedWeight,
      quantity: 1,
      isCustom: true,
      customName: trimmed,
    );
    _emit([...state.items, newItem]);
  }

  /// Met a jour le nom d'un article personnalise et persiste (parite GR20).
  /// Sans effet sur les articles du template (nom en lecture seule).
  Future<void> setCustomName(String itemId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final item = state.items.firstWhere((i) => i.template.id == itemId);
    if (!item.isCustom) return;

    final dao = ChecklistDao(_db);
    await dao.setCustomName(_trailId, itemId, trimmed);
    _emit(_mapItem(itemId, (i) => i.copyWith(customName: trimmed)));
  }

  /// Supprime un article personnalise et persiste (parite GR20). Garde-fou :
  /// ne supprime jamais un article du template.
  Future<void> deleteCustomItem(String itemId) async {
    final item = state.items.firstWhere((i) => i.template.id == itemId);
    if (!item.isCustom) return;

    final dao = ChecklistDao(_db);
    await dao.deleteCustomItem(_trailId, itemId);
    _emit(state.items.where((i) => i.template.id != itemId).toList());
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
      bagValidated: state.bagValidated,
    );
  }

  /// Marque le sac comme valide (« SAC OK », parite GR20). Session courante.
  void validateBag() {
    state = ChecklistState(
      items: state.items,
      checkedCount: state.checkedCount,
      totalCount: state.totalCount,
      bodyWeightKg: state.bodyWeightKg,
      bagValidated: true,
    );
  }

  /// Annule la validation du sac (parite GR20 « ANNULER LA VALIDATION »).
  void cancelValidation() {
    state = ChecklistState(
      items: state.items,
      checkedCount: state.checkedCount,
      totalCount: state.totalCount,
      bodyWeightKg: state.bodyWeightKg,
      bagValidated: false,
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
