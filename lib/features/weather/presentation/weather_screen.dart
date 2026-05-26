import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/weather_provider.dart';
import '../widgets/day_forecast_card.dart';
import '../widgets/weather_alert_banner.dart';

/// Écran météo par étape.
///
/// Affiche la prévision à 7 jours avec bandeau d'alerte
/// si des conditions dangereuses sont prévues.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({
    super.key,
    required this.trailId,
    required this.stageNumber,
    required this.latitude,
    required this.longitude,
    required this.stageName,
  });

  final String trailId;
  final int stageNumber;
  final double latitude;
  final double longitude;
  final String stageName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = WeatherStageParams(
      trailId: trailId,
      stageNumber: stageNumber,
      latitude: latitude,
      longitude: longitude,
    );
    final weather = ref.watch(weatherProvider(params));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Météo — $stageName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(weatherProvider(params).notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, theme, weather),
    );
  }

  Widget _buildBody(
      BuildContext context, ThemeData theme, WeatherState weather) {
    if (weather.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (weather.errorMessage != null && weather.forecast == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64),
            const SizedBox(height: AppTheme.spacingBase),
            Text(weather.errorMessage!, style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    final forecast = weather.forecast!;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        // Bandeau d'alerte si conditions dangereuses
        if (weather.alerts.isNotEmpty) ...[
          WeatherAlertBanner(alerts: weather.alerts),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // Indicateur cache
        if (weather.isFromCache)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: Row(
              children: [
                Icon(Icons.cached, size: 14,
                    color: theme.colorScheme.onSurface.withAlpha(120)),
                const SizedBox(width: 4),
                Text(
                  'Données en cache',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),

        // Prévisions par jour
        ...forecast.days.map((day) => DayForecastCard(day: day)),
      ],
    );
  }
}
