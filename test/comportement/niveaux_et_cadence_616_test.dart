import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/ordonnanceur_de_synchronisation.dart';
import 'package:moteur_gr/core/services/trail_record_source.dart';
import 'package:moteur_gr/core/services/update_checker.dart';
import 'package:moteur_gr/core/services/update_downloader.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';

import '../../tool/publication/publicateur.dart';

/// TACHE 616 — LES TROIS NIVEAUX DE TELECHARGEMENT, ET LA CADENCE QUI N EXISTAIT
/// PAS.
///
/// DEUX DEMANDES DE CHRISTOPHE, VERBATIM.
///
///  * 28/09 11:27 : « Attention de ne pas telecharger les donnees inutiles quand
///    on prepare avec pub et quand on prepare en ayant achete le sentier ».
///  * 28/09 09:32 : « quand l appli recupere du reseau (et ensuite toutes les 4
///    heures par exemple) elle vient verifier toutes les donnees superieures a sa
///    date de MAJ ».
///
/// CE FICHIER COMPTE, IL NE DECRIT PAS. C est la consigne du lot, et elle vient de
/// ce que la tache 606 a prouve en comptant qu UN enregistrement transitait la ou
/// le journal en annoncait dix. Un niveau qui descend plus que son perimetre doit
/// donc etre un test ROUGE, pas un commentaire prudent. Le sentier de reference
/// est `gr-monts-dore`, publie par l outil de la tache 607, et ses effectifs sont
/// connus a l unite :
///
///   trail_meta 1 · itineraries 1 · stages 2 · accommodations 2 · pois 2
///   gpx_tracks 1 · gpx_points 10
///
/// soit REGARDER = 0, PREPARER = 8, REALISER = 19. Ces trois nombres sont
/// affirmes tels quels ci-dessous.
///
/// POURQUOI LE VOLUME COMPTE, ET LES DEUX MESURES SONT DEJA GRAVEES. Le chiffrage
/// de la tache 608 : les tuiles pesent 260 Mo en z10-16. La mesure de la tache
/// 615 : lire une trace de 10 000 points prend 18,6 ms sur le fil d affichage,
/// 49,9 ms a 20 000. Faire descendre le volumineux a quelqu un qui regarde si le
/// sentier lui plait, c est payer du transport pour rien, remplir son telephone et
/// ralentir son ecran.
///
/// LA NUANCE QU IL NE FAUT PAS PERDRE : « preparer avec la publicite » et
/// « preparer apres avoir achete » demandent EXACTEMENT les memes donnees. Ce qui
/// change entre les deux est la publicite et le DROIT de realiser, pas le volume.
/// Il n y a donc pas quatre niveaux, et aucun test ci-dessous ne consulte l achat
/// pour decider ce qui descend.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory bac;
  late String source;
  late String publie;
  late AppDatabase db;
  late TrailManifestsDao manifestes;

  /// Nombre de requetes servies sur le FICHIER DE DONNEES du sentier.
  ///
  /// La liste (`manifest.json`) n est pas comptee : elle descend de toute facon
  /// pour peupler le catalogue, c est le niveau REGARDER lui-meme. Ce qui est
  /// mesure ici, c est le transport des DONNEES.
  late List<String> requetesDonnees;

  setUp(() {
    bac = Directory.systemTemp.createTempSync('niveaux616');
    source = '${bac.path.replaceAll(r'\', '/')}/source';
    publie = '${bac.path.replaceAll(r'\', '/')}/publie';
    Directory(source).createSync(recursive: true);
    for (final nom in const ['sentier.json', 'trace.gpx']) {
      File(
        'test/fixtures/publication/gr-monts-dore/$nom',
      ).copySync('$source/$nom');
    }
    db = AppDatabase(NativeDatabase.memory());
    manifestes = TrailManifestsDao(db);
    requetesDonnees = [];
  });

  tearDown(() async {
    await db.close();
    bac.deleteSync(recursive: true);
  });

  // Chaque publication a son instant, FIXE : jamais `DateTime.now()`, qui ferait
  // dependre le test du jour ou il tourne (regle du lot 610).
  DateTime horlogeAuJour(int jour) =>
      DateTime.utc(2026, 9, 28).add(Duration(days: jour - 1));

  HorodatageServeur instantAuJour(int jour) =>
      HorodatageServeur.annonceParLeServeur(
        horlogeAuJour(jour).toIso8601String(),
      )!;

  ManifestService listeService({
    ConnectivityStatus? statut,
    MockClient? client,
  }) => ManifestService(
    dao: manifestes,
    connectivityMonitor: _ReseauPilotable(
      statut ?? ConnectivityStatusValues.online,
    ),
    httpClient: client,
  );

  /// Publie l etat courant de la source et conserve son entree en base.
  Future<TrailManifestEntry> publier({int jour = 1}) async {
    Publicateur(sortie: publie, horloge: horlogeAuJour(jour)).publier(source);
    final brut =
        jsonDecode(
              File('$publie/${Publicateur.nomDeLaListe}').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final entree = TrailManifest.fromJson(
      brut,
    ).trails.firstWhere((e) => e.trailId == 'gr-monts-dore');
    await listeService().saveLocalManifest(entree);
    return entree;
  }

  /// Le double sert les OCTETS REELLEMENT PRODUITS par l outil.
  MockClient stockage() {
    return MockClient((requete) async {
      final url = requete.url.toString();
      for (final fichier in _fichiersDe(publie)) {
        final chemin = fichier.substring(publie.length + 1);
        if (!url.contains(Uri.encodeComponent(chemin)) &&
            !url.contains(chemin)) {
          continue;
        }
        if (chemin != Publicateur.nomDeLaListe) requetesDonnees.add(chemin);
        return http.Response.bytes(
          File(fichier).readAsBytesSync(),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('non trouve', 404);
    });
  }

  DeltaUpdateService service({TrailRecordSource? avecSource}) =>
      DeltaUpdateService(
        db: db,
        manifestService: listeService(),
        trailManifestsDao: manifestes,
        trailMetaDao: TrailMetaDao(db),
        trailItinerariesDao: TrailItinerariesDao(db),
        trailStagesDao: TrailStagesDao(db),
        trailAccommodationsDao: TrailAccommodationsDao(db),
        trailPoisDao: TrailPoisDao(db),
        trailGpxTracksDao: TrailGpxTracksDao(db),
        trailGpxPointsDao: TrailGpxPointsDao(db),
        source: avecSource,
        httpClient: stockage(),
      );

  /// COMBIEN D ENREGISTREMENTS CHAQUE FAMILLE PORTE EN BASE, pour ce sentier.
  ///
  /// Le comptage passe par les etapes REELLEMENT posees, il ne suppose pas
  /// laquelle porte quel hebergement : un test qui devine les identifiants de sa
  /// fixture casse des qu on enrichit la fixture, et pour une raison qui n a rien
  /// a voir avec ce qu il verifie.
  Future<Map<String, int>> enBase() async {
    final stages = <String>[];
    for (final itineraire in await TrailItinerariesDao(
      db,
    ).getByTrailId('gr-monts-dore')) {
      stages.addAll(
        (await TrailStagesDao(
          db,
        ).getByItineraryId(itineraire.id)).map((e) => e.id),
      );
    }
    var hebergements = 0;
    var pointsDInteret = 0;
    for (final etape in stages) {
      hebergements += (await TrailAccommodationsDao(
        db,
      ).getByStageId(etape)).length;
      pointsDInteret += (await TrailPoisDao(db).getByStageId(etape)).length;
    }
    return {
      TrailChunks.fiche: await TrailMetaDao(db).getById('gr-monts-dore') == null
          ? 0
          : 1,
      TrailChunks.itineraires: (await TrailItinerariesDao(
        db,
      ).getByTrailId('gr-monts-dore')).length,
      TrailChunks.stages: stages.length,
      TrailChunks.hebergements: hebergements,
      TrailChunks.pointsDInteret: pointsDInteret,
      TrailChunks.traces: (await TrailGpxTracksDao(db).getAll()).length,
      TrailChunks.pointsDeTrace: (await TrailGpxPointsDao(db).getAll()).length,
    };
  }

  /// MODIFIE LA SOURCE, pour qu une republication porte VRAIMENT un nouvel
  /// instant.
  ///
  /// Republier une source inchangee conserve la revision de chaque donnee — c est
  /// le comportement que la tache 607 a verrouille et qu il ne faut pas confondre
  /// avec un defaut. Pour eprouver la cadence il faut donc un changement REEL.
  void corrigerUneAltitude(int nouvelle) {
    final fichier = File('$source/sentier.json');
    final contenu =
        jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
    (contenu['stages'] as List).first as Map<String, dynamic>;
    ((contenu['stages'] as List).first
            as Map<String, dynamic>)['elevation_gain'] =
        nouvelle;
    fichier.writeAsStringSync(jsonEncode(contenu));
  }

  ProviderContainer conteneur() {
    final reseau = _ReseauPilotable(ConnectivityStatusValues.online);
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        connectivityMonitorProvider.overrideWithValue(reseau),
        manifestServiceProvider.overrideWithValue(
          listeService(client: stockage()),
        ),
        deltaUpdateServiceProvider.overrideWith((ref) => service()),
      ],
    );
  }

  // =========================================================================
  // 1. LES TROIS NIVEAUX, COMPTES A L UNITE
  // =========================================================================
  group('616 — LES TROIS NIVEAUX : ce qui descend est COMPTE', () {
    test('REGARDER ne descend RIEN : zero enregistrement, zero octet, et AUCUNE '
        'requete sur le fichier de donnees', () async {
      final entree = await publier();

      final bilan = await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        revisionCible: entree.dataVersion,
        empreinteAttendue: entree.hash,
        niveau: NiveauDeTelechargement.regarder,
      );

      // LE COMPTE, PAS L INTENTION.
      expect(bilan.ecrits, 0);
      expect(bilan.retenus, 0);
      expect(bilan.transferes, 0);
      expect(bilan.octetsRecus, 0);
      expect(bilan.aucunTransport, isTrue);
      expect(bilan.famillesTouchees, isEmpty);

      // ET SURTOUT : LE RESEAU N A PAS ETE TOUCHE. C est la reponse exacte a
      // Christophe — la fiche du catalogue est deja arrivee avec la liste, il n y
      // a rien de plus a chercher pour decider si un sentier plait.
      expect(
        requetesDonnees,
        isEmpty,
        reason:
            'regarder un sentier au catalogue ne doit ouvrir AUCUNE '
            'connexion vers son fichier de donnees',
      );

      expect(await enBase(), {for (final f in TrailChunks.tous) f: 0});

      // LE REPERE N EST PAS POSE : le sentier n est pas « telecharge ».
      expect(
        (await manifestes.getByTrailId('gr-monts-dore'))!.localVersion,
        isNull,
      );
      expect(
        await manifestes.getTelecharges(),
        isEmpty,
        reason:
            'un sentier qu on a seulement regarde ne doit pas entrer dans '
            'le perimetre de la cadence : il n y a rien a y maintenir a jour',
      );
    });

    test('PREPARER descend les CINQ familles de la faisabilite et du sac — '
        '8 enregistrements — et PAS UN SEUL point de trace', () async {
      final entree = await publier();

      final bilan = await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        revisionCible: entree.dataVersion,
        empreinteAttendue: entree.hash,
        niveau: NiveauDeTelechargement.preparer,
      );

      expect(
        bilan.ecrits,
        8,
        reason:
            '1 fiche + 1 itineraire + 2 etapes + 2 hebergements + 2 points '
            'd interet',
      );
      expect(bilan.retenus, 8);
      expect(bilan.famillesTouchees, const [
        'trail_meta',
        'itineraries',
        'stages',
        'accommodations',
        'pois',
      ]);
      expect(bilan.niveauAtteint, NiveauDeTelechargement.preparer);

      // LE VOLUMINEUX N EST PAS EN BASE. Le test serait ROUGE si une seule ligne
      // de trace y etait, et c est le point du lot.
      expect(await enBase(), {
        'trail_meta': 1,
        'itineraries': 1,
        'stages': 2,
        'accommodations': 2,
        'pois': 2,
        'gpx_tracks': 0,
        'gpx_points': 0,
      });

      // ET LE COUT DU TRANSPORT ACTUEL EST DIT, PAS MASQUE. Sur une source de
      // FICHIER le fichier descend en entier : les 11 enregistrements de trace
      // ont traverse le reseau et sont ecartes a la porte. Le chiffre reste
      // visible parce qu il est genant — c est lui qui dit que l economie de
      // transport n arrivera qu avec une source interrogeable.
      expect(
        bilan.ecartesHorsNiveau,
        11,
        reason:
            '1 entete de trace + 10 points : descendus par le transport '
            'global, jamais ecrits',
      );
      expect(bilan.transferes, 19);
      expect(bilan.transferesEnTrop, 11);
    });

    test(
      'REALISER descend TOUT : 19 enregistrements, les sept familles',
      () async {
        final entree = await publier();

        final bilan = await service().synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
          niveau: NiveauDeTelechargement.realiser,
        );

        expect(bilan.ecrits, 19);
        expect(bilan.retenus, 19);
        expect(
          bilan.ecartesHorsNiveau,
          0,
          reason: 'a ce niveau rien n est hors perimetre',
        );
        expect(bilan.famillesTouchees, TrailChunks.tous);
        expect(bilan.niveauAtteint, NiveauDeTelechargement.realiser);

        expect(await enBase(), {
          'trail_meta': 1,
          'itineraries': 1,
          'stages': 2,
          'accommodations': 2,
          'pois': 2,
          'gpx_tracks': 1,
          'gpx_points': 10,
        });
      },
    );

    test(
      'LE PERIMETRE DE CHAQUE NIVEAU EST EMBOITE, et le volumineux est nomme '
      'une seule fois',
      () {
        expect(NiveauDeTelechargement.regarder.familles, isEmpty);
        expect(NiveauDeTelechargement.preparer.familles, hasLength(5));
        expect(NiveauDeTelechargement.realiser.familles, TrailChunks.tous);

        // EMBOITEMENT : c est ce qui rend « faut-il completer ? » decidable.
        for (final bas in NiveauDeTelechargement.values) {
          for (final haut in NiveauDeTelechargement.values) {
            if (!haut.couvre(bas)) continue;
            expect(
              haut.familles,
              containsAll(bas.familles),
              reason: '${haut.code} doit porter tout ce que porte ${bas.code}',
            );
          }
        }

        // LA FRONTIERE DE VOLUME EST EXACTEMENT LA TRACE ET SES POINTS.
        expect(
          NiveauDeTelechargement.realiser.familles.where(
            (f) => !NiveauDeTelechargement.preparer.carries(f),
          ),
          NiveauDeTelechargement.volumineux,
        );
        expect(NiveauDeTelechargement.volumineux, const [
          'gpx_tracks',
          'gpx_points',
        ]);

        // L ORDRE DES CLES ETRANGERES EST PRESERVE PAR CHAQUE NIVEAU : un
        // hebergement pose avant son etape echouerait.
        for (final niveau in NiveauDeTelechargement.values) {
          expect(
            niveau.familles,
            TrailChunks.tous.where(niveau.carries).toList(),
            reason:
                '${niveau.code} doit suivre l ordre d insertion, pas un autre',
          );
        }
      },
    );

    test(
      'LE CODE PERSISTE SURVIT A UN RENOMMAGE, et une valeur illisible retombe '
      'au niveau le PLUS BAS',
      () {
        for (final niveau in NiveauDeTelechargement.values) {
          expect(NiveauDeTelechargement.depuisLeCode(niveau.code), niveau);
        }
        expect(NiveauDeTelechargement.depuisLeCode(null), isNull);
        expect(
          NiveauDeTelechargement.depuisLeCode('niveau-d-une-version-future'),
          isNull,
          reason:
              'ne pas savoir doit faire RECOPIER, jamais faire croire '
              'complet : l appelant replie sur « regarder »',
        );
      },
    );
  });

  // =========================================================================
  // 2. LE PIEGE : UN NIVEAU QUI MONTE
  // =========================================================================
  group('616 — LE PIEGE DU NIVEAU QUI MONTE, silencieux et definitif', () {
    test(
      'PREPARER PUIS REALISER A LA MEME PUBLICATION : la trace ARRIVE — sans '
      'cette garde le randonneur partait sans trace en croyant avoir tout',
      () async {
        final entree = await publier();

        // 1. Il prepare. Le repere est pose a l instant de publication.
        await service().synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
          niveau: NiveauDeTelechargement.preparer,
        );
        expect((await enBase())['gpx_points'], 0);
        expect(
          await manifestes.niveauDe('gr-monts-dore'),
          NiveauDeTelechargement.preparer,
        );

        // 2. Il decide de partir. LE SERVEUR N A RIEN PUBLIE ENTRE-TEMPS : la date
        // distante est identique a son repere. Toute la regle de revision dit donc
        // « tu es a jour » — et les points de trace, dates du jour 1, seraient
        // refuses un a un, en silence, pour toujours.
        final bilan = await service().synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
          niveau: NiveauDeTelechargement.realiser,
        );

        expect(
          bilan.ecrits,
          19,
          reason:
              'la montee de niveau repart de l origine : tout est repose au '
              'nouveau niveau, dans la meme transaction',
        );
        expect(
          (await enBase())['gpx_points'],
          10,
          reason:
              'C EST LE DEFAUT QUE CE LOT FERME. Sans la colonne de niveau, '
              'ce compte resterait a zero et rien ne le dirait jamais.',
        );
        expect((await enBase())['gpx_tracks'], 1);
        expect(
          await manifestes.niveauDe('gr-monts-dore'),
          NiveauDeTelechargement.realiser,
        );
      },
    );

    test(
      'UN NIVEAU QUI BAISSE NE RETIRE RIEN : liberer de la place est un AUTRE '
      'geste',
      () async {
        final entree = await publier();

        await service().synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
          niveau: NiveauDeTelechargement.realiser,
        );
        expect((await enBase())['gpx_points'], 10);

        // Une demande a un niveau INFERIEUR ne doit pas effacer la trace du
        // randonneur qui part demain.
        await service().synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
          niveau: NiveauDeTelechargement.preparer,
        );

        expect((await enBase())['gpx_points'], 10);
        expect(
          await manifestes.niveauDe('gr-monts-dore'),
          NiveauDeTelechargement.realiser,
          reason:
              'le niveau inscrit est le PLUS HAUT atteint, pas le dernier '
              'demande',
        );
      },
    );

    test(
      'LE NIVEAU EST OUBLIE AVEC LE REPERE quand le sentier est supprime',
      () async {
        final entree = await publier();
        await service().synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
          niveau: NiveauDeTelechargement.realiser,
        );

        await manifestes.oublierRevision('gr-monts-dore');

        expect(
          await manifestes.niveauDe('gr-monts-dore'),
          isNull,
          reason:
              'un niveau qui survivrait a la suppression dirait « realiser » '
              'sur un sentier vide, et la reprise croirait n avoir qu une mise a '
              'jour a faire',
        );
        expect(await manifestes.getTelecharges(), isEmpty);
      },
    );

    test(
      'LE NIVEAU SURVIT A UN RAFRAICHISSEMENT DU CATALOGUE, comme le repere',
      () async {
        final entree = await publier();
        await service().synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
          niveau: NiveauDeTelechargement.preparer,
        );

        // La lecture du catalogue reecrit la ligne de liste a chaque passage.
        await listeService().saveLocalManifest(entree);

        expect(
          await manifestes.niveauDe('gr-monts-dore'),
          NiveauDeTelechargement.preparer,
          reason:
              'un niveau efface a chaque rafraichissement du catalogue '
              'ferait recopier le sentier entier a chaque ouverture',
        );
      },
    );
  });

  // =========================================================================
  // 3. LA CADENCE — ELLE N EXISTAIT PAS
  // =========================================================================
  group('616 — LA CADENCE : au retour du reseau, puis toutes les quatre heures', () {
    /// Un ordonnanceur cable sur la vraie chaine, avec une horloge PILOTEE.
    ///
    /// LA CADENCE REELLE EST DE QUATRE HEURES et elle vit dans
    /// `OrdonnanceurDeSynchronisation.cadenceParDefaut`. Ce qui est eprouve ici,
    /// c est la MECANIQUE : le declenchement periodique, le declenchement sur
    /// retour de reseau, le perimetre et le niveau.
    ///
    /// L HORLOGE EST INJECTEE, ET VOICI CE QUE CA REPARE (tache 695, kaizen
    /// #101267). Ces tests laissaient battre une VRAIE horloge de 25 ms, puis
    /// dormaient un budget en temps reel avant d affirmer qu une passe avait eu
    /// lieu. MESURE DU 05/10, pendant le build 10 :
    /// `expect(avant, greaterThanOrEqualTo(1))` a rendu `Actual: <0>` — au bout
    /// de 80 ms de sommeil, le minuteur de 25 ms n avait pas encore FINI une
    /// seule passe, parce que la machine etait occupee. Le test mesurait la
    /// vitesse de la machine de fabrication, pas le reveil de la
    /// synchronisation : rouge environ une fois sur trois. Avec une horloge que
    /// le test fait battre, chaque compte est EXACT et aucun verdict ne depend
    /// plus de la charge.
    ({
      OrdonnanceurDeSynchronisation ordonnanceur,
      _ReseauPilotable reseau,
      _CheckerTropLarge checker,
      _HorlogePilotable horloge,
    })
    monter({Duration cadence = const Duration(hours: 4)}) {
      final reseau = _ReseauPilotable(ConnectivityStatusValues.online);
      final checker = _CheckerTropLarge(
        dao: manifestes,
        connectivityMonitor: reseau,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
      );
      final downloader = UpdateDownloader(
        updateChecker: checker,
        deltaUpdateService: service(),
        manifestService: listeService(client: stockage()),
        dao: manifestes,
        connectivityMonitor: reseau,
        dataBaseUrl: 'https://double',
      );
      final horloge = _HorlogePilotable();
      return (
        ordonnanceur: OrdonnanceurDeSynchronisation(
          downloader: downloader,
          dao: manifestes,
          connectivityMonitor: reseau,
          urlManifeste: 'https://double/${Publicateur.nomDeLaListe}',
          cadence: cadence,
          poserLHorloge: horloge.poser,
        ),
        reseau: reseau,
        checker: checker,
        horloge: horloge,
      );
    }

    /// Le meme montage, mais avec la VRAIE horloge de production.
    ///
    /// Sert a une seule chose, et elle est indispensable : prouver que le point
    /// d injection n a pas debranche la cadence reelle.
    ({OrdonnanceurDeSynchronisation ordonnanceur, _ReseauPilotable reseau})
    monterSurLHorlogeReelle({required Duration cadence}) {
      final reseau = _ReseauPilotable(ConnectivityStatusValues.online);
      final downloader = UpdateDownloader(
        updateChecker: _CheckerTropLarge(
          dao: manifestes,
          connectivityMonitor: reseau,
          firebaseService: FirebaseService.testOnly(isAvailable: true),
        ),
        deltaUpdateService: service(),
        manifestService: listeService(client: stockage()),
        dao: manifestes,
        connectivityMonitor: reseau,
        dataBaseUrl: 'https://double',
      );
      return (
        ordonnanceur: OrdonnanceurDeSynchronisation(
          downloader: downloader,
          dao: manifestes,
          connectivityMonitor: reseau,
          urlManifeste: 'https://double/${Publicateur.nomDeLaListe}',
          cadence: cadence,
        ),
        reseau: reseau,
      );
    }

    test(
      'LA CADENCE BAT : chaque battement de l horloge part en passe — et AVANT '
      'CE LOT rien ne reveillait la synchronisation',
      () async {
        await publier();
        final m = monter(cadence: const Duration(hours: 4));
        addTearDown(m.ordonnanceur.stop);

        expect(
          m.ordonnanceur.passesExecutees,
          0,
          reason:
              'l ordonnanceur ne synchronise PAS au demarrage : le premier '
              'ecran ne doit pas attendre le reseau',
        );
        expect(
          m.horloge.posee,
          isFalse,
          reason: 'aucune horloge ne doit etre armee avant start()',
        );

        m.ordonnanceur.start();
        expect(m.ordonnanceur.demarre, isTrue);
        expect(
          m.horloge.cadence,
          const Duration(hours: 4),
          reason:
              'L HORLOGE EST ARMEE SUR LA CADENCE DEMANDEE, et c est un compte '
              'exact que l ancienne version ne pouvait pas faire : elle '
              'dormait et deduisait',
        );
        expect(
          m.ordonnanceur.passesExecutees,
          0,
          reason: 'armer l horloge ne declenche aucune passe',
        );

        // ON ATTEND LA PASSE **FINIE**, PAS SEULEMENT COMPTEE, et ce detail est
        // le defaut de cette famille de tests. `_passesExecutees++` se fait
        // AVANT le transport : le compteur passe a 1 alors que la passe tourne
        // encore. Enchainer un second battement a cet instant-la, c est tomber
        // sur le verrou « une seule passe a la fois » — le battement est alors
        // legitimement IGNORE, et le test attendrait un 2 qui ne viendra jamais.
        await m.horloge.battre();
        await jusqua(
          () => m.ordonnanceur.passesExecutees == 1 && !m.ordonnanceur.enCours,
          quoi: 'la premiere passe de la cadence, FINIE',
        );
        expect(
          m.ordonnanceur.passesExecutees,
          1,
          reason:
              'la mecanique existait depuis E4.11c et AUCUN code de '
              'production ne l appelait — c est ce lot qui la reveille',
        );

        // ET ELLE EST PERIODIQUE, PAS A UN COUP : le second battement repart.
        await m.horloge.battre();
        await jusqua(
          () => m.ordonnanceur.passesExecutees == 2 && !m.ordonnanceur.enCours,
          quoi: 'la seconde passe de la cadence, FINIE',
        );
        expect(m.ordonnanceur.passesExecutees, 2);
      },
    );

    test(
      'L HORLOGE PAR DEFAUT EST UNE VRAIE HORLOGE : la cadence de production '
      'bat pour de bon',
      () async {
        await publier();
        // CE TEST EST LE SEUL QUI LAISSE BATTRE LE TEMPS REEL, et il ne PARIE
        // sur aucun budget : il attend L EVENEMENT. Sans lui, le point
        // d injection pourrait debrancher la cadence de production sans qu un
        // seul test rougisse.
        final m = monterSurLHorlogeReelle(
          cadence: const Duration(milliseconds: 25),
        );
        addTearDown(m.ordonnanceur.stop);

        m.ordonnanceur.start();
        await jusqua(
          () => m.ordonnanceur.passesExecutees >= 1,
          quoi:
              'une passe declenchee par la VRAIE Timer.periodic (defaut de '
              'poserLHorloge). Jamais atteinte = la cadence de production '
              'n est plus branchee sur une horloge.',
        );
        expect(m.ordonnanceur.passesExecutees, greaterThanOrEqualTo(1));
      },
    );

    test(
      'LE RETOUR DU RESEAU DECLENCHE UNE PASSE, et le passage HORS ligne n en '
      'declenche aucune',
      () async {
        await publier();
        // Cadence lointaine ET horloge pilotee : seul l evenement declenche.
        final m = monter(cadence: const Duration(hours: 4));
        addTearDown(m.ordonnanceur.stop);
        m.ordonnanceur.start();

        m.reseau.emettre(ConnectivityStatusValues.offline);
        await vider();
        expect(
          m.ordonnanceur.passesExecutees,
          0,
          reason:
              'perdre le reseau est l evenement INVERSE : declencher la ne '
              'produirait qu un echec de transport et un journal trompeur',
        );
        expect(
          m.ordonnanceur.enCours,
          isFalse,
          reason:
              'une passe EN VOL compterait plus tard : le compte de zero ne '
              'vaut que si rien ne tourne',
        );

        m.reseau.emettre(ConnectivityStatusValues.online);
        await jusqua(
          () => m.ordonnanceur.passesExecutees == 1 && !m.ordonnanceur.enCours,
          quoi: 'la passe du retour de reseau, FINIE',
        );
        expect(
          m.ordonnanceur.passesExecutees,
          1,
          reason:
              'un randonneur qui redescend d un col retrouve la 4G et doit '
              'recevoir ce qui a ete publie pendant qu il marchait',
        );
      },
    );

    test(
      'HORS LIGNE, AUCUNE PASSE NE PART, meme si l horloge echoit',
      () async {
        await publier();
        final m = monter();
        addTearDown(m.ordonnanceur.stop);
        m.reseau.statut = ConnectivityStatusValues.offline;
        m.ordonnanceur.start();

        // TROIS BATTEMENTS PROUVES, la ou l ancienne version dormait 120 ms en
        // esperant que l horloge de 25 ms ait echu quatre fois.
        for (var i = 0; i < 3; i++) {
          await m.horloge.battre();
        }
        await vider();
        expect(m.horloge.battements, 3);
        expect(m.ordonnanceur.passesExecutees, 0);
        expect(m.ordonnanceur.enCours, isFalse);
      },
    );

    test('ARRETER ARRETE VRAIMENT : plus une seule passe apres', () async {
      await publier();
      final m = monter();
      addTearDown(m.ordonnanceur.stop);
      m.ordonnanceur.start();

      // LE REPERE SE PREND AU REPOS, ET C'ETAIT L'AUTRE MOITIE DU DEFAUT.
      // `stop()` n'interrompt PAS une passe en cours — c'est ecrit dans sa doc,
      // elle tient une transaction. Prendre le repere pendant qu'une passe est
      // EN VOL, c'est donc le prendre avant un increment legitime, et conclure
      // « l arret n a pas arrete » sur une passe qui avait demarre AVANT
      // l arret.
      await m.horloge.battre();
      await jusqua(
        () => m.ordonnanceur.passesExecutees == 1 && !m.ordonnanceur.enCours,
        quoi: 'la passe de la cadence, FINIE',
      );
      final avant = m.ordonnanceur.passesExecutees;
      expect(avant, 1);
      expect(m.ordonnanceur.enCours, isFalse);

      await m.ordonnanceur.stop();
      expect(m.ordonnanceur.demarre, isFalse);
      expect(
        m.horloge.annulations,
        1,
        reason:
            'L HORLOGE DOIT ETRE ANNULEE, et c est desormais verifie au lieu '
            'd etre deduit d un sommeil',
      );
      expect(m.horloge.isActive, isFalse);

      // LE BATTEMENT EST REJOUE APRES L ARRET. Une horloge annulee ne rappelle
      // plus son battement : la fausse horloge se comporte comme la vraie et
      // REFUSE de battre. C est la preuve du negatif, et aucune attente ne
      // pouvait la donner.
      await m.horloge.battre();
      await vider();
      expect(m.horloge.battements, 1, reason: 'le battement a ete refuse');
      expect(m.ordonnanceur.passesExecutees, avant);

      m.reseau.emettre(ConnectivityStatusValues.online);
      await vider();
      expect(
        m.ordonnanceur.passesExecutees,
        avant,
        reason: 'l ecoute du reseau est annulee, pas seulement l horloge',
      );
      expect(m.ordonnanceur.enCours, isFalse);
    });

    test(
      'LE PERIMETRE EST LES SENTIERS TELECHARGES : un sentier VU AU CATALOGUE '
      'ne fait descendre AUCUNE donnee',
      () async {
        await publier();
        // Le sentier est au catalogue (sa ligne de liste existe) mais n a jamais
        // ete copie : `localVersion` est nul.
        expect(await manifestes.getTelecharges(), isEmpty);

        final m = monter(cadence: const Duration(hours: 4));
        addTearDown(m.ordonnanceur.stop);

        final bilans = await m.ordonnanceur.passer('test');

        expect(
          bilans,
          isEmpty,
          reason:
              'sur quarante sentiers publies, un randonneur qui en a copie '
              'un seul ne doit pas en synchroniser quarante',
        );
        expect(requetesDonnees, isEmpty);
        expect(await enBase(), {for (final f in TrailChunks.tous) f: 0});
      },
    );

    test('LA CADENCE NE MONTE JAMAIS LE NIVEAU : un sentier PREPARE reste '
        'prepare, et le volumineux NE DESCEND PAS', () async {
      final entree = await publier();

      // Le randonneur prepare son sentier. Rien de plus.
      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        revisionCible: entree.dataVersion,
        empreinteAttendue: entree.hash,
        niveau: NiveauDeTelechargement.preparer,
      );
      expect((await enBase())['gpx_points'], 0);

      // Le serveur republie : une etape corrigee, au jour 2.
      corrigerUneAltitude(1234);
      final entree2 = await publier(jour: 2);
      expect(entree2.dataVersion, instantAuJour(2));

      final m = monter(cadence: const Duration(hours: 4));
      addTearDown(m.ordonnanceur.stop);
      final bilans = await m.ordonnanceur.passer('cadence de test');

      expect(bilans, hasLength(1));
      expect(bilans.single.success, isTrue);
      expect(
        bilans.single.niveau,
        NiveauDeTelechargement.preparer,
        reason:
            'la cadence resynchronise au niveau DEJA descendu, elle n en '
            'porte pas un a elle',
      );

      // LE POINT DU TEST, ET IL EST LA DEMANDE DU 28/09 11:27 PROTEGEE PAR LA
      // PORTE DE DERRIERE : reveiller la cadence ne doit pas faire arriver 10 000
      // points de trace et 260 Mo de tuiles sur un sentier seulement prepare,
      // toutes les quatre heures, sans que le randonneur l ait demande.
      expect((await enBase())['gpx_points'], 0);
      expect((await enBase())['gpx_tracks'], 0);
      expect(
        await manifestes.niveauDe('gr-monts-dore'),
        NiveauDeTelechargement.preparer,
      );
      expect(
        bilans.single.tablesUpdated,
        isNot(contains(TrailChunks.pointsDeTrace)),
      );
    });

    test(
      'LA CADENCE ENTRETIENT UN SENTIER COMPLET AU NIVEAU COMPLET',
      () async {
        final entree = await publier();
        await service().synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
          niveau: NiveauDeTelechargement.realiser,
        );
        expect((await enBase())['gpx_points'], 10);

        corrigerUneAltitude(1234);
        await publier(jour: 2);

        final m = monter(cadence: const Duration(hours: 4));
        addTearDown(m.ordonnanceur.stop);
        final bilans = await m.ordonnanceur.passer('cadence de test');

        expect(bilans.single.niveau, NiveauDeTelechargement.realiser);
        expect((await enBase())['gpx_points'], 10);
        expect(
          await manifestes.niveauDe('gr-monts-dore'),
          NiveauDeTelechargement.realiser,
        );
      },
    );

    test('LA CADENCE PASSE PAR `scheduleBackgroundDownload` : le point '
        'd injection du travail en arriere-plan n est PAS contourne', () async {
      final entree = await publier();
      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        revisionCible: entree.dataVersion,
        empreinteAttendue: entree.hash,
        niveau: NiveauDeTelechargement.realiser,
      );
      corrigerUneAltitude(1234);
      await publier(jour: 2);

      // UN RUNNER QUI COMPTE. C est la seule facon de prouver que la cadence
      // emprunte `scheduleBackgroundDownload` et non `downloadAllUpdates` par
      // dessous : la tache 610 avait signale cette methode comme existante et
      // jamais appelee, et la contourner l aurait laissee morte une seconde fois.
      final taches = <String>[];
      final reseau = _ReseauPilotable(ConnectivityStatusValues.online);
      final downloader = UpdateDownloader(
        updateChecker: _CheckerTropLarge(
          dao: manifestes,
          connectivityMonitor: reseau,
          firebaseService: FirebaseService.testOnly(isAvailable: true),
        ),
        deltaUpdateService: service(),
        manifestService: listeService(client: stockage()),
        dao: manifestes,
        connectivityMonitor: reseau,
        dataBaseUrl: 'https://double',
        backgroundRunner: (nom, tache) async {
          taches.add(nom);
          await tache();
        },
      );
      final ordonnanceur = OrdonnanceurDeSynchronisation(
        downloader: downloader,
        dao: manifestes,
        connectivityMonitor: reseau,
        urlManifeste: 'https://double/${Publicateur.nomDeLaListe}',
        cadence: const Duration(hours: 4),
      );
      addTearDown(ordonnanceur.stop);

      final bilans = await ordonnanceur.passer('test');

      expect(
        taches,
        ['update_download'],
        reason:
            'le jour ou un runner workmanager est injecte, la cadence doit '
            'en beneficier sans qu on recable l ordonnanceur',
      );
      expect(bilans, hasLength(1));
      expect(bilans.single.niveau, NiveauDeTelechargement.realiser);
    });

    test('DEUX PASSES NE SE CHEVAUCHENT PAS : les deux reveils peuvent tomber '
        'ensemble', () async {
      final entree = await publier();
      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        revisionCible: entree.dataVersion,
        empreinteAttendue: entree.hash,
        niveau: NiveauDeTelechargement.realiser,
      );
      corrigerUneAltitude(1234);
      await publier(jour: 2);

      final m = monter(cadence: const Duration(hours: 4));
      addTearDown(m.ordonnanceur.stop);

      // Deux passes lancees au meme instant : la seconde doit se retirer.
      final deux = await Future.wait([
        m.ordonnanceur.passer('horloge'),
        m.ordonnanceur.passer('retour du reseau'),
      ]);

      expect(
        m.ordonnanceur.passesExecutees,
        1,
        reason:
            'deux transactions concurrentes sur les memes tables '
            'pourraient inscrire deux reperes pour un seul jeu de donnees',
      );
      expect(deux.where((b) => b.isEmpty), hasLength(1));
      expect(m.ordonnanceur.enCours, isFalse);
    });
  });

  // =========================================================================
  // 4. CE QUI NE DOIT PAS CASSER
  // =========================================================================
  group('616 — NON-REGRESSION : gr-monts-dore traverse toute la chaine', () {
    test('le geste TELECHARGER au niveau REALISER amene la trace jusqu a '
        'l affichage, par le chemin unique', () async {
      await publier();
      final c = conteneur();
      addTearDown(c.dispose);

      await c.read(catalogStateProvider.future);
      await c
          .read(catalogStateProvider.notifier)
          .downloadTrail(
            'gr-monts-dore',
            niveau: NiveauDeTelechargement.realiser,
          );

      expect(await manifestes.needsUpdate('gr-monts-dore'), isFalse);
      expect(
        await manifestes.niveauDe('gr-monts-dore'),
        NiveauDeTelechargement.realiser,
      );

      // LA TRACE S AFFICHE : c est le bout de la chaine, et il doit tenir.
      final trace = await c.read(
        traceDuSentierProvider('gr-monts-dore').future,
      );
      expect(trace.estVide, isFalse);
      expect(trace.points, hasLength(10));
    });

    test('le geste TELECHARGER au niveau PREPARER rend le sentier calculable '
        'SANS trace affichable — et c est voulu', () async {
      await publier();
      final c = conteneur();
      addTearDown(c.dispose);

      await c.read(catalogStateProvider.future);
      await c
          .read(catalogStateProvider.notifier)
          .downloadTrail(
            'gr-monts-dore',
            niveau: NiveauDeTelechargement.preparer,
          );

      // De quoi calculer la faisabilite et remplir le sac.
      expect(
        await TrailStagesDao(db).getByItineraryId('montsdore-i1'),
        hasLength(2),
      );
      expect(
        await TrailAccommodationsDao(db).getByStageId('montsdore-s1'),
        isNotEmpty,
      );

      // Mais pas de trace : preparer se fait sur les CHIFFRES des etapes.
      final trace = await c.read(
        traceDuSentierProvider('gr-monts-dore').future,
      );
      expect(
        trace.estVide,
        isTrue,
        reason:
            'la trace ne sert qu a marcher — la suivre, se situer, mesurer '
            'l ecart. C est le seul usage qui la justifie, et c est REALISER. '
            'Une trace vide est NOMMEE (TrailTrack.source), jamais un vide '
            'muet.',
      );
    });

    test('LE MODELE DE REVISION DU LOT 610 TIENT AU NIVEAU PREPARER : une etape '
        'corrigee fait descendre UNE etape, pas huit enregistrements', () async {
      final entree = await publier();
      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        revisionCible: entree.dataVersion,
        empreinteAttendue: entree.hash,
        niveau: NiveauDeTelechargement.preparer,
      );

      // Le serveur republie SANS rien changer : la revision de chaque donnee ne
      // bouge pas, donc rien ne doit redescendre.
      final entree2 = await publier(jour: 2);
      final bilan = await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree2.filePath}',
        revisionCible: entree2.dataVersion,
        empreinteAttendue: entree2.hash,
        niveau: NiveauDeTelechargement.preparer,
      );

      expect(
        bilan.ecrits,
        0,
        reason:
            'la revision unitaire du lot 610 doit rester intacte sous les '
            'niveaux : republier a l identique n ecrit rien',
      );
      expect(bilan.famillesTouchees, isEmpty);
      expect(
        await manifestes.niveauDe('gr-monts-dore'),
        NiveauDeTelechargement.preparer,
      );
    });

    test(
      'UNE SOURCE INTERROGEABLE N INTERROGE MEME PAS LE VOLUMINEUX : c est la '
      'ou l economie de transport est REELLE',
      () async {
        final interrogees = <String>[];
        final source = SourceInterrogeable((
          trailId,
          famille,
          revisionMinimale,
        ) async {
          interrogees.add(famille);
          return const [];
        });

        final aPrendre = await source.depuisLaRevision(
          'gr-monts-dore',
          adresse: 'ignoree',
          revisionLocale: RevisionDeDonnee.revisionInitiale,
          revisionCible: instantAuJour(1),
          famillesDemandees: NiveauDeTelechargement.preparer.familles,
        );

        expect(
          interrogees,
          NiveauDeTelechargement.preparer.familles,
          reason:
              'les familles hors niveau ne sont pas filtrees a l arrivee : '
              'elles ne sont PAS DEMANDEES',
        );
        expect(interrogees, isNot(contains(TrailChunks.pointsDeTrace)));
        expect(
          aPrendre.ecartesHorsNiveau,
          0,
          reason: 'rien n est descendu pour rien, donc rien a ecarter',
        );

        // Et au niveau REGARDER, pas une seule requete.
        interrogees.clear();
        final rien = await source.depuisLaRevision(
          'gr-monts-dore',
          adresse: 'ignoree',
          revisionLocale: RevisionDeDonnee.revisionInitiale,
          revisionCible: instantAuJour(1),
          famillesDemandees: NiveauDeTelechargement.regarder.familles,
        );
        expect(interrogees, isEmpty);
        expect(rien.transferes, 0);
      },
    );
  });
}

