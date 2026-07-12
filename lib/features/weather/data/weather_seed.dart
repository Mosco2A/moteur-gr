import '../models/weather_forecast.dart';

/// Générateur de météo de démonstration (P2-P3, #DP7 / D-4).
///
/// Fournit une prévision 7 jours **déterministe** (pas d'aléa non reproductible)
/// quand ni le réseau ni le cache ne répondent, afin d'illustrer l'UX en phase
/// de développement. Marqué « données de démonstration » côté UI
/// ([WeatherSource.demo]). AUCUN appel réseau, AUCUN Firebase (différé P4).
///
/// La graine dépend des coordonnées : deux étapes distinctes obtiennent des
/// séquences différentes mais stables d'un appel à l'autre.
abstract final class WeatherSeed {
  /// Codes météo WMO représentatifs (dégagé → orage) pour varier l'affichage.
  static const List<int> _codeCycle = [0, 1, 2, 3, 61, 80, 95];

  /// Construit une prévision fictive de [days] jours à partir de [now].
  static WeatherForecast forCoords({
    required double latitude,
    required double longitude,
    DateTime? now,
    int days = 7,
  }) {
    final base = now ?? DateTime.now();
    // Graine stable dérivée des coordonnées (arrondi au centième de degré).
    // Poids distincts sur lat/lng pour éviter les collisions par somme
    // symétrique (ex. 42.0/9.0 vs 45.0/6.0).
    final latKey = (latitude.abs() * 100).round();
    final lngKey = (longitude.abs() * 100).round();
    final seed = (latKey * 31 + lngKey * 7) % _codeCycle.length;

    final list = <DayForecast>[];
    for (var i = 0; i < days; i++) {
      final code = _codeCycle[(seed + i) % _codeCycle.length];
      final tMax = 12.0 + ((seed + i * 3) % 14); // 12–25 °C
      final tMin = tMax - 6;
      final wind = 5.0 + ((seed + i * 7) % 30); // 5–34 km/h
      final precip = code >= 61 ? (5.0 + (i % 4) * 6) : 0.0;
      final prob = code >= 80 ? 70.0 : (code >= 61 ? 40.0 : 5.0);
      list.add(DayForecast(
        date: DateTime(base.year, base.month, base.day).add(Duration(days: i)),
        temperatureMax: tMax.toDouble(),
        temperatureMin: tMin.toDouble(),
        precipitationMm: precip,
        windSpeedKmh: wind.toDouble(),
        uvIndex: (2 + (seed + i) % 8).toDouble(), // 2–9
        weatherCode: code,
        precipitationProbabilityMax: prob,
      ));
    }

    return WeatherForecast(
      days: list,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
