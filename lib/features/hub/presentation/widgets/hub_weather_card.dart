/// La meteo du jour de l'etape de reference, avec sa pastille d'alerte orage,
/// qui se degrade proprement quand la prevision manque.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_icon_colors.dart';
import '../../../../domain/temperature_unit.dart'
    show TemperatureUnit, formatTemperatureRange;
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../settings/settings_facade.dart' show settingsProvider;
import '../../../weather/weather_facade.dart'
    show
        DayForecast,
        WeatherIcon,
        WeatherStageParams,
        referenceStageNumberProvider,
        stageWeatherProvider;
import '../../../../core/branding/stepways_icons.dart';

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
    final unit = ref.watch(settingsProvider.select((s) => s.temperatureUnit));

    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final stageNumber = ref.watch(referenceStageNumberProvider);
    final params = WeatherStageParams(
      trailId: trailId,
      stageNumber: stageNumber,
    );
    final state = ref.watch(stageWeatherProvider(params));

    final forecast = state.forecast;
    final today = (forecast != null && forecast.days.isNotEmpty)
        ? forecast.days.first
        : null;

    // Pastille orage : aujourd'hui ou demain au-dessus du seuil.
    final stormSoon =
        forecast != null &&
        forecast.days.take(2).any((d) => d.stormProbability >= 60);

    // Tap seulement si la route météo est utile (toujours vraie ici : la route
    // E31 existe désormais). Le stub sans onTap (S8) est levé.
    return AppCard(
      onTap: () => context.push('/trail/$trailId/weather?stage=$stageNumber'),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Row(
        children: [
          // Icone meteo en orange categoriel (parite GR20 Meteo -> orangeTerre)
          // au lieu de l'accent-sentier unique. Portee par le theme (#IR02).
          _leading(
            context,
            today,
            state.isLoading,
            scheme,
            CategoryIconColors.of(context).orange,
          ),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.hub.weather.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (stormSoon) ...[
                      const SizedBox(width: AppTheme.spacingSm),
                      _StormBadge(label: t.hub.weather.alertStorm),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  _subtitle(context, today, state.isLoading, t, unit),
                  style: theme.textTheme.bodySmall?.copyWith(
                    // R1 (retour Chris) : le sous-titre meteo etait illisible
                    // (gris sur fond sombre, ~0.7 d'opacite -> contraste < AA).
                    // On remonte l'opacite a 0.87 : la couleur derive toujours
                    // d'`onSurface` (contraste garanti dans les DEUX themes,
                    // clair ET sombre), sans nouvelle couleur en dur ni changer
                    // la typo/le layout. Vise WCAG AA (>= 4.5:1).
                    color: scheme.onSurface.withValues(alpha: 0.87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StepIcon(
            StepwaysIcons.chevronDroite,
            color: scheme.onSurface.withAlpha(120),
          ),
        ],
      ),
    );
  }

  Widget _leading(
    BuildContext context,
    DayForecast? today,
    bool loading,
    ColorScheme scheme,
    Color accent,
  ) {
    if (today != null) {
      return WeatherIcon(
        iconName: today.weatherIconName,
        size: 32,
        color: accent,
      );
    }
    if (loading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return StepIcon(
      StepwaysIcons.weather,
      size: 32,
      color: scheme.onSurface.withValues(alpha: 0.6),
    );
  }

  String _subtitle(
    BuildContext context,
    DayForecast? today,
    bool loading,
    Translations t,
    TemperatureUnit unit,
  ) {
    if (today != null) {
      // P2 (#101255 point 2) : l'ancienne cle i18n `hub.weather.tempRange`
      // portait « ° » EN DUR dans les cinq langues, sans jamais dire laquelle.
      // Le format vit maintenant dans `lib/domain/`, avec le symbole qui suit
      // le reglage — et l'ordre min / max du cockpit est conserve.
      final temp = formatTemperatureRange(
        today.temperatureMin,
        today.temperatureMax,
        unit,
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
        color: AppTheme.emergencyRed.withAlpha(28),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StepIcon(
            StepwaysIcons.orage,
            size: 13,
            color: AppTheme.emergencyRed,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.emergencyRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
