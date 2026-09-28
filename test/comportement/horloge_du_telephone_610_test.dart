import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/empreinte_de_publication.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';

/// TACHE 610 — LA SYNCHRONISATION PASSE DU NUMERO A L HORODATAGE, ET LES QUATRE
/// PIEGES DU MODELE SONT FERMES PAR UN TEST CHACUN.
///
/// DECISION DE CHRISTOPHE DU 28/09 09:32, verbatim : « le serveur a une seule
/// version de meteo par etapes et ce a 3 ou 5 jours. Avec une date de MAJ. Quand
/// l appli recupere du reseau (et ensuite toutes les 4 heures par exemple) elle
/// vient verifier toutes les donnees superieures a sa date de MAJ. Pas besoin
/// d une version mais d un timestamp de donnees. On regarde le dernier timestamp
/// de MAJ complet et on telecharge tout ce qui concerne ses sentiers qui ont une
/// date superieure a cette MAJ ».
///
/// LES QUATRE PIEGES, ET POURQUOI CHACUN MERITE SON TEST.
///
///  1. L HORLOGE DU TELEPHONE. Un horodatage se compare entre machines : s il en
///     existe deux autorites de temps, un telephone en avance enregistre un
///     repere DANS LE FUTUR et rate POUR TOUJOURS tout ce qui arrive entre-temps,
///     sans jamais s en apercevoir. C est le pire defaut possible de ce modele
///     parce qu il ne se voit pas.
///
///  2. LA BORNE, PAS LE MAXIMUM RECU. Le telephone ne retient pas la plus grande
///     date qu il a vue passer, mais CELLE QUE LE SERVEUR LUI ANNONCE. Sans cela,
///     une collecte en cours d ecriture fait sauter tout ce qui est ecrit apres
///     la lecture — meme demonstration que le point 1, autre cause.
///
///  3. LE MOT « COMPLET ». Le repere n avance QUE si TOUT a ete recu, dans la
///     MEME transaction que la pose. Un telephone coupe au milieu ne doit pas se
///     croire a jour.
///
///  4. LE PERIMETRE. Le telephone demande ce qui concerne SES sentiers. Le test
///     de perimetre vit dans `update_checker_test.dart`, au plus pres du filtre.
void main() {
  late Directory bac;
  late AppDatabase db;
  late TrailManifestsDao manifestes;

  /// L instant de reference : FIXE, dans le passe, jamais `DateTime.now()`.
  final leServeurPublieA = DateTime.utc(2026, 9, 28, 6, 0, 0);
  HorodatageServeur instantServeur([Duration decalage = Duration.zero]) =>
      HorodatageServeur.annonceParLeServeur(
          leServeurPublieA.add(decalage).toIso8601String())!;

  setUp(() {
    bac = Directory.systemTemp.createTempSync('horloge610');
    db = AppDatabase(NativeDatabase.memory());
    manifestes = TrailManifestsDao(db);
  });

  tearDown(() async {
    await db.close();
    bac.deleteSync(recursive: true);
  });

  /// Le fichier de donnees d un sentier, chaque enregistrement a l instant voulu.
  Map<String, Object?> donnees({
    required HorodatageServeur instant,
    int elevationGain = 800,
    bool avecPoi = true,
    bool etapeAbimee = false,
  }) =>
      {
        'trail_meta': {
          'id': 'gr-test',
          'code': 'TEST',
          'data_version': instant.iso8601,
          'status': 'active',
          'rev': instant.iso8601,
        },
        'itineraries': [
          {
            'id': 'test-i1',
            'trail_id': 'gr-test',
            'code': 'TEST-NS',
            'name_fr': 'Test nord-sud',
            'name_en': 'Test north-south',
            'name_de': 'Test Nord-Sud',
            'name_it': 'Test nord-sud',
            'name_es': 'Test norte-sur',
            'distance_km': 14.0,
            'elevation_gain': 800,
            'stage_count': 1,
            'rev': instant.iso8601,
          }
        ],
        'stages': [
          {
            'id': 'test-s1',
            'itinerary_id': 'test-i1',
            'stage_number': 1,
            'name_fr': 'Etape 1',
            'name_en': 'Stage 1',
            'name_de': 'Etappe 1',
            'name_it': 'Tappa 1',
            'name_es': 'Etapa 1',
            'start_lat': 44.66,
            'start_lng': 3.04,
            'end_lat': 44.63,
            'end_lng': 2.98,
            'distance_km': 14.0,
            'elevation_gain': elevationGain,
            'elevation_loss': 210,
            // UNE DUREE MANQUANTE FAIT ECHOUER LA POSE DE CETTE FAMILLE, et c est
            // ce qui sert a simuler la coupure EN PLEIN MILIEU de la transaction :
            // les familles precedentes ont deja ete ecrites quand celle-ci leve.
            if (!etapeAbimee) 'duration_minutes': 240,
            'difficulty': 'moyen',
            'rev': instant.iso8601,
          }
        ],
        if (avecPoi)
          'pois': [
            {
              'id': 'test-p1',
              'stage_id': 'test-s1',
              'name_fr': 'Fontaine',
              'name_en': 'Spring',
              'name_de': 'Quelle',
              'name_it': 'Fonte',
              'name_es': 'Fuente',
              'type': 'water',
              'lat': 44.65,
              'lng': 3.0,
              'rev': instant.iso8601,
            }
          ],
      };

  /// Ecrit un fichier de donnees dans le bac et rend son entree de liste.
  ///
  /// [instantAnnonce] est ce que LA LISTE annonce — la BORNE. Il peut etre
  /// POSTERIEUR a la date du plus recent enregistrement du fichier, et c est
  /// justement le cas que le point 2 verifie.
  TrailManifestEntry deposer(
    String nom,
    Map<String, Object?> contenu, {
    required HorodatageServeur instantAnnonce,
  }) {
    final corps = jsonEncode(contenu);
    final octets = utf8.encode(corps);
    File('${bac.path}/$nom').writeAsBytesSync(octets);
    return TrailManifestEntry(
      trailId: 'gr-test',
      dataVersion: instantAnnonce,
      hash: EmpreinteDePublication.de(octets),
      filePath: nom,
      fileSize: octets.length,
      status: 'active',
      lastUpdated: instantAnnonce.iso8601,
    );
  }

  MockClient stockage() => MockClient((requete) async {
        final nom = requete.url.pathSegments.last;
        final fichier = File('${bac.path}/$nom');
        if (!fichier.existsSync()) return http.Response('non trouve', 404);
        return http.Response.bytes(fichier.readAsBytesSync(), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      });

  DeltaUpdateService service() => DeltaUpdateService(
        db: db,
        manifestService: ManifestService(
          dao: manifestes,
          connectivityMonitor: _FauxReseau(ConnectivityStatusValues.online),
        ),
        trailManifestsDao: manifestes,
        trailMetaDao: TrailMetaDao(db),
        trailItinerariesDao: TrailItinerariesDao(db),
        trailStagesDao: TrailStagesDao(db),
        trailAccommodationsDao: TrailAccommodationsDao(db),
        trailPoisDao: TrailPoisDao(db),
        trailGpxTracksDao: TrailGpxTracksDao(db),
        trailGpxPointsDao: TrailGpxPointsDao(db),
        httpClient: stockage(),
      );

  /// Pose la ligne de liste locale, comme le fait la lecture du catalogue.
  Future<void> conserver(TrailManifestEntry entree) => ManifestService(
        dao: manifestes,
        connectivityMonitor: _FauxReseau(ConnectivityStatusValues.online),
      ).saveLocalManifest(entree);

  // =========================================================================
  // 1. L HORLOGE DU TELEPHONE
  // =========================================================================
  group('610 — le telephone ne pose JAMAIS son horloge', () {
    test('LE TEST EXIGE PAR SKYNET : un telephone dont l horloge AVANCE D UNE '
        'HEURE recoit quand meme l integralite des donnees', () async {
      // LA MISE EN SCENE, ET ELLE EST EXACTEMENT CELLE DU DANGER. L appareil est
      // en avance d une heure sur le serveur : son `now()` vaut 07:00 quand le
      // serveur publie a 06:00. S il inscrivait son propre `now()` comme repere,
      // il se croirait a jour jusqu a 07:00 — et TOUT ce que le serveur publie
      // entre 06:00 et 07:00 porterait une date INFERIEURE a son repere, donc ne
      // redescendrait JAMAIS. Sans erreur, sans trace, sans moyen de le voir.
      final horlogeDeLAppareil = leServeurPublieA.add(const Duration(hours: 1));
      expect(horlogeDeLAppareil.isAfter(leServeurPublieA), isTrue,
          reason: 'la premisse du test : l appareil est en avance');

      final v1 = deposer('v1.json', donnees(instant: instantServeur()),
          instantAnnonce: instantServeur());
      await conserver(v1);
      await service().synchroniser('gr-test', 'https://double/v1.json',
          niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion, empreinteAttendue: v1.hash);

      // LE REPERE EST CELUI DU SERVEUR, A LA MILLISECONDE. Pas l heure de
      // l appareil, et pas non plus « quelque part entre les deux ».
      final repere = (await manifestes.getByTrailId('gr-test'))!.localVersion;
      expect(repere, instantServeur());
      expect(repere!.millisecondesEpoch,
          lessThan(
              HorodatageServeur.annonceParLeServeur(
                      horlogeDeLAppareil.toIso8601String())!
                  .millisecondesEpoch),
          reason: 'le repere est en ARRIERE de l horloge de l appareil : c est le '
              'sens qui se repare (on relit), l autre est definitif (on saute)');

      // ET LA PREUVE QUI COMPTE : une donnee publiee 30 MINUTES APRES, donc
      // encore DANS l heure d avance du telephone, DESCEND QUAND MEME.
      final v2 = deposer(
        'v2.json',
        donnees(
            instant: instantServeur(const Duration(minutes: 30)),
            elevationGain: 915),
        instantAnnonce: instantServeur(const Duration(minutes: 30)),
      );
      await conserver(v2);
      final bilan = await service().synchroniser(
        'gr-test',
        'https://double/v2.json',
        niveau: NiveauDeTelechargement.realiser, revisionCible: v2.dataVersion,
        empreinteAttendue: v2.hash,
      );

      expect(bilan.ecrits, greaterThan(0),
          reason: 'AVEC UN REPERE PRIS SUR L HORLOGE DE L APPAREIL, ce chiffre '
              'vaudrait ZERO : 06:30 est anterieur a 07:00, donc rien ne serait '
              'juge « plus recent ». La donnee serait perdue pour toujours.');
      expect(
        (await TrailStagesDao(db).getByItineraryId('test-i1'))
            .single
            .elevationGain,
        915,
        reason: 'la correction est bien arrivee sur le telephone',
      );
      expect((await manifestes.getByTrailId('gr-test'))!.localVersion,
          instantServeur(const Duration(minutes: 30)));
    });

    test('AUCUN FICHIER DE `lib/` NE POSE D HORODATAGE — la garde est '
        'structurelle, pas une consigne', () {
      // `HorodatageServeur.poseeParLeServeur` est le SEUL point d entree qui
      // transforme une horloge en horodatage, et il est reserve a l outil de
      // publication, qui EST l autorite de temps. Si un fichier de
      // l application l appelait, le modele entier se remettrait a dependre de
      // l horloge d un appareil. Un type interdit l accident ; ce test interdit
      // l intention.
      final coupables = <String>[];
      for (final fichier in Directory('lib').listSync(recursive: true)) {
        if (fichier is! File || !fichier.path.endsWith('.dart')) continue;
        // Le fichier qui DECLARE le point d entree n est pas un appelant. C est la
        // seule exception, et elle est nommee ici plutot que dans un commentaire
        // que personne ne relit.
        if (fichier.path.endsWith('revision_de_donnee.dart')) continue;
        final texte = fichier.readAsStringSync();
        if (texte.contains('poseeParLeServeur')) {
          coupables.add(fichier.path);
        }
      }
      expect(coupables, isEmpty,
          reason: 'l application ne pose JAMAIS d horodatage : elle LIT celui '
              'que le serveur annonce. Seul `tool/publication/` a le droit de '
              'poser, parce qu il est le serveur.');
    });

    test('une date sans fuseau est lue en UTC, jamais en heure de l appareil',
        () {
      // Le meme fichier publie doit donner le MEME repere a Paris et a Tokyo.
      // `DateTime.parse` rendrait un instant LOCAL sur une ecriture sans `Z`.
      expect(
        HorodatageServeur.annonceParLeServeur('2026-09-28T06:00:00.000'),
        HorodatageServeur.annonceParLeServeur('2026-09-28T06:00:00.000Z'),
      );
      // Un decalage explicite, lui, est respecte.
      expect(
        HorodatageServeur.annonceParLeServeur('2026-09-28T08:00:00.000+02:00'),
        HorodatageServeur.annonceParLeServeur('2026-09-28T06:00:00.000Z'),
      );
    });

    test('la precision est la MILLISECONDE : deux publications dans la meme '
        'seconde restent distinctes', () {
      // LA SECONDE AURAIT ETE TROP GROSSIERE, et ce n est pas theorique : la
      // meteo et le risque incendie ecriront en rafale. Avec une comparaison
      // stricte, deux enregistrements indiscernables font rater le second POUR
      // TOUJOURS.
      final a = HorodatageServeur.annonceParLeServeur('2026-09-28T06:00:00.100Z')!;
      final b = HorodatageServeur.annonceParLeServeur('2026-09-28T06:00:00.900Z')!;
      expect(b > a, isTrue);
      expect(a.iso8601, '2026-09-28T06:00:00.100Z');
    });
  });

  // =========================================================================
  // 2. LA BORNE, PAS LE MAXIMUM RECU
  // =========================================================================
  group('610 — le repere est la BORNE ANNONCEE, pas le maximum recu', () {
    test('LE TELEPHONE RETIENT CE QUE LA LISTE ANNONCE, MEME QUAND C EST PLUS '
        'RECENT QUE TOUT CE QU IL A RECU', () async {
      // POURQUOI CE N EST PAS UN DETAIL (conception 611 d Athena, #100738). Une
      // collecte ecrit ses enregistrements un par un. Un telephone qui
      // interroge au milieu recoit les premiers ; s il retient LE MAXIMUM DE CE
      // QU IL A RECU, les suivants portent une date inferieure a son repere et
      // NE REDESCENDRONT JAMAIS. La borne, elle, vaut « avant cet instant, plus
      // rien ne sera ecrit » : le telephone relit au pire quelques
      // enregistrements qu il a deja (l ecriture est idempotente, c est gratuit)
      // au lieu d en sauter definitivement. RELIRE EST GRATUIT, SAUTER EST
      // DEFINITIF.
      final borne = instantServeur(const Duration(hours: 1));
      final v1 = deposer(
        'v1.json',
        donnees(instant: instantServeur()), // enregistrements a 06:00
        instantAnnonce: borne, // la liste annonce 07:00
      );
      await conserver(v1);

      await service().synchroniser('gr-test', 'https://double/v1.json',
          niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion, empreinteAttendue: v1.hash);

      expect((await manifestes.getByTrailId('gr-test'))!.localVersion, borne,
          reason: 'le repere est la BORNE (07:00), pas le maximum des '
              'enregistrements recus (06:00)');
    });

    test('un enregistrement plus recent que le repere descend, un plus ancien '
        'ne descend pas — et la borne stricte est verifiee', () async {
      final v1 = deposer('v1.json', donnees(instant: instantServeur()),
          instantAnnonce: instantServeur());
      await conserver(v1);
      await service().synchroniser('gr-test', 'https://double/v1.json',
          niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion, empreinteAttendue: v1.hash);

      // Republication a la MEME date : rien n est « plus recent », rien ne bouge.
      final memeInstant = deposer(
        'meme.json',
        donnees(instant: instantServeur(), elevationGain: 999),
        instantAnnonce: instantServeur(),
      );
      await conserver(memeInstant);
      final rien = await service().synchroniser(
        'gr-test',
        'https://double/meme.json',
        niveau: NiveauDeTelechargement.realiser, revisionCible: memeInstant.dataVersion,
        empreinteAttendue: memeInstant.hash,
      );
      expect(rien.rienAFaire, isTrue,
          reason: 'la comparaison est STRICTE : « plus recent », pas « au moins '
              'aussi recent »');
      expect(
        (await TrailStagesDao(db).getByItineraryId('test-i1'))
            .single
            .elevationGain,
        800,
      );
    });
  });

  // =========================================================================
  // 3. LE MOT « COMPLET » DE CHRISTOPHE
  // =========================================================================
  group('610 — le repere n avance QUE si TOUT a ete recu', () {
    test('COUPURE EN PLEIN MILIEU : la sixieme famille echoue, les precedentes '
        'sont ANNULEES, et le repere ne bouge pas', () async {
      // La premiere copie reussit : le telephone a un sentier et un repere.
      final v1 = deposer('v1.json', donnees(instant: instantServeur()),
          instantAnnonce: instantServeur());
      await conserver(v1);
      await service().synchroniser('gr-test', 'https://double/v1.json',
          niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion, empreinteAttendue: v1.hash);
      expect(await TrailPoisDao(db).getByStageId('test-s1'), hasLength(1));

      // La seconde est ABIMEE AU MILIEU : `itineraries` passe, `stages` leve. La
      // transaction est deja ouverte et a deja ecrit la fiche et l itineraire.
      final v2 = deposer(
        'v2.json',
        donnees(
          instant: instantServeur(const Duration(hours: 1)),
          etapeAbimee: true,
        ),
        instantAnnonce: instantServeur(const Duration(hours: 1)),
      );
      await conserver(v2);

      await expectLater(
        service().synchroniser('gr-test', 'https://double/v2.json',
            niveau: NiveauDeTelechargement.realiser, revisionCible: v2.dataVersion, empreinteAttendue: v2.hash),
        throwsA(anything),
        reason: 'un echec de pose doit se DIRE : rendre un bilan vide se '
            'confondrait avec « deja a jour »',
      );

      expect((await manifestes.getByTrailId('gr-test'))!.localVersion,
          instantServeur(),
          reason: 'LE MOT « COMPLET » DE CHRISTOPHE : le repere n avance QUE si '
              'TOUT a ete recu. Un telephone coupe au milieu qui se croirait a '
              'jour ne redemanderait plus jamais ce qui manque.');
      expect(
        (await TrailStagesDao(db).getByItineraryId('test-i1'))
            .single
            .elevationGain,
        800,
        reason: 'retour arriere complet : l etape de la copie precedente est '
            'intacte, la transaction n a rien laisse a moitie',
      );
    });

    test('LE REPERE EST DANS LA MEME TRANSACTION QUE LES DONNEES : sans ligne '
        'de liste locale, la copie ENTIERE est annulee (#X10)', () async {
      // LE FAUX SUCCES QUE CECI FERME, LAISSE OUVERT PAR LA TACHE 607.
      // `inscrireRevision` est un `UPDATE` : sans ligne de liste locale il ne
      // touchait AUCUNE ligne et rendait 0 EN SILENCE. La copie etait annoncee
      // reussie, le repere n existait pas, et le telephone retelechargeait tout
      // le sentier a chaque ouverture — sans que rien ne le dise. Le mot
      // « complet » de Christophe interdit ce cas : il leve, donc la copie
      // entiere est annulee et le sentier reste honnetement « a prendre ».
      final v1 = deposer('v1.json', donnees(instant: instantServeur()),
          instantAnnonce: instantServeur());
      // On NE conserve PAS l entree : pas de ligne dans `trail_manifests`.

      await expectLater(
        service().synchroniser('gr-test', 'https://double/v1.json',
            niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion, empreinteAttendue: v1.hash),
        throwsA(isA<RepereNonInscriptible>()),
      );

      expect(await TrailStagesDao(db).getByItineraryId('test-i1'), isEmpty,
          reason: 'la transaction a tout annule : pas de sentier pose sans son '
              'repere');
      expect(await manifestes.getByTrailId('gr-test'), isNull);
    });
  });
}

class _FauxReseau extends ConnectivityMonitor {
  _FauxReseau(this._etat);
  final ConnectivityStatus _etat;
  @override
  Future<ConnectivityStatus> checkStatus() async => _etat;
}
