import 'package:drift/drift.dart';

/// Table de cache météo par étape.
///
/// Stocke les prévisions météo récupérées depuis Open-Meteo,
/// avec un TTL de cache de 3 heures. Ajoutée en migration v5.
class WeatherCache extends Table {
  /// Clé primaire auto-incrémentée
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier (ex: 'gr10')
  TextColumn get trailId => text()();

  /// Numéro d'étape concernée
  IntColumn get stageNumber => integer()();

  /// Données JSON brutes de la prévision météo
  TextColumn get forecastJson => text()();

  /// Date de récupération (pour calcul TTL)
  DateTimeColumn get fetchedAt => dateTime()();

  /// Date d'expiration du cache (fetchedAt + 3h)
  DateTimeColumn get expiresAt => dateTime()();
}
