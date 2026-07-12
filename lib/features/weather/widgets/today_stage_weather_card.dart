import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../domain/weather_recommendation.dart';
import '../models/weather_forecast.dart';
import 'day_forecast_card.dart' show WeatherIcon;

/// Carte « étape en cours » : météo du jour mise en avant (RF-4).
///
/// Affiche la condition dominante, les températures min/max, les 4 indicateurs
/// clés (précipitations, vent, UV, probabilité d'orage) et une recommandation
/// de randonnée dérivée (3 niveaux). Tous les libellés passent par Slang.
class TodayStageWeatherCard extends StatelessWidget {
  const TodayStageWeatherCard({super.key, required this.day});

  final DayForecast day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final level = WeatherRecommendation.forDay(day);
    final (Color recoColor, String recoLabel) = switch (level) {
      WeatherRecommendationLevel.ok => (
          AppTheme.vertFacile,
          t.weather.recommendation.ok
        ),
      WeatherRecommendationLevel.watch => (
          AppTheme.orangeDifficile,
          t.weather.recommendation.watch
        ),
      WeatherRecommendationLevel.danger => (
          AppTheme.rougeUrgence,
          t.weather.recommendation.danger
        ),
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : « Aujourd'hui » + condition + températures.
            Row(
              children: [
                WeatherIcon(
                  iconName: day.weatherIconName,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingBase),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.weather.today,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          )),
                      Text(
                        day.weatherDescription,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  '${day.temperatureMax.round()}° / ${day.temperatureMin.round()}°',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // 4 indicateurs clés (wrap : jamais d'overflow horizontal).
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: [
                _Indicator(
                  icon: Icons.water_drop,
                  label: '${day.precipitationMm.round()} mm',
                  danger: day.precipitationMm >= 20,
                ),
                _Indicator(
                  icon: Icons.air,
                  label: '${day.windSpeedKmh.round()} km/h',
                  danger: day.windSpeedKmh >= 60,
                ),
                _Indicator(
                  icon: Icons.wb_sunny_outlined,
                  label: 'UV ${day.uvIndex.round()}',
                  danger: day.uvIndex >= 8,
                ),
                _Indicator(
                  icon: Icons.thunderstorm_outlined,
                  label: '${day.stormProbability.round()} %',
                  danger: day.stormProbability >= 50,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // Bandeau recommandation.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: recoColor.withAlpha(28),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Row(
                children: [
                  Icon(_recoIcon(level), size: 18, color: recoColor),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      recoLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: recoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _recoIcon(WeatherRecommendationLevel level) {
    switch (level) {
      case WeatherRecommendationLevel.ok:
        return Icons.check_circle_outline;
      case WeatherRecommendationLevel.watch:
        return Icons.info_outline;
      case WeatherRecommendationLevel.danger:
        return Icons.warning_amber_rounded;
    }
  }
}

/// Puce indicateur compacte (icône + valeur), rouge si seuil dépassé.
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.icon,
    required this.label,
    required this.danger,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger ? AppTheme.rougeUrgence : null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: danger
            ? AppTheme.rougeUrgence.withAlpha(28)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
