import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/weather_forecast.dart';
import '../presentation/weather_date_format.dart';

/// Carte de prévision pour un jour.
///
/// Affiche la température, les précipitations, le vent et l'UV
/// avec un code couleur selon les conditions.
class DayForecastCard extends StatelessWidget {
  const DayForecastCard({super.key, required this.day});

  final DayForecast day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // LOT-B (RF-15) : locale courante au lieu de 'fr_FR' figé (cloisonnement).
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAlert = day.isAlertCondition;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: isAlert
            ? const BorderSide(color: AppTheme.rougeUrgence, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + icône météo
            Row(
              children: [
                WeatherIcon(
                  iconName: day.weatherIconName,
                  size: 28,
                  color: isAlert
                      ? AppTheme.rougeUrgence
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatWeatherDate(day.date, 'EEEE d MMM', languageCode),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        day.weatherDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
                // Température
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${day.temperatureMax.round()}°',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _tempColor(day.temperatureMax),
                      ),
                    ),
                    Text(
                      '${day.temperatureMin.round()}°',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Détails : précipitations, vent, UV.
            // Wrap (pas Row) : évite tout débordement horizontal aux largeurs
            // mobiles étroites (retour Lot A #95062).
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingXs,
              children: [
                _detailChip(
                  context,
                  Icons.water_drop,
                  '${day.precipitationMm.round()} mm',
                  day.precipitationMm >= 20,
                ),
                _detailChip(
                  context,
                  Icons.air,
                  '${day.windSpeedKmh.round()} km/h',
                  day.windSpeedKmh >= 60,
                ),
                _detailChip(
                  context,
                  Icons.wb_sunny_outlined,
                  'UV ${day.uvIndex.round()}',
                  day.uvIndex >= 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(
      BuildContext context, IconData icon, String label, bool isDanger) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isDanger
            ? AppTheme.rougeUrgence.withAlpha(30)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14,
              color: isDanger ? AppTheme.rougeUrgence : null),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDanger ? AppTheme.rougeUrgence : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _tempColor(double temp) {
    if (temp <= 0) return AppTheme.rougeExtreme;
    if (temp <= 10) return AppTheme.orangeDifficile;
    if (temp <= 25) return AppTheme.vertFacile;
    return AppTheme.rougeUrgence;
  }
}

/// Icône Material dérivée du nom de condition météo (`DayForecast.weatherIconName`).
///
/// Widget partagé par les cartes météo (jour, aujourd'hui, tuile HUB) pour
/// éviter la duplication du mapping nom → [IconData].
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.iconName,
    this.size = 24,
    this.color,
  });

  final String iconName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(_iconFor(iconName), size: size, color: color);
  }

  static IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'cloud':
        return Icons.cloud;
      case 'foggy':
        return Icons.foggy;
      case 'grain':
        return Icons.grain;
      case 'water_drop':
        return Icons.water_drop;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.thunderstorm;
      default:
        return Icons.cloud;
    }
  }
}
