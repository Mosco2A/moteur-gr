import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Sélecteur de durée pour le planning.
///
/// Affiche une rangée de ChoiceChip permettant de choisir
/// le nombre de jours parmi les durées disponibles.
/// Le chip actif correspond à la durée actuellement sélectionnée.
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.availableDurations,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  /// Liste des durées proposées (en jours)
  final List<int> availableDurations;

  /// Durée actuellement sélectionnée
  final int selectedDuration;

  /// Callback appelé quand l'utilisateur change la durée
  final ValueChanged<int> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: availableDurations.map((duration) {
          final isSelected = duration == selectedDuration;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXs,
            ),
            child: ChoiceChip(
              label: Text(
                '$duration j',
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
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusChip),
              ),
              onSelected: (_) => onDurationChanged(duration),
            ),
          );
        }).toList(),
      ),
    );
  }
}
