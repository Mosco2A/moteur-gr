import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/weather_forecast.dart';
import '../presentation/weather_date_format.dart';
import '../../../core/branding/stepways_icons.dart';

/// Carte de prévision pour un jour.
///
/// Affiche la température, les précipitations, le vent et l'UV
/// avec un code couleur selon les conditions.
///
/// TACHE 572 — EN-TETE SURCHARGEABLE. La meteo etape par etape (U1) affiche la
/// meme carte, mais titree par le JOUR DE PROGRAMME et son LIEU D'ARRIVEE au
/// lieu de la seule date du bulletin. Plutot que de recopier le corps de cette
/// carte (icone, temperatures, pastilles) dans un second widget — deux copies a
/// maintenir, deux rendus qui divergent au premier correctif — on rend son
/// en-tete surchargeable. Sans [title], le comportement est inchange.
class DayForecastCard extends StatelessWidget {
  const DayForecastCard({
    super.key,
    required this.day,
    this.title,
    this.subtitle,
    this.trailing,
    this.extraChips = const [],
    this.footnote,
  });

  final DayForecast day;

  /// Ligne de titre. `null` = date du bulletin (comportement d'origine).
  final String? title;

  /// Ligne sous le titre. `null` = description meteo (comportement d'origine).
  final String? subtitle;

  /// Badge affiche a droite du titre (ex. « Repos »).
  final Widget? trailing;

  /// Pastilles supplementaires apres pluie / vent / UV (ex. « Tendance »).
  final List<Widget> extraChips;

  /// Note en pied de carte (ex. la mise en garde sur la portee « tendance »).
  final Widget? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // LOT-B (RF-15) : locale courante au lieu de 'fr_FR' figé (cloisonnement).
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAlert = day.isAlertCondition;

    // SW-SKIN-L3b : Card -> AppCard (grammaire unifiee). Liseré d'alerte
    // semantique (rouge 1.5px) conserve via borderColor/borderWidth ; padding
    // interne porte par le parametre padding (memes marges spacingMd).
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      borderColor: isAlert ? AppTheme.rougeUrgence : null,
      borderWidth: isAlert ? 1.5 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + icône météo
          Row(
            children: [
              WeatherIcon(
                iconName: day.weatherIconName,
                size: 28,
                color: isAlert
                    ? AppTheme.rougeUrgence
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title ??
                                formatWeatherDate(
                                  day.date,
                                  'EEEE d MMM',
                                  languageCode,
                                ),
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: AppTheme.spacingXs),
                          trailing!,
                        ],
                      ],
                    ),
                    Text(
                      subtitle ?? day.weatherDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Température
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${day.temperatureMax.round()}°',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: _tempColor(day.temperatureMax),
                    ),
                  ),
                  Text(
                    '${day.temperatureMin.round()}°',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Détails : précipitations, vent, UV.
          // Wrap (pas Row) : évite tout débordement horizontal aux largeurs
          // mobiles étroites (retour Lot A #95062).
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingXs,
            children: [
              _detailChip(
                context,
                StepwaysIcons.pluie,
                '${day.precipitationMm.round()} mm',
                day.precipitationMm >= 20,
              ),
              _detailChip(
                context,
                StepwaysIcons.vent,
                '${day.windSpeedKmh.round()} km/h',
                day.windSpeedKmh >= 60,
              ),
              _detailChip(
                context,
                StepwaysIcons.meteo,
                'UV ${day.uvIndex.round()}',
                day.uvIndex >= 8,
              ),
              ...extraChips,
            ],
          ),
          if (footnote != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            footnote!,
          ],
        ],
      ),
    );
  }

  Widget _detailChip(
    BuildContext context,
    String icon,
    String label,
    bool isDanger,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isDanger
            ? AppTheme.rougeUrgence.withAlpha(30)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepIcon(
            icon,
            size: 14,
            color: isDanger ? AppTheme.rougeUrgence : null,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDanger ? AppTheme.rougeUrgence : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _tempColor(double temp) {
    if (temp <= 0) return AppTheme.rougeExtreme;
    if (temp <= 10) return AppTheme.orangeDifficile;
    if (temp <= 25) return AppTheme.vertFacile;
    return AppTheme.rougeUrgence;
  }
}

/// Icône Material dérivée du nom de condition météo (`DayForecast.weatherIconName`).
///
/// Widget partagé par les cartes météo (jour, aujourd'hui, tuile HUB) pour
/// éviter la duplication du mapping nom → [IconData].
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.iconName,
    this.size = 24,
    this.color,
  });

  final String iconName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return StepIcon(_iconFor(iconName), size: size, color: color);
  }

  static String _iconFor(String iconName) {
    switch (iconName) {
      case 'wb_sunny':
        return StepwaysIcons.soleil;
      case 'cloud':
        return StepwaysIcons.nuageux;
      case 'foggy':
        return StepwaysIcons.brouillard;
      case 'grain':
        return StepwaysIcons.pluie;
      case 'water_drop':
        return StepwaysIcons.pluie;
      case 'ac_unit':
        return StepwaysIcons.neige;
      case 'thunderstorm':
        return StepwaysIcons.orage;
      default:
        return StepwaysIcons.nuageux;
    }
  }
}
