import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../domain/forecast_reach.dart';
import '../models/weather_forecast.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Service d'appel API Open-Meteo (gratuit, sans cle).
///
/// Encapsule la requete HTTP vers Open-Meteo et le parsing
/// de la reponse en [WeatherForecast].
///
/// PORTEE (tache 572) : [forecastHorizonDays] jours — la portee annoncee a
/// l'ecran DERIVE de la meme constante, l'appel ne peut donc pas promettre
/// moins que ce que l'ecran affiche. Borne du fournisseur : `forecast_days`
/// accepte 0-16, defaut 7. Voir `domain/forecast_reach.dart` pour la decision
/// et ses sources.
class WeatherApiService {
  WeatherApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// URL de base de l'API Open-Meteo
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Timeout pour les appels API
  static const Duration timeout = Duration(seconds: 10);

  /// Parametres meteo demandes a l'API
  ///
  /// LOT-B (PT-5) : ajout de `precipitation_probability_max` pour la
  /// probabilite d'orage (derivee `stormProbability`). Les champs neige
  /// (snowfall, freezing_level_height) sont differes (dependance socle E00).
  static const String _dailyParams =
      'temperature_2m_max,temperature_2m_min,'
      'precipitation_sum,wind_speed_10m_max,'
      'uv_index_max,weather_code,'
      'precipitation_probability_max';

  /// Recupere la prevision meteo pour des coordonnees dynamiques.
  ///
  /// Retourne null en cas d'erreur reseau ou de reponse invalide.
  /// Les coordonnees doivent provenir de la base Drift (pas en dur).
  ///
  /// Le bulletin rendu porte son INSTANT DE RELEVE ([WeatherForecast.fetchedAt])
  /// — sans lui, aucun ecran ne peut dire si une donnee est fraiche, et un
  /// rafraichissement reussi est invisible (tache 572, U2/U3).
  Future<WeatherForecast?> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl?latitude=$latitude&longitude=$longitude'
        '&daily=$_dailyParams'
        '&timezone=auto&forecast_days=$forecastHorizonDays',
      );

      final response = await _client.get(uri).timeout(timeout);

      if (response.statusCode != 200) {
        _log.w('[WeatherApiService] API erreur: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherForecast.fromOpenMeteo(json)
          .withFetchedAt(DateTime.now());
    } catch (e) {
      _log.w('[WeatherApiService] Erreur recuperation meteo: $e');
      return null;
    }
  }

  /// Libere les ressources du client HTTP
  void dispose() {
    _client.close();
  }
}
