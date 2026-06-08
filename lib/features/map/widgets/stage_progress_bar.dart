import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Barre de progression d'étape affichée en bas de la carte.
///
/// Affiche le nom de l'étape courante, la distance restante,
/// le pourcentage de progression, et un indicateur "hors tracé"
/// si l'utilisateur est à plus de 100m du sentier.
class StageProgressBar extends StatelessWidget {
  const StageProgressBar({
    super.key,
    required this.stageName,
    required this.distanceRemainingKm,
    required this.progressRatio,
    required this.isOffTrack,
  });

  /// Nom de l'étape courante
  final String stageName;

  /// Distance restante en kilomètres
  final double distanceRemainingKm;

  /// Pourcentage de progression (0.0 à 1.0)
  final double progressRatio;

  /// Indicateur hors tracé (distance > 100m)
  final bool isOffTrack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (progressRatio * 100).round();
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne titre + indicateur hors tracé
          Row(
            children: [
              Expanded(
                child: Text(
                  stageName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isOffTrack)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.rougeUrgence.withAlpha(30),
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusChip,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: AppTheme.rougeUrgence,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hors tracé',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.rougeUrgence,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppTheme.grisClair,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOffTrack ? AppTheme.rougeUrgence : primaryColor,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Ligne distance + pourcentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${distanceRemainingKm.toStringAsFixed(1)} km restants',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
                ),
              ),
              Text(
                '$progressPercent%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
