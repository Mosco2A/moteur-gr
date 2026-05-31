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

  /// Resout le nom traduit via Slang (lookup dynamique).
  /// Retourne la cle brute si aucune traduction trouvee.
  String _resolvedName() {
    final resolved = t['checklist.items.$nameKey'];
    if (resolved is String) return resolved;
    return nameKey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checklistT = t.checklist;
    final displayName = _resolvedName();

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
      // Badge "essentiel" via Slang
      trailing: isEssential
          ? Container(
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
