/// Configuration des categories de fiches conseils.
///
/// Fournit un mapping categorie -> metadata (label i18n, icone).
/// Fallback sur une categorie 'general' si la categorie demandee
/// est inconnue. JAMAIS d enum — String extensible.
class TipCategoryConfig {
  const TipCategoryConfig._();

  /// Metadata d une categorie de conseils.
  /// [labelKey] : cle i18n pour le nom affiche.
  /// [icon] : nom de l icone Material.
  static const Map<String, TipCategoryMeta> _categories = {
    'preparation': TipCategoryMeta(
      labelKey: 'tipCategoryPreparation',
      icon: 'checklist',
    ),
    'equipment': TipCategoryMeta(
      labelKey: 'tipCategoryEquipment',
      icon: 'backpack',
    ),
    'nutrition': TipCategoryMeta(
      labelKey: 'tipCategoryNutrition',
      icon: 'restaurant',
    ),
    'safety': TipCategoryMeta(
      labelKey: 'tipCategorySafety',
      icon: 'health_and_safety',
    ),
    'nature': TipCategoryMeta(
      labelKey: 'tipCategoryNature',
      icon: 'forest',
    ),
    'recovery': TipCategoryMeta(
      labelKey: 'tipCategoryRecovery',
      icon: 'self_improvement',
    ),
  };

  /// Categorie par defaut utilisee en fallback.
  static const TipCategoryMeta _fallback = TipCategoryMeta(
    labelKey: 'tipCategoryGeneral',
    icon: 'info',
  );

  /// Retourne la metadata pour une categorie donnee.
  ///
  /// Si la categorie est inconnue, retourne le fallback (general).
  /// Permet d ajouter de nouvelles categories sans modifier le code.
  static TipCategoryMeta getConfig(String category) {
    return _categories[category] ?? _fallback;
  }

  /// Retourne toutes les categories connues.
  static Set<String> get knownCategories => _categories.keys.toSet();

  /// Verifie si une categorie est connue.
  static bool isKnown(String category) => _categories.containsKey(category);
}

/// Metadata associee a une categorie de conseils.
class TipCategoryMeta {
  const TipCategoryMeta({
    required this.labelKey,
    required this.icon,
  });

  /// Cle i18n pour le label affiche
  final String labelKey;

  /// Nom de l icone Material
  final String icon;
}
