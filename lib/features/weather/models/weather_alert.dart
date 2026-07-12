import 'fire_risk_config.dart';
import 'weather_forecast.dart';

/// Type d'alerte pour distinguer meteo classique et incendie.
///
/// Permet au bandeau d'adapter le rendu et le CTA selon le type.
enum AlertType {
  /// Alerte meteo classique (orage, neige, vent, pluie, UV)
  weather,

  /// Alerte risque incendie (conditions parametrees via FireRiskConfig)
  fire,
}

/// Nature semantique d'une alerte meteo.
///
/// LOT-B (D-5, RF-15) : les libelles (titre/description) sont EXTERNALISES en
/// i18n (`weather.alert.*`, 5 langues). Le modele reste une donnee pure,
/// sans texte en dur ni BuildContext : la resolution du libelle se fait au
/// niveau widget via [Translations]. Chaque valeur mappe une cle Slang.
enum WeatherAlertKind {
  storm,
  wind,
  rain,
  snow,
  uv,
  fire,
}

/// Alerte météo générée à partir des prévisions.
///
/// Détecte automatiquement les conditions dangereuses et génère des alertes
/// avec niveau de sévérité et [kind] sémantique. Le texte affiché est résolu
/// en i18n côté widget (LOT-B, D-5). Les données quantitatives utiles au
/// message (vent, pluie, température, description WMO) sont exposées via
/// [amount] / [conditionLabel] pour paramétrer les traductions.
class WeatherAlert {
  const WeatherAlert({
    required this.severity,
    required this.kind,
    required this.date,
    this.amount,
    this.conditionLabel,
    this.type = AlertType.weather,
    this.fireTipId,
  });

  /// Niveau de sévérité ('warning' = orange, 'danger' = rouge)
  final String severity;

  /// Nature sémantique de l'alerte (pilote le libellé i18n + l'icône).
  final WeatherAlertKind kind;

  /// Date concernée
  final DateTime date;

  /// Grandeur associée au message (mm de pluie, km/h de vent, °C, indice UV).
  /// Interprétée selon [kind] par la couche de présentation. Null si sans objet.
  final double? amount;

  /// Libellé de condition WMO (ex. description du code météo) quand pertinent
  /// (orage/neige). Null sinon.
  final String? conditionLabel;

  /// Type d'alerte (meteo classique ou incendie)
  final AlertType type;

  /// ID de la fiche conseil incendie (uniquement pour type == fire)
  final String? fireTipId;

  /// Génère les alertes météo classiques depuis une prévision.
  ///
  /// Les seuils sont conservés à l'identique (non-régression) ; seuls les
  /// libellés sont désormais portés par [kind] (résolus en i18n côté widget).
  static List<WeatherAlert> fromForecast(WeatherForecast forecast) {
    final alerts = <WeatherAlert>[];

    for (final day in forecast.days) {
      // Orage
      if (day.weatherCode >= 95) {
        alerts.add(WeatherAlert(
          severity: 'danger',
          kind: WeatherAlertKind.storm,
          date: day.date,
          conditionLabel: day.weatherDescription,
        ));
      }

      // Vent fort
      if (day.windSpeedKmh >= 60) {
        alerts.add(WeatherAlert(
          severity: day.windSpeedKmh >= 80 ? 'danger' : 'warning',
          kind: WeatherAlertKind.wind,
          date: day.date,
          amount: day.windSpeedKmh,
        ));
      }

      // Pluie forte
      if (day.precipitationMm >= 20) {
        alerts.add(WeatherAlert(
          severity: day.precipitationMm >= 40 ? 'danger' : 'warning',
          kind: WeatherAlertKind.rain,
          date: day.date,
          amount: day.precipitationMm,
        ));
      }

      // Neige
      if (day.weatherCode >= 71 && day.weatherCode <= 77) {
        alerts.add(WeatherAlert(
          severity: 'warning',
          kind: WeatherAlertKind.snow,
          date: day.date,
          conditionLabel: day.weatherDescription,
        ));
      }

      // UV extrême
      if (day.uvIndex >= 8) {
        alerts.add(WeatherAlert(
          severity: 'warning',
          kind: WeatherAlertKind.uv,
          date: day.date,
          amount: day.uvIndex,
        ));
      }
    }

    return alerts;
  }

  /// Genere les alertes incendie depuis une prevision et une config.
  ///
  /// Evalue chaque jour de la prevision contre les conditions parametrees dans
  /// [fireConfig] pour la [region] donnee. Retourne une liste d'alertes de type
  /// [AlertType.fire] / [WeatherAlertKind.fire]. La [region] sert la config
  /// (evaluation du risque) ; le libelle affiche est resolu en i18n cote widget.
  static List<WeatherAlert> fireAlertsFromForecast(
    WeatherForecast forecast, {
    required FireRiskConfig fireConfig,
    required String region,
  }) {
    final alerts = <WeatherAlert>[];

    for (final day in forecast.days) {
      if (fireConfig.isFireRiskActive(
        month: day.date.month,
        temperatureMax: day.temperatureMax,
        region: region,
      )) {
        alerts.add(WeatherAlert(
          severity: 'danger',
          kind: WeatherAlertKind.fire,
          date: day.date,
          amount: day.temperatureMax,
          type: AlertType.fire,
          fireTipId: fireConfig.fireTipId,
        ));
      }
    }

    return alerts;
  }
}
