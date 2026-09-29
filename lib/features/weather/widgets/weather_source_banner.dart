import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../presentation/weather_date_format.dart';
import '../../../core/branding/stepways_icons.dart';

/// Origine des données météo affichées (RF-3).
enum WeatherSource { api, cache, offline, demo }

/// Bandeau discret indiquant la source des données et l'horodatage (RF-3).
///
/// Remplace le simple badge « cache » : précise si les données viennent du
/// réseau, du cache local, du mode hors-ligne ou d'un jeu de démonstration,
/// avec la date de dernière mise à jour. Tous les libellés sont i18n.
class WeatherSourceBanner extends StatelessWidget {
  const WeatherSourceBanner({
    super.key,
    required this.source,
    this.updatedAt,
  });

  final WeatherSource source;

  /// Horodatage de la dernière donnée (null = inconnu).
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(140);

    final (String icon, String label) = switch (source) {
      WeatherSource.api => (StepwaysIcons.synchronise, t.weather.source.api),
      WeatherSource.cache => (StepwaysIcons.rafraichir, t.weather.source.cache),
      WeatherSource.offline => (StepwaysIcons.horsLigne, t.weather.source.offline),
      WeatherSource.demo => (StepwaysIcons.eprouvette, t.weather.source.demo),
    };

    final parts = <String>[label];
    if (updatedAt != null) {
      final languageCode = Localizations.localeOf(context).languageCode;
      final formatted =
          formatWeatherDate(updatedAt!, 'd MMM HH:mm', languageCode);
      parts.add(t.weather.lastUpdate(date: formatted));
    }

    return Row(
      children: [
        StepIcon(icon, size: 14, color: muted),
        const SizedBox(width: AppTheme.spacingXs),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
