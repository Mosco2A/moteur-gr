import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/grise_en_demo.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';
import 'checklist_item_widget.dart';
import 'checklist_weight_banner.dart' show formatChecklistGrams;
import '../../../core/branding/stepways_icons.dart';

/// Section (Card + ExpansionTile) d'une categorie de materiel — CLONE du rendu
/// GR20 « Materiel & Sac » (_GearCategoryCard).
///
/// En-tete : icone de categorie + nom + sous-titre « sous-total poids —
/// coches/total ». Corps : liste des articles ([ChecklistItemWidget]) puis un
/// bouton « Ajouter un item ».
class ChecklistCategorySection extends StatelessWidget {
  const ChecklistCategorySection({
    super.key,
    required this.categoryKey,
    required this.categoryName,
    required this.items,
    required this.onToggle,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onAddItem,
    required this.onQuantityChanged,
    required this.onToggleShoppingList,
  });

  /// Cle i18n de la categorie (pour l'icone).
  final String categoryKey;

  /// Nom traduit de la categorie (resolu via Slang dans le screen).
  final String categoryName;

  /// Articles de cette categorie.
  final List<ChecklistItemState> items;

  final void Function(String itemId) onToggle;
  final void Function(String itemId) onEditItem;
  final void Function(String itemId) onDeleteItem;
  final VoidCallback onAddItem;
  final void Function(String itemId, int newQuantity) onQuantityChanged;
  final void Function(String itemId) onToggleShoppingList;

  /// Poids (g) des articles COCHES de la categorie (sous-total, parite GR20 :
  /// quantite comprise).
  int get _checkedWeightGrams =>
      items.where((i) => i.isChecked).fold(0, (s, i) => s + i.totalWeightGrams);

  /// L icone de la categorie, prise TELLE QUELLE dans la table const.
  ///
  /// Elle n est plus FABRIQUEE ici a partir d un codepoint : une construction
  /// `IconData(...)` non constante fait echouer la compilation release, qui doit
  /// pouvoir voir chaque glyphe utilise pour alleger la police. Voir la table
  /// [checklistCategoryIcons] (tache 619).
  String get _icon => checklistCategoryIcons[categoryKey] ?? StepwaysIcons.menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedInCat = items.where((i) => i.isChecked).length;
    final catWeight = _checkedWeightGrams;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: ExpansionTile(
        leading: StepIcon(_icon, color: theme.colorScheme.primary, size: 22),
        title: Text(
          categoryName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${catWeight > 0 ? formatChecklistGrams(catWeight) : "0 ${t.checklist.weight.grams}"}'
          ' — $checkedInCat/${items.length}',
          style: theme.textTheme.bodySmall,
        ),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.only(
          left: AppTheme.spacingSm,
          right: AppTheme.spacingSm,
          bottom: AppTheme.spacingSm,
        ),
        children: [
          ...items.map(
            (item) => ChecklistItemWidget(
              item: item,
              onToggle: () => onToggle(item.template.id),
              onEdit: () => onEditItem(item.template.id),
              onDelete: item.isCustom
                  ? () => onDeleteItem(item.template.id)
                  : null,
              onQuantityChanged: (newQty) =>
                  onQuantityChanged(item.template.id, newQty),
              onToggleShoppingList: () =>
                  onToggleShoppingList(item.template.id),
            ),
          ),
          // Bouton « Ajouter un item » (parite GR20).
          // GRISE EN DEMO (tache 638, bug 14) : ajouter un article ecrit une
          // ligne en base. Grise et visiblement indisponible, pas muet.
          GriseEnDemo(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddItem,
                icon: const StepIcon(StepwaysIcons.plus, size: 16),
                label: Text(t.checklist.ui.addItem),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
