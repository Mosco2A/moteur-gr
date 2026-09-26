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

    test('cacheTtlHours vaut 3', () {
      expect(WeatherCacheDao.cacheTtlHours, 3);
    });
  });

  // TACHE 572 — le TTL gouverne le RE-TELECHARGEMENT, pas le droit d'afficher.
  // Le test `clearByTrailId` a disparu avec la methode : plus aucun appelant
  // dans l'application (reaudit : retirer ce qui ne sert a rien).
  group('WeatherCacheDao — hors ligne (tache 572)', () {
    test(
        'getLastCache rend la ligne meme PERIMEE, la ou getValidCache rend null',
        () async {
      final old = DateTime.now().subtract(const Duration(hours: 6));
      await db.into(db.weatherCache).insert(WeatherCacheCompanion.insert(
            trailId: 'sentier-bleu',
            stageNumber: 1,
            forecastJson: '{"version": "matin"}',
            fetchedAt: old,
            // Perime depuis 3 h : le re-telechargement est du, l'affichage non.
            expiresAt: old.add(const Duration(hours: 3)),
          ));

      expect(
        await dao.getValidCache('sentier-bleu', 1),
        isNull,
        reason: 'La ligne est perimee : il FAUT rappeler le fournisseur.',
      );
      final last = await dao.getLastCache('sentier-bleu', 1);
      expect(
        last,
        isNotNull,
        reason: 'Mais le randonneur garde le bulletin qu\'il a telecharge le '
            'matin : sans reseau, c\'est tout ce qu\'il a.',
      );
      expect(last!.forecastJson, '{"version": "matin"}');
      expect(last.fetchedAt.difference(old).inSeconds.abs(), lessThan(2),
          reason: 'L\'instant du releve doit remonter tel quel : c\'est lui '
              'que l\'ecran affiche comme age.');
    });

    test(
        'clearFetchedBefore purge sur l\'AGE du bulletin, pas sur son expiration',
        () async {
      final now = DateTime(2026, 7, 20, 12);
      // Bulletin de ce matin : perime pour le re-telechargement, mais c'est la
      // seule meteo du randonneur. Il DOIT survivre a la purge.
      await db.into(db.weatherCache).insert(WeatherCacheCompanion.insert(
            trailId: 'sentier-bleu',
            stageNumber: 1,
            forecastJson: '{"age": "6h"}',
            fetchedAt: now.subtract(const Duration(hours: 6)),
            expiresAt: now.subtract(const Duration(hours: 3)),
          ));
      // Bulletin vieux de dix jours : plus aucune valeur, il part.
      await db.into(db.weatherCache).insert(WeatherCacheCompanion.insert(
            trailId: 'sentier-bleu',
            stageNumber: 2,
            forecastJson: '{"age": "10j"}',
            fetchedAt: now.subtract(const Duration(days: 10)),
            expiresAt: now.subtract(const Duration(days: 10)),
          ));

      final deleted =
          await dao.clearFetchedBefore(now.subtract(const Duration(days: 7)));

      expect(deleted, 1);
      expect(await dao.getLastCache('sentier-bleu', 1), isNotNull,
          reason: 'Le bulletin de ce matin survit : la politique ecrite est de '
              '7 jours pour les caches carto/meteo, pas de 3 heures.');
      expect(await dao.getLastCache('sentier-bleu', 2), isNull);
    });
  });
}
