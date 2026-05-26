/// Donnees statiques des fiches conseils trek.
///
/// 6 categories, chaque categorie a 3-5 conseils.
/// Contenu editorial embarque, offline-first.
class TipCategory {
  const TipCategory({
    required this.id,
    required this.nameKey,
    required this.icon,
    required this.tips,
  });

  /// Identifiant unique de la categorie
  final String id;

  /// Cle i18n pour le nom
  final String nameKey;

  /// Nom de l icone Material
  final String icon;

  /// Conseils de la categorie
  final List<Tip> tips;
}

/// Un conseil individuel.
class Tip {
  const Tip({
    required this.id,
    required this.titleKey,
    required this.contentKey,
  });

  /// Identifiant unique
  final String id;

  /// Cle i18n du titre
  final String titleKey;

  /// Cle i18n du contenu
  final String contentKey;
}

/// Categories de conseils trek.
///
/// 6 categories : preparation, equipement, alimentation,
/// securite, nature, recup.
const List<TipCategory> tipsCategories = [
  TipCategory(
    id: 'preparation',
    nameKey: 'preparation',
    icon: 'checklist',
    tips: [
      Tip(id: 'prep1', titleKey: 'prepTraining', contentKey: 'prepTrainingContent'),
      Tip(id: 'prep2', titleKey: 'prepPlanning', contentKey: 'prepPlanningContent'),
      Tip(id: 'prep3', titleKey: 'prepAdmin', contentKey: 'prepAdminContent'),
    ],
  ),
  TipCategory(
    id: 'equipment',
    nameKey: 'equipment',
    icon: 'backpack',
    tips: [
      Tip(id: 'equip1', titleKey: 'equipShoes', contentKey: 'equipShoesContent'),
      Tip(id: 'equip2', titleKey: 'equipLayers', contentKey: 'equipLayersContent'),
      Tip(id: 'equip3', titleKey: 'equipWeight', contentKey: 'equipWeightContent'),
      Tip(id: 'equip4', titleKey: 'equipElectronics', contentKey: 'equipElectronicsContent'),
    ],
  ),
  TipCategory(
    id: 'nutrition',
    nameKey: 'nutrition',
    icon: 'restaurant',
    tips: [
      Tip(id: 'nutri1', titleKey: 'nutriHydration', contentKey: 'nutriHydrationContent'),
      Tip(id: 'nutri2', titleKey: 'nutriEnergy', contentKey: 'nutriEnergyContent'),
      Tip(id: 'nutri3', titleKey: 'nutriMeals', contentKey: 'nutriMealsContent'),
    ],
  ),
  TipCategory(
    id: 'safety',
    nameKey: 'safety',
    icon: 'health_and_safety',
    tips: [
      Tip(id: 'safe1', titleKey: 'safeWeather', contentKey: 'safeWeatherContent'),
      Tip(id: 'safe2', titleKey: 'safeFirstAid', contentKey: 'safeFirstAidContent'),
      Tip(id: 'safe3', titleKey: 'safeNavigation', contentKey: 'safeNavigationContent'),
      Tip(id: 'safe4', titleKey: 'safeEmergency', contentKey: 'safeEmergencyContent'),
    ],
  ),
  TipCategory(
    id: 'nature',
    nameKey: 'nature',
    icon: 'forest',
    tips: [
      Tip(id: 'nat1', titleKey: 'natLeaveNoTrace', contentKey: 'natLeaveNoTraceContent'),
      Tip(id: 'nat2', titleKey: 'natWildlife', contentKey: 'natWildlifeContent'),
      Tip(id: 'nat3', titleKey: 'natWater', contentKey: 'natWaterContent'),
    ],
  ),
  TipCategory(
    id: 'recovery',
    nameKey: 'recovery',
    icon: 'self_improvement',
    tips: [
      Tip(id: 'recov1', titleKey: 'recovStretching', contentKey: 'recovStretchingContent'),
      Tip(id: 'recov2', titleKey: 'recovSleep', contentKey: 'recovSleepContent'),
      Tip(id: 'recov3', titleKey: 'recovFeet', contentKey: 'recovFeetContent'),
    ],
  ),
];
