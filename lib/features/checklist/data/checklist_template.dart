import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Template de checklist materiel pour la randonnee.
///
/// Donnees statiques embarquees — pas de reseau necessaire.
/// Chaque item a un identifiant unique, une categorie,
/// un nom i18n-ready et un flag "essentiel".
/// Configurable par sentier via assets/data/checklist_template.json.
class ChecklistTemplateItem {
  const ChecklistTemplateItem({
    required this.id,
    required this.category,
    required this.nameKey,
    this.isEssential = false,
  });

  /// Identifiant unique de l'item (ex: 'backpack')
  final String id;

  /// Categorie (ex: 'equipment', 'clothing', 'food', 'safety', 'documents', 'hygiene')
  final String category;

  /// Cle i18n pour le nom de l'item (resolu via les traductions)
  final String nameKey;

  /// Item indispensable (marque visuellement)
  final bool isEssential;

  /// Construit depuis un JSON
  factory ChecklistTemplateItem.fromJson(Map<String, dynamic> json) {
    return ChecklistTemplateItem(
      id: json['id'] as String,
      category: json['category'] as String,
      nameKey: json['nameKey'] as String,
      isEssential: json['isEssential'] as bool? ?? false,
    );
  }

  /// Serialise en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'nameKey': nameKey,
      'isEssential': isEssential,
    };
  }
}

/// Overrides specifiques a un sentier.
///
/// Permet d'ajouter/retirer des items et de changer le flag essentiel
/// par sentier (ex: crampons obligatoires sur certains sentiers alpins).
class TrailChecklistOverride {
  const TrailChecklistOverride({
    this.addItems = const [],
    this.removeItems = const [],
    this.essentialOverrides = const {},
  });

  /// Items supplementaires pour ce sentier
  final List<ChecklistTemplateItem> addItems;

  /// IDs d'items a retirer pour ce sentier
  final List<String> removeItems;

  /// Surcharge du flag essentiel (itemId -> isEssential)
  final Map<String, bool> essentialOverrides;