/// UNE HORLOGE QUE LE TEST FAIT BATTRE, et qui se comporte comme la vraie.
///
/// POURQUOI ELLE EXISTE (tache 695, kaizen #101267). Les tests de cadence
/// laissaient battre un VRAI `Timer.periodic` de 25 ms, puis dormaient un budget
/// en TEMPS REEL avant d affirmer qu une passe avait eu lieu. Le 05/10, pendant
/// le build 10, `expect(avant, greaterThanOrEqualTo(1))` a rendu `Actual: <0>` :
/// au bout de 80 ms de sommeil, l horloge n avait pas encore FINI une passe
/// parce que la machine etait occupee. Le verdict dependait de la charge de la
/// machine de fabrication — rouge environ une fois sur trois, et pour une raison
/// qui n apprend rien sur l application.
///
/// ELLE EST FIDELE SUR LE SEUL POINT QUI COMPTE : ANNULEE, ELLE NE BAT PLUS. Un
/// `Timer.periodic` annule ne rappelle plus son battement ; `battre()` refuse
/// donc apres `cancel()`. C est ce qui permet de prouver « apres stop(), plus
/// une seule passe » PAR LA MESURE et non par un sommeil.
class _HorlogePilotable implements Timer {
  Duration? cadence;
  void Function(Timer)? _battement;
  int battements = 0;
  int annulations = 0;

