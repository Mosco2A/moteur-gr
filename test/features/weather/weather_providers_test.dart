import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/daos/trail_meteo_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/weather/data/weather_repository.dart';
import 'package:moteur_gr/features/weather/providers/weather_providers.dart';

import 'meteo_du_serveur.dart';

/// LOT 625 — CE QUE L ECRAN OBTIENT, ET CE QU IL N OBTIENT PLUS.
///
/// Ce fichier testait « le provider retourne les donnees du cache si offline », avec
/// deux `MockClient` : un qui repond, un qui jette. Les deux ont disparu, et c est le
/// point : hors ligne ne change RIEN a la lecture, puisque la lecture n a jamais ete
/// un appel. Le bulletin est en base, le serveur l y a mis, l ecran le lit.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  ProviderContainer contenant({
    ConnectivityStatus reseau = ConnectivityStatusValues.online,
    Future<bool> Function()? passe,
  }) {
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      connectivityProvider.overrideWith((ref) => Stream.value(reseau)),
      weatherRepositoryProvider.overrideWith((ref) => WeatherRepository(
            dao: TrailMeteoDao(db),
            demanderUnePasse: passe ?? () async => true,
          )),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  const params = WeatherStageParams(trailId: 'sentier-bleu', stageNumber: 1);

  group('StageWeatherNotifier — la lecture du bulletin du serveur', () {
    test('expose le bulletin depose en base', () async {
      await deposerMeteoEnBase(
        db,
        trailId: 'sentier-bleu',
        stageNumber: 1,
        produiteLe: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );

      final c = contenant();
      c.listen(stageWeatherProvider(params), (_, __) {});
      await pumpEventQueue();

      final etat = c.read(stageWeatherProvider(params));
      expect(etat.forecast, isNotNull);
      expect(etat.jamaisRecue, false);
      expect(etat.forecast!.produiteLe, isNotNull);
    });

    test('HORS LIGNE NE CHANGE RIEN : le bulletin est la, avec son age', () async {
      await deposerMeteoEnBase(
        db,
        trailId: 'sentier-bleu',
        stageNumber: 1,
        produiteLe: DateTime.now().toUtc().subtract(const Duration(hours: 5)),
      );

      final c = contenant(reseau: ConnectivityStatusValues.offline);
      c.listen(stageWeatherProvider(params), (_, __) {});
      await pumpEventQueue();

      final etat = c.read(stageWeatherProvider(params));
      expect(etat.forecast, isNotNull,
          reason: 'La lecture n est pas un appel : elle ne depend pas du reseau.');
      expect(etat.forecast!.ageAt()!.inHours, greaterThanOrEqualTo(4));
    });

    test('RIEN EN BASE : jamaisRecue, et AUCUNE prevision inventee', () async {
      final c = contenant(reseau: ConnectivityStatusValues.offline);
      c.listen(stageWeatherProvider(params), (_, __) {});
      await pumpEventQueue();

      final etat = c.read(stageWeatherProvider(params));
      expect(etat.jamaisRecue, true,
          reason: 'C est le randonneur qui n a jamais eu de reseau depuis '
              'l installation, et ce cas doit etre NOMME.');
      expect(etat.forecast, isNull);
      expect(etat.alerts, isEmpty,
          reason: 'Aucune alerte ne peut etre derivee de rien.');
    });

    test('rafraichir HORS LIGNE n emet aucune passe et le dit', () async {
      await deposerMeteoEnBase(
        db,
        trailId: 'sentier-bleu',
        stageNumber: 1,
        produiteLe: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      );
      // La passe rend `false` : c est ce que l ordonnanceur fait quand il ecarte
      // une passe faute de reseau.
      final c = contenant(
        reseau: ConnectivityStatusValues.offline,
        passe: () async => false,
      );
      c.listen(stageWeatherProvider(params), (_, __) {});
      await pumpEventQueue();

      final abouti =
          await c.read(stageWeatherProvider(params).notifier).refresh();

      expect(abouti, false);
      expect(c.read(stageWeatherProvider(params)).derniereIssue,
          IssueMiseAJourMeteo.horsLigne);
      expect(c.read(stageWeatherProvider(params)).forecast, isNotNull,
          reason: 'Un echec ne vide pas l ecran.');
    });

    test('rafraichir EN LIGNE passe par l ordonnanceur, une seule fois', () async {
      var passes = 0;
      final c = contenant(passe: () async {
        passes++;
        await deposerMeteoEnBase(
          db,
          trailId: 'sentier-bleu',
          stageNumber: 1,
          produiteLe: DateTime.now().toUtc(),
        );
        return true;
      });
      c.listen(stageWeatherProvider(params), (_, __) {});
      await pumpEventQueue();

      final abouti =
          await c.read(stageWeatherProvider(params).notifier).refresh();

      expect(passes, 1,
          reason: 'UNE passe pour tout le sentier, plus un appel par etape.');
      expect(abouti, true);
      expect(c.read(stageWeatherProvider(params)).derniereIssue,
          IssueMiseAJourMeteo.recue);
    });

    test('« rien de plus recent » est un succes, pas un echec', () async {
      final produiteLe = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      await deposerMeteoEnBase(
        db,
        trailId: 'sentier-bleu',
        stageNumber: 1,
        produiteLe: produiteLe,
      );

      final c = contenant(passe: () async => true);
      c.listen(stageWeatherProvider(params), (_, __) {});
      await pumpEventQueue();

      final abouti =
          await c.read(stageWeatherProvider(params).notifier).refresh();

      expect(abouti, true);
      expect(c.read(stageWeatherProvider(params)).derniereIssue,
          IssueMiseAJourMeteo.rienDePlusRecent);
      expect(c.read(stageWeatherProvider(params)).refreshFailed, false);
    });
  });

  group('WeatherStageParams', () {
    test('identite par sentier et numero d etape', () {
      expect(params.trailId, 'sentier-bleu');
      expect(params.stageNumber, 1);
      expect(
        params,
        equals(const WeatherStageParams(trailId: 'sentier-bleu', stageNumber: 1)),
      );
      expect(
        params,
        isNot(const WeatherStageParams(trailId: 'sentier-bleu', stageNumber: 2)),
      );
    });
  });
}
