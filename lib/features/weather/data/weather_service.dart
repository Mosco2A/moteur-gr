import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../models/weather_forecast.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Service météo utilisant l'API Open-Meteo (gratuit, sans clé).
///
/// Récupère les prévisions à 7 jours pour des coordonnées GPS données.
/// Open-Meteo fournit température, précipitations, vent, UV.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// URL de base de l'API Open-Meteo
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Récupère la prévision météo pour des coordonnées
  Future<WeatherForecast?> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude'
        '&daily=temperature_2m_max,temperature_2m_min,'
        'precipitation_sum,wind_speed_10m_max,'
        'uv_index_max,weather_code'
        '&timezone=auto&forecast_days=7',
      );

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        _log.w('[WeatherService] API erreur: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherForecast.fromOpenMeteo(json);
    } catch (e) {
      _log.w('[WeatherService] Erreur récupération météo: $e');
      return null;
    }
  }

  /// Libère les ressources du client HTTP
  void dispose() {
    _client.close();
  }
}
