/// Template de checklist materiel pour la randonnee.
///
/// Donnees statiques embarquees — pas de reseau necessaire.
/// Chaque item a un identifiant unique, une categorie,
/// un nom i18n-ready et un flag "essentiel".
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
}

/// Template par defaut de checklist materiel trek.
///
/// 6 categories, items essentiels flagues.
/// Les cles correspondent aux entrees i18n checklist.items.*
const List<ChecklistTemplateItem> defaultChecklistTemplate = [
  // --- Equipement ---
  ChecklistTemplateItem(id: 'backpack', category: 'equipment', nameKey: 'backpack', isEssential: true),
  ChecklistTemplateItem(id: 'sleepingBag', category: 'equipment', nameKey: 'sleepingBag', isEssential: true),
  ChecklistTemplateItem(id: 'sleepingPad', category: 'equipment', nameKey: 'sleepingPad'),
  ChecklistTemplateItem(id: 'hikingPoles', category: 'equipment', nameKey: 'hikingPoles'),
  ChecklistTemplateItem(id: 'headlamp', category: 'equipment', nameKey: 'headlamp', isEssential: true),
  ChecklistTemplateItem(id: 'waterBottle', category: 'equipment', nameKey: 'waterBottle', isEssential: true),

  // --- Vetements ---
  ChecklistTemplateItem(id: 'hikingBoots', category: 'clothing', nameKey: 'hikingBoots', isEssential: true),
  ChecklistTemplateItem(id: 'rainJacket', category: 'clothing', nameKey: 'rainJacket', isEssential: true),
  ChecklistTemplateItem(id: 'warmLayer', category: 'clothing', nameKey: 'warmLayer', isEssential: true),
  ChecklistTemplateItem(id: 'hikingSocks', category: 'clothing', nameKey: 'hikingSocks'),
  ChecklistTemplateItem(id: 'hat', category: 'clothing', nameKey: 'hat'),
  ChecklistTemplateItem(id: 'gloves', category: 'clothing', nameKey: 'gloves'),

  // --- Alimentation ---
  ChecklistTemplateItem(id: 'trailSnacks', category: 'food', nameKey: 'trailSnacks'),
  ChecklistTemplateItem(id: 'energyBars', category: 'food', nameKey: 'energyBars'),
  ChecklistTemplateItem(id: 'waterPurification', category: 'food', nameKey: 'waterPurification'),

  // --- Securite ---
  ChecklistTemplateItem(id: 'firstAidKit', category: 'safety', nameKey: 'firstAidKit', isEssential: true),
  ChecklistTemplateItem(id: 'whistle', category: 'safety', nameKey: 'whistle', isEssential: true),
  ChecklistTemplateItem(id: 'emergencyBlanket', category: 'safety', nameKey: 'emergencyBlanket', isEssential: true),
  ChecklistTemplateItem(id: 'sunscreen', category: 'safety', nameKey: 'sunscreen'),

  // --- Documents ---
  ChecklistTemplateItem(id: 'idCard', category: 'documents', nameKey: 'idCard', isEssential: true),
  ChecklistTemplateItem(id: 'insurance', category: 'documents', nameKey: 'insurance'),
  ChecklistTemplateItem(id: 'trailMap', category: 'documents', nameKey: 'trailMap'),

  // --- Hygiene ---
  ChecklistTemplateItem(id: 'toiletPaper', category: 'hygiene', nameKey: 'toiletPaper'),
  ChecklistTemplateItem(id: 'handSanitizer', category: 'hygiene', nameKey: 'handSanitizer'),
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
