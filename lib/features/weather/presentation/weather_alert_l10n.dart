import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';
import '../models/weather_alert.dart';

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
  String localizedDescription(Translations t) {
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
        return t.weather.alert.fire.desc(value: value);
    }
  }

  /// Icône associée à la nature de l'alerte.
  IconData get icon {
    switch (kind) {
      case WeatherAlertKind.storm:
        return Icons.thunderstorm;
      case WeatherAlertKind.wind:
        return Icons.air;
      case WeatherAlertKind.rain:
        return Icons.water_drop;
      case WeatherAlertKind.snow:
        return Icons.ac_unit;
      case WeatherAlertKind.uv:
        return Icons.wb_sunny;
      case WeatherAlertKind.fire:
        return Icons.local_fire_department;
    }
  }
}
