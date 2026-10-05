/// Traduit un type d'alerte semantique en libelle localise : le modele d'alerte
/// reste une donnee pure, sans i18n.
library;

import '../../../domain/temperature_unit.dart'
    show TemperatureUnit, formatTemperature;
import '../../../i18n/translations.g.dart';
import '../models/weather_alert.dart';
import '../../../core/branding/stepways_icons.dart';

/// Résolution i18n des alertes météo (LOT-B, D-5 / RF-15).
///
/// Le modèle [WeatherAlert] est une donnée pure porteuse d'un
/// [WeatherAlertKind] sémantique. Cette extension traduit ce type en
/// libellés localisés (`weather.alert.*`, 5 langues) à l'affichage, ce qui
/// évite tout texte en dur dans le modèle ou les widgets.
extension WeatherAlertL10n on WeatherAlert {
  /// Titre localisé de l'alerte.
  String localizedTitle(Translations t) {
    switch (kind) {
      case WeatherAlertKind.storm:
        return t.weather.alert.storm.title;
      case WeatherAlertKind.wind:
        return t.weather.alert.wind.title;
      case WeatherAlertKind.rain:
        return t.weather.alert.rain.title;
      case WeatherAlertKind.snow:
        return t.weather.alert.snow.title;
      case WeatherAlertKind.uv:
        return t.weather.alert.uv.title;
      case WeatherAlertKind.fire:
        return t.weather.alert.fire.title;
    }
  }

  /// Description localisée de l'alerte (paramétrée par [amount]/[conditionLabel]).
  ///
  /// P2 (#101255 point 2) — [unit] EST OBLIGATOIRE, ET C'EST VOULU. L'alerte
  /// incendie annonce une température ; son libellé portait « °C » EN DUR dans
  /// les cinq fichiers de traduction, donc une alerte en Fahrenheit aurait
  /// affiché la valeur convertie avec le mauvais symbole — ou, pire, la valeur
  /// Celsius avec le symbole Fahrenheit. Un paramètre nommé optionnel aurait
  /// laissé l'oubli passer sans bruit : ici l'appelant doit dire dans quelle
  /// unité il écrit. Les autres natures d'alerte (mm, km/h, indice UV) n'ont
  /// pas d'unité réglable et l'ignorent.
  String localizedDescription(Translations t, {required TemperatureUnit unit}) {
    final int value = (amount ?? 0).round();
    final String condition = conditionLabel ?? '';
    switch (kind) {
      case WeatherAlertKind.storm:
        return t.weather.alert.storm.desc(condition: condition);
      case WeatherAlertKind.wind:
        return t.weather.alert.wind.desc(value: value);
      case WeatherAlertKind.rain:
        return t.weather.alert.rain.desc(value: value);
      case WeatherAlertKind.snow:
        return t.weather.alert.snow.desc(condition: condition);
      case WeatherAlertKind.uv:
        return t.weather.alert.uv.desc(value: value);
      case WeatherAlertKind.fire:
        // `amount` est la temperature maximale prevue, en degres Celsius.
        return t.weather.alert.fire.desc(
          temperature: formatTemperature(amount ?? 0, unit),
        );
    }
  }

  /// Icône associée à la nature de l'alerte.
  String get icon {
    switch (kind) {
      case WeatherAlertKind.storm:
        return StepwaysIcons.orage;
      case WeatherAlertKind.wind:
        return StepwaysIcons.vent;
      case WeatherAlertKind.rain:
        return StepwaysIcons.pluie;
      case WeatherAlertKind.snow:
        return StepwaysIcons.neige;
      case WeatherAlertKind.uv:
        return StepwaysIcons.soleil;
      case WeatherAlertKind.fire:
        return StepwaysIcons.incendie;
    }
  }
}
