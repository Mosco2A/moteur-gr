/// Donnees meteo pour une position et une date.
///
/// Modele immutable utilise dans toute l'app pour afficher
/// la meteo d'une etape. Les champs correspondent aux donnees
/// retournees par l'API Open-Meteo (forecast endpoint).
class WeatherData {
  const WeatherData({
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.precipitationMm,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.windSpeedMax,
    required this.uvIndexMax,
  });

  /// Date de la prevision (YYYY-MM-DD)
  final String date;

  /// Latitude de la position demandee
  final double latitude;

  /// Longitude de la position demandee
  final double longitude;

  /// Temperature minimale en degres Celsius
  final double temperatureMin;

  /// Temperature maximale en degres Celsius
  final double temperatureMax;

  /// Precipitations cumulees en millimetres
  final double precipitationMm;

  /// Probabilite de precipitations en pourcentage (0-100)
  final int precipitationProbability;

  /// Code meteo WMO (0=clair, 1-3=nuages, 45-48=brouillard,
  /// 51-67=pluie, 71-77=neige, 80-82=averses, 95-99=orages)
  final int weatherCode;

  /// Vitesse maximale du vent en km/h
  final double windSpeedMax;

  /// Indice UV maximal
  final double uvIndexMax;

  /// Description textuelle du code meteo WMO.
  String get weatherDescription => _wmoDescription(weatherCode);

  /// Indique si des precipitations sont probables (>= 40%).
  bool get hasPrecipitation => precipitationProbability >= 40;

  /// Indique si les conditions sont dangereuses
  /// (orage, vent fort, UV extreme).
  bool get isDangerous =>
      weatherCode >= 95 || windSpeedMax >= 60 || uvIndexMax >= 8;

  static String _wmoDescription(int code) {
    if (code == 0) return 'Ciel dégagé';
    if (code <= 3) return 'Partiellement nuageux';
    if (code <= 48) return 'Brouillard';
    if (code <= 57) return 'Bruine';
    if (code <= 67) return 'Pluie';
    if (code <= 77) return 'Neige';
    if (code <= 82) return 'Averses';
    if (code <= 86) return 'Averses de neige';
    if (code <= 99) return 'Orage';
    return 'Inconnu';
  }

  @override
  String toString() =>
      'WeatherData($date, ${temperatureMin.toStringAsFixed(1)}-'
      '${temperatureMax.toStringAsFixed(1)}°C, '
      'WMO:$weatherCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherData &&
          date == other.date &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(date, latitude, longitude);
}
