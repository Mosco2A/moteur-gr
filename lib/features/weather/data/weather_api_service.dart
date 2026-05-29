import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../domain/weather_data.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: Level.debug,
);

/// Service HTTP pour l'API Open-Meteo (forecast).
///
/// Appelle l'endpoint gratuit https://api.open-meteo.com/v1/forecast
/// pour recuperer les previsions journalieres sur 7 jours.
/// Aucune cle API requise. Rate limit: 10 000 requetes/jour.
///
/// Parametres demandes:
/// - temperature_2m_min/max, precipitation_sum,
///   precipitation_probability_max, weather_code,
///   wind_speed_10m_max, uv_index_max
class WeatherApiService {
  WeatherApiService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _forecastDays = 7;

  /// Recupere les previsions meteo pour une position GPS.
  ///
  /// Retourne une liste de [WeatherData] pour les [_forecastDays]
  /// prochains jours. Leve une [WeatherApiException] en cas d'erreur
  /// reseau ou de reponse invalide.
  Future<List<WeatherData>> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'daily': [
          'temperature_2m_min',
          'temperature_2m_max',
          'precipitation_sum',
          'precipitation_probability_max',
          'weather_code',
          'wind_speed_10m_max',
          'uv_index_max',
        ].join(','),
        'forecast_days': '$_forecastDays',
        'timezone': 'auto',
      },
    );

    _log.d('[WeatherApi] GET $uri');

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );
    } catch (e) {
      throw WeatherApiException('Erreur reseau: $e');
    }

    if (response.statusCode != 200) {
      throw WeatherApiException(
        'Open-Meteo HTTP ${response.statusCode}: ${response.body}',
      );
    }

    return _parseResponse(response.body, latitude, longitude);
  }

  List<WeatherData> _parseResponse(
    String body,
    double latitude,
    double longitude,
  ) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw WeatherApiException('JSON invalide: $e');
    }

    final daily = json['daily'] as Map<String, dynamic>?;
    if (daily == null) {
      throw WeatherApiException('Pas de donnees daily dans la reponse');
    }

    final dates = (daily['time'] as List).cast<String>();
    final tempMin = (daily['temperature_2m_min'] as List).cast<num>();
    final tempMax = (daily['temperature_2m_max'] as List).cast<num>();
    final precip = (daily['precipitation_sum'] as List).cast<num>();
    final precipProb =
        (daily['precipitation_probability_max'] as List).cast<num>();
    final codes = (daily['weather_code'] as List).cast<num>();
    final wind = (daily['wind_speed_10m_max'] as List).cast<num>();
    final uv = (daily['uv_index_max'] as List).cast<num>();

    return List.generate(dates.length, (i) {
      return WeatherData(
        date: dates[i],
        latitude: latitude,
        longitude: longitude,
        temperatureMin: tempMin[i].toDouble(),
        temperatureMax: tempMax[i].toDouble(),
        precipitationMm: precip[i].toDouble(),
        precipitationProbability: precipProb[i].toInt(),
        weatherCode: codes[i].toInt(),
        windSpeedMax: wind[i].toDouble(),
        uvIndexMax: uv[i].toDouble(),
      );
    });
  }

  /// Libere les ressources du client HTTP.
  void dispose() {
    _client.close();
  }
}

/// Exception levee par [WeatherApiService].
class WeatherApiException implements Exception {
  WeatherApiException(this.message);
  final String message;

  @override
  String toString() => 'WeatherApiException: $message';
}
