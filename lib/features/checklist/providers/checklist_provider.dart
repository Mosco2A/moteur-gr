import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/data/daos/checklist_dao.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../../feasibility/domain/hiker_input_bounds.dart';
import '../../notifications/providers/download_reminder_provider.dart';
import '../data/checklist_seasonal_adapter.dart';
import '../data/checklist_template.dart';
import '../domain/season.dart';

/// Poids corporel de reference par defaut (kg), parite GR20 « Materiel & Sac ».
///
/// Sert de denominateur au ratio sac/corps tant que l'utilisateur ne l'a pas
/// personnalise. Valeur neutre, non liee a un sentier (moteur generique).
const double kDefaultBodyWeightKg = 70.0;

/// Poids unitaire minimum d'un article (grammes).
const int kItemWeightMinGrams = 0;

/// Poids unitaire maximum d'un article (grammes) — 50 kg, au-dela ca ne tient
/// pas dans un sac a dos.
///
/// FIX-1 (finding M3) : cette borne existait deja mais s'appliquait en CLAMP
/// SILENCIEUX (99999999 g devenait 50000 g sans un mot). Elle est desormais
/// publique pour que l'ECRAN refuse la saisie avec un message borne AVANT
/// d'appeler le provider ; le clamp reste en dernier rempart.
const int kItemWeightMaxGrams = 50000;

/// Nombre max de chiffres saisissables pour un poids d'article (50000 g = 5
/// chiffres) : barriere PHYSIQUE a la saisie, qui rend impossible le
/// « 999999999999999999999 » du rapport personas (depassement 64 bits).
const int kItemWeightFieldMaxLength = 5;

/// Quantite minimum d'un article.
const int kItemQuantityMin = 1;

/// Quantite maximum d'un article.
///
/// FIX-1 (finding m4) : la quantite de session n'etait PAS bornee (40 appuis sur
/// « + » affichaient 40) alors que le rechargement depuis la DB clampait a 999 —
/// l'ecran et l'etat recharge divergeaient. Meme borne des deux cotes.
const int kItemQuantityMax = 999;

/// Etat de la checklist pour un sentier donne.
class ChecklistState {
  const ChecklistState({
    required this.items,
    required this.checkedCount,
    required this.totalCount,
    this.bodyWeightKg = kDefaultBodyWeightKg,
    this.isLoading = false,
    this.bagValidated = false,
    this.bodyWeightEdited = false,
  });

  /// Liste des items avec leur etat coche/decoche
  final List<ChecklistItemState> items;

  /// Nombre d'items coches
  final int checkedCount;

  /// Nombre total d'items
  final int totalCount;

  /// Poids corporel de l'utilisateur en kg (jauge sac/corps, parite GR20).
  ///
  /// LOT 1 (retour Chris #12) : SOURCE DE VERITE = le poids de la fiche profil
  /// (`hikerProfileProvider`). Il est injecte au chargement de l'ecran Sac
  /// ([seedBodyWeightFromProfile]) pour que « le poids du sac corresponde au
  /// poids defini dans les infos utilisateur ». La saisie manuelle du champ Sac
  /// reste possible (override de session) et prime alors ([bodyWeightEdited]).
  final double bodyWeightKg;

  /// Chargement en cours
  final bool isLoading;

  /// Sac valide par l'utilisateur (« SAC OK », parite GR20). Session courante.
  final bool bagValidated;

