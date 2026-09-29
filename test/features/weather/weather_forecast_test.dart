import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';

/// Tests du modèle WeatherForecast.
///
/// LE FOURNISSEUR A DISPARU DE CES TESTS, ET C'EST LA MESURE DU LOT 625. Ils
/// parsaient une réponse Open-Meteo (`fromOpenMeteo`, clefs `temperature_2m_max`,
/// `daily`) ; ils lisent désormais le bulletin que NOTRE SERVEUR publie, en
/// snake_case comme les sept autres familles de données de sentier. Aucun test de ce
/// fichier ne connaît plus la forme d'un fournisseur de météo.
void main() {
  group('WeatherForecast — ce que le serveur publie', () {
    test('depuisLePublie lit les jours, le point et la date de fabrication', () {
      final forecast = WeatherForecast.depuisLePublie(
        jours: _joursPublies(),
        latitude: 42.15,
        longitude: 9.1,
        produiteLe: _instant('2026-09-28T07:17:30.000Z'),
        collecteeLe: _instant('2026-09-28T07:42:10.000Z'),
        source: 'met-norway',
      );

      expect(forecast.days.length, 3);
      expect(forecast.latitude, 42.15);
      expect(forecast.longitude, 9.1);
      expect(forecast.produiteLe!.iso8601, '2026-09-28T07:17:30.000Z');
      expect(forecast.collecteeLe!.iso8601, '2026-09-28T07:42:10.000Z');
      expect(forecast.source, 'met-norway');
    });

    test('LA DATE AFFICHABLE EST CELLE DE FABRICATION, PAS CELLE DE COLLECTE', () {
      // Demande de Christophe du 28/09, verbatim : « la date affichee est celle de
      // FABRICATION ». Les deux instants sont volontairement distants de 25 minutes
      // ici : c'est exactement l'ecart qui trompait le randonneur, et le seul moyen
      // de prouver lequel des deux sort du modele.
      final forecast = WeatherForecast.depuisLePublie(
        jours: _joursPublies(),
        latitude: 42.15,
        longitude: 9.1,
        produiteLe: _instant('2026-09-28T07:17:30.000Z'),
        collecteeLe: _instant('2026-09-28T07:42:10.000Z'),
      );

      expect(forecast.produiteLeLocal,
          DateTime.utc(2026, 9, 28, 7, 17, 30).toLocal());
      expect(forecast.produiteLeLocal,
          isNot(forecast.collecteeLe!.date.toLocal()));
    });

    test('ageAt mesure l age depuis la FABRICATION', () {
      final forecast = WeatherForecast.depuisLePublie(
        jours: _joursPublies(),
        latitude: 42.15,
        longitude: 9.1,
        produiteLe: _instant('2026-09-28T06:00:00.000Z'),
        collecteeLe: _instant('2026-09-28T11:00:00.000Z'),
      );

      // Huit heures apres la fabrication, cinq apres la collecte : c'est HUIT que
      // le randonneur doit lire.
      expect(
        forecast.ageAt(DateTime.utc(2026, 9, 28, 14)),
        const Duration(hours: 8),
      );
    });

    test('un bulletin sans date de fabrication a un age INCONNU, pas nul', () {
      const forecast = WeatherForecast(days: [], latitude: 0, longitude: 0);
      expect(forecast.produiteLe, isNull);
      expect(forecast.ageAt(DateTime.utc(2026, 9, 28)), isNull);
    });

    test('dayOn trouve la journee calendaire, pas l index du bulletin', () {
      final forecast = WeatherForecast.depuisLePublie(
        jours: _joursPublies(),
        latitude: 42.15,
        longitude: 9.1,
        produiteLe: _instant('2026-07-01T06:00:00.000Z'),
      );
      expect(forecast.dayOn(DateTime(2026, 7, 2))!.temperatureMax, 25.0);
      expect(forecast.dayOn(DateTime(2026, 8, 2)), isNull);
    });

    test('un jour non conforme est ignore, il ne casse pas le bulletin', () {
      // #S10 de la spec 605 appliquee au grain du jour : mieux vaut un bulletin
      // partiel qu'une exception sur un ecran de montagne.
      final forecast = WeatherForecast.depuisLePublie(
        jours: [..._joursPublies(), 'pas un objet', 42],
        latitude: 42.15,
        longitude: 9.1,
        produiteLe: _instant('2026-07-01T06:00:00.000Z'),
      );
      expect(forecast.days.length, 3);
    });
  });

  group('DayForecast', () {
    test('isAlertCondition détecte pluie forte', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 25,
        temperatureMin: 15,
        precipitationMm: 30,
        windSpeedKmh: 20,
        uvIndex: 5,
        weatherCode: 65,
      );
      expect(day.isAlertCondition, true);
    });

    test('isAlertCondition détecte vent fort', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 10,
        precipitationMm: 0,
        windSpeedKmh: 65,
        uvIndex: 3,
        weatherCode: 2,
      );
      expect(day.isAlertCondition, true);
    });

    test('isAlertCondition false pour beau temps', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 28,
        temperatureMin: 18,
        precipitationMm: 0,
        windSpeedKmh: 10,
        uvIndex: 6,
        weatherCode: 0,
      );
      expect(day.isAlertCondition, false);
    });

    test('weatherDescription retourne le bon texte', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 10,
        precipitationMm: 0,
        windSpeedKmh: 10,
        uvIndex: 5,
        weatherCode: 0,
      );
      expect(day.weatherDescription, 'Ciel dégagé');
    });

    test('weatherDescription orage', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 10,
        precipitationMm: 15,
        windSpeedKmh: 40,
        uvIndex: 2,
        weatherCode: 95,
      );
      expect(day.weatherDescription, 'Orage');
    });

    test('weatherIconName soleil pour code 0', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 10,
        precipitationMm: 0,
        windSpeedKmh: 10,
        uvIndex: 5,
        weatherCode: 0,
      );
      expect(day.weatherIconName, 'wb_sunny');
    });

    test('weatherIconName neige pour code 71', () {
      final day = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 2,
        temperatureMin: -3,
        precipitationMm: 10,
        windSpeedKmh: 20,
        uvIndex: 1,
        weatherCode: 71,
      );
      expect(day.weatherIconName, 'ac_unit');
    });

    test('versLePublie et depuisLePublie sont symétriques', () {
      final original = DayForecast(
        date: DateTime(2026, 7, 15),
        temperatureMax: 28.5,
        temperatureMin: 14.2,
        precipitationMm: 2.3,
        windSpeedKmh: 15.0,
        uvIndex: 7.0,
        weatherCode: 2,
      );
      final restored = DayForecast.depuisLePublie(original.versLePublie());

      expect(restored.temperatureMax, 28.5);
      expect(restored.temperatureMin, 14.2);
      expect(restored.precipitationMm, 2.3);
      expect(restored.windSpeedKmh, 15.0);
      expect(restored.uvIndex, 7.0);
      expect(restored.weatherCode, 2);
      expect(restored.date, DateTime(2026, 7, 15));
    });

    test('LE FORMAT PUBLIE EST EN SNAKE_CASE, comme les sept autres familles', () {
      // #S11 de la spec 605 : le depot porte DEJA le piege inverse — fichier
      // embarque en camelCase, fichier publie en snake_case, et les deux ecritures
      // du Mare a Mare se contredisent pour cette raison exacte. Une huitieme
      // famille publiee en camelCase aurait rouvert ce piege, et ce test est ce qui
      // l'interdit.
      final publie = DayForecast(
        date: DateTime(2026, 7, 15),
        temperatureMax: 28.5,
        temperatureMin: 14.2,
        precipitationMm: 2.3,
        windSpeedKmh: 15.0,
        uvIndex: 7.0,
        weatherCode: 2,
        precipitationProbabilityMax: 40,
      ).versLePublie();

      expect(
        publie.keys.toSet(),
        {
          'date',
          'temperature_max',
          'temperature_min',
          'precipitation_mm',
          'wind_speed_kmh',
          'uv_index',
          'weather_code',
          'precipitation_probability_max',
        },
      );
      for (final cle in publie.keys) {
        expect(cle, isNot(matches('[A-Z]')),
            reason: 'La clef « $cle » n est pas en snake_case.');
      }
    });
  });

  // --- Probabilité d'orage + dérivation stormProbability ---
  group('DayForecast — orage', () {
    test('depuisLePublie lit precipitation_probability_max', () {
      final forecast = WeatherForecast.depuisLePublie(
        jours: [
          _jour('2026-07-01', code: 1, proba: 10),
          _jour('2026-07-02', code: 80, proba: 75),
        ],
        latitude: 42.0,
        longitude: 9.0,
        produiteLe: _instant('2026-07-01T06:00:00.000Z'),
      );
      expect(forecast.days[0].precipitationProbabilityMax, 10);
      expect(forecast.days[1].precipitationProbabilityMax, 75);
    });

    test('champ absent => precipitationProbabilityMax null', () {
      // Un serveur qui n'agrege pas la probabilite ne doit pas rendre le bulletin
      // illisible : `stormProbability` retombe alors sur le code WMO seul.
      final forecast = WeatherForecast.depuisLePublie(
        jours: [_jour('2026-07-01', code: 1)],
        latitude: 42.0,
        longitude: 9.0,
        produiteLe: _instant('2026-07-01T06:00:00.000Z'),
      );
      expect(forecast.days.first.precipitationProbabilityMax, isNull);
      expect(forecast.days.first.stormProbability, 0);
    });

    test('stormProbability = 100 si code orage, sinon la proba de pluie', () {
      final storm = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 12,
        precipitationMm: 5,
        windSpeedKmh: 30,
        uvIndex: 3,
        weatherCode: 95,
        precipitationProbabilityMax: 40,
      );
      expect(storm.isStorm, true);
      expect(storm.stormProbability, 100);

      final rainy = DayForecast(
        date: DateTime(2026, 7, 2),
        temperatureMax: 22,
        temperatureMin: 14,
        precipitationMm: 4,
        windSpeedKmh: 15,
        uvIndex: 4,
        weatherCode: 80,
        precipitationProbabilityMax: 65,
      );
      expect(rainy.isStorm, false);
      expect(rainy.stormProbability, 65);

      final clear = DayForecast(
        date: DateTime(2026, 7, 3),
        temperatureMax: 26,
        temperatureMin: 16,
        precipitationMm: 0,
        windSpeedKmh: 8,
        uvIndex: 6,
        weatherCode: 1,
      );
      expect(clear.stormProbability, 0);
    });

    test('aller-retour publie conserve precipitationProbabilityMax', () {
      final original = DayForecast(
        date: DateTime(2026, 7, 1),
        temperatureMax: 20,
        temperatureMin: 12,
        precipitationMm: 5,
        windSpeedKmh: 30,
        uvIndex: 3,
        weatherCode: 80,
        precipitationProbabilityMax: 55,
      );
      final restored = DayForecast.depuisLePublie(original.versLePublie());
      expect(restored.precipitationProbabilityMax, 55);
    });
  });
}

/// Un instant tel que le SERVEUR l'annonce. Aucune horloge de telephone ici.
HorodatageServeur _instant(String iso) =>
    HorodatageServeur.annonceParLeServeur(iso)!;

/// Un jour de prevision dans la forme PUBLIEE (snake_case).
Map<String, dynamic> _jour(
  String date, {
  required int code,
  double tMax = 25.0,
  double tMin = 15.0,
  num? proba,
}) =>
    {
      'date': date,
      'temperature_max': tMax,
      'temperature_min': tMin,
      'precipitation_mm': 0.0,
      'wind_speed_kmh': 10.0,
      'uv_index': 7.0,
      'weather_code': code,
      if (proba != null) 'precipitation_probability_max': proba,
    };

/// Trois jours publies par le serveur.
List<dynamic> _joursPublies() => [
      _jour('2026-07-01', code: 0, tMax: 28.0, tMin: 18.0),
      _jour('2026-07-02', code: 3, tMax: 25.0, tMin: 15.0),
      _jour('2026-07-03', code: 61, tMax: 22.0, tMin: 12.0),
    ];
