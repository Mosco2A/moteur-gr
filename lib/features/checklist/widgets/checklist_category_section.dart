import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/checklist_provider.dart';

/// Section de categorie dans la checklist materiel.
///
/// Affiche un titre de categorie avec sa barre de progression
/// et la liste des items cochables.
class ChecklistCategorySection extends StatelessWidget {
  const ChecklistCategorySection({
    super.key,
    required this.categoryName,
    required this.items,
    required this.onToggle,
  });

  /// Nom traduit de la categorie
  final String categoryName;

  /// Items de cette categorie
  final List<ChecklistItemState> items;

  /// Callback quand un item est coche/decoche
  final void Function(String itemId) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checked = items.where((i) => i.isChecked).length;
    final total = items.length;
    final progress = total > 0 ? checked / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tete categorie avec progression
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '$checked/$total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        // Barre de progression de la categorie
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor:
                  theme.colorScheme.onSurface.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0
                    ? AppTheme.vertFacile
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // Liste des items
        ...items.map((item) => _ChecklistItemTile(
              item: item,
              onToggle: () => onToggle(item.template.id),
            )),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}

/// Tuile individuelle d un item de checklist.
class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.item,
    required this.onToggle,
  });

  final ChecklistItemState item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (_) => onToggle(),
        activeColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(
        item.template.nameKey,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration:
              item.isChecked ? TextDecoration.lineThrough : null,
          color: item.isChecked
              ? theme.colorScheme.onSurface.withAlpha(120)
              : null,
        ),
      ),
      trailing: item.template.isEssential
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                color: AppTheme.rougeUrgence.withAlpha(40),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Text(
                '!',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.rougeUrgence,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: onToggle,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
      ),
      dense: true,
    );
  }
}
