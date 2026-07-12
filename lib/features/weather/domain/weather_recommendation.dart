import '../models/weather_forecast.dart';

/// Niveau de recommandation randonnée dérivé de la météo du jour (AM-7).
///
/// Trois niveaux (RF-4) : conditions favorables, vigilance, danger.
/// La couche de présentation mappe chaque niveau vers un libellé i18n
/// (`weather.recommendation.ok/watch/danger`) et une couleur du thème.
enum WeatherRecommendationLevel {
  /// Conditions favorables : rien de particulier.
  ok,

  /// Vigilance : conditions à surveiller (vent modéré, UV élevé, pluie).
  watch,

  /// Danger : conditions défavorables (orage, vent violent, fortes pluies).
  danger,
}

/// Dérivation de la recommandation à partir d'une prévision quotidienne.
///
/// Règle pure et testable (aucun texte ni couleur ici — cf. cloisonnement
/// et i18n D-5). Les seuils reprennent ceux des alertes météo pour rester
/// cohérents avec le bandeau.
abstract final class WeatherRecommendation {
  /// Calcule le niveau de recommandation pour un [day] donné.
  static WeatherRecommendationLevel forDay(DayForecast day) {
    // Danger : orage certain, vent violent, pluie très forte, proba d'orage
    // élevée.
    final bool danger = day.isStorm ||
        day.windSpeedKmh >= 80 ||
        day.precipitationMm >= 40 ||
        day.stormProbability >= 80;
    if (danger) return WeatherRecommendationLevel.danger;

    // Vigilance : vent fort, pluie notable, UV très élevé, neige, proba
    // d'orage modérée.
    final bool watch = day.windSpeedKmh >= 60 ||
        day.precipitationMm >= 20 ||
        day.uvIndex >= 8 ||
        (day.weatherCode >= 71 && day.weatherCode <= 77) ||
        day.stormProbability >= 50;
    if (watch) return WeatherRecommendationLevel.watch;

    return WeatherRecommendationLevel.ok;
  }
}
