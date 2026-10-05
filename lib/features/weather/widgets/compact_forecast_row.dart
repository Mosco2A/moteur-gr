/// Les deux jours suivants cote a cote, en cellules a largeur partagee : aucun
/// debordement horizontal sur un ecran etroit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/temperature_unit.dart'
    show TemperatureUnit, formatTemperatureRange;
import '../../../i18n/translations.g.dart';
import '../../settings/settings_facade.dart' show settingsProvider;
import '../models/weather_forecast.dart';
import 'day_forecast_card.dart' show WeatherIcon;

/// Prévisions compactes J+1 / J+2 côte à côte (RF-5).
///
/// Deux tuiles minimalistes (libellé relatif + icône + températures) affichées
/// sous la carte du jour. Utilise un [Row] d'[Expanded] : les cellules se
/// partagent la largeur, aucun débordement horizontal aux largeurs mobiles.
/// P2 (#101255 point 2) : la rangee lit l'unite UNE fois et la passe a ses deux
/// tuiles — un seul abonnement au reglage pour les deux cellules.
class CompactForecastRow extends ConsumerWidget {
  const CompactForecastRow({super.key, required this.days});

  /// Prévisions à venir (on n'affiche que les 2 premières : demain, après-demain).
  final List<DayForecast> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final upcoming = days.take(2).toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final labels = <String>[t.weather.tomorrow, t.weather.dayPlus2];
    final unit = ref.watch(settingsProvider.select((s) => s.temperatureUnit));

    return Row(
      children: [
        for (var i = 0; i < upcoming.length; i++) ...[
          if (i > 0) const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: _CompactTile(label: labels[i], day: upcoming[i], unit: unit),
          ),
        ],
      ],
    );
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({
    required this.label,
    required this.day,
    required this.unit,
  });

  final String label;
  final DayForecast day;
  final TemperatureUnit unit;

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
                  formatTemperatureRange(
                    day.temperatureMax,
                    day.temperatureMin,
                    unit,
                  ),
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
