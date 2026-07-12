/// Prévision météo quotidienne pour un point géographique.
///
/// Modèle immuable construit depuis la réponse Open-Meteo.
/// Chaque DayForecast contient les données d'une journée.
class WeatherForecast {
  const WeatherForecast({
    required this.days,
    required this.latitude,
    required this.longitude,
  });

  final List<DayForecast> days;
  final double latitude;
  final double longitude;

  /// Parse depuis la réponse JSON Open-Meteo
  factory WeatherForecast.fromOpenMeteo(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = (daily['time'] as List).cast<String>();
    final tempMax = (daily['temperature_2m_max'] as List).cast<num>();
    final tempMin = (daily['temperature_2m_min'] as List).cast<num>();
    final precipitation = (daily['precipitation_sum'] as List).cast<num>();
    final windMax = (daily['wind_speed_10m_max'] as List).cast<num>();
    final uvMax = (daily['uv_index_max'] as List).cast<num>();
    final weatherCode = (daily['weather_code'] as List).cast<int>();
    // Probabilité d'orage/précipitation (LOT-B, PT-5). Champ optionnel :
    // absent des réponses/caches antérieurs => null (dérivé stormProbability).
    final precipProb = (daily['precipitation_probability_max'] as List?)
        ?.map((e) => e == null ? null : (e as num).toDouble())
        .toList();

    final days = <DayForecast>[];
    for (var i = 0; i < dates.length; i++) {
      days.add(DayForecast(
        date: DateTime.parse(dates[i]),
        temperatureMax: tempMax[i].toDouble(),
        temperatureMin: tempMin[i].toDouble(),
        precipitationMm: precipitation[i].toDouble(),
        windSpeedKmh: windMax[i].toDouble(),
        uvIndex: uvMax[i].toDouble(),
        weatherCode: weatherCode[i],
        precipitationProbabilityMax:
            (precipProb != null && i < precipProb.length)
                ? precipProb[i]
                : null,
      ));
    }

    return WeatherForecast(
      days: days,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  /// Sérialise en JSON pour le cache Drift
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'days': days.map((d) => d.toJson()).toList(),
      };

  /// Désérialise depuis le cache JSON
  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      days: (json['days'] as List)
          .map((d) => DayForecast.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Prévision pour une journée unique
class DayForecast {
  const DayForecast({
    required this.date,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.precipitationMm,
    required this.windSpeedKmh,
    required this.uvIndex,
    required this.weatherCode,
    this.precipitationProbabilityMax,
  });

  final DateTime date;
  final double temperatureMax;
  final double temperatureMin;
  final double precipitationMm;
  final double windSpeedKmh;
  final double uvIndex;
  final int weatherCode;

  /// Probabilité maximale de précipitations dans la journée (0-100 %).
  ///
  /// Fournie par Open-Meteo (`precipitation_probability_max`, LOT-B PT-5).
  /// Nullable : absente des caches/réponses antérieurs à l'enrichissement.
  final double? precipitationProbabilityMax;

  /// Indicateur de conditions dangereuses (orage, neige, pluie forte)
  bool get isAlertCondition =>
      weatherCode >= 65 || // Pluie forte, neige, orage
      windSpeedKmh >= 60 || // Vent très fort
      precipitationMm >= 20; // Grosses précipitations

  /// Vrai si un orage est prévu (code WMO 95/96/99).
  bool get isStorm => weatherCode >= 95;

  /// Probabilité d'orage dérivée (0-100 %) — AM-7.
  ///
  /// Combine le code WMO (orage certain => 100) et la probabilité de
  /// précipitations Open-Meteo quand elle est disponible. Sert la pastille
  /// d'alerte orage du HUB et le toggle de l'écran météo.
  double get stormProbability {
    if (isStorm) return 100;
    return precipitationProbabilityMax ?? 0;
  }

  /// Description textuelle du code météo WMO
  String get weatherDescription {
    return _wmoCodeDescriptions[weatherCode] ?? 'Inconnu';
  }

  /// Icône du code météo (nom Material Icon)
  String get weatherIconName {
    if (weatherCode <= 1) return 'wb_sunny';
    if (weatherCode <= 3) return 'cloud';
    if (weatherCode <= 48) return 'foggy';
    if (weatherCode <= 57) return 'grain';
    if (weatherCode <= 67) return 'water_drop';
    if (weatherCode <= 77) return 'ac_unit';
    if (weatherCode <= 82) return 'thunderstorm';
    if (weatherCode <= 86) return 'ac_unit';
    return 'thunderstorm';
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'temperatureMax': temperatureMax,
        'temperatureMin': temperatureMin,
        'precipitationMm': precipitationMm,
        'windSpeedKmh': windSpeedKmh,
        'uvIndex': uvIndex,
        'weatherCode': weatherCode,
        if (precipitationProbabilityMax != null)
          'precipitationProbabilityMax': precipitationProbabilityMax,
      };

  factory DayForecast.fromJson(Map<String, dynamic> json) {
    return DayForecast(
      date: DateTime.parse(json['date'] as String),
      temperatureMax: (json['temperatureMax'] as num).toDouble(),
      temperatureMin: (json['temperatureMin'] as num).toDouble(),
      precipitationMm: (json['precipitationMm'] as num).toDouble(),
      windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
      uvIndex: (json['uvIndex'] as num).toDouble(),
      weatherCode: json['weatherCode'] as int,
      precipitationProbabilityMax:
          (json['precipitationProbabilityMax'] as num?)?.toDouble(),
    );
  }
}

/// Descriptions des codes météo WMO
const Map<int, String> _wmoCodeDescriptions = {
  0: 'Ciel dégagé',
  1: 'Principalement dégagé',
  2: 'Partiellement nuageux',
  3: 'Couvert',
  45: 'Brouillard',
  48: 'Brouillard givrant',
  51: 'Bruine légère',
  53: 'Bruine modérée',
  55: 'Bruine dense',
  56: 'Bruine verglaçante',
  57: 'Bruine verglaçante forte',
  61: 'Pluie légère',
  63: 'Pluie modérée',
  65: 'Pluie forte',
  66: 'Pluie verglaçante',
  67: 'Pluie verglaçante forte',
  71: 'Neige légère',
  73: 'Neige modérée',
  75: 'Neige forte',
  77: 'Grains de neige',
  80: 'Averses légères',
  81: 'Averses modérées',
  82: 'Averses violentes',
  85: 'Averses de neige',
  86: 'Averses de neige fortes',
  95: 'Orage',
  96: 'Orage avec grêle légère',
  99: 'Orage avec grêle forte',
};
