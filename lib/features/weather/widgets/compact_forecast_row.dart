import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../models/weather_forecast.dart';
import 'day_forecast_card.dart' show WeatherIcon;

/// Prévisions compactes J+1 / J+2 côte à côte (RF-5).
///
/// Deux tuiles minimalistes (libellé relatif + icône + températures) affichées
/// sous la carte du jour. Utilise un [Row] d'[Expanded] : les cellules se
/// partagent la largeur, aucun débordement horizontal aux largeurs mobiles.
class CompactForecastRow extends StatelessWidget {
  const CompactForecastRow({super.key, required this.days});

  /// Prévisions à venir (on n'affiche que les 2 premières : demain, après-demain).
  final List<DayForecast> days;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final upcoming = days.take(2).toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final labels = <String>[t.weather.tomorrow, t.weather.dayPlus2];

    return Row(
      children: [
        for (var i = 0; i < upcoming.length; i++) ...[
          if (i > 0) const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: _CompactTile(
              label: labels[i],
              day: upcoming[i],
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({required this.label, required this.day});

  final String label;
  final DayForecast day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            children: [
              WeatherIcon(
                iconName: day.weatherIconName,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  '${day.temperatureMax.round()}° / ${day.temperatureMin.round()}°',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
