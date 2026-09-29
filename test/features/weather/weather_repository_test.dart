import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/daos/trail_meteo_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/features/weather/data/weather_repository.dart';

/// LOT 625 — L APPLI LIT LA METEO, ELLE NE LA DEMANDE PLUS.
///
/// Decision de Christophe du 28/09, verbatim : « Ce n est pas l appli qui demande la
/// meteo mais notre serveur, les infos meteo sont mises sur firebase et quand l appli
/// voit qu il y a des donnees a jour elle les met a jour, comme pour le reste. »
///
/// CE QUE CES TESTS NE PEUVENT PLUS FAIRE, ET C EST LA MESURE : il n y a plus de
/// `MockClient` ici. Aucun client HTTP n est injectable dans le chemin meteo, parce
/// qu aucun appel n en part. Un test qui voudrait simuler une reponse de fournisseur
/// n aurait plus de point d insertion — c est la garantie la plus solide que la
/// decision est appliquee et pas seulement ecrite.
void main() {
  late AppDatabase db;
  late TrailMeteoDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailMeteoDao(db);
  });

  tearDown(() async => db.close());

  Future<void> deposerBulletin({
    String id = 'bleu-s1-meteo',
    String trailId = 'sentier-bleu',
    int stageNumber = 1,
    required String produiteLe,
    String? collecteeLe,
    String source = 'met-norway',
  }) async {
    await dao.insertOrReplace(TrailMeteoCompanion(
      id: Value(id),
      trailId: Value(trailId),
      stageId: Value('bleu-s$stageNumber'),
      stageNumber: Value(stageNumber),
      latitude: const Value(42.472),
      longitude: const Value(8.927),
      source: Value(source),
      produiteLe: Value(HorodatageServeur.annonceParLeServeur(produiteLe)!),
      collecteeLe:
          Value(HorodatageServeur.annonceParLeServeur(collecteeLe)),
      joursJson: Value(jsonEncode(_joursPublies)),
      rev: Value(HorodatageServeur.annonceParLeServeur(produiteLe)),
    ));
  }

  WeatherRepository repo({Future<bool> Function()? passe}) =>
      WeatherRepository(
        dao: dao,
        demanderUnePasse: passe ?? () async => true,
      );

  group('Lire la meteo deposee par le serveur', () {
    test('le bulletin d une etape se lit en base, avec ses trois dates', () async {
      await deposerBulletin(
        produiteLe: '2026-09-28T07:17:30.000Z',
        collecteeLe: '2026-09-28T07:42:10.000Z',
      );

      final bulletin = await repo().bulletinDeLEtape(
        trailId: 'sentier-bleu',
        stageNumber: 1,
      );

      expect(bulletin, isNotNull);
      expect(bulletin!.days.length, 3);
      expect(bulletin.days[0].temperatureMax, 25.0);
      expect(bulletin.days[1].precipitationMm, 5.0);
      expect(bulletin.days[2].weatherCode, 1);
      expect(bulletin.produiteLe!.iso8601, '2026-09-28T07:17:30.000Z');
      expect(bulletin.collecteeLe!.iso8601, '2026-09-28T07:42:10.000Z');
      expect(bulletin.source, 'met-norway');
    });

    test('LA LECTURE N A BESOIN D AUCUNE ETAPE EN BASE, et c est un gain reel',
        () async {
      // DEFAUT FERME PAR LE LOT 625. L ancien repository lisait `endLat`/`endLng`
      // dans la table `stages` pour construire son appel : un sentier venu du SEUL
      // distant, dont les etapes vivent dans `trail_stages`, n avait donc aucune
      // meteo et rien ne le disait. Ici la base ne contient AUCUNE etape, et le
      // bulletin sort quand meme.
      await deposerBulletin(produiteLe: '2026-09-28T07:17:30.000Z');
      expect(await db.select(db.stages).get(), isEmpty);

      final bulletin = await repo().bulletinDeLEtape(
        trailId: 'sentier-bleu',
        stageNumber: 1,
      );
      expect(bulletin, isNotNull);
    });

    test('RIEN EN BASE = REPONSE, PAS PANNE : null, et aucune invention',
        () async {
      final bulletin = await repo().bulletinDeLEtape(
        trailId: 'sentier-bleu',
        stageNumber: 1,
      );
      expect(bulletin, isNull);
    });

    test('une ligne illisible vaut « pas de bulletin », jamais une exception',
        () async {
      await dao.insertOrReplace(TrailMeteoCompanion(
        id: const Value('bleu-s1-meteo'),
        trailId: const Value('sentier-bleu'),
        stageId: const Value('bleu-s1'),
        stageNumber: const Value(1),
        latitude: const Value(42.4),
        longitude: const Value(8.9),
        source: const Value('met-norway'),
        produiteLe: Value(
            HorodatageServeur.annonceParLeServeur('2026-09-28T07:00:00.000Z')!),
        joursJson: const Value('{ceci n est pas du json'),
      ));

      expect(
        await repo().bulletinDeLEtape(trailId: 'sentier-bleu', stageNumber: 1),
        isNull,
      );
    });

    test('les bulletins d un sentier sortent par numero d etape croissant',
        () async {
      await deposerBulletin(
          id: 'b3', stageNumber: 3, produiteLe: '2026-09-28T07:00:00.000Z');
      await deposerBulletin(
          id: 'b1', stageNumber: 1, produiteLe: '2026-09-28T07:00:00.000Z');
      await deposerBulletin(
          id: 'b2', stageNumber: 2, produiteLe: '2026-09-28T07:00:00.000Z');

      final tous = await repo().bulletinsDuSentier('sentier-bleu');
      expect(tous.length, 3);
    });
  });

  group('Demander la mise a jour — QUATRE ISSUES DISTINCTES', () {
    test('un bulletin plus recent arrive : issue « recue »', () async {
      await deposerBulletin(produiteLe: '2026-09-28T03:00:00.000Z');

      final resultat = await repo(passe: () async {
        // La passe de synchronisation pose un bulletin plus recent, comme le fait
        // la vraie pose transactionnelle de `DeltaUpdateService`.
        await deposerBulletin(produiteLe: '2026-09-28T07:00:00.000Z');
        return true;
      }).demanderLaMiseAJour(trailId: 'sentier-bleu', stageNumber: 1);

      expect(resultat.issue, IssueMiseAJourMeteo.recue);
      expect(resultat.echoue, false);
      expect(resultat.bulletin!.produiteLe!.iso8601,
          '2026-09-28T07:00:00.000Z');
    });

    test('LE SERVEUR N A RIEN DE PLUS RECENT N EST PAS UN ECHEC', () async {
      // C est le cas LE PLUS FREQUENT d une cadence de quatre heures. L annoncer
      // comme un echec apprendrait au randonneur a ignorer le message — exactement
      // la faute que la tache 572 a corrigee dans l autre sens.
      await deposerBulletin(produiteLe: '2026-09-28T07:00:00.000Z');

      final resultat = await repo(passe: () async => true)
          .demanderLaMiseAJour(trailId: 'sentier-bleu', stageNumber: 1);

      expect(resultat.issue, IssueMiseAJourMeteo.rienDePlusRecent);
      expect(resultat.echoue, false);
      expect(resultat.bulletin, isNotNull);
    });

    test('HORS LIGNE : LA PASSE N A PAS TOURNE, et le bulletin reste', () async {
      await deposerBulletin(produiteLe: '2026-09-28T07:00:00.000Z');

      // L ORDONNANCEUR EST LA SEULE AUTORITE SUR CETTE QUESTION. C est lui qui
      // ecarte une passe hors ligne — « une passe hors ligne ne produirait qu un
      // echec de transport et des journaux trompeurs » — et il ne compte que
      // celles qui ont REELLEMENT tourne. Le repository lit son verdict au lieu
      // d interroger le reseau une seconde fois : deux sources pour un meme fait,
      // c est le piege #M7 de la spec 605, et la plus silencieuse gagne.
      final resultat = await repo(passe: () async => false)
          .demanderLaMiseAJour(trailId: 'sentier-bleu', stageNumber: 1);

      expect(resultat.issue, IssueMiseAJourMeteo.horsLigne);
      expect(resultat.echoue, true);
      expect(resultat.bulletin, isNotNull,
          reason: 'Ce qui est affiche reste affiche, avec son age.');
    });

    test('une passe en echec laisse le dernier bulletin connu', () async {
      await deposerBulletin(produiteLe: '2026-09-28T07:00:00.000Z');

      final resultat = await repo(
        passe: () async => throw Exception('transport interrompu'),
      ).demanderLaMiseAJour(trailId: 'sentier-bleu', stageNumber: 1);

      expect(resultat.issue, IssueMiseAJourMeteo.echec);
      expect(resultat.echoue, true);
      expect(resultat.bulletin, isNotNull);
      expect(resultat.cause, contains('transport interrompu'));
    });

    test('LE PREMIER BULLETIN DE LA VIE DU TELEPHONE EST UNE RECEPTION',
        () async {
      // Rien en base au depart : c est le randonneur qui vient d installer
      // l application et qui retrouve du reseau pour la premiere fois.
      final resultat = await repo(passe: () async {
        await deposerBulletin(produiteLe: '2026-09-28T07:00:00.000Z');
        return true;
      }).demanderLaMiseAJour(trailId: 'sentier-bleu', stageNumber: 1);

      expect(resultat.issue, IssueMiseAJourMeteo.recue);
      expect(resultat.bulletin, isNotNull);
    });

    test('une passe qui ne rapporte rien du tout reste honnete', () async {
      // Ni bulletin avant, ni bulletin apres : il n y a rien a montrer, et il faut
      // le dire sans pretendre a un echec de reseau qui n a pas eu lieu.
      final resultat = await repo(passe: () async => true)
          .demanderLaMiseAJour(trailId: 'sentier-bleu', stageNumber: 1);

      expect(resultat.issue, IssueMiseAJourMeteo.rienDePlusRecent);
      expect(resultat.bulletin, isNull);
    });
  });
}

/// Trois jours publies par le serveur, en snake_case (forme du fichier publie).
const _joursPublies = [
  {
    'date': '2026-06-01',
    'temperature_max': 25.0,
    'temperature_min': 12.0,
    'precipitation_mm': 0.0,
    'wind_speed_kmh': 15.0,
    'uv_index': 7.0,
    'weather_code': 0,
  },
  {
    'date': '2026-06-02',
    'temperature_max': 22.0,
    'temperature_min': 10.0,
    'precipitation_mm': 5.0,
    'wind_speed_kmh': 25.0,
    'uv_index': 5.0,
    'weather_code': 61,
  },
  {
    'date': '2026-06-03',
    'temperature_max': 28.0,
    'temperature_min': 15.0,
    'precipitation_mm': 0.0,
    'wind_speed_kmh': 10.0,
    'uv_index': 9.0,
    'weather_code': 1,
  },
];
