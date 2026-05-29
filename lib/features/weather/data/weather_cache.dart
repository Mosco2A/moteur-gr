import 'package:drift/drift.dart';

import '../domain/weather_data.dart';

/// Table Drift pour le cache meteo (definition).
///
/// Sera ajoutee a AppDatabase lors de la prochaine migration.
/// En attendant, le DAO cree la table via raw SQL au premier acces.
///
/// Cle composite: (latitude arrondie, longitude arrondie, date).
/// TTL: 6 heures (les previsions changent peu intra-journee).
class WeatherCache extends Table {
  /// Latitude arrondie a 2 decimales (precision ~1km)
  RealColumn get latitude => real()();

  /// Longitude arrondie a 2 decimales
  RealColumn get longitude => real()();

  /// Date de la prevision (YYYY-MM-DD)
  TextColumn get date => text()();

  /// Temperature minimale en degres Celsius
  RealColumn get temperatureMin => real()();

  /// Temperature maximale en degres Celsius
  RealColumn get temperatureMax => real()();

  /// Precipitations cumulees en mm
  RealColumn get precipitationMm => real()();

  /// Probabilite de precipitations (0-100)
  IntColumn get precipitationProbability => integer()();

  /// Code meteo WMO
  IntColumn get weatherCode => integer()();

  /// Vitesse max du vent en km/h
  RealColumn get windSpeedMax => real()();

  /// Indice UV max
  RealColumn get uvIndexMax => real()();

  /// Timestamp d'insertion (millisecondes epoch)
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {latitude, longitude, date};
}

/// Interface abstraite pour le cache meteo.
///
/// Permet de substituer facilement en tests (fake in-memory)
/// sans dependre de Drift.
abstract class WeatherCacheStore {
  /// Recupere les previsions en cache (non expirees).
  Future<List<WeatherData>> getCachedForecast({
    required double latitude,
    required double longitude,
  });

  /// Insere ou met a jour les previsions en cache.
  Future<void> cacheForecast(List<WeatherData> forecasts);

  /// Purge les entrees expirees.
  Future<int> purgeExpired();
}

/// Implementation Drift du cache meteo.
///
/// Utilise raw SQL via Drift pour eviter de modifier AppDatabase
/// et son schema version. La table est creee automatiquement
/// au premier acces (CREATE TABLE IF NOT EXISTS).
///
/// Le TTL est de 6 heures par defaut.
class DriftWeatherCacheDao implements WeatherCacheStore {
  DriftWeatherCacheDao(this._db);

  final GeneratedDatabase _db;

  static const _ttlMs = 6 * 60 * 60 * 1000; // 6 heures
  static const _tableName = 'weather_cache';

  bool _tableCreated = false;

  /// Cree la table si elle n'existe pas encore.
  Future<void> _ensureTable() async {
    if (_tableCreated) return;
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        date TEXT NOT NULL,
        temperature_min REAL NOT NULL,
        temperature_max REAL NOT NULL,
        precipitation_mm REAL NOT NULL,
        precipitation_probability INTEGER NOT NULL,
        weather_code INTEGER NOT NULL,
        wind_speed_max REAL NOT NULL,
        uv_index_max REAL NOT NULL,
        cached_at INTEGER NOT NULL,
        PRIMARY KEY (latitude, longitude, date)
      )
    ''');
    _tableCreated = true;
  }

  @override
  Future<List<WeatherData>> getCachedForecast({
    required double latitude,
    required double longitude,
  }) async {
    await _ensureTable();
    final roundedLat = _round2(latitude);
    final roundedLng = _round2(longitude);
    final cutoff = DateTime.now().millisecondsSinceEpoch - _ttlMs;

    final rows = await _db.customSelect(
      'SELECT * FROM $_tableName '
      'WHERE latitude = ? AND longitude = ? AND cached_at >= ? '
      'ORDER BY date ASC',
      variables: [
        Variable.withReal(roundedLat),
        Variable.withReal(roundedLng),
        Variable.withInt(cutoff),
      ],
    ).get();

    return rows
        .map((row) => WeatherData(
              date: row.read<String>('date'),
              latitude: row.read<double>('latitude'),
              longitude: row.read<double>('longitude'),
              temperatureMin: row.read<double>('temperature_min'),
              temperatureMax: row.read<double>('temperature_max'),
              precipitationMm: row.read<double>('precipitation_mm'),
              precipitationProbability:
                  row.read<int>('precipitation_probability'),
              weatherCode: row.read<int>('weather_code'),
              windSpeedMax: row.read<double>('wind_speed_max'),
              uvIndexMax: row.read<double>('uv_index_max'),
            ))
        .toList();
  }

  @override
  Future<void> cacheForecast(List<WeatherData> forecasts) async {
    if (forecasts.isEmpty) return;
    await _ensureTable();

    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      for (final f in forecasts) {
        await _db.customStatement(
          'INSERT OR REPLACE INTO $_tableName '
          '(latitude, longitude, date, temperature_min, temperature_max, '
          'precipitation_mm, precipitation_probability, weather_code, '
          'wind_speed_max, uv_index_max, cached_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            _round2(f.latitude),
            _round2(f.longitude),
            f.date,
            f.temperatureMin,
            f.temperatureMax,
            f.precipitationMm,
            f.precipitationProbability,
            f.weatherCode,
            f.windSpeedMax,
            f.uvIndexMax,
            now,
          ],
        );
      }
    });
  }

  @override
  Future<int> purgeExpired() async {
    await _ensureTable();
    final cutoff = DateTime.now().millisecondsSinceEpoch - _ttlMs;
    await _db.customStatement(
      'DELETE FROM $_tableName WHERE cached_at < ?',
      [cutoff],
    );
    return 0;
  }

  /// Arrondi a 2 decimales (~1.1km de precision).
  double _round2(double value) => (value * 100).roundToDouble() / 100;
}
