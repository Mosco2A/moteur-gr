import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_icon_colors.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../weather/models/weather_forecast.dart';
import '../../../weather/presentation/fire_risk_screen.dart' show fireRiskColor;
import '../../../weather/providers/current_stage_provider.dart';
import '../../../weather/providers/fire_risk_providers.dart'
    show FireRiskDay, trailFireRiskProvider;
import '../../../weather/providers/weather_providers.dart';
import '../../../weather/widgets/day_forecast_card.dart' show WeatherIcon;

/// BANDEAU « ICI ET MAINTENANT » — MÉTÉO PENDANT LA RANDO, AU JOUR J (R11).
///
/// Parité GR20 : côté GR20 la météo n'est PAS dans la préparation — elle est
/// joignable en TERRAIN (section « Randonner » du HUB -> écran météo) et
/// résumée sur l'étape active (« Météo du jour »). Ce bandeau porte la même
/// promesse côté StepWays : il n'est monté QUE en phase `hike` (cf.
/// `HubScreen`), donc jamais visible en préparation (R2e).
///
/// Donne les conditions LOCALISÉES à la position GPS courante : météo du JOUR +
/// risque INCENDIE, à l'endroit où se trouve le randonneur. La localisation
/// réutilise le socle météo StepWays PAR ÉTAPE (coordonnées résolues
/// dynamiquement depuis Drift) via l'**étape détectée par le GPS**
/// ([localizedStageNumberProvider], dérivé du pipeline `positionStream` ->
/// détection d'étape) — même liaison GPS -> étape que le reste du moteur, aucune
/// nouvelle source, jamais de localité en dur (#84627/#99460).
///
/// C'est le point clé de R11 : on affiche l'étape COURANTE détectée, et non
/// l'étape de référence D-3 ([referenceStageNumberProvider], défaut 1) qui
/// servait à la tuile de préparation retirée.
///
/// Structure : icône météo + T° min/max + condition à gauche ; pastille de
/// risque incendie colorée ([fireRiskColor], parité `FireRiskScreen`) ; bouton
/// « météo des étapes » -> détail par étape (`/trail/:id/weather`). Dégradation
/// propre : sans prévision localisée, le bandeau affiche « Météo localisée
/// indisponible » MAIS conserve le bouton (l'accès au détail reste offert).
/// Réutilise [AppCard] + tokens `AppTheme`, [WeatherIcon] partagé, zéro texte
/// en dur (Slang).
class LocalizedConditionsBanner extends ConsumerWidget {
  const LocalizedConditionsBanner({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Étape LOCALISÉE (GPS -> étape détectée, repli étape de référence). La
    // météo est chargée pour CETTE étape (coords dynamiques Drift).
    final stageNumber = ref.watch(localizedStageNumberProvider);
    final params = WeatherStageParams(
      trailId: trailId,
      stageNumber: stageNumber,
    );
    final weather = ref.watch(stageWeatherProvider(params));
    final forecast = weather.forecast;
    final today = (forecast != null && forecast.days.isNotEmpty)
        ? forecast.days.first
        : null;

    // Risque incendie LOCALISÉ = niveau d'AUJOURD'HUI de l'étape localisée
    // (dérivé de la même météo, algorithme GR20 via [trailFireRiskProvider]).
    final fireState = ref.watch(trailFireRiskProvider(trailId));
    final localizedFire = fireState.stages
        .where((s) => s.stageNumber == stageNumber)
        .fold<FireRiskDay?>(
          null,
          (acc, s) => s.days.isNotEmpty ? s.days.first : acc,
        );
    final fireLevel = localizedFire?.level ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      // Liseré discret en teinte « Randonner » (ambiance de phase) — signale le
      // bloc « live » sans repeindre l'UI.
      borderColor: AppTheme.phaseHike.withValues(alpha: 0.5),
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du bandeau (« Ici et maintenant ») + localisation par étape.
          Row(
            children: [
              const Icon(
                Icons.my_location,
                size: 16,
                color: AppTheme.phaseHike,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  t.navPilote.weatherBannerTitle,
                  style: theme.textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                t.weather.stageLabel(number: stageNumber),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Ligne conditions : météo localisée (gauche) + pastille incendie.
          Row(
            children: [
              _leadingWeather(context, today, weather.isLoading, scheme),
              const SizedBox(width: AppTheme.spacingBase),
              Expanded(child: _weatherText(context, today, weather.isLoading)),
              if (fireLevel >= 1) ...[
                const SizedBox(width: AppTheme.spacingSm),
                _FireChip(level: fireLevel),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Bouton « météo des étapes » -> détail par étape (toujours présent,
          // même si la météo localisée est indisponible : accès préservé).
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/trail/$trailId/weather'),
              icon: const Icon(Icons.wb_sunny_outlined, size: 18),
              label: Text(t.navPilote.weatherBannerStages),
            ),
          ),
        ],
      ),
    );
  }

  /// Icône météo à gauche (parité tuile HUB) : condition du jour, skeleton en
  /// chargement, nuage atténué si indisponible.
  Widget _leadingWeather(
    BuildContext context,
    DayForecast? today,
    bool loading,
    ColorScheme scheme,
  ) {
    if (today != null) {
      return WeatherIcon(
        iconName: today.weatherIconName,
        size: 32,
        color: CategoryIconColors.of(context).orange, // parité Météo -> orange
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

  /// Texte météo localisée : T° min/max + condition, ou repli lisible.
  Widget _weatherText(BuildContext context, DayForecast? today, bool loading) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (today != null) {
      final temp = t.hub.weather.tempRange(
        min: today.temperatureMin.round(),
        max: today.temperatureMax.round(),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(temp, style: theme.textTheme.titleMedium),
          Text(
            today.weatherDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    return Text(
      loading ? t.weather.loading : t.navPilote.weatherBannerUnavailable,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

/// Pastille de risque INCENDIE localisé (parité `FireRiskScreen` : couleur
/// sémantique par niveau + libellé « Niv. X »). N'apparaît qu'à partir du
/// niveau 1 (parité GR20 : pas d'affichage si aucun risque).
class _FireChip extends StatelessWidget {
  const _FireChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = fireRiskColor(level);
    return Semantics(
      label: t.fireRisk.a11y.levelBadge(level: level),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              t.fireRisk.levelBadge(level: level),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
