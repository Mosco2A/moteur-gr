import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/stage.dart';

/// Carte d'etape pour la liste scrollable du mode trek.
///
/// Affiche : numero (orderIndex + 1), nom (francais), distance (km),
/// denivele D+/D- (m), duree estimee, badge de difficulte colore.
/// Un tap declenche [onTap] pour naviguer vers le detail.
///
/// Utilise le modele [Stage] du domaine trek (pas le StageModel legacy).
class StageCard extends StatelessWidget {
  const StageCard({
    super.key,
    required this.stage,
    this.onTap,
  });

  /// Modele de l'etape a afficher.
  final Stage stage;

  /// Callback au tap (navigation vers detail).
  final VoidCallback? onTap;

  /// Formate la duree en heures et minutes (ex: "3h45").
  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  /// Couleur associee a la difficulte.
  static Color difficultyColor(String difficulty) {
    return switch (difficulty) {
      'easy' => AppTheme.vertFacile,
      'moderate' => AppTheme.jauneModere,
      'hard' => AppTheme.orangeDifficile,
      'extreme' => AppTheme.rougeExtreme,
      _ => AppTheme.grisGranite,
    };
  }

  /// Libelle traduit de la difficulte.
  static String difficultyLabel(String difficulty) {
    return switch (difficulty) {
      'easy' => 'Facile',
      'moderate' => 'Modere',
      'hard' => 'Difficile',
      'extreme' => 'Extreme',
      _ => difficulty,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = stage.orderIndex + 1;
    final color = difficultyColor(stage.difficulty);
    final label = difficultyLabel(stage.difficulty);

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm / 2,
      ),
      child: Row(
        children: [
          // Numero de l'etape dans un cercle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Infos principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + badge difficulte
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage.nameFr,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(40),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip),
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                // Distance + duree
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 14,
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stage.distance.toStringAsFixed(1)} km',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDuration(stage.estimatedDurationMinutes),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                // Denivele D+ / D-
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: AppTheme.vertFacile,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${stage.elevationGain}m',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.vertFacile,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    const Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: AppTheme.rougeUrgence,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${stage.elevationLoss}m',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.rougeUrgence,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chevron de navigation
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withAlpha(120),
          ),
        ],
      ),
    );
  }
}
