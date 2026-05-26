import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/weather_alert.dart';

/// Bandeau d'alerte météo en haut de l'écran.
///
/// Affiche les alertes actives avec un code couleur
/// selon la sévérité (warning = orange, danger = rouge).
class WeatherAlertBanner extends StatelessWidget {
  const WeatherAlertBanner({super.key, required this.alerts});

  final List<WeatherAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDanger = alerts.any((a) => a.severity == 'danger');

    return Container(
      decoration: BoxDecoration(
        color: hasDanger
            ? AppTheme.rougeUrgence.withAlpha(30)
            : AppTheme.orangeDifficile.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: hasDanger ? AppTheme.rougeUrgence : AppTheme.orangeDifficile,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color:
                    hasDanger ? AppTheme.rougeUrgence : AppTheme.orangeDifficile,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                '${alerts.length} alerte${alerts.length > 1 ? 's' : ''} météo',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: hasDanger
                      ? AppTheme.rougeUrgence
                      : AppTheme.orangeDifficile,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    alert.severity == 'danger'
                        ? Icons.dangerous
                        : Icons.warning,
                    size: 16,
                    color: alert.severity == 'danger'
                        ? AppTheme.rougeUrgence
                        : AppTheme.orangeDifficile,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Text(
                      '${alert.title} — ${alert.description}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