  /// Vrai des que l ordonnanceur a arme son horloge.
  bool get posee => _battement != null;

  /// Ce que l ordonnanceur appelle a la place de `Timer.periodic`.
  Timer poser(Duration cadence, void Function(Timer) battement) {
    this.cadence = cadence;
    _battement = battement;
    return this;
  }

  /// Fait echoir l horloge UNE fois, puis rend la main a la boucle.
  Future<void> battre() async {
    final battement = _battement;
    if (battement == null || !isActive) return;
    battements++;
    battement(this);
    await vider();
  }

  @override
  bool get isActive => annulations == 0;

  @override
  int get tick => battements;

  @override
  void cancel() => annulations++;
}

/// Rend la main a la boucle d evenements, quelques tours.
///
/// Sert aux affirmations NEGATIVES (« rien ne s est declenche ») : il faut
/// laisser au declenchement eventuel la chance de se produire avant d affirmer
/// qu il n a pas eu lieu. Ce n est pas un budget de temps : chaque tour est un
/// tour de boucle, pas une duree.
Future<void> vider({int tours = 8}) async {
  for (var i = 0; i < tours; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Fait tourner la boucle d evenements JUSQU A ce que [condition] tienne.
///
/// CE N EST PAS UN SOMMEIL, ET C EST TOUT L INTERET. L ancienne recette dormait
/// un budget fixe puis affirmait ; celle-ci rend la main autant de fois qu il
/// faut et n affirme qu une fois la condition atteinte. Le verdict ne depend
/// donc plus de la vitesse de la machine : il ne reste rouge que si le
/// mecanisme est VRAIMENT casse. La borne est absurde expres — l atteindre
/// signifie que rien ne se declenchera jamais.
Future<void> jusqua(bool Function() condition, {String quoi = ''}) async {
  for (var i = 0; i < 20000; i++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('JAMAIS ATTEINT apres 20000 tours de boucle : $quoi');
}

/// Un reseau dont le test decide, et qui peut EMETTRE des changements.
///
/// Les tests anterieurs se contentaient d un statut fixe ; la cadence, elle, se
/// declenche sur un EVENEMENT, donc il faut pouvoir le produire.
class _ReseauPilotable extends ConnectivityMonitor {
  _ReseauPilotable(this.statut);

  ConnectivityStatus statut;
  final _canal = StreamController<ConnectivityStatus>.broadcast();

  void emettre(ConnectivityStatus nouveau) {
    statut = nouveau;
    _canal.add(nouveau);
  }

  @override
  Future<ConnectivityStatus> checkStatus() async => statut;

  @override
  Stream<ConnectivityStatus> get onStatusChange => _canal.stream;
}

/// UN DETECTEUR VOLONTAIREMENT TROP LARGE : il annonce une mise a jour pour TOUT
/// sentier de la liste locale, telecharge ou pas.
///
/// C est ce qui rend les tests de perimetre significatifs. Si le filtre
/// `getTelecharges` de l ordonnanceur ne tenait pas, ce detecteur laisserait
/// passer le sentier vu au catalogue — et le test deviendrait rouge. Un fake qui
/// filtrerait lui-meme ne prouverait rien.
class _CheckerTropLarge extends UpdateChecker {
  _CheckerTropLarge({
    required super.dao,
    required super.connectivityMonitor,
    required super.firebaseService,
  });

  @override
  Future<List<UpdateCheckResult>> checkAllForUpdates() async {
    final toutes = await dao.getAll();
    return [
      for (final ligne in toutes)
        UpdateCheckResult(trailId: ligne.trailId, hasUpdate: true),
    ];
  }
}

List<String> _fichiersDe(String racine) {
  final dossier = Directory(racine);
  if (!dossier.existsSync()) return const [];
  return dossier
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .toList();
}
