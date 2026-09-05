import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Selecteur de duree pour le programme (parite GR20 : choix du nombre de jours).
///
/// Affiche un libelle puis une rangee (defilante horizontalement) de
/// [ChoiceChip] permettant de choisir le nombre de jours parmi les durees
/// proposees. Le chip actif correspond a la duree actuellement selectionnee.
/// Le defilement horizontal evite tout debordement quand le sentier propose
/// beaucoup de durees (liste derivee du nombre d'etapes).
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.availableDurations,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  /// Liste des durees proposees (en jours)
  final List<int> availableDurations;

  /// Duree actuellement selectionnee
  final int selectedDuration;

  /// Callback appele quand l'utilisateur change la duree
  final ValueChanged<int> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.programme.duration.label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableDurations.map((duration) {
                final isSelected = duration == selectedDuration;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXs,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      t.programme.duration.days
                          .replaceAll('{count}', '$duration'),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                    onSelected: (_) => onDurationChanged(duration),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
