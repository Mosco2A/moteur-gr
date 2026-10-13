/// Un article sur deux lignes : coche, exigence, nom barre une fois pris,
/// cadenas si obligatoire, puis poids et quantite dessous.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';
import 'checklist_weight_banner.dart' show formatChecklistGrams;
import '../../../core/branding/stepways_icons.dart';
import 'checklist_item_actions.dart';

/// Pastille coloree du niveau d'exigence (parite GR20 — _RequirementDot).
class ChecklistRequirementDot extends StatelessWidget {
  const ChecklistRequirementDot({super.key, required this.requirement});

  final ChecklistRequirement requirement;

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    switch (requirement) {
      case ChecklistRequirement.required:
        dotColor = AppTheme.emergencyRed;
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
            _ChecklistItemLine1(
              item: item,
              name: name,
              isRequired: isRequired,
              onToggle: onToggle,
            ),
            // Ligne 2 : poids + actions (alignees a droite sous le nom).
            ChecklistItemLine2(
              item: item,
              weightText: weightText,
              onQuantityChanged: onQuantityChanged,
              onToggleShoppingList: onToggleShoppingList,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Le nom de l'article, sur deux lignes au plus (retour Chris #10).
class _ChecklistItemName extends StatelessWidget {
  const _ChecklistItemName({required this.item, required this.name});

  /// L'article du sac et son etat.
  final ChecklistItemState item;

  /// Le nom affichable de l'article.
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Text(
        item.quantity > 1 ? '$name (x${item.quantity})' : name,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: item.isChecked ? TextDecoration.lineThrough : null,
          color: item.isChecked ? AppTheme.grisGranite : null,
        ),
      ),
    );
  }
}

/// Le badge « Obligatoire » d'un article que le sentier impose.
class _ChecklistRequiredBadge extends StatelessWidget {
  const _ChecklistRequiredBadge();

  @override
  Widget build(BuildContext context) {
    final ui = t.checklist.ui;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.emergencyRed.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StepIcon(
            StepwaysIcons.cadenas,
            size: 14,
            color: AppTheme.emergencyRed,
          ),
          const SizedBox(width: 2),
          Text(
            ui.requirementRequired,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.emergencyRed,
            ),
          ),
        ],
      ),
    );
  }
}

/// La premiere ligne d'un article : coche, pastille, nom et badge.
class _ChecklistItemLine1 extends StatelessWidget {
  const _ChecklistItemLine1({
    required this.item,
    required this.name,
    required this.isRequired,
    required this.onToggle,
  });

  /// L'article du sac et son etat.
  final ChecklistItemState item;

  /// Le nom affichable de l'article.
  final String name;

  /// Vrai quand le sentier impose l'article.
  final bool isRequired;

  /// Coche ou decoche l'article.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: item.isChecked,
          onChanged: (_) => onToggle(),
          activeColor: AppTheme.vertFacile,
        ),
        const SizedBox(width: 6),
        ChecklistRequirementDot(requirement: item.template.requirement),
        const SizedBox(width: 6),
        _ChecklistItemName(item: item, name: name),
        if (isRequired) const _ChecklistRequiredBadge(),
      ],
    );
  }
}
