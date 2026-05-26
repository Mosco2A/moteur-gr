import 'weather_forecast.dart';

/// Alerte météo générée à partir des prévisions.
///
/// Détecte automatiquement les conditions dangereuses
/// et génère des alertes avec niveau de sévérité.
class WeatherAlert {
  const WeatherAlert({
    required this.severity,
    required this.title,
    required this.description,
    required this.date,
  });

  /// Niveau de sévérité ('warning' = orange, 'danger' = rouge)
  final String severity;

  /// Titre court de l'alerte
  final String title;

  /// Description détaillée
  final String description;

  /// Date concernée
  final DateTime date;

  /// Génère les alertes depuis une prévision
  static List<WeatherAlert> fromForecast(WeatherForecast forecast) {
    final alerts = <WeatherAlert>[];

    for (final day in forecast.days) {
      // Orage
      if (day.weatherCode >= 95) {
        alerts.add(WeatherAlert(
          severity: 'danger',
          title: 'Orage prévu',
          description:
              '${day.weatherDescription}. '
              'Évitez les crêtes et les zones exposées.',
          date: day.date,
        ));
      }

      // Vent fort
      if (day.windSpeedKmh >= 60) {
        alerts.add(WeatherAlert(
          severity: day.windSpeedKmh >= 80 ? 'danger' : 'warning',
          title: 'Vent fort',
          description:
              'Rafales jusqu\'à ${day.windSpeedKmh.round()} km/h. '
              'Prudence sur les passages exposés.',
          date: day.date,
        ));
      }

      // Pluie forte
      if (day.precipitationMm >= 20) {
        alerts.add(WeatherAlert(
          severity: day.precipitationMm >= 40 ? 'danger' : 'warning',
          title: 'Fortes précipitations',
          description:
              '${day.precipitationMm.round()} mm prévus. '
              'Risque de sentiers glissants et de torrents.',
          date: day.date,
        ));
      }

      // Neige
      if (day.weatherCode >= 71 && day.weatherCode <= 77) {
        alerts.add(WeatherAlert(
          severity: 'warning',
          title: 'Neige prévue',
          description:
              '${day.weatherDescription}. '
              'Équipement adapté nécessaire.',
          date: day.date,
        ));
      }

      // UV extrême
      if (day.uvIndex >= 8) {
        alerts.add(WeatherAlert(
          severity: 'warning',
          title: 'UV très élevé',
          description:
              'Indice UV ${day.uvIndex.round()}. '
              'Protection solaire maximale recommandée.',
          date: day.date,
        ));
      }
    }

    return alerts;
  }
}
