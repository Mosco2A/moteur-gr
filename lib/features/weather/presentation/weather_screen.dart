import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_monitor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../tips/domain/models/tip_card.dart';
import '../data/weather_seed.dart';
import '../models/fire_risk_config.dart';
import '../models/weather_alert.dart';
import '../models/weather_forecast.dart';
import '../providers/current_stage_provider.dart';
import '../providers/weather_providers.dart';
import '../widgets/all_stages_weather_list.dart';
import '../widgets/compact_forecast_row.dart';
import '../widgets/day_forecast_card.dart';
import '../widgets/today_stage_weather_card.dart';
import '../widgets/weather_alert_banner.dart';
import '../widgets/weather_guide_sheet.dart';
import '../widgets/weather_source_banner.dart';

/// Écran météo d'une étape (E31, LOT-B — périmètre dégradé).
///
/// Réutilise le socle données/cache/API via [stageWeatherProvider] (coords
/// auto-résolues, D-1) et expose l'UX de référence : carte du jour + reco
/// (RF-4), prévisions J+1/J+2 (RF-5), « toutes les étapes » (RF-6), bandeau
/// source horodaté (RF-3), toggle alertes orage + guide (RF-1), pull-to-refresh
/// (RF-7). Volet NEIGE / altitude / incendie plein : DIFFÉRÉS (dépendance socle
/// E00). Tous les libellés passent par Slang (cloisonnement, aucun libellé GR20).
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({
    super.key,
    required this.trailId,
    required this.stageNumber,
    this.region = '',
    this.fireRiskConfig = const FireRiskConfig(),
    this.fireTipCard,
  });

  final String trailId;
  final int stageNumber;

  /// Région géographique du sentier pour l'évaluation du risque incendie.
  /// Vide par défaut (config incendie inerte tant que le socle E00 ne
  /// l'alimente pas — dégradation propre, sans alerte).
  final String region;

  /// Config paramétrable du risque incendie (seuils, mois, régions).
  final FireRiskConfig fireRiskConfig;

  /// Fiche conseil incendie pour le CTA (null = pas de CTA).
  final TipCard? fireTipCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final params = WeatherStageParams(
      trailId: trailId,
      stageNumber: stageNumber,
    );
    final weather = ref.watch(stageWeatherProvider(params));
    final stormAlertsEnabled = ref.watch(stormAlertsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.weather.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: t.weather.guideTitle,
            onPressed: () => WeatherGuideSheet.show(context),
          ),
          IconButton(
            icon: Icon(stormAlertsEnabled
                ? Icons.thunderstorm
                : Icons.thunderstorm_outlined),
            tooltip: stormAlertsEnabled
                ? t.weather.stormAlertsToggleOn
                : t.weather.stormAlertsToggleOff,
            onPressed: () => ref
                .read(stormAlertsEnabledProvider.notifier)
                .state = !stormAlertsEnabled,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.weather.refresh,
            onPressed: () =>
                ref.read(stageWeatherProvider(params).notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(stageWeatherProvider(params).notifier).refresh(),
        child: _buildBody(context, ref, theme, weather, t, stormAlertsEnabled),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    WeatherState weather,
    Translations t,
    bool stormAlertsEnabled,
  ) {
    if (weather.isLoading && weather.forecast == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppTheme.spacingBase),
                Text(t.weather.loading, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
    }

    // Repli démo (D-4 / #DP7) : ni réseau ni cache -> seed fictif badgé démo.
    WeatherForecast? forecast = weather.forecast;
    var source = _resolveSource(ref, weather);
    if (forecast == null) {
      final stages = ref.watch(trailStagesProvider(trailId)).value;
      final stage =
          stages?.where((s) => s.stageNumber == stageNumber).firstOrNull;
      if (stage != null) {
        forecast = WeatherSeed.forCoords(
          latitude: stage.startLat,
          longitude: stage.startLng,
        );
        source = WeatherSource.demo;
      }
    }

    if (forecast == null) {
      // Aucune donnée exploitable (étape inconnue + offline).
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 64),
                const SizedBox(height: AppTheme.spacingBase),
                Text(t.weather.error, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      );
    }

    final days = forecast.days;
    final today = days.isNotEmpty ? days.first : null;
    final upcoming = days.length > 1 ? days.sublist(1) : const <DayForecast>[];

    // Alertes météo + incendie, filtrées par le toggle orage (RF-1).
    final fireAlerts = WeatherAlert.fireAlertsFromForecast(
      forecast,
      fireConfig: fireRiskConfig,
      region: region,
    );
    final allAlerts = [...weather.alerts, ...fireAlerts].where((a) {
      if (!stormAlertsEnabled && a.kind == WeatherAlertKind.storm) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        WeatherSourceBanner(source: source, updatedAt: today?.date),
        const SizedBox(height: AppTheme.spacingSm),
        if (allAlerts.isNotEmpty) ...[
          WeatherAlertBanner(alerts: allAlerts, fireTipCard: fireTipCard),
          const SizedBox(height: AppTheme.spacingBase),
        ],
        if (today != null) ...[
          TodayStageWeatherCard(day: today),
          const SizedBox(height: AppTheme.spacingBase),
        ],
        if (upcoming.isNotEmpty) ...[
          CompactForecastRow(days: upcoming),
          const SizedBox(height: AppTheme.spacingBase),
        ],
        AllStagesWeatherList(trailId: trailId),
        const SizedBox(height: AppTheme.spacingLg),
        // Détail jour par jour (socle réutilisé).
        ...days.map((day) => DayForecastCard(day: day)),
      ],
    );
  }

  /// Détermine la source affichée : cache si l'état vient du cache, sinon
  /// online/offline selon la connectivité courante.
  WeatherSource _resolveSource(WidgetRef ref, WeatherState weather) {
    if (weather.isFromCache) return WeatherSource.cache;
    final status = ref
            .watch(connectivityProvider)
            .value ??
        ConnectivityStatusValues.offline;
    return status == ConnectivityStatusValues.online
        ? WeatherSource.api
        : WeatherSource.offline;
  }
}