  /// Vrai si l'utilisateur a EDITE manuellement le poids corporel dans l'ecran
  /// Sac (LOT 1 #12). Empeche l'auto-injection du poids profil d'ecraser une
  /// saisie manuelle en cours de session.
  final bool bodyWeightEdited;

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

/// Saison de reference du Sac ADAPTATIF (StepWays LOT 5, sous-ensemble B).
///
/// Cle stable [Season] (winter/spring/summer/autumn), DERIVEE de la DATE DE
/// DEPART du Calendrier ([downloadReminderProvider]) — c'est la saison du trek
/// qui compte — avec repli sur la date du JOUR ([currentSeasonNow]) tant qu'aucun
/// depart n'est pose. N'est observee QUE par la section additive du Sac (l'ecran
/// a acces aux prefs) : le SOCLE du Sac (template de base, parite GR20) ne depend
/// PAS de cette source, il reste robuste sans prefs ni reseau.
final checklistSeasonFromDepartureProvider = Provider<String>((ref) {
  final trailId = ref.watch(trailIdProvider);
  final departure = ref.watch(downloadReminderProvider(trailId)).departureDate;
  return departure != null ? Season.fromDate(departure) : currentSeasonNow();
});

/// Suggestions saisonnieres du Sac (trek + saison de depart) — LOT 5 (B).
///
/// Articles pertinents a AJOUTER pour le sentier actif et la saison du depart
/// (ou du jour). Additif (section a part) : la liste de base reste intacte
/// (parite). Chargee depuis la donnee externalisee [ChecklistSeasonalAdapter].
final checklistSeasonalSuggestionsProvider =
    FutureProvider<List<ChecklistTemplateItem>>((ref) async {
  final trailId = ref.watch(trailIdProvider);
  final season = ref.watch(checklistSeasonFromDepartureProvider);
  return ChecklistSeasonalAdapter.seasonalItems(
    trailId: trailId,
    season: season,
  );
});

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

