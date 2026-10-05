/// Vue d'ensemble avant de partir : une ligne depliable par etape, sa meteo
/// chargee seulement a l'ouverture de la ligne.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/temperature_unit.dart'
    show TemperatureUnit, formatTemperatureRange;
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../settings/settings_facade.dart' show settingsProvider;
import '../models/weather_forecast.dart' show DayForecast;
import '../providers/current_stage_provider.dart';
import '../providers/weather_providers.dart';
import 'day_forecast_card.dart' show WeatherIcon;
import '../../../core/branding/stepways_icons.dart';

/// Vue « Toutes les étapes » (RF-6) : liste dépliable de la météo par étape.
///
/// Un [ExpansionTile] par sentier ; chaque ligne affiche l'étape et sa météo
/// du jour (icône + températures), chargée paresseusement via
/// [stageWeatherProvider]. Pensée pour la préparation : vue d'ensemble avant
/// de partir. Aucun libellé propre à un sentier (cloisonnement).
class AllStagesWeatherList extends ConsumerWidget {
  const AllStagesWeatherList({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final stagesAsync = ref.watch(trailStagesProvider(trailId));

    // SW-SKIN-L3b : Card -> AppCard (grammaire unifiee). padding zero car
    // l'ExpansionTile gere sa propre mise en page pleine largeur ; AppCard
    // clippe deja au rayon de la carte (Material antiAlias interne) comme le
    // faisait clipBehavior: Clip.antiAlias. Rendu conserve.
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const StepIcon(StepwaysIcons.questionnaire),
        title: Text(t.weather.allStages, style: theme.textTheme.titleMedium),
        childrenPadding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        children: stagesAsync.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingBase),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, __) => [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Text(t.weather.error, style: theme.textTheme.bodySmall),
            ),
          ],
          data: (stages) {
            if (stages.isEmpty) {
              return [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingBase),
                  child: Text(
                    t.weather.noForecast,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ];
            }
            return [
              for (final stage in stages)
                _StageWeatherRow(trailId: trailId, stage: stage),
            ];
          },
        ),
      ),
    );
  }
}

/// Ligne compacte : numéro/nom d'étape + météo du jour (chargée à la demande).
class _StageWeatherRow extends ConsumerWidget {
  const _StageWeatherRow({required this.trailId, required this.stage});

  final String trailId;
  final Stage stage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final params = WeatherStageParams(
      trailId: trailId,
      stageNumber: stage.stageNumber,
    );
    final unit = ref.watch(settingsProvider.select((s) => s.temperatureUnit));
    // Météo du 1er jour de l'étape via le provider dérivé (select forecast).
    final forecast = ref.watch(weatherForecastProvider(params));
    final today = (forecast != null && forecast.days.isNotEmpty)
        ? forecast.days.first
        : null;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          '${stage.stageNumber}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        stage.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        t.weather.stageLabel(number: stage.stageNumber),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(150),
        ),
      ),
      trailing: _meteoDuJour(context, today, unit),
    );
  }

  /// Icône + températures du jour, ou un voile de chargement.
  ///
  /// EXTRAIT DU `build` PAR LE LOT PRODUIT P1 (#101255). La lecture du réglage
  /// d'unité ajoutait quatre lignes à un `build` qui en comptait déjà 60 : il
  /// aurait franchi le plafond ECR-28 sans rien apporter de neuf. Le bloc sort
  /// donc dans sa propre méthode, et le compteur ne monte pas.
  Widget _meteoDuJour(
    BuildContext context,
    DayForecast? today,
    TemperatureUnit unit,
  ) {
    if (today == null) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WeatherIcon(
          iconName: today.weatherIconName,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          formatTemperatureRange(
            today.temperatureMax,
            today.temperatureMin,
            unit,
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
