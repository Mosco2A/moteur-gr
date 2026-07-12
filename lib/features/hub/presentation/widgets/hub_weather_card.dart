import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../weather/models/weather_forecast.dart';
import '../../../weather/providers/current_stage_provider.dart';
import '../../../weather/providers/weather_providers.dart';
import '../../../weather/widgets/day_forecast_card.dart' show WeatherIcon;

/// Tuile météo du jour du HUB (AM-3, LOT-B — tuile réelle).
///
/// Remplace le stub LOT-A : affiche la météo du jour de l'étape de référence
/// (étape 1 hors trek, D-3) — icône + température min/max + condition — avec
/// une pastille d'alerte ORAGE si l'étape courante ou le lendemain déclenche
/// une alerte orage. Tap -> écran météo E31. Se dégrade proprement (skeleton en
/// chargement, message discret sinon). Branchée sur [stageWeatherProvider]
/// (coords auto-résolues). Aucun libellé propre à un sentier (cloisonnement).
class HubWeatherCard extends ConsumerWidget {
  const HubWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = Translations.of(context);

    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final stageNumber = ref.watch(referenceStageNumberProvider);
    final params =
        WeatherStageParams(trailId: trailId, stageNumber: stageNumber);
    final state = ref.watch(stageWeatherProvider(params));

    final forecast = state.forecast;
    final today = (forecast != null && forecast.days.isNotEmpty)
        ? forecast.days.first
        : null;

    // Pastille orage : aujourd'hui ou demain au-dessus du seuil.
    final stormSoon = forecast != null &&
        forecast.days.take(2).any((d) => d.stormProbability >= 60);

    // Tap seulement si la route météo est utile (toujours vraie ici : la route
    // E31 existe désormais). Le stub sans onTap (S8) est levé.
    return AppCard(
      onTap: () => context.push('/trail/$trailId/weather?stage=$stageNumber'),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Row(
        children: [
          _leading(context, today, state.isLoading, scheme),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t.hub.weather.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (stormSoon) ...[
                      const SizedBox(width: AppTheme.spacingSm),
                      _StormBadge(label: t.hub.weather.alertStorm),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  _subtitle(context, today, state.isLoading, t),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurface.withAlpha(120)),
        ],
      ),
    );
  }

  Widget _leading(
    BuildContext context,
    DayForecast? today,
    bool loading,
    ColorScheme scheme,
  ) {
    if (today != null) {
      return WeatherIcon(
        iconName: today.weatherIconName,
        size: 32,
        color: scheme.primary,
      );
    }
    if (loading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      Icons.wb_cloudy_outlined,
      size: 32,
      color: scheme.onSurface.withValues(alpha: 0.6),
    );
  }

  String _subtitle(
    BuildContext context,
    DayForecast? today,
    bool loading,
    Translations t,
  ) {
    if (today != null) {
      final temp = t.hub.weather.tempRange(
        min: today.temperatureMin.round(),
        max: today.temperatureMax.round(),
      );
      return '$temp · ${today.weatherDescription}';
    }
    if (loading) return t.weather.loading;
    return t.hub.weather.unavailable;
  }
}

/// Pastille compacte « alerte orage ».
class _StormBadge extends StatelessWidget {
  const _StormBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.rougeUrgence.withAlpha(28),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.thunderstorm,
              size: 13, color: AppTheme.rougeUrgence),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.rougeUrgence,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
