import 'package:flutter/material.dart';

import '../../../core/models/stage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/stage_number_badge.dart';
import 'difficulty_badge.dart';
import 'elevation_indicator.dart';

/// Carte d'étape pour la liste scrollable.
///
/// Affiche : numéro, nom, distance (km), dénivelé D+/D- (m),
/// durée estimée (calculée), badge de difficulté coloré.
/// Un tap déclenche [onTap] pour naviguer vers le détail.
class StageListTile extends StatelessWidget {
  const StageListTile({
    super.key,
    required this.stage,
    this.onTap,
  });

  /// Modèle de l'étape à afficher
  final StageModel stage;

  /// Callback au tap (navigation vers détail)
  final VoidCallback? onTap;

  /// Calcule la durée estimée en heures.
  ///
  /// Formule : distance/4 + D+/400
  /// (vitesse moyenne 4 km/h + 1h par 400m de D+)
  static double estimatedHours(StageModel stage) {
    return stage.distanceKm / 4 + stage.elevationGainM / 400;
  }

  /// Formate la durée en heures et minutes (ex: "3h45")
  static String formatDuration(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = estimatedHours(stage);

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm / 2,
      ),
      child: Row(
        children: [
          // Numéro de l'étape dans un cercle (Hero vers le détail — E5.5a)
          StageNumberBadge(number: stage.stageNumber),
          const SizedBox(width: AppTheme.spacingMd),
          // Infos principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + badge difficulté
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    DifficultyBadge(difficulty: stage.difficulty),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                // Distance + durée
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 14,
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stage.distanceKm.toStringAsFixed(1)} km',
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
                      formatDuration(duration),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                // Dénivelé D+ / D-
                ElevationIndicator(
                  gainM: stage.elevationGainM,
                  lossM: stage.elevationLossM,
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

