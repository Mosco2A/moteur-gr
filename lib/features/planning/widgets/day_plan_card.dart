import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/day_plan.dart';

/// Carte affichant le plan d'une journée de trek.
///
/// Affiche le numéro du jour, la liste des étapes prévues,
/// la distance totale, le dénivelé et la durée estimée.
/// Si c'est un jour de repos, affiche un message dédié.
class DayPlanCard extends StatelessWidget {
  const DayPlanCard({
    super.key,
    required this.dayPlan,
  });

  /// Le plan du jour à afficher
  final DayPlan dayPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : numéro du jour
          _DayHeader(dayPlan: dayPlan, theme: theme),
          if (dayPlan.isRestDay)
            _RestDayContent(theme: theme)
          else
            _WalkDayContent(dayPlan: dayPlan, theme: theme),
        ],
      ),
    );
  }
}

/// En-tête avec le numéro du jour et un badge repos si applicable
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.dayPlan, required this.theme});

  final DayPlan dayPlan;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Jour ${dayPlan.dayNumber}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (dayPlan.isRestDay) ...[
          const SizedBox(width: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withAlpha(40),
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              'Repos',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Contenu affiché pour un jour de repos
class _RestDayContent extends StatelessWidget {
  const _RestDayContent({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(
            Icons.self_improvement,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            'Jour de repos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(180),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenu affiché pour un jour de marche
class _WalkDayContent extends StatelessWidget {
  const _WalkDayContent({
    required this.dayPlan,
    required this.theme,
  });

  final DayPlan dayPlan;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingSm),
        // Liste des noms d'étapes
        ...dayPlan.stages.map(
          (stage) => Padding(
            padding: const EdgeInsets.only(
              bottom: AppTheme.spacingXs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hiking,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    stage.name,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // Résumé chiffré du jour
        _DayStats(dayPlan: dayPlan, theme: theme),
      ],
    );
  }
}

/// Ligne de statistiques du jour (distance, D+, durée)
class _DayStats extends StatelessWidget {
  const _DayStats({required this.dayPlan, required this.theme});

  final DayPlan dayPlan;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final statStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withAlpha(200),
    );

    return Row(
      children: [
        Icon(Icons.straighten, size: 14,
            color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '${dayPlan.totalDistanceKm.toStringAsFixed(1)} km',
          style: statStyle,
        ),
        const SizedBox(width: AppTheme.spacingBase),
        Icon(Icons.trending_up, size: 14,
            color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '${dayPlan.totalElevationGainM} m D+',
          style: statStyle,
        ),
        const SizedBox(width: AppTheme.spacingBase),
        Icon(Icons.schedule, size: 14,
            color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '${dayPlan.estimatedDurationHours.toStringAsFixed(1)} h',
          style: statStyle,
        ),
      ],
    );
  }
}