  /// Construit depuis un JSON
  factory TrailChecklistOverride.fromJson(Map<String, dynamic> json) {
    final addItemsList = (json['addItems'] as List<dynamic>?)
            ?.map((e) =>
                ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final removeList = (json['removeItems'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final essentials = (json['essentialOverrides'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as bool)) ??
        {};
    return TrailChecklistOverride(
      addItems: addItemsList,
      removeItems: removeList,
      essentialOverrides: essentials,
    );
  }
}

/// Charge et resout le template de checklist pour un sentier donne.
///
/// Lit le JSON embarque dans assets/data/checklist_template.json,
/// applique les overrides du sentier, et retourne la liste finale.
class ChecklistTemplateLoader {
  /// Cache du JSON parse (charge une seule fois)
  static Map<String, dynamic>? _cachedJson;

  /// Charge le template JSON depuis les assets (avec cache).
  static Future<Map<String, dynamic>> _loadJson() async {
    if (_cachedJson != null) return _cachedJson!;
    final raw =
        await rootBundle.loadString('assets/data/checklist_template.json');
    _cachedJson = json.decode(raw) as Map<String, dynamic>;
    return _cachedJson!;
  }

  /// Retourne la liste d'items resolue pour un sentier.
  ///
  /// Applique les overrides du sentier (ajout/retrait/essentiel).
  /// Si pas d'override pour ce sentier, retourne le template par defaut.
  static Future<List<ChecklistTemplateItem>> loadForTrail(
      String trailId) async {
    final data = await _loadJson();
    final defaultData = data['defaultTemplate'] as Map<String, dynamic>;
    final defaultItems = (defaultData['items'] as List<dynamic>)
        .map((e) => ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Verifier s'il y a des overrides pour ce sentier
    final overrides = data['trailOverrides'] as Map<String, dynamic>?;
    if (overrides == null || !overrides.containsKey(trailId)) {
      return defaultItems;
    }

    final trailOverride = TrailChecklistOverride.fromJson(
      overrides[trailId] as Map<String, dynamic>,
    );

    return _applyOverrides(defaultItems, trailOverride);
  }

  /// Applique les overrides a la liste par defaut.
  static List<ChecklistTemplateItem> _applyOverrides(
    List<ChecklistTemplateItem> defaults,
    TrailChecklistOverride override,
  ) {
    // Retirer les items exclus
    var result = defaults
        .where((item) => !override.removeItems.contains(item.id))
        .toList();

    // Appliquer les surcharges essentielles
    result = result.map((item) {
      if (override.essentialOverrides.containsKey(item.id)) {
        return ChecklistTemplateItem(
          id: item.id,
          category: item.category,
          nameKey: item.nameKey,
          isEssential: override.essentialOverrides[item.id]!,
        );
      }
      return item;
    }).toList();

    // Ajouter les items supplementaires
    result.addAll(override.addItems);

    return result;
  }

  /// Retourne les categories disponibles depuis le template.
  static Future<List<String>> loadCategories() async {
    final data = await _loadJson();
    final defaultData = data['defaultTemplate'] as Map<String, dynamic>;
    return (defaultData['categories'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
  }

  /// Reinitialise le cache (utile pour les tests).
  static void clearCache() {
    _cachedJson = null;
  }
}

/// Template par defaut de checklist materiel trek.
///
/// 6 categories, items essentiels flagues.
/// Les cles correspondent aux entrees i18n checklist.items.*
/// RETROCOMPAT: garde pour les usages existants.
const List<ChecklistTemplateItem> defaultChecklistTemplate = [
  // --- Equipement ---
  ChecklistTemplateItem(
      id: 'backpack',
      category: 'equipment',
      nameKey: 'backpack',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'sleepingBag',
      category: 'equipment',
      nameKey: 'sleepingBag',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'sleepingPad', category: 'equipment', nameKey: 'sleepingPad'),
  ChecklistTemplateItem(
      id: 'hikingPoles', category: 'equipment', nameKey: 'hikingPoles'),
  ChecklistTemplateItem(
      id: 'headlamp',
      category: 'equipment',
      nameKey: 'headlamp',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'waterBottle',
      category: 'equipment',
      nameKey: 'waterBottle',
      isEssential: true),

  // --- Vetements ---
  ChecklistTemplateItem(
      id: 'hikingBoots',
      category: 'clothing',
      nameKey: 'hikingBoots',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'rainJacket',
      category: 'clothing',
      nameKey: 'rainJacket',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'warmLayer',
      category: 'clothing',
      nameKey: 'warmLayer',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'hikingSocks', category: 'clothing', nameKey: 'hikingSocks'),
  ChecklistTemplateItem(id: 'hat', category: 'clothing', nameKey: 'hat'),
  ChecklistTemplateItem(
      id: 'gloves', category: 'clothing', nameKey: 'gloves'),

  // --- Alimentation ---
  ChecklistTemplateItem(
      id: 'trailSnacks', category: 'food', nameKey: 'trailSnacks'),
  ChecklistTemplateItem(
      id: 'energyBars', category: 'food', nameKey: 'energyBars'),
  ChecklistTemplateItem(
      id: 'waterPurification', category: 'food', nameKey: 'waterPurification'),

  // --- Securite ---
  ChecklistTemplateItem(
      id: 'firstAidKit',
      category: 'safety',
      nameKey: 'firstAidKit',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'whistle',
      category: 'safety',
      nameKey: 'whistle',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'emergencyBlanket',
      category: 'safety',
      nameKey: 'emergencyBlanket',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'sunscreen', category: 'safety', nameKey: 'sunscreen'),

  // --- Documents ---
  ChecklistTemplateItem(
      id: 'idCard',
      category: 'documents',
      nameKey: 'idCard',
      isEssential: true),
  ChecklistTemplateItem(
      id: 'insurance', category: 'documents', nameKey: 'insurance'),
  ChecklistTemplateItem(
      id: 'trailMap', category: 'documents', nameKey: 'trailMap'),

  // --- Hygiene ---
  ChecklistTemplateItem(
      id: 'toiletPaper', category: 'hygiene', nameKey: 'toiletPaper'),
  ChecklistTemplateItem(
      id: 'handSanitizer', category: 'hygiene', nameKey: 'handSanitizer'),
  ChecklistTemplateItem(id: 'towel', category: 'hygiene', nameKey: 'towel'),
];

/// Categories disponibles pour la checklist.
const List<String> checklistCategories = [
  'equipment',
  'clothing',
  'food',
  'safety',
  'documents',
  'hygiene',
];
