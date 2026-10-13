/// La deuxieme ligne d'un article du sac : son poids, et les gestes qui
/// ECRIVENT dessus — panier, quantite, menu — grises en demo.
///
/// Chaque morceau est un sous-widget NOMME (ECR-28) qui recoit ses donnees en
/// parametres nommes : l'etat de l'article et ses callbacks restent chez
/// l'ecran du sac, aucun de ces widgets n'en garde.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/grise_en_demo.dart';
import '../providers/checklist_provider.dart';

/// Le poids de l'article (parite GR20 : unitaire, ou « NNNg xQ = total »).
class _ChecklistItemWeight extends StatelessWidget {
  const _ChecklistItemWeight({required this.weightText});

  /// Le poids deja mis en forme.
  final String weightText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Flexible(
      child: Text(
        weightText,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Le panier : ajoute ou retire l'article de la liste de courses.
class _ChecklistShoppingButton extends StatelessWidget {
  const _ChecklistShoppingButton({
    required this.item,
    required this.onToggleShoppingList,
  });

  /// L'article du sac et son etat.
  final ChecklistItemState item;

  /// Ajoute ou retire de la liste de courses.
  final VoidCallback onToggleShoppingList;

  @override
  Widget build(BuildContext context) {
    final ui = t.checklist.ui;
    return IconButton(
      icon: StepIcon(
        item.inShoppingList ? StepwaysIcons.panier : StepwaysIcons.panier,
        size: 18,
      ),
      color: item.inShoppingList ? AppTheme.vertFacile : AppTheme.grisGranite,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: onToggleShoppingList,
      tooltip: item.inShoppingList
          ? ui.removeFromShoppingList
          : ui.addToShoppingList,
    );
  }
}

/// Les deux boutons de quantite et le nombre entre eux.
class _ChecklistQuantityStepper extends StatelessWidget {
  const _ChecklistQuantityStepper({
    required this.item,
    required this.onQuantityChanged,
  });

  /// L'article du sac et son etat.
  final ChecklistItemState item;

  /// La quantite a change.
  final void Function(int newQuantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ui = t.checklist.ui;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const StepIcon(StepwaysIcons.moins, size: 18),
          color: AppTheme.emergencyRed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
          icon: const StepIcon(StepwaysIcons.plus, size: 18),
          color: AppTheme.vertFacile,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () => onQuantityChanged(item.quantity + 1),
          tooltip: ui.increaseQuantity,
        ),
      ],
    );
  }
}

/// Le menu « Modifier / Supprimer » de l'article.
class _ChecklistItemMenu extends StatelessWidget {
  const _ChecklistItemMenu({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  /// L'article du sac et son etat.
  final ChecklistItemState item;

  /// Ouvre la modification de l'article.
  final VoidCallback onEdit;

  /// Supprime l'article, s'il est supprimable.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ui = t.checklist.ui;
    return PopupMenuButton<String>(
      icon: const StepIcon(StepwaysIcons.menu, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const StepIcon(
                StepwaysIcons.crayon,
                size: 14,
                color: AppTheme.grisGranite,
              ),
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
                const StepIcon(
                  StepwaysIcons.corbeille,
                  size: 14,
                  color: AppTheme.emergencyRed,
                ),
                const SizedBox(width: 8),
                Text(
                  ui.delete,
                  style: const TextStyle(color: AppTheme.emergencyRed),
                ),
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
    );
  }
}

/// Les gestes qui ECRIVENT sur l'article, grises en demo.
class _ChecklistItemActions extends StatelessWidget {
  const _ChecklistItemActions({
    required this.item,
    required this.onQuantityChanged,
    required this.onToggleShoppingList,
    required this.onEdit,
    required this.onDelete,
  });

  /// L'article du sac et son etat.
  final ChecklistItemState item;

  /// La quantite a change.
  final void Function(int newQuantity) onQuantityChanged;

  /// Ajoute ou retire de la liste de courses.
  final VoidCallback onToggleShoppingList;

  /// Ouvre la modification de l'article.
  final VoidCallback onEdit;

  /// Supprime l'article, s'il est supprimable.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GriseEnDemo(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panier — ajouter/retirer de la liste de courses (non coche).
          if (!item.isChecked)
            _ChecklistShoppingButton(
              item: item,
              onToggleShoppingList: onToggleShoppingList,
            ),
          _ChecklistQuantityStepper(
            item: item,
            onQuantityChanged: onQuantityChanged,
          ),
          // Menu edit + delete (delete si custom).
          _ChecklistItemMenu(item: item, onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

/// La deuxieme ligne d'un article : son poids et ses gestes.
class ChecklistItemLine2 extends StatelessWidget {
  const ChecklistItemLine2({
    required this.item,
    required this.weightText,
    required this.onQuantityChanged,
    required this.onToggleShoppingList,
    required this.onEdit,
    required this.onDelete,
  });

  /// L'article du sac et son etat.
  final ChecklistItemState item;

  /// Le poids mis en forme, ou null sans poids.
  final String? weightText;

  /// La quantite a change.
  final void Function(int newQuantity) onQuantityChanged;

  /// Ajoute ou retire de la liste de courses.
  final VoidCallback onToggleShoppingList;

  /// Ouvre la modification de l'article.
  final VoidCallback onEdit;

  /// Supprime l'article, s'il est supprimable.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Row(
        children: [
          if (weightText != null) _ChecklistItemWeight(weightText: weightText!),
          const SizedBox(width: 8),
          // TOUT CE QUI SUIT EST GRISE EN DEMO (tache 638, bug 14 —
          // DEM-260930-1022, verbatim : « laisser 2 menus et griser les
          // autres »).
          //
          // Les deux actions VIVANTES du sac en demo sont la LECTURE de
          // la liste et la COCHE (qui change bien l'etat, en memoire).
          // Tout le reste — liste de courses, quantite, modifier,
          // supprimer — ecrirait en base : c'est donc grise et
          // visiblement indisponible, jamais un bouton qui repond au
          // doigt sans rien faire. Le POIDS de l'article, lui, reste
          // lisible : c'est une information, pas une commande.
          _ChecklistItemActions(
            item: item,
            onQuantityChanged: onQuantityChanged,
            onToggleShoppingList: onToggleShoppingList,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}
