import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';
import '../widgets/checklist_category_section.dart';
import '../widgets/checklist_progress_header.dart';

/// Noms traduits des categories par langue.
/// Quand Slang sera integre, ces maps seront remplacees
/// par les cles Slang generees.
const Map<String, Map<String, String>> _categoryNames = {
  'fr': {
    'equipment': '\u00c9quipement',
    'clothing': 'V\u00eatements',
    'food': 'Alimentation',
    'safety': 'S\u00e9curit\u00e9',
    'documents': 'Documents',
    'hygiene': 'Hygi\u00e8ne',
  },
  'en': {
    'equipment': 'Equipment',
    'clothing': 'Clothing',
    'food': 'Food',
    'safety': 'Safety',
    'documents': 'Documents',
    'hygiene': 'Hygiene',
  },
};

/// Noms traduits des items par langue.
const Map<String, Map<String, String>> _itemNames = {
  'fr': {
    'backpack': 'Sac \u00e0 dos',
    'sleepingBag': 'Sac de couchage',
    'sleepingPad': 'Matelas de sol',
    'hikingPoles': 'B\u00e2tons de marche',
    'headlamp': 'Lampe frontale',
    'waterBottle': 'Gourde',
    'hikingBoots': 'Chaussures de randonn\u00e9e',
    'rainJacket': 'Veste imperm\u00e9able',
    'warmLayer': 'Couche chaude',
    'hikingSocks': 'Chaussettes de randonn\u00e9e',
    'hat': 'Chapeau',
    'gloves': 'Gants',
    'trailSnacks': 'Encas de marche',
    'energyBars': 'Barres \u00e9nerg\u00e9tiques',
    'waterPurification': "Purification d'eau",
    'firstAidKit': 'Trousse de secours',
    'whistle': 'Sifflet',
    'emergencyBlanket': 'Couverture de survie',
    'sunscreen': 'Cr\u00e8me solaire',
    'idCard': "Pi\u00e8ce d'identit\u00e9",
    'insurance': 'Assurance',
    'trailMap': 'Carte du sentier',
    'toiletPaper': 'Papier toilette',
    'handSanitizer': 'Gel hydroalcoolique',
    'towel': 'Serviette',
  },
  'en': {
    'backpack': 'Backpack',
    'sleepingBag': 'Sleeping bag',
    'sleepingPad': 'Sleeping pad',
    'hikingPoles': 'Hiking poles',
    'headlamp': 'Headlamp',
    'waterBottle': 'Water bottle',
    'hikingBoots': 'Hiking boots',
    'rainJacket': 'Rain jacket',
    'warmLayer': 'Warm layer',
    'hikingSocks': 'Hiking socks',
    'hat': 'Hat',
    'gloves': 'Gloves',
    'trailSnacks': 'Trail snacks',
    'energyBars': 'Energy bars',
    'waterPurification': 'Water purification',
    'firstAidKit': 'First aid kit',
    'whistle': 'Whistle',
    'emergencyBlanket': 'Emergency blanket',
    'sunscreen': 'Sunscreen',
    'idCard': 'ID card',
    'insurance': 'Insurance',
    'trailMap': 'Trail map',
    'toiletPaper': 'Toilet paper',
    'handSanitizer': 'Hand sanitizer',
    'towel': 'Towel',
  },
};

/// Ecran principal de la checklist materiel.
///
/// Affiche la progression globale en en-tete,
/// puis les items groupes par categorie avec checkboxes.
/// Bouton reset dans l AppBar.
class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistState = ref.watch(checklistProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final lang = _categoryNames.containsKey(locale) ? locale : 'en';

    if (checklistState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_title(lang)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: _resetLabel(lang),
            onPressed: () => _showResetDialog(context, ref, lang),
          ),
        ],
      ),
      body: ListView(
        children: [
          // En-tete progression
          ChecklistProgressHeader(
            checkedCount: checklistState.checkedCount,
            totalCount: checklistState.totalCount,
            progressLabel: _progressLabel(
              lang,
              checklistState.checkedCount,
              checklistState.totalCount,
            ),
            completeLabel: _completeLabel(lang),
          ),
          const Divider(height: 1),
          // Categories
          for (final category in checklistCategories)
            ChecklistCategorySection(
              categoryName:
                  _categoryNames[lang]?[category] ?? category,
              items: _resolveItemNames(
                checklistState.items
                    .where(
                        (i) => i.template.category == category)
                    .toList(),
                lang,
              ),
              onToggle: (itemId) {
                ref.read(checklistProvider.notifier).toggle(itemId);
              },
            ),
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  /// Resout les noms i18n des items pour affichage.
  List<ChecklistItemState> _resolveItemNames(
    List<ChecklistItemState> items,
    String lang,
  ) {
    return items.map((item) {
      final resolvedName =
          _itemNames[lang]?[item.template.nameKey] ??
              item.template.nameKey;
      return ChecklistItemState(
        template: ChecklistTemplateItem(
          id: item.template.id,
          category: item.template.category,
          nameKey: resolvedName,
          isEssential: item.template.isEssential,
        ),
        isChecked: item.isChecked,
      );
    }).toList();
  }

  String _title(String lang) =>
      lang == 'fr' ? 'Checklist mat\u00e9riel' : 'Gear checklist';

  String _resetLabel(String lang) =>
      lang == 'fr' ? 'R\u00e9initialiser' : 'Reset';

  String _progressLabel(String lang, int checked, int total) =>
      lang == 'fr'
          ? '$checked/$total pr\u00e9par\u00e9s'
          : '$checked/$total packed';

  String _completeLabel(String lang) =>
      lang == 'fr'
          ? 'Checklist compl\u00e8te !'
          : 'Checklist complete!';

  void _showResetDialog(
      BuildContext context, WidgetRef ref, String lang) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          lang == 'fr'
              ? 'R\u00e9initialiser la checklist ?'
              : 'Reset checklist?',
        ),
        content: Text(
          lang == 'fr'
              ? 'Tous les \u00e9l\u00e9ments seront d\u00e9coch\u00e9s.'
              : 'All items will be unchecked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang == 'fr' ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(checklistProvider.notifier).resetAll();
              Navigator.of(ctx).pop();
            },
            child: Text(lang == 'fr' ? 'Confirmer' : 'Confirm'),
          ),
        ],
      ),
    );
  }
}
