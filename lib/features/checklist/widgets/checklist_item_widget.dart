import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Widget cochable representant un item de checklist materiel.
///
/// Affiche le nom traduit via Slang, une checkbox interactive,
/// et un badge "essentiel" si applicable.
/// Le barrage du texte indique visuellement les items coches.
class ChecklistItemWidget extends StatelessWidget {
  const ChecklistItemWidget({
    super.key,
    required this.itemId,
    required this.nameKey,
    required this.isChecked,
    required this.isEssential,
    required this.onToggle,
    this.weightGrams = 0,
    this.onEditWeight,
  });

  /// Identifiant unique de l'item (ex: 'backpack')
  final String itemId;

  /// Cle i18n de l'item (correspond a checklist.items.*)
  final String nameKey;

  /// Etat coche/decoche
  final bool isChecked;

  /// Item marque comme essentiel
  final bool isEssential;

  /// Callback au cochage/decochage
  final VoidCallback onToggle;

  /// Poids unitaire courant en grammes (parite GR20 « Materiel & Sac »).
  final int weightGrams;

  /// Callback d'edition du poids (chip poids tapable). Null = non editable.
  final VoidCallback? onEditWeight;

  /// Resout le nom traduit via Slang (lookup dynamique).
  /// Retourne la cle brute si aucune traduction trouvee.
  String _resolvedName() {
    final resolved = t['checklist.items.$nameKey'];
    if (resolved is String) return resolved;
    return nameKey;
  }

  /// Formate un poids en grammes -> "1,2 kg" ou "350 g" (parite GR20).
  String _formatWeight() {
    if (weightGrams >= 1000) {
      final kg = weightGrams / 1000.0;
      return '${kg.toStringAsFixed(kg.truncateToDouble() == kg ? 0 : 1)}'
          ' ${t.checklist.weight.kilograms}';
    }
    return '$weightGrams ${t.checklist.weight.grams}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checklistT = t.checklist;
    final displayName = _resolvedName();

    // Chip poids (parite GR20) : affiche le poids unitaire, tapable pour editer.
    // Masque pour un item porte / non pese (0 g) afin de ne pas suggerer une
    // contribution nulle comme un choix.
    final Widget? weightChip = weightGrams > 0
        ? _WeightChip(
            label: _formatWeight(),
            onTap: onEditWeight,
          )
        : (onEditWeight != null
            ? _WeightChip(
                label: '— ${t.checklist.weight.grams}',
                onTap: onEditWeight,
                muted: true,
              )
            : null);

    // Badge "essentiel" (rouge) + chip poids alignes a droite.
    final trailingChildren = <Widget>[
      if (isEssential)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: AppTheme.rougeUrgence.withAlpha(40),
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          ),
          child: Text(
            checklistT.essential,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.rougeUrgence,
              fontSize: 10,
            ),
          ),
        ),
      if (weightChip != null) ...[
        if (isEssential) const SizedBox(width: AppTheme.spacingXs),
        weightChip,
      ],
    ];

    return ListTile(
      leading: Checkbox(
        value: isChecked,
        onChanged: (_) => onToggle(),
        activeColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(
        displayName,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: isChecked ? TextDecoration.lineThrough : null,
          color: isChecked
              ? theme.colorScheme.onSurface.withAlpha(120)
              : null,
        ),
      ),
      trailing: trailingChildren.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: trailingChildren,
            ),
      onTap: onToggle,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
      ),
      dense: true,
    );
  }
}

/// Chip poids unitaire d'un item (parite GR20 « Materiel & Sac »).
///
/// Tapable pour ouvrir l'edition du poids. [muted] grise le rendu pour un item
/// dont le poids n'est pas encore renseigne.
class _WeightChip extends StatelessWidget {
  const _WeightChip({
    required this.label,
    this.onTap,
    this.muted = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = muted
        ? theme.colorScheme.onSurface.withAlpha(120)
        : theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.scale_outlined, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
