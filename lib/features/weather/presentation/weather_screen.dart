import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../tips/domain/models/tip_card.dart';
import '../models/fire_risk_config.dart';
import '../models/weather_alert.dart';
import '../providers/weather_provider.dart';
import '../widgets/day_forecast_card.dart';
import '../widgets/weather_alert_banner.dart';

/// Ecran meteo par etape.
///
/// Affiche la prevision a 7 jours avec bandeau d'alerte
/// si des conditions dangereuses sont prevues.
/// Supporte les alertes incendie parametrables via [FireRiskConfig]
/// avec lien vers la fiche conseil securite_incendie.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({
    super.key,
    required this.trailId,
    required this.stageNumber,
    required this.latitude,
    required this.longitude,
    required this.stageName,
    required this.region,
    this.fireRiskConfig = const FireRiskConfig(),
    this.fireTipCard,
  });

  final String trailId;
  final int stageNumber;
  final double latitude;
  final double longitude;
  final String stageName;

  /// Region geographique du sentier pour evaluation du risque incendie
  final String region;

  /// Config parametrable du risque incendie (seuils, mois, regions)
  final FireRiskConfig fireRiskConfig;

  /// Fiche conseil incendie pour le CTA (null = pas de CTA)
  final TipCard? fireTipCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
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
        title: Text('${t.weather.title} — $stageName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.weather.refresh,
            onPressed: () =>
                ref.read(weatherProvider(params).notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, theme, weather, t),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    WeatherState weather,
    Translations t,
  ) {
    if (weather.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppTheme.spacingBase),
            Text(t.weather.loading, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (weather.errorMessage != null && weather.forecast == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64),
            const SizedBox(height: AppTheme.spacingBase),
            Text(t.weather.error, style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    final forecast = weather.forecast!;

    // Combiner alertes meteo classiques + alertes incendie
    final fireAlerts = WeatherAlert.fireAlertsFromForecast(
      forecast,
      fireConfig: fireRiskConfig,
      region: region,
    );
    final allAlerts = [...weather.alerts, ...fireAlerts];

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        // Bandeau d'alerte si conditions dangereuses
        if (allAlerts.isNotEmpty) ...[
          WeatherAlertBanner(
            alerts: allAlerts,
            fireTipCard: fireTipCard,
          ),
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
                  t.weather.cached,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),

        // Previsions par jour
        ...forecast.days.map((day) => DayForecastCard(day: day)),
      ],
    );
  }
}
