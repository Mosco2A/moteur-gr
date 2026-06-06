import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/weather_cache_dao.dart';

/// Tests du DAO cache météo.
void main() {
  late AppDatabase db;
  late WeatherCacheDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = WeatherCacheDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WeatherCacheDao', () {
    test('upsertForecast insère un cache', () async {
      await dao.upsertForecast(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        forecastJson: '{"test": true}',
      );

      final cached = await dao.getValidCache('sentier-bleu', 1);
      expect(cached, isNotNull);
      expect(cached!.forecastJson, '{"test": true}');
    });

    test('getValidCache retourne null si aucun cache', () async {
      final cached = await dao.getValidCache('sentier-bleu', 1);
      expect(cached, isNull);
    });

    test('upsertForecast remplace l\'ancien cache', () async {
      await dao.upsertForecast(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        forecastJson: '{"version": 1}',
      );
      await dao.upsertForecast(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        forecastJson: '{"version": 2}',
      );

      final cached = await dao.getValidCache('sentier-bleu', 1);
      expect(cached!.forecastJson, '{"version": 2}');
    });

    test('clearByTrailId supprime le cache du sentier', () async {
      await dao.upsertForecast(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        forecastJson: '{}',
      );
      await dao.upsertForecast(
        trailId: 'sentier-bleu',
        stageNumber: 2,
        forecastJson: '{}',
      );
      await dao.upsertForecast(
        trailId: 'tmb',
        stageNumber: 1,
        forecastJson: '{}',
      );

      final deleted = await dao.clearByTrailId('sentier-bleu');
      expect(deleted, 2);

      final tmb = await dao.getValidCache('tmb', 1);
      expect(tmb, isNotNull);
    });

    test('cacheTtlHours vaut 3', () {
      expect(WeatherCacheDao.cacheTtlHours, 3);
    });
  });
}
