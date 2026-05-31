import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/checklist_provider.dart';
import 'checklist_item_widget.dart';

/// Section de categorie dans la checklist materiel (E3.2b).
///
/// Affiche un titre de categorie avec sa barre de progression
/// et la liste des items cochables via ChecklistItemWidget.
class ChecklistCategorySection extends StatelessWidget {
  const ChecklistCategorySection({
    super.key,
    required this.categoryName,
    required this.items,
    required this.onToggle,
  });

  /// Nom traduit de la categorie (resolu via Slang dans le screen)
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
        // Liste des items via ChecklistItemWidget
        ...items.map((item) => ChecklistItemWidget(
              itemId: item.template.id,
              nameKey: item.template.nameKey,
              isChecked: item.isChecked,
              isEssential: item.template.isEssential,
              onToggle: () => onToggle(item.template.id),
            )),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}
