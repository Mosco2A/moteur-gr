import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Niveau d'exigence d'un article (parite GR20 « Materiel & Sac »).
///
/// - [required] : obligatoire (cadenas + garde-fou au decochage) ;
/// - [recommended] : conseille ;
/// - [optional] : facultatif (defaut).
enum ChecklistRequirement { required, recommended, optional }

/// Template de checklist materiel pour la randonnee.
///
/// Donnees statiques embarquees — pas de reseau necessaire.
/// Chaque item a un identifiant unique, une categorie,
/// un nom i18n-ready, un poids de reference, une quantite par defaut et un
/// niveau d'exigence.
/// PARITE GR20 « Materiel & Sac » : le contenu par defaut (categories, articles,
/// poids, quantites, exigences) CLONE celui de l'ecran GR20. Reste generique :
/// c'est une donnee (surchargeable par sentier via
/// assets/data/checklist_template.json), aucune localite en dur.
class ChecklistTemplateItem {
  const ChecklistTemplateItem({
    required this.id,
    required this.category,
    required this.nameKey,
    this.isEssential = false,
    this.weightGrams = 0,
    this.quantity = 1,
    this.requirement = ChecklistRequirement.optional,
  });

  /// Identifiant unique de l'item (ex: 'backpack')
  final String id;

  /// Categorie (cle i18n checklist.categories.*). Parite GR20 : 'carrying',
  /// 'sleeping', 'clothing', 'cooking', 'foodWater', 'hygiene', 'firstAid',
  /// 'electronics', 'women', 'men', 'misc', 'dog'.
  final String category;

  /// Cle i18n pour le nom de l'item (resolu via les traductions)
  final String nameKey;

  /// Item indispensable (retrocompat). Derive de [requirement] == required.
  final bool isEssential;

  /// Poids unitaire de reference en grammes (parite GR20 « Materiel & Sac »).
  ///
  /// Sert de valeur par defaut de la jauge poids. 0 = non renseigne / porte
  /// (l'article ne contribue pas au poids, ex : chaussures portees).
  final int weightGrams;

  /// Quantite par defaut de l'article (parite GR20, min 1).
  final int quantity;

  /// Niveau d'exigence (parite GR20 : required / recommended / optional).
  final ChecklistRequirement requirement;

