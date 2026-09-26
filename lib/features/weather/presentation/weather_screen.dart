import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_monitor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_header.dart';
import '../../tips/domain/models/tip_card.dart';
import '../data/weather_seed.dart';
import '../models/fire_risk_config.dart';
import '../models/weather_alert.dart';
import '../models/weather_forecast.dart';
import '../providers/current_stage_provider.dart';
import '../providers/program_weather_provider.dart';
import '../providers/weather_providers.dart';
import '../widgets/all_stages_weather_list.dart';
import '../widgets/compact_forecast_row.dart';
import '../widgets/program_weather_list.dart';
import '../widgets/today_stage_weather_card.dart';
import '../widgets/weather_alert_banner.dart';
import '../widgets/weather_guide_sheet.dart';
import '../widgets/weather_source_banner.dart';
import 'weather_freshness.dart';

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
      // Ph5 (L6c) : AppHeader universel + actions conservees (guide / alertes
      // orage / rafraichir) — parite ecran, aucune action perdue.
      appBar: AppHeader(
        title: t.weather.title,
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
            onPressed: () => _refresh(context, ref, params),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref, params, silent: true),
        child: _buildBody(context, ref, theme, weather, t, stormAlertsEnabled),
      ),
    );
  }

  /// Rafraichit l'etape affichee ET toutes les etapes du PROGRAMME.
  ///
  /// TACHE 572 (U2). Le bouton ne rafraichissait que l'etape ouverte, alors que
  /// l'ecran montre desormais le temps de chaque journee du programme : une
  /// partie de l'ecran restait donc vieille apres un « Actualiser », ce qui est
  /// une autre facon de ne rien produire. On rafraichit ce qu'on affiche, et le
  /// resultat est ANNONCE — reussi, partiel, ou impossible.
  Future<void> _refresh(
    BuildContext context,
    WidgetRef ref,
    WeatherStageParams params, {
    bool silent = false,
  }) async {
    final t = Translations.of(context);
    final messenger = silent ? null : ScaffoldMessenger.of(context);

    // Etapes a rafraichir : celle qu'on regarde + celles que le programme nomme
    // (dedoublonnees : deux journees qui finissent au meme endroit, ou un repos
    // qui suit une etape, ne declenchent qu'un appel).
    final stageNumbers = <int>{params.stageNumber};
    for (final day in ref.read(programWeatherProvider(trailId)).days) {
      if (day.stageNumber > 0) stageNumbers.add(day.stageNumber);
    }

    final results = await Future.wait([
      for (final n in stageNumbers)
        ref
            .read(stageWeatherProvider(
              WeatherStageParams(trailId: trailId, stageNumber: n),
            ).notifier)
            .refresh(),
    ]);

    if (messenger == null || !context.mounted) return;
    final ok = results.where((r) => r).length;
    if (ok == results.length) {
      final at = ref
          .read(stageWeatherProvider(params))
          .forecast
          ?.fetchedAt;
      messenger.showSnackBar(SnackBar(
        content: Text(t.weather.refreshedAt(
          date: at == null ? '-' : formatFetchedAt(at),
        )),
      ));
    } else if (ok == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.weather.error)),
      );
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(t.weather.refreshPartial(
          done: ok,
          total: results.length,
        )),
      ));
    }
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
        // TACHE 572 (U2) : l'horodatage est l'INSTANT DU RELEVE, plus le jour du
        // bulletin. C'est lui qui bouge quand « Actualiser » aboutit — c'etait
        // la seule chose a l'ecran capable de prouver que le bouton a agi, et
        // elle affichait une date qui ne changeait jamais.
        WeatherSourceBanner(source: source, updatedAt: forecast.fetchedAt),
        const SizedBox(height: AppTheme.spacingSm),

        // TACHE 572 (U2) : un rafraichissement RATE se voit. Avant, l'echec
        // etait ecrit dans `WeatherState.errorMessage` et lu par personne. On
        // regarde les DEUX signaux : aucun echec present dans l'etat ne doit
        // pouvoir rester muet, quelle que soit la branche qui l'a pose.
        if (weather.refreshFailed || weather.errorMessage != null) ...[
          _RefreshFailedBanner(fetchedAt: forecast.fetchedAt),
          const SizedBox(height: AppTheme.spacingSm),
        ],

        if (allAlerts.isNotEmpty) ...[
          WeatherAlertBanner(alerts: allAlerts, fireTipCard: fireTipCard),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // « Meteo = ici et maintenant, ok » (Chris) : la carte du jour au point
        // ou on se trouve reste en tete, elle sert a s'habiller le matin.
        if (today != null) ...[
          TodayStageWeatherCard(day: today),
          const SizedBox(height: AppTheme.spacingBase),
        ],
        if (upcoming.isNotEmpty) ...[
          CompactForecastRow(days: upcoming),
          const SizedBox(height: AppTheme.spacingBase),
        ],

        // ... « mais indiquer le lieu des etapes et la meteo des etapes, pas
        // celle du jour ». C'est CETTE section qui sert a decider : une journee
        // de programme par ligne, son lieu d'arrivee NOMME, sa date, son temps.
        // Elle remplace l'ancienne liste « jour par jour » du bulletin d'un seul
        // point, qui melangeait les index d'API et les journees de marche.
        ProgramWeatherList(trailId: trailId),
        const SizedBox(height: AppTheme.spacingLg),

        AllStagesWeatherList(trailId: trailId),
        const SizedBox(height: AppTheme.spacingLg),
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

/// Bandeau « la mise a jour n'a pas abouti » (tache 572, U2).
///
/// Un bouton qui echoue en silence est pire qu'un bouton absent : le randonneur
/// croit disposer d'une donnee fraiche. Le bandeau dit l'echec ET l'age de ce qui
/// reste affiche, pour qu'il sache sur quoi il decide.
class _RefreshFailedBanner extends StatelessWidget {
  const _RefreshFailedBanner({required this.fetchedAt});

  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    const color = AppTheme.orangeDifficile;
    final message = fetchedAt == null
        ? t.weather.refreshFailedNoData
        : t.weather.refreshFailed(date: formatFetchedAt(fetchedAt!));

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sync_problem, size: 18, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