  /// Template de base (parite GR20 : 84 articles, ordre GR20). Le Sac ADAPTATIF
  /// (LOT 5, B) n'INJECTE PAS d'articles ici (sinon la parite casserait) : les
  /// suggestions saison/trek sont une SECTION additive a part
  /// ([ChecklistSeasonalSection]), ajoutables au sac a la demande (comptees dans
  /// la jauge une fois ajoutees, via le meme chemin que les articles custom).
  List<ChecklistTemplateItem> get _template => defaultChecklistTemplate;

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
      bodyWeightEdited: state.bodyWeightEdited,
    );
  }

  /// Fusionne template (articles standard, ordre GR20) + articles personnalises
  /// (lignes DB avec isCustom), parite GR20.
  List<ChecklistItemState> _buildItemStates(List<ChecklistItem> dbItems) {
    final itemStates = <ChecklistItemState>[];

    // Articles du template resolu (base GR20 + ajouts saison/trek), dans l'ordre
    // du template (parite : la base garde l'ordre GR20, les ajouts a la fin).
    for (final template in _template) {
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
    final templateIds = _template.map((t) => t.id).toSet();
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

  /// Initialise la checklist en DB depuis le template resolu (base + saison/trek).
  Future<void> _initFromTemplate(ChecklistDao dao) async {
    final entries = _template.map((item) {
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
      bodyWeightEdited: state.bodyWeightEdited,
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
  /// Borne a [kItemWeightMinGrams, kItemWeightMaxGrams] g — DERNIER REMPART :
  /// depuis FIX-1 (M3), l'ecran refuse la saisie hors bornes avec un message
  /// avant d'arriver ici, donc ce clamp ne doit plus jamais mentir a personne.
  Future<void> setItemWeight(String itemId, int weightGrams) async {
    final clamped =
        weightGrams.clamp(kItemWeightMinGrams, kItemWeightMaxGrams);
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
  ///  - sinon -> appliquer la nouvelle quantite, BORNEE a [kItemQuantityMax]
  ///    (FIX-1 / m4 : meme borne qu'au rechargement, l'affichage ne peut plus
  ///    diverger de l'etat recharge).
  Future<void> setItemQuantity(String itemId, int newQuantity) async {
    final item = state.items.firstWhere((i) => i.template.id == itemId);

    int quantity;
    bool isChecked;
    if (newQuantity < kItemQuantityMin) {
      isChecked = false;
      quantity = kItemQuantityMin;
    } else if (!item.isChecked) {
      isChecked = true;
      quantity = kItemQuantityMin;
    } else {
      isChecked = true;
      quantity = newQuantity.clamp(kItemQuantityMin, kItemQuantityMax);
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
    // Dernier rempart (voir [setItemWeight]) : l'ecran valide et refuse avec un
    // message avant d'en arriver la (FIX-1 / M3).
    final clampedWeight =
        weightGrams.clamp(kItemWeightMinGrams, kItemWeightMaxGrams);
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

  /// Ajoute au sac un article SUGGERE (Sac adaptatif saison/trek, LOT 5, B).
  ///
  /// Reutilise le chemin des articles custom ([addCustomItem]) — l'article
  /// ajoute est coche et COMPTE donc dans la jauge (« jauge adaptee »).
  /// IDEMPOTENT : si un article du meme nom est deja au sac, ne fait rien
  /// (evite les doublons quand on retape la suggestion). Retourne true si ajout.
  Future<bool> addSuggestedItem({
    required String category,
    required String name,
    required int weightGrams,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final already = state.items.any(
      (i) => i.isCustom && (i.customName?.trim() == trimmed),
    );
    if (already) return false;
    await addCustomItem(category, trimmed, weightGrams);
    return true;
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
  /// Saisie MANUELLE dans l'ecran Sac : marque [ChecklistState.bodyWeightEdited]
  /// pour que l'auto-injection du poids profil (LOT 1 #12) ne l'ecrase plus
  /// ensuite. Session courante uniquement (comme GR20 : non persiste).
  ///
  /// FIX-1 (finding B1, BLOQUANT) : le seul garde-fou etait `kg <= 0`, ce qui
  /// laissait passer 1e9 et surtout `Infinity` (`double.tryParse('Infinity')`),
  /// affiche tel quel dans le bandeau. Toute valeur non finie ou hors
  /// [kWeightMinKg]..[kWeightMaxKg] est desormais IGNOREE : la jauge conserve le
  /// dernier poids valide (l'ecran, lui, affiche le message borne).
  void setBodyWeight(double kg) {
    if (!isValidBodyWeightKg(kg)) return;
    state = ChecklistState(
      items: state.items,
      checkedCount: state.checkedCount,
      totalCount: state.totalCount,
      bodyWeightKg: kg,
      bagValidated: state.bagValidated,
      bodyWeightEdited: true,
    );
  }

  /// Injecte le poids corporel depuis la FICHE PROFIL (LOT 1, retour Chris #12).
  ///
  /// Rend le poids du sac coherent avec « le poids defini dans les infos
  /// utilisateur » : une seule source de verite (la morpho). Appelee par l'ecran
  /// Sac quand la fiche profil expose un poids valide. N'ECRASE PAS une saisie
  /// manuelle de session ([ChecklistState.bodyWeightEdited]) ni une valeur
  /// identique (evite un rebuild inutile). Session courante (non persiste, comme
  /// GR20) : le champ profil reste la source durable.
  void seedBodyWeightFromProfile(double kg) {
    // Meme regle que la saisie manuelle (FIX-1 / B1) : la source profil est
    // deja bornee [kWeightMinKg..kWeightMaxKg], ce garde-fou empeche toute
    // valeur absurde d'entrer par une autre porte (donnee migree, miroir cloud
    // corrompu).
    if (!isValidBodyWeightKg(kg)) return;
    if (state.bodyWeightEdited) return;
    if (state.bodyWeightKg == kg) return;
    state = ChecklistState(
      items: state.items,
      checkedCount: state.checkedCount,
      totalCount: state.totalCount,
      bodyWeightKg: kg,
      bagValidated: state.bagValidated,
      bodyWeightEdited: false,
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
      bodyWeightEdited: state.bodyWeightEdited,
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
      bodyWeightEdited: state.bodyWeightEdited,
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