  /// Construit depuis un JSON
  factory ChecklistTemplateItem.fromJson(Map<String, dynamic> json) {
    final req = _requirementFromString(json['requirement'] as String?);
    return ChecklistTemplateItem(
      id: json['id'] as String,
      category: json['category'] as String,
      nameKey: json['nameKey'] as String,
      isEssential: json['isEssential'] as bool? ??
          (req == ChecklistRequirement.required),
      weightGrams: json['weightGrams'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      requirement: req,
    );
  }

  /// Serialise en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'nameKey': nameKey,
      'isEssential': isEssential,
      'weightGrams': weightGrams,
      'quantity': quantity,
      'requirement': requirement.name,
    };
  }

  static ChecklistRequirement _requirementFromString(String? raw) {
    switch (raw) {
      case 'required':
        return ChecklistRequirement.required;
      case 'recommended':
        return ChecklistRequirement.recommended;
      default:
        return ChecklistRequirement.optional;
    }
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
        final essential = override.essentialOverrides[item.id]!;
        return ChecklistTemplateItem(
          id: item.id,
          category: item.category,
          nameKey: item.nameKey,
          isEssential: essential,
          weightGrams: item.weightGrams,
          quantity: item.quantity,
          // Aligner l'exigence sur la surcharge essentielle (required si vrai).
          requirement: essential
              ? ChecklistRequirement.required
              : item.requirement,
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

/// Categories disponibles pour la checklist — ORDRE = celui de l'ecran GR20
/// « Materiel & Sac » (L-07 : ... Femme, Homme, Divers, Chien en fin).
///
/// Cles i18n : checklist.categories.<cle>. Generiques (aucune localite).
const List<String> checklistCategories = [
  'carrying', // Sac & portage
  'sleeping', // Couchage
  'clothing', // Vetements
  'cooking', // Cuisine
  'foodWater', // Nourriture & Eau
  'hygiene', // Hygiene
  'firstAid', // Trousse de secours
  'electronics', // Electronique
  'women', // Femme
  'men', // Homme
  'misc', // Divers
  'dog', // Chien
];

/// Template par defaut de checklist materiel trek — CLONE du contenu GR20
/// « Materiel & Sac ».
///
/// Poids unitaires de reference (grammes) = poids moyen commerce outdoor
/// 2024-2025 (parite GR20). Quantites et niveaux d'exigence clones de GR20.
/// Generiques, surchargeables par sentier via les overrides.
/// weightGrams: 0 = porte / non pese (ex : chaussures aux pieds, batons portes)
/// -> ne compte pas dans la jauge.
/// RETROCOMPAT : reste `defaultChecklistTemplate` (meme nom d'API).
const List<ChecklistTemplateItem> defaultChecklistTemplate = [
  // --- Sac & portage ---
  ChecklistTemplateItem(
      id: 'backpack',
      category: 'carrying',
      nameKey: 'backpack',
      weightGrams: 1400,
      requirement: ChecklistRequirement.recommended,
      isEssential: false),
  ChecklistTemplateItem(
      id: 'rainCover',
      category: 'carrying',
      nameKey: 'rainCover',
      weightGrams: 100),
  ChecklistTemplateItem(
      id: 'dryBags',
      category: 'carrying',
      nameKey: 'dryBags',
      weightGrams: 150,
      quantity: 3),

  // --- Couchage ---
  ChecklistTemplateItem(
      id: 'sleepingBag',
      category: 'sleeping',
      nameKey: 'sleepingBag',
      weightGrams: 900,
      requirement: ChecklistRequirement.recommended,
      isEssential: false),
  ChecklistTemplateItem(
      id: 'sleepingPad',
      category: 'sleeping',
      nameKey: 'sleepingPad',
      weightGrams: 400),
  ChecklistTemplateItem(
      id: 'sleepingLiner',
      category: 'sleeping',
      nameKey: 'sleepingLiner',
      weightGrams: 200),
  ChecklistTemplateItem(
      id: 'pillow',
      category: 'sleeping',
      nameKey: 'pillow',
      weightGrams: 80),

  // --- Vetements ---
  ChecklistTemplateItem(
      id: 'hikingPants',
      category: 'clothing',
      nameKey: 'hikingPants',
      weightGrams: 300),
  ChecklistTemplateItem(
      id: 'rainPants',
      category: 'clothing',
      nameKey: 'rainPants',
      weightGrams: 200),
  ChecklistTemplateItem(
      id: 'shorts',
      category: 'clothing',
      nameKey: 'shorts',
      weightGrams: 150),
  ChecklistTemplateItem(
      id: 'techTshirt',
      category: 'clothing',
      nameKey: 'techTshirt',
      weightGrams: 150,
      quantity: 2),
  ChecklistTemplateItem(
      id: 'fleece',
      category: 'clothing',
      nameKey: 'fleece',
      weightGrams: 350),
  ChecklistTemplateItem(
      id: 'rainJacket',
      category: 'clothing',
      nameKey: 'rainJacket',
      weightGrams: 400,
      requirement: ChecklistRequirement.required,
      isEssential: true),
  ChecklistTemplateItem(
      id: 'underwear',
      category: 'clothing',
      nameKey: 'underwear',
      weightGrams: 50,
      quantity: 3),
  ChecklistTemplateItem(
      id: 'hikingSocks',
      category: 'clothing',
      nameKey: 'hikingSocks',
      weightGrams: 60,
      quantity: 3),
  ChecklistTemplateItem(
      id: 'gaiters',
      category: 'clothing',
      nameKey: 'gaiters',
      weightGrams: 100),
  ChecklistTemplateItem(
      id: 'hat',
      category: 'clothing',
      nameKey: 'hat',
      weightGrams: 80),
  ChecklistTemplateItem(
      id: 'beanie',
      category: 'clothing',
      nameKey: 'beanie',
      weightGrams: 50),
  ChecklistTemplateItem(
      id: 'buff',
      category: 'clothing',
      nameKey: 'buff',
      weightGrams: 40),
  ChecklistTemplateItem(
      id: 'lightGloves',
      category: 'clothing',
      nameKey: 'lightGloves',
      weightGrams: 40),
  ChecklistTemplateItem(
      id: 'hikingBoots',
      category: 'clothing',
      nameKey: 'hikingBoots',
      weightGrams: 0,
      requirement: ChecklistRequirement.recommended,
      isEssential: false),
  ChecklistTemplateItem(
      id: 'campSandals',
      category: 'clothing',
      nameKey: 'campSandals',
      weightGrams: 200),

  // --- Cuisine ---
  ChecklistTemplateItem(
      id: 'stove',
      category: 'cooking',
      nameKey: 'stove',
      weightGrams: 85),
  ChecklistTemplateItem(
      id: 'gasCanister',
      category: 'cooking',
      nameKey: 'gasCanister',
      weightGrams: 230,
      quantity: 2),
  ChecklistTemplateItem(
      id: 'cookpot',
      category: 'cooking',
      nameKey: 'cookpot',
      weightGrams: 200),
  ChecklistTemplateItem(
      id: 'cutlery',
      category: 'cooking',
      nameKey: 'cutlery',
      weightGrams: 60),
  ChecklistTemplateItem(
      id: 'waterBottle',
      category: 'cooking',
      nameKey: 'waterBottle',
      weightGrams: 150,
      requirement: ChecklistRequirement.required,
      isEssential: true),
  ChecklistTemplateItem(
      id: 'knife',
      category: 'cooking',
      nameKey: 'knife',
      weightGrams: 80),
  ChecklistTemplateItem(
      id: 'lighter',
      category: 'cooking',
      nameKey: 'lighter',
      weightGrams: 20),

  // --- Nourriture & Eau ---
  ChecklistTemplateItem(
      id: 'energyBars',
      category: 'foodWater',
      nameKey: 'energyBars',
      weightGrams: 35,
      quantity: 1),
  ChecklistTemplateItem(
      id: 'driedFruits',
      category: 'foodWater',
      nameKey: 'driedFruits',
      weightGrams: 150),
  ChecklistTemplateItem(
      id: 'freezeDriedMeal',
      category: 'foodWater',
      nameKey: 'freezeDriedMeal',
      weightGrams: 100,
      quantity: 1),
  ChecklistTemplateItem(
      id: 'waterPurification',
      category: 'foodWater',
      nameKey: 'waterPurification',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'electrolytes',
      category: 'foodWater',
      nameKey: 'electrolytes',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'carriedWater',
      category: 'foodWater',
      nameKey: 'carriedWater',
      weightGrams: 1000,
      quantity: 2,
      requirement: ChecklistRequirement.recommended,
      isEssential: false),

  // --- Hygiene ---
  ChecklistTemplateItem(
      id: 'soap',
      category: 'hygiene',
      nameKey: 'soap',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'toothbrush',
      category: 'hygiene',
      nameKey: 'toothbrush',
      weightGrams: 15),
  ChecklistTemplateItem(
      id: 'toothpaste',
      category: 'hygiene',
      nameKey: 'toothpaste',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'microfiberTowel',
      category: 'hygiene',
      nameKey: 'microfiberTowel',
      weightGrams: 80),
  ChecklistTemplateItem(
      id: 'toiletPaper',
      category: 'hygiene',
      nameKey: 'toiletPaper',
      weightGrams: 50),
  ChecklistTemplateItem(
      id: 'trashBag',
      category: 'hygiene',
      nameKey: 'trashBag',
      weightGrams: 7,
      quantity: 3),
  ChecklistTemplateItem(
      id: 'antiChafingCream',
      category: 'hygiene',
      nameKey: 'antiChafingCream',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'earplugs',
      category: 'hygiene',
      nameKey: 'earplugs',
      weightGrams: 5),

  // --- Trousse de secours ---
  ChecklistTemplateItem(
      id: 'bandages',
      category: 'firstAid',
      nameKey: 'bandages',
      weightGrams: 10,
      quantity: 2,
      requirement: ChecklistRequirement.recommended,
      isEssential: false),
  ChecklistTemplateItem(
      id: 'sterileCompresses',
      category: 'firstAid',
      nameKey: 'sterileCompresses',
      weightGrams: 15,
      quantity: 2),
  ChecklistTemplateItem(
      id: 'elasticBandage',
      category: 'firstAid',
      nameKey: 'elasticBandage',
      weightGrams: 40),
  ChecklistTemplateItem(
      id: 'disinfectant',
      category: 'firstAid',
      nameKey: 'disinfectant',
      weightGrams: 80,
      requirement: ChecklistRequirement.recommended,
      isEssential: false),
  ChecklistTemplateItem(
      id: 'painkillers',
      category: 'firstAid',
      nameKey: 'painkillers',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'sunscreen',
      category: 'firstAid',
      nameKey: 'sunscreen',
      weightGrams: 100,
      requirement: ChecklistRequirement.required,
      isEssential: true),
  ChecklistTemplateItem(
      id: 'lipBalm',
      category: 'firstAid',
      nameKey: 'lipBalm',
      weightGrams: 15),
  ChecklistTemplateItem(
      id: 'emergencyBlanket',
      category: 'firstAid',
      nameKey: 'emergencyBlanket',
      weightGrams: 60,
      requirement: ChecklistRequirement.required,
      isEssential: true),
  ChecklistTemplateItem(
      id: 'tickRemover',
      category: 'firstAid',
      nameKey: 'tickRemover',
      weightGrams: 5),
  ChecklistTemplateItem(
      id: 'whistle',
      category: 'firstAid',
      nameKey: 'whistle',
      weightGrams: 10,
      requirement: ChecklistRequirement.required,
      isEssential: true),
  ChecklistTemplateItem(
      id: 'strapping',
      category: 'firstAid',
      nameKey: 'strapping',
      weightGrams: 50),
  ChecklistTemplateItem(
      id: 'eyeDrops',
      category: 'firstAid',
      nameKey: 'eyeDrops',
      weightGrams: 20),
  ChecklistTemplateItem(
      id: 'antiDiarrheal',
      category: 'firstAid',
      nameKey: 'antiDiarrheal',
      weightGrams: 15),
  ChecklistTemplateItem(
      id: 'antihistamine',
      category: 'firstAid',
      nameKey: 'antihistamine',
      weightGrams: 15),
  ChecklistTemplateItem(
      id: 'kneeTape',
      category: 'firstAid',
      nameKey: 'kneeTape',
      weightGrams: 40),

  // --- Electronique ---
  ChecklistTemplateItem(
      id: 'phone',
      category: 'electronics',
      nameKey: 'phone',
      weightGrams: 200,
      requirement: ChecklistRequirement.required,
      isEssential: true),
  ChecklistTemplateItem(
      id: 'powerBank',
      category: 'electronics',
      nameKey: 'powerBank',
      weightGrams: 350,
      requirement: ChecklistRequirement.recommended,
      isEssential: false),
  ChecklistTemplateItem(
      id: 'usbCable',
      category: 'electronics',
      nameKey: 'usbCable',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'headlamp',
      category: 'electronics',
      nameKey: 'headlamp',
      weightGrams: 80,
      requirement: ChecklistRequirement.required,
      isEssential: true),
  ChecklistTemplateItem(
      id: 'spareBatteries',
      category: 'electronics',
      nameKey: 'spareBatteries',
      weightGrams: 25,
      quantity: 2),

  // --- Femme ---
  ChecklistTemplateItem(
      id: 'periodProtection',
      category: 'women',
      nameKey: 'periodProtection',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'sportsBra',
      category: 'women',
      nameKey: 'sportsBra',
      weightGrams: 60,
      quantity: 2),
  ChecklistTemplateItem(
      id: 'intimateWipes',
      category: 'women',
      nameKey: 'intimateWipes',
      weightGrams: 20),
  ChecklistTemplateItem(
      id: 'peeCloth',
      category: 'women',
      nameKey: 'peeCloth',
      weightGrams: 10),

  // --- Homme ---
  ChecklistTemplateItem(
      id: 'razor',
      category: 'men',
      nameKey: 'razor',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'techBoxers',
      category: 'men',
      nameKey: 'techBoxers',
      weightGrams: 50,
      quantity: 3),

  // --- Divers ---
  ChecklistTemplateItem(
      id: 'hikingPoles',
      category: 'misc',
      nameKey: 'hikingPoles',
      weightGrams: 0),
  ChecklistTemplateItem(
      id: 'sunglasses',
      category: 'misc',
      nameKey: 'sunglasses',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'trailMap',
      category: 'misc',
      nameKey: 'trailMap',
      weightGrams: 80),
  ChecklistTemplateItem(
      id: 'spareLaces',
      category: 'misc',
      nameKey: 'spareLaces',
      weightGrams: 10),
  ChecklistTemplateItem(
      id: 'needleThread',
      category: 'misc',
      nameKey: 'needleThread',
      weightGrams: 10),
  ChecklistTemplateItem(
      id: 'ductTape',
      category: 'misc',
      nameKey: 'ductTape',
      weightGrams: 20),
  ChecklistTemplateItem(
      id: 'ziplocBags',
      category: 'misc',
      nameKey: 'ziplocBags',
      weightGrams: 10),
  ChecklistTemplateItem(
      id: 'cord',
      category: 'misc',
      nameKey: 'cord',
      weightGrams: 20),
  ChecklistTemplateItem(
      id: 'cash',
      category: 'misc',
      nameKey: 'cash',
      weightGrams: 0),

  // --- Chien ---
  ChecklistTemplateItem(
      id: 'dogBowl',
      category: 'dog',
      nameKey: 'dogBowl',
      weightGrams: 50),
  ChecklistTemplateItem(
      id: 'dogLeash',
      category: 'dog',
      nameKey: 'dogLeash',
      weightGrams: 80),
  ChecklistTemplateItem(
      id: 'dogKibble',
      category: 'dog',
      nameKey: 'dogKibble',
      weightGrams: 300),
  ChecklistTemplateItem(
      id: 'dogBooties',
      category: 'dog',
      nameKey: 'dogBooties',
      weightGrams: 60,
      quantity: 4),
  ChecklistTemplateItem(
      id: 'dogVaccineBook',
      category: 'dog',
      nameKey: 'dogVaccineBook',
      weightGrams: 30),
  ChecklistTemplateItem(
      id: 'dogPoopBags',
      category: 'dog',
      nameKey: 'dogPoopBags',
      weightGrams: 10,
      quantity: 10),
];

/// Icones par categorie (parite GR20 « Materiel & Sac »). Cle = cle i18n de la
/// categorie. Vit ici (donnee de template) pour rester generique/multi-sentier.
const Map<String, int> checklistCategoryIconCodepoints = {
  // Material Icons codepoints (const IconData construits dans la couche UI).
  'carrying': 0xe3b0, // luggage
  'sleeping': 0xe0a6, // bed
  'clothing': 0xea58, // checkroom
  'cooking': 0xe56c, // restaurant
  'foodWater': 0xe57a, // fastfood
  'hygiene': 0xf1b6, // soap
  'firstAid': 0xe95d, // medical_services
  'electronics': 0xe1a3, // battery_charging_full
  'women': 0xe310, // female
  'men': 0xe58e, // male
  'misc': 0xe619, // more_horiz
  'dog': 0xe4a1, // pets
};
