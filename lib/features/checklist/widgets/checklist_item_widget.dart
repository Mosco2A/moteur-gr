import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';
import 'checklist_weight_banner.dart' show formatChecklistGrams;

/// Pastille coloree du niveau d'exigence (parite GR20 — _RequirementDot).
class ChecklistRequirementDot extends StatelessWidget {
  const ChecklistRequirementDot({super.key, required this.requirement});

  final ChecklistRequirement requirement;

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    switch (requirement) {
      case ChecklistRequirement.required:
        dotColor = AppTheme.rougeUrgence;
      case ChecklistRequirement.recommended:
        dotColor = AppTheme.orangeDifficile;
      case ChecklistRequirement.optional:
        dotColor = AppTheme.grisGranite;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
  }
}

/// Widget d'un article de la checklist materiel — CLONE du rendu GR20
/// (« Materiel & Sac ») : layout 2 lignes.
///
/// Ligne 1 : checkbox + pastille exigence + nom (barre si coche) + badge
/// « Obligatoire » (cadenas). Ligne 2 (alignee sous le nom) : poids
/// (unitaire ou `NNNg xQ = total`), bouton panier (si non coche), boutons
/// - / quantite / +, menu (Modifier / Supprimer). Appui long = editer.
class ChecklistItemWidget extends StatelessWidget {
  const ChecklistItemWidget({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onQuantityChanged,
    required this.onToggleShoppingList,
    this.onDelete,
  });

  /// Etat complet de l'article (template + coche + poids + quantite...).
  final ChecklistItemState item;

  /// Coche / decoche.
  final VoidCallback onToggle;

  /// Ouvre le dialogue d'edition (poids, et nom si custom).
  final VoidCallback onEdit;

  /// Change la quantite (delta applique par l'appelant).
  final void Function(int newQuantity) onQuantityChanged;

  /// Ajoute / retire de la liste de courses.
  final VoidCallback onToggleShoppingList;

  /// Supprime (articles custom uniquement). Null = non supprimable.
  final VoidCallback? onDelete;

  /// Nom affiche : nom custom si present, sinon resolution i18n du template.
  String _displayName() {
    if (item.isCustom) return item.customName ?? item.template.nameKey;
    final resolved = t['checklist.items.${item.template.nameKey}'];
    return resolved is String ? resolved : item.template.nameKey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ui = t.checklist.ui;
    final unit = t.checklist.weight.grams;
    final isRequired =
        item.template.requirement == ChecklistRequirement.required;
    final name = _displayName();

    // Texte du poids (parite GR20 : unitaire, ou "NNNg xQ = total").
    final weightText = item.weightGrams > 0
        ? (item.quantity > 1
            ? '${item.weightGrams}$unit x${item.quantity} = '
                '${formatChecklistGrams(item.totalWeightGrams)}'
            : formatChecklistGrams(item.weightGrams))
        : null;

    return GestureDetector(
      onLongPress: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : checkbox + pastille + nom + badge Obligatoire.
            Row(
              children: [
                Checkbox(
                  value: item.isChecked,
                  onChanged: (_) => onToggle(),
                  activeColor: AppTheme.vertFacile,
                ),
                const SizedBox(width: 6),
                ChecklistRequirementDot(requirement: item.template.requirement),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.quantity > 1 ? '$name (x${item.quantity})' : name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration:
                          item.isChecked ? TextDecoration.lineThrough : null,
                      color: item.isChecked ? AppTheme.grisGranite : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isRequired)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.rougeUrgence.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock,
                            size: 14, color: AppTheme.rougeUrgence),
                        const SizedBox(width: 2),
                        Text(
                          ui.requirementRequired,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.rougeUrgence,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Ligne 2 : poids + actions (alignees a droite sous le nom).
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Row(
                children: [
                  if (weightText != null)
                    Flexible(
                      child: Text(
                        weightText,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Panier — ajouter/retirer de la liste de courses (non coche).
                  if (!item.isChecked)
                    IconButton(
                      icon: Icon(
                        item.inShoppingList
                            ? Icons.shopping_cart
                            : Icons.add_shopping_cart,
                        size: 18,
                      ),
                      color: item.inShoppingList
                          ? AppTheme.vertFacile
                          : AppTheme.grisGranite,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: onToggleShoppingList,
                      tooltip: item.inShoppingList
                          ? ui.removeFromShoppingList
                          : ui.addToShoppingList,
                    ),
                  // Bouton - (toujours actif : deselectionne sous 1).
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    color: AppTheme.rougeUrgence,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => onQuantityChanged(item.quantity - 1),
                    tooltip: ui.reduceQuantity,
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Bouton +
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    color: AppTheme.vertFacile,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => onQuantityChanged(item.quantity + 1),
                    tooltip: ui.increaseQuantity,
                  ),
                  // Menu edit + delete (delete si custom).
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit,
                                size: 14, color: AppTheme.grisGranite),
                            const SizedBox(width: 8),
                            Text(ui.modify),
                          ],
                        ),
                      ),
                      if (item.isCustom)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  size: 14, color: AppTheme.rougeUrgence),
                              const SizedBox(width: 8),
                              Text(ui.delete,
                                  style: const TextStyle(
                                      color: AppTheme.rougeUrgence)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
