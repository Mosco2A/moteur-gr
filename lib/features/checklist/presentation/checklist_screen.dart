import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';
import '../widgets/checklist_bottom_actions.dart';
import '../widgets/checklist_category_section.dart';
import '../widgets/checklist_preparation_section.dart';
import '../widgets/checklist_recommendation_banner.dart';
import '../widgets/checklist_shopping_modal.dart';
import '../widgets/checklist_weight_banner.dart';

/// Ecran « Materiel & Sac » — CLONE INTEGRAL de l'ecran GR20 du meme nom
/// (parite #99433, PAREIL = PAREIL).
///
/// Nom d'ecran, rubriques, articles, categories, champs, libelles, disposition,
/// actions et comportements reproduisent GR20 « Materiel & Sac ». Hors systeme
/// de peaux (couleurs semantiques via [AppTheme]). Generique multi-sentiers :
/// le contenu est une donnee de template (surchargeable par sentier), mais le
/// contenu par defaut + le rendu + les fonctions sont ceux de GR20.
/// Persistance Drift (poids, quantite, coche, articles custom, liste de
/// courses). Tout texte via Slang (t.checklist.*).
class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  @override
  Widget build(BuildContext context) {
    final checklistT = t.checklist;
    final isLoading = ref.watch(checklistProvider.select((s) => s.isLoading));

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(checklistT.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(checklistProvider);
    final shoppingCount = state.shoppingListCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(checklistT.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: checklistT.ui.help,
            onPressed: () => _showInfoSheet(context),
          ),
          // Badge compteur sur icone chariot (liste de courses).
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: checklistT.ui.shoppingListTitle,
                onPressed: () => _showShoppingListModal(state),
              ),
              if (shoppingCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.rougeUrgence,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$shoppingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: checklistT.reset,
            onPressed: () => _showResetDialog(context, checklistT),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // --- Bandeau poids total + indicateur (pleine largeur, GR20) ---
            ChecklistWeightBanner(
              checkedWeightGrams: state.checkedWeightGrams,
              backpackRatio: state.backpackRatio,
              checkedCount: state.checkedCount,
              totalCount: state.totalCount,
            ),
            // --- Bandeau poids recommande ---
            ChecklistRecommendationBanner(bodyWeightKg: state.bodyWeightKg),
            // --- Poids corporel + ratio ---
            ChecklistBodyWeightRow(
              bodyWeightKg: state.bodyWeightKg,
              backpackRatio: state.backpackRatio,
              onBodyWeightChanged: (kg) =>
                  ref.read(checklistProvider.notifier).setBodyWeight(kg),
            ),
            // --- Jauge poids relatif ---
            ChecklistWeightGauge(backpackRatio: state.backpackRatio),
            const SizedBox(height: AppTheme.spacingSm),
            // --- Categories + sections, avec padding horizontal (GR20) ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final category in checklistCategories)
                    ChecklistCategorySection(
                      categoryKey: category,
                      categoryName: _resolveCategoryName(category),
                      items: state.items
                          .where((i) => i.template.category == category)
                          .toList(),
                      onToggle: _handleToggle,
                      onEditItem: _showEditItemDialog,
                      onDeleteItem: _showDeleteItemDialog,
                      onAddItem: () => _showAddItemDialog(category),
                      onQuantityChanged: (itemId, newQty) => ref
                          .read(checklistProvider.notifier)
                          .setItemQuantity(itemId, newQty),
                      onToggleShoppingList: (itemId) => ref
                          .read(checklistProvider.notifier)
                          .toggleShoppingList(itemId),
                    ),
                  // --- Preparation du sac ---
                  ChecklistPreparationSection(items: state.items),
                  // --- Checklist avant depart ---
                  const ChecklistPreDepartureSection(),
                  // --- Boutons du bas ---
                  const ChecklistBottomActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveCategoryName(String categoryKey) {
    final resolved = t['checklist.categories.$categoryKey'];
    return resolved is String ? resolved : categoryKey;
  }

  // ------------------------------------------------------------------ toggle

  void _handleToggle(String itemId) {
    final item =
        ref.read(checklistProvider).items.firstWhere((i) => i.template.id == itemId);
    if (item.template.requirement == ChecklistRequirement.required &&
        item.isChecked) {
      _showRequiredWarning(itemId);
    } else {
      ref.read(checklistProvider.notifier).toggle(itemId);
    }
  }

  Future<void> _showRequiredWarning(String itemId) async {
    final ui = t.checklist.ui;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ui.requiredWarnTitle),
        content: Text(ui.requiredWarnBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ui.keep),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rougeUrgence,
              foregroundColor: Colors.white,
            ),
            child: Text(ui.removeAnyway),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(checklistProvider.notifier).forceUncheck(itemId);
    }
  }

  // -------------------------------------------------------------- add / edit

  Future<void> _showAddItemDialog(String category) async {
    final ui = t.checklist.ui;
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '100');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ui.addItemTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: ui.fieldName),
              autofocus: true,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: weightCtrl,
              decoration: InputDecoration(labelText: ui.fieldWeightGrams),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.checklist.weight.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ui.add),
          ),
        ],
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      await ref.read(checklistProvider.notifier).addCustomItem(
            category,
            nameCtrl.text.trim(),
            int.tryParse(weightCtrl.text) ?? 100,
          );
    }
  }

  /// Dialogue d'edition d'un article (parite GR20) :
  /// - article du template : poids modifiable, nom en lecture seule ;
  /// - article custom : nom ET poids modifiables.
  Future<void> _showEditItemDialog(String itemId) async {
    final ui = t.checklist.ui;
    final weightT = t.checklist.weight;
    final item =
        ref.read(checklistProvider).items.firstWhere((i) => i.template.id == itemId);
    final name = checklistItemDisplayName(item);
    final nameCtrl = TextEditingController(text: name);
    final weightCtrl = TextEditingController(text: item.weightGrams.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.isCustom ? ui.editCustomTitle : ui.editWeightTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: ui.fieldName,
                suffixIcon: item.isCustom
                    ? null
                    : const Icon(Icons.lock_outline, size: 16),
              ),
              enabled: item.isCustom,
              style: item.isCustom
                  ? null
                  : const TextStyle(color: AppTheme.grisGranite),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: weightCtrl,
              decoration: InputDecoration(
                labelText: weightT.itemWeight,
                suffixText: weightT.grams,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(weightT.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(weightT.save),
          ),
        ],
      ),
    );

    if (result == true) {
      final newWeight = int.tryParse(weightCtrl.text) ?? item.weightGrams;
      final newName = nameCtrl.text.trim();
      final notifier = ref.read(checklistProvider.notifier);

      if (newWeight != item.weightGrams) {
        await notifier.setItemWeight(itemId, newWeight);
      }
      if (item.isCustom && newName.isNotEmpty && newName != name) {
        await notifier.setCustomName(itemId, newName);
      }
      // Auto-cocher l'article apres edition s'il ne l'est pas (parite GR20).
      final refreshed = ref
          .read(checklistProvider)
          .items
          .firstWhere((i) => i.template.id == itemId);
      if (!refreshed.isChecked) {
        await notifier.toggle(itemId);
      }
    }
  }

  Future<void> _showDeleteItemDialog(String itemId) async {
    final ui = t.checklist.ui;
    final item =
        ref.read(checklistProvider).items.firstWhere((i) => i.template.id == itemId);
    if (!item.isCustom) return;
    final name = checklistItemDisplayName(item);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ui.deleteItemTitle),
        content: Text(ui.deleteItemBody.replaceAll('{name}', name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.checklist.weight.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rougeUrgence,
              foregroundColor: Colors.white,
            ),
            child: Text(ui.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(checklistProvider.notifier).deleteCustomItem(itemId);
    }
  }

  // ---------------------------------------------------------- shopping modal

  void _showShoppingListModal(ChecklistState state) {
    final byCategory = <String, List<ChecklistItemState>>{};
    for (final item in state.items.where((i) => i.inShoppingList)) {
      final catName = _resolveCategoryName(item.template.category);
      byCategory.putIfAbsent(catName, () => []).add(item);
    }
    if (byCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.checklist.ui.shoppingListEmpty)),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) =>
          ChecklistShoppingModal(uncheckedByCategory: byCategory),
    );
  }

  // ----------------------------------------------------------------- info

  void _showInfoSheet(BuildContext ctx) {
    final ui = t.checklist.ui;
    final theme = Theme.of(ctx);
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grisGranite.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.luggage, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  ui.infoTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _richInfoItem(theme, Icons.check_box, ui.infoCheckTitle,
                ui.infoCheckBody, theme.colorScheme.primary),
            const SizedBox(height: 12),
            _richInfoItem(theme, Icons.lock, ui.infoRequiredTitle,
                ui.infoRequiredBody, AppTheme.rougeUrgence),
            const SizedBox(height: 12),
            _richInfoItem(theme, Icons.monitor_weight, ui.infoGaugeTitle,
                ui.infoGaugeBody, AppTheme.vertFacile),
            const SizedBox(height: 12),
            _richInfoItem(theme, Icons.add_circle_outline, ui.infoAddTitle,
                ui.infoAddBody, AppTheme.orangeDifficile),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.vertFacile.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.vertFacile.withAlpha(40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: AppTheme.vertFacile),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ui.infoValidateBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppTheme.vertFacile,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: Text(ui.infoUnderstood,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _richInfoItem(ThemeData theme, IconData icon, String title,
      String description, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- reset

  void _showResetDialog(
    BuildContext context,
    Translations$checklist$fr checklistT,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(checklistT.resetConfirm),
        content: Text(checklistT.resetDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(checklistT.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(checklistProvider.notifier).resetAll();
              Navigator.of(ctx).pop();
            },
            child: Text(checklistT.confirm),
          ),
        ],
      ),
    );
  }
}
