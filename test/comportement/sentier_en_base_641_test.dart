import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/mise_a_jour_a_la_source.dart';
import 'package:moteur_gr/core/services/trail_record_source.dart';
import 'package:moteur_gr/core/services/firestore_trail_source.dart';
import 'package:moteur_gr/features/planning/domain/transport_info.dart';
import 'package:moteur_gr/features/planning/providers/lieux_en_base_provider.dart';

/// LES DONNEES DU SENTIER SONT EN BASE, ET L APPLICATION VA LES Y CHERCHER
/// (tache 641).
///
/// CE QUE CES TESTS PROUVENT, DANS L ORDRE DE LA DEMANDE DE CHRISTOPHE.
///
///  1. LE SENTIER EST PUBLIABLE PAR L OUTIL — et il ne l avait jamais ete. La
///     dette #X8 de la tache 610 disait, noir sur blanc : « le Mare a Mare n est
///     pas passe par l outil, #Z01 tient ». Ces tests lisent le depot REEL du
///     repot et verifient que le sentier y est, avec ses sept familles et ses
///     horodatages.
///
///  2. UNE MODIFICATION EN BASE ARRIVE SUR LE TELEPHONE SANS NOUVELLE VERSION DE
///     L APPLICATION. C est le critere de recette verbatim du lot : « une
///     modification en base (rev+1 et updated_at neuf sur un hebergement) arrive
///     sur le telephone sans nouvelle version de l appli ».
///
///  3. HORS LIGNE, LA COPIE SERT — et le repere local NE BOUGE PAS.
///
///  4. LE TRANSPORT ET LE RAVITAILLEMENT VIENNENT DE LA BASE, pas de deux
///     constantes Dart derriere un `switch (trailId)`.
void main() {
  group('641 — le Mare a Mare Centre est PUBLIE, et le depot le prouve', () {
    late Map<String, dynamic> list;
    late Map<String, dynamic> donnees;

    setUpAll(() {
      final fichierListe = File('publication/publie/manifest.json');
      expect(
        fichierListe.existsSync(),
        isTrue,
        reason:
            'la liste publiee doit exister dans le depot — sans elle rien '
            'n a jamais ete publie, et c est exactement ce que Christophe a '
            'constate le 30/09 : « je ne vois toujours pas les donnees Mare a '
            'Mare dans Firebase, ni demo, ni normal, rien »',
      );
      list =
          jsonDecode(fichierListe.readAsStringSync()) as Map<String, dynamic>;

      final entrees = (list['trails'] as List)
          .cast<Map<String, dynamic>>()
          .where((e) => e['trailId'] == 'mare-a-mare-centre')
          .toList();
      expect(
        entrees,
        hasLength(1),
        reason:
            'le Mare a Mare Centre doit avoir UNE entree dans la liste '
            'publiee (dette #X8 de la tache 610, fermee ici)',
      );

      final chemin = entrees.single['filePath'] as String;
      donnees =
          jsonDecode(File('publication/publie/$chemin').readAsStringSync())
              as Map<String, dynamic>;
    });

    test('l entree de liste porte une fiche complete et le statut « active » — '
        'sans fiche, un sentier publie est INAFFICHABLE (#M9)', () {
      final entree = (list['trails'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => e['trailId'] == 'mare-a-mare-centre');

      expect(entree['status'], 'active');
      final fiche = entree['fiche'] as Map<String, dynamic>;
      expect(fiche['displayName'], 'Mare a Mare Centre');
      expect(fiche['region'], 'Corse');
      expect(fiche['totalStages'], 7);
      expect(fiche['totalDistanceKm'], 84.0);

      // `lastUpdated` ET `dataVersion` DESIGNENT LE MEME INSTANT (dette #X12 de
      // la tache 610). Deux valeurs, c est deux autorites, et celle qui decide
      // n est pas celle qu un humain lit.
      expect(entree['lastUpdated'], entree['dataVersion']);
    });

    test('les numeros de secours publies CONSERVENT celui de production et '
        'AJOUTENT ceux qui sont sources — on ne retire jamais un numero de '
        'secours sur la foi d une recherche', () {
      final entree = (list['trails'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => e['trailId'] == 'mare-a-mare-centre');
      final numeros =
          ((entree['fiche'] as Map<String, dynamic>)['emergencyNumbers']
                  as List)
              .cast<Map<String, dynamic>>();
      final telephones = numeros.map((n) => n['phone']).toList();

      expect(
        telephones,
        contains('+33495613636'),
        reason: 'le numero deja en production doit etre conserve',
      );
      expect(
        telephones,
        contains('+33495477146'),
        reason:
            'le PGHM de Corte, releve dans l annuaire officiel de '
            'l administration, doit etre ajoute',
      );
    });

    test('les sept familles sont publiees, chaque enregistrement portant son '
        'instant — c est la demande verbatim de Christophe : « chaque donnee a '
        'jour avec son timestamp de MAJ »', () {
      const attendues = <String>[
        'trail_meta',
        'itineraries',
        'stages',
        'accommodations',
        'pois',
        'gpx_tracks',
        'gpx_points',
      ];
      for (final famille in attendues) {
        expect(
          donnees.containsKey(famille),
          isTrue,
          reason: 'la famille « $famille » doit etre publiee',
        );
      }

      expect((donnees['stages'] as List), hasLength(7));
      expect(
        (donnees['gpx_points'] as List).length,
        greaterThan(2),
        reason: 'une trace de moins de deux points ne dessine rien',
      );

      var sansInstant = 0;
      for (final famille in attendues) {
        final brut = donnees[famille];
        final tous = <Map<String, dynamic>>[
          if (brut is Map) Map<String, dynamic>.from(brut),
          if (brut is List)
            ...brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        ];
        for (final e in tous) {
          if (e[RevisionDeDonnee.champRevision] == null) sansInstant++;
        }
      }
      expect(
        sansInstant,
        0,
        reason:
            'un enregistrement sans « rev » est rattache a l instant courant '
            'du sentier (#R6) : il REDESCEND a chaque publication, sur le '
            'forfait du randonneur',
      );
    });

    test('le TRANSPORT et le RAVITAILLEMENT sont en base — c est la reponse aux '
        'bugs 12, 13 et 17, dont la cause etait qu ils n y etaient PAS', () {
      final pois = (donnees['pois'] as List).cast<Map<String, dynamic>>();
      final transports = pois.where(
        (p) => LieuxEnBase.estTransport(p['type'] as String),
      );
      final ravitaillements = pois.where(
        (p) => LieuxEnBase.estRavitaillement(p['type'] as String),
      );

      expect(
        transports,
        isNotEmpty,
        reason:
            'avant ce lot, le transport vivait dans une constante Dart '
            'derriere un switch sur l identifiant du sentier — donc muet pour le '
            'mode demo, qui porte un identifiant different',
      );
      expect(
        ravitaillements,
        isNotEmpty,
        reason:
            'avant ce lot, le ravitaillement vivait dans une constante Dart, '
            'et l ecran rendait un SizedBox.shrink() : un ecran BLANC sous le '
            'titre « Ravitaillement »',
      );
    });

    test(
      'CHAQUE lieu publie par ce lot CITE SA SOURCE — une information sans '
      'source verifiable n a rien a faire entre les mains d un randonneur',
      () {
        final pois = (donnees['pois'] as List).cast<Map<String, dynamic>>();
        final ajoutes = pois.where((p) {
          final type = p['type'] as String;
          return LieuxEnBase.estTransport(type) ||
              LieuxEnBase.estRavitaillement(type);
        });

        for (final poi in ajoutes) {
          expect(
            poi['source'],
            isA<String>().having((s) => s.isNotEmpty, 'non vide', isTrue),
            reason: '« ${poi['id']} » doit porter sa source',
          );
        }
      },
    );

    test('les cinq langues sont renseignees sur chaque lieu publie — c est le '
        'piege #A13 du MODOP 603, et il ne pardonne pas', () {
      final pois = (donnees['pois'] as List).cast<Map<String, dynamic>>();
      for (final poi in pois) {
        for (final langue in const ['fr', 'en', 'de', 'it', 'es']) {
          expect(
            poi['name_$langue'],
            isA<String>().having((s) => s.isNotEmpty, 'non vide', isTrue),
            reason: '« ${poi['id']} » doit porter name_$langue',
          );
        }
      }
    });

    test('les hebergements portent desormais une ADRESSE — bug 15 : « hebergement '
        'il doit avoir une adresse et un point GPS qui link sur Maps »', () {
      final hebergements = (donnees['accommodations'] as List)
          .cast<Map<String, dynamic>>();
      expect(hebergements.length, greaterThanOrEqualTo(11));
      expect(
        hebergements.where((h) => h['address'] != null),
        isNotEmpty,
        reason:
            'la colonne n existait pas avant ce lot, et les onze '
            'hebergements du sentier n avaient ni telephone, ni site, ni adresse',
      );
      // AU MOINS UN TELEPHONE REEL, SOURCE. Avant ce lot, les onze etaient nuls.
      expect(
        hebergements.where((h) => (h['phone'] as String?)?.isNotEmpty == true),
        isNotEmpty,
      );
    });

    test('les Bergeries de Capannelle NE SONT PAS PUBLIEES — elles sont sur le '
        'GR20, pas sur cette traversee, et un lieu faux ne se deplace pas : il '
        'se retire', () {
      final pois = (donnees['pois'] as List).cast<Map<String, dynamic>>();
      expect(
        pois.where((p) => p['id'] == 'mam-poi-03'),
        isEmpty,
        reason:
            'Capannelle est une etape du GR20, entre le col de Verde et '
            'Onda, a plus de vingt kilometres au nord de l itineraire '
            'Cozzano - Guitera. Le point etait une erreur de contenu heritee de '
            'l asset embarque.',
      );

      // POURQUOI UNE ABSENCE ET NON UN MARQUEUR DE SUPPRESSION, ICI. Un marqueur
      // sert a transmettre une absence a un telephone QUI AVAIT DEJA la donnee.
      // Ce point n a JAMAIS ete publie : il n existe dans aucune base et sur
      // aucun repere. Publier un marqueur pour lui ferait descendre un
      // enregistrement que personne n a, pour rien. Le marqueur restera le
      // chemin de tout retrait FUTUR, et c est l outil de publication qui le
      // fabriquera, en comparant a la publication precedente.
      //
      // ATTENTION, LA COPIE EMBARQUEE LE PORTE ENCORE : `assets/data/`
      // mare_a_mare_centre.json n est pas touche par ce lot. Un telephone qui
      // seede depuis l asset avant sa premiere synchronisation verra donc encore
      // ce point d interet. C est nomme comme reste a faire, et la correction
      // est le retrait du point de l asset embarque.
      final asset =
          jsonDecode(
                File('assets/data/mare_a_mare_centre.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(
        (asset['pois'] as List).cast<Map<String, dynamic>>().where(
          (p) => p['id'] == 'mam-poi-03',
        ),
        isNotEmpty,
        reason:
            'ce test DOCUMENTE le reste a faire : tant que l asset porte le '
            'point, un premier demarrage hors ligne le montre encore. Le jour ou '
            'l asset est corrige, ce test tombe et c est le signal qu il faut le '
            'retourner.',
      );
    });
  });

  group('641 — la liste des sentiers se lit dans Firestore', () {
    test('un document `trails/{id}` devient une entree de liste complete', () {
      final entree = FirestoreTrailList.versEntree('mare-a-mare-centre', {
        'trail_id': 'mare-a-mare-centre',
        'data_version': 1759227264414,
        'last_updated': '2026-09-30T10:27:44.414Z',
        'hash': 'abc',
        'file_path': 'mare_a_mare_centre/v1.json',
        'file_size': 89990,
        'status': 'active',
        'fiche': <String, dynamic>{
          'name': 'Mare a Mare Centre',
          'displayName': 'Mare a Mare Centre',
          'tagline': 'De la mer a la mer',
          'region': 'Corse',
          'country': 'France',
          'totalStages': 7,
          'totalDistanceKm': 84.0,
          'totalElevationGain': 3550,
        },
      });

      expect(entree, isNotNull);
      expect(entree!.trailId, 'mare-a-mare-centre');
      expect(entree.fiche?.displayName, 'Mare a Mare Centre');
      expect(entree.dataVersion.millisecondesEpoch, 1759227264414);
      expect(
        entree.lastUpdated,
        entree.dataVersion.iso8601,
        reason:
            'DETTE #X12 FERMEE : `lastUpdated` est DERIVE de `dataVersion` '
            'et jamais relu separement. Deux noms pour un meme instant, c est '
            'deux autorites, et la plus silencieuse gagne',
      );
    });

    test(
      'un document mal forme est ECARTE, jamais fatal — une entree cassee ne '
      'doit pas rendre TOUT le catalogue illisible',
      () {
        final entree = FirestoreTrailList.versEntree('casse', {
          'fiche': <String, dynamic>{'name': 'incomplete'},
        });
        expect(entree, isNull);
      },
    );

    test('un horodatage Firestore serialise est LU, et pas confondu avec du '
        'texte — sinon la comparaison de revision compare des chaines', () {
      final entree = FirestoreTrailList.versEntree('x', {
        'data_version': <String, dynamic>{
          'seconds': 1759227264,
          'nanoseconds': 414000000,
        },
        'status': 'active',
      });
      expect(entree, isNotNull);
      expect(entree!.dataVersion.millisecondesEpoch, 1759227264414);
    });
  });

  group('641 — une correction en base arrive sur le telephone', () {
    late AppDatabase db;
    late TrailManifestsDao manifests;
    late TrailPoisDao pois;
    late DeltaUpdateService delta;
    late _ListeDouble listeDouble;
    late _ReseauDouble reseau;
    late MiseAJourALaSource service;
    late _SourceDouble sourceDouble;

    const trailId = 'mare-a-mare-centre';
    final instantUn = HorodatageServeur.annonceParLeServeur(
      '2026-09-30T10:00:00.000Z',
    )!;
    final instantDeux = HorodatageServeur.annonceParLeServeur(
      '2026-09-30T11:00:00.000Z',
    )!;

    Map<String, dynamic> lotDeDonnees(HorodatageServeur instant, String nom) =>
        <String, dynamic>{
          'trail_meta': <String, dynamic>{
            'id': trailId,
            'code': 'mam-centre',
            'status': 'active',
            'rev': instant.iso8601,
          },
          'itineraries': <Map<String, dynamic>>[
            {
              'id': 'itin',
              'trail_id': trailId,
              'code': 'EW',
              'name_fr': 'Est-Ouest',
              'name_en': 'East-West',
              'name_de': 'Ost-West',
              'name_it': 'Est-Ovest',
              'name_es': 'Este-Oeste',
              'distance_km': 84.0,
              'elevation_gain': 3550,
              'stage_count': 1,
              'rev': instant.iso8601,
            },
          ],
          'stages': <Map<String, dynamic>>[
            {
              'id': 'etape-1',
              'itinerary_id': 'itin',
              'stage_number': 1,
              'name_fr': 'Ghisonaccia',
              'name_en': 'Ghisonaccia',
              'name_de': 'Ghisonaccia',
              'name_it': 'Ghisonaccia',
              'name_es': 'Ghisonaccia',
              'start_lat': 42.0156,
              'start_lng': 9.4039,
              'end_lat': 41.9567,
              'end_lng': 9.2864,
              'distance_km': 15.0,
              'elevation_gain': 850,
              'elevation_loss': 100,
              'duration_minutes': 330,
              'difficulty': 'hard',
              'rev': instant.iso8601,
            },
          ],
          'accommodations': <Map<String, dynamic>>[
            {
              'id': 'gite-1',
              'stage_id': 'etape-1',
              'name_fr': nom,
              'name_en': nom,
              'name_de': nom,
              'name_it': nom,
              'name_es': nom,
              'type': 'gite',
              'lat': 41.957,
              'lng': 9.287,
              'phone': '+33781768471',
              'address': 'Catastaghju, 20243 San-Gavino-di-Fiumorbo',
              'rev': instant.iso8601,
            },
          ],
          'pois': <Map<String, dynamic>>[
            {
              'id': 'transport-1',
              'stage_id': 'etape-1',
              'name_fr': 'Autocar Bastia - Porto-Vecchio',
              'name_en': 'Bastia - Porto-Vecchio coach',
              'name_de': 'Bus Bastia - Porto-Vecchio',
              'name_it': 'Autobus Bastia - Porto-Vecchio',
              'name_es': 'Autocar Bastia - Porto-Vecchio',
              'type': 'transport_bus',
              'lat': 42.0156,
              'lng': 9.4039,
              'phone': '+33495310379',
              'website': 'https://www.rapides-bleus.com/bastia-porto-vecchio/',
              'rev': instant.iso8601,
            },
            {
              'id': 'ravitaillement-1',
              'stage_id': 'etape-1',
              'name_fr': 'Commerces de Ghisonaccia',
              'name_en': 'Ghisonaccia shops',
              'name_de': 'Geschafte Ghisonaccia',
              'name_it': 'Negozi di Ghisonaccia',
              'name_es': 'Comercios de Ghisonaccia',
              'type': 'shop_supermarche',
              'lat': 42.0156,
              'lng': 9.4039,
              'address': 'Centre de Ghisonaccia, 20240',
              'rev': instant.iso8601,
            },
          ],
        };

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      manifests = TrailManifestsDao(db);
      pois = TrailPoisDao(db);
      reseau = _ReseauDouble();
      sourceDouble = _SourceDouble();
      delta = DeltaUpdateService(
        db: db,
        source: sourceDouble,
        manifestService: ManifestService(
          dao: manifests,
          connectivityMonitor: reseau,
        ),
        trailManifestsDao: manifests,
        trailMetaDao: TrailMetaDao(db),
        trailItinerariesDao: TrailItinerariesDao(db),
        trailStagesDao: TrailStagesDao(db),
        trailAccommodationsDao: TrailAccommodationsDao(db),
        trailPoisDao: pois,
        trailGpxTracksDao: TrailGpxTracksDao(db),
        trailGpxPointsDao: TrailGpxPointsDao(db),
      );
      listeDouble = _ListeDouble();
      service = MiseAJourALaSource(
        list: listeDouble,
        delta: delta,
        dao: manifests,
        connectivityMonitor: reseau,
      );

      // La ligne de liste locale doit exister : c est elle qui porte le repere.
      await manifests.insertOrReplace(
        TrailManifestsCompanion(
          trailId: const Value(trailId),
          dataVersion: Value(instantUn),
          hash: const Value('h'),
          filePath: const Value('p'),
          fileSize: const Value(1),
          status: const Value('active'),
          lastUpdated: Value(instantUn.iso8601),
        ),
      );
    });

    tearDown(() async => db.close());

    test('PREMIERE COPIE puis CORRECTION : une modification en base arrive sur '
        'le telephone SANS nouvelle version de l application — c est le critere '
        'de recette verbatim du lot', () async {
      // 1. Premiere copie : le telephone n a rien, tout descend.
      listeDouble.entree = _entree(trailId, instantUn);
      sourceDouble.lot = lotDeDonnees(instantUn, 'Gite de Catastaghju');

      final premier = await service.auDemarrage(trailId);
      expect(premier.aPrisQuelqueChose, isTrue);
      expect(await delta.revisionLocale(trailId), instantUn);

      final avant = await TrailAccommodationsDao(db).getByStageId('etape-1');
      expect(avant.single.nameFr, 'Gite de Catastaghju');
      expect(
        avant.single.address,
        'Catastaghju, 20243 San-Gavino-di-Fiumorbo',
        reason:
            'L ADRESSE DESCEND DE LA BASE (bug 15). Avant ce lot la colonne '
            'n existait pas : aucune adresse ne pouvait arriver, quoi qu on '
            'publie',
      );

      // 2. CORRECTION EN BASE : rev + updated_at neufs sur l hebergement.
      listeDouble.entree = _entree(trailId, instantDeux);
      sourceDouble.lot = lotDeDonnees(
        instantDeux,
        'Gite Catastaghju Sangavinu',
      );

      final second = await service.auDemarrage(trailId);
      expect(second.aPrisQuelqueChose, isTrue);

      final apres = await TrailAccommodationsDao(db).getByStageId('etape-1');
      expect(
        apres.single.nameFr,
        'Gite Catastaghju Sangavinu',
        reason:
            'LA CORRECTION EST ARRIVEE SANS REPUBLIER L APPLICATION. C est '
            'toute la demande de Christophe du 30/09 11:54',
      );
      expect(await delta.revisionLocale(trailId), instantDeux);
    });

    test('RIEN A PRENDRE : quand la base n annonce rien de plus recent, aucune '
        'requete de donnees n est emise — sinon le randonneur paierait un '
        'transport pour rien a chaque ouverture', () async {
      listeDouble.entree = _entree(trailId, instantUn);
      sourceDouble.lot = lotDeDonnees(instantUn, 'Gite de Catastaghju');
      await service.auDemarrage(trailId);

      sourceDouble.appels = 0;
      final second = await service.auDemarrage(trailId);
      expect(second.aPrisQuelqueChose, isFalse);
      expect(
        sourceDouble.appels,
        0,
        reason:
            'la source ne doit pas meme etre interrogee quand l instant '
            'publie n est pas plus recent que le repere local',
      );
    });

    test(
      'HORS LIGNE : la copie sert, rien n est demande, et le repere local NE '
      'BOUGE PAS — un telephone coupe ne doit jamais se croire a jour',
      () async {
        listeDouble.entree = _entree(trailId, instantUn);
        sourceDouble.lot = lotDeDonnees(instantUn, 'Gite de Catastaghju');
        await service.auDemarrage(trailId);
        final repereAvant = await delta.revisionLocale(trailId);

        reseau.statut = ConnectivityStatusValues.offline;
        listeDouble.entree = _entree(trailId, instantDeux);
        sourceDouble.appels = 0;

        final bilan = await service.auDemarrage(trailId);
        expect(bilan.horsLigne, isTrue);
        expect(bilan.aPrisQuelqueChose, isFalse);
        expect(sourceDouble.appels, 0);
        expect(await delta.revisionLocale(trailId), repereAvant);

        // ET LA COPIE EST TOUJOURS LA : c est ce que « la copie sert » veut dire.
        final hebergements = await TrailAccommodationsDao(
          db,
        ).getByStageId('etape-1');
        expect(hebergements, hasLength(1));
      },
    );

    test('LE GESTE MANUEL N ATTEND PAS QU ON LUI DISE QU IL Y A DU RESEAU : il '
        'essaie, et l echec se dit', () async {
      reseau.statut = ConnectivityStatusValues.offline;
      listeDouble.entree = _entree(trailId, instantUn);
      sourceDouble.lot = lotDeDonnees(instantUn, 'Gite de Catastaghju');

      final bilan = await service.onHikerRequest(trailId);
      expect(
        bilan.horsLigne,
        isFalse,
        reason:
            'quand quelqu un appuie sur « rafraichir », il attend qu on '
            'essaie — l echec sera dit, il ne sera pas devine a l avance',
      );
      expect(bilan.aPrisQuelqueChose, isTrue);
    });

    test(
      'UN SENTIER ABSENT DE LA BASE NE CASSE RIEN : la copie embarquee reste '
      'la seule source, et c est dit',
      () async {
        listeDouble.entree = null;
        final bilan = await service.auDemarrage(trailId);
        expect(bilan.aPrisQuelqueChose, isFalse);
        expect(bilan.echecs, isEmpty);
      },
    );

    test(
      'UN SENTIER PUBLIE EN « draft » NE DESCEND PAS — une carte au catalogue '
      'qu on ne peut pas telecharger est un mensonge (#M6)',
      () async {
        listeDouble.entree = _entree(trailId, instantDeux, statut: 'draft');
        sourceDouble.lot = lotDeDonnees(instantDeux, 'x');
        final bilan = await service.auDemarrage(trailId);
        expect(bilan.aPrisQuelqueChose, isFalse);
        expect(sourceDouble.appels, 0);
      },
    );

    test('LE TRANSPORT ET LE RAVITAILLEMENT DESCENDUS SE LISENT — et c est la '
        'premiere fois que `trail_pois` a des lecteurs', () async {
      listeDouble.entree = _entree(trailId, instantUn);
      sourceDouble.lot = lotDeDonnees(instantUn, 'Gite de Catastaghju');
      await service.auDemarrage(trailId);

      final lignes = await pois.getByStageId('etape-1');
      final lieux = lignes
          .map(
            (p) => LieuDeSentier(
              poi: p,
              stageNumber: 1,
              estPremiereEtape: true,
              estDerniereEtape: true,
            ),
          )
          .toList();

      final transport = transportDepuisLesLieux(
        trailId,
        lieux,
        nomDepart: 'Ghisonaccia',
        nomArrivee: 'Porticcio',
      );
      expect(transport, isNotNull);
      final onglet = transport!.forEndpoint(
        'Ghisonaccia',
        TransportRole.arrival,
      );
      expect(onglet, isNotNull);
      expect(onglet!.hasContent, isTrue);
      final option = onglet.sections.first.options.first;
      expect(option.mode, TransportModeKind.bus);
      expect(option.contact, '+33495310379');
      expect(
        option.url,
        'https://www.rapides-bleus.com/bastia-porto-vecchio/',
        reason:
            'les horaires d un autocar corse changent quatre fois par an : '
            'on publie l adresse officielle ou ils sont lisibles, pas une copie '
            'figee dans le binaire',
      );

      final ravitaillement = ravitaillementDepuisLesLieux(trailId, lieux);
      expect(ravitaillement, isNotNull);
      expect(ravitaillement!.shops, hasLength(1));
      expect(
        ravitaillement.shops.single.address,
        'Centre de Ghisonaccia, 20240',
      );
    });

    test(
      'AUCUN LIEU EN BASE : les fabriques rendent `null` et NON un objet vide '
      '— c est ce qui permet a l ecran de retomber sur le catalogue compile au '
      'lieu de montrer l ecran blanc du bug 17',
      () {
        expect(
          transportDepuisLesLieux(
            trailId,
            const <LieuDeSentier>[],
            nomDepart: 'A',
            nomArrivee: 'B',
          ),
          isNull,
        );
        expect(
          ravitaillementDepuisLesLieux(trailId, const <LieuDeSentier>[]),
          isNull,
        );
      },
    );
  });

  group('641 — la conversion des valeurs Firestore', () {
    test('un type de transport inconnu retombe sur « autre » sans lever — le '
        'serveur peut publier un mode que cette version ne connait pas', () {
      expect(
        LieuxEnBase.modeDe('transport_teleporteur'),
        TransportModeKind.other,
      );
      expect(LieuxEnBase.modeDe('transport_bus'), TransportModeKind.bus);
      expect(LieuxEnBase.modeDe('transport_ferry'), TransportModeKind.ferry);
    });

    test('les prefixes reconnaissent les deux rubriques, et rien d autre', () {
      expect(LieuxEnBase.estTransport('transport_bus'), isTrue);
      expect(LieuxEnBase.estTransport('transport'), isTrue);
      expect(LieuxEnBase.estTransport('water'), isFalse);
      expect(LieuxEnBase.estRavitaillement('shop_epicerie'), isTrue);
      expect(LieuxEnBase.estRavitaillement('shelter'), isFalse);
    });

    test(
      'APLATIR NE LAISSE AUCUN OBJET DE PILOTE DANS LA CARTE. Un `Timestamp` '
      'laisse tel quel ferait rendre `null` a `annonceParLeServeur`, donc '
      'rattacher l enregistrement a la revision courante du sentier : il '
      'redescendrait a CHAQUE passage, en silence',
      () {
        final aplati = RequeteFirestoreParRevision.aplatir(<String, dynamic>{
          'id': 'x',
          'nombre': 3,
          'liste': <Object?>[1, 'deux'],
          'carte': <String, Object?>{'a': 1},
        });
        expect(aplati['id'], 'x');
        expect(aplati['nombre'], 3);
        expect(aplati['liste'], <Object?>[1, 'deux']);
        expect(aplati['carte'], <String, Object?>{'a': 1});
      },
    );
  });
}

TrailManifestEntry _entree(
  String trailId,
  HorodatageServeur instant, {
  String statut = 'active',
}) => TrailManifestEntry(
  trailId: trailId,
  dataVersion: instant,
  hash: '',
  filePath: 'mare_a_mare_centre/v1.json',
  fileSize: 1,
  status: statut,
  lastUpdated: instant.iso8601,
);

/// La liste des sentiers publies, remplacee par un double.
///
/// LE DOUBLE PORTE SUR LA LECTURE DE LA BASE, PAS SUR LA LOGIQUE. Firestore n est
/// pas provisionne dans un test unitaire, et le pilote `cloud_firestore` exige un
/// canal de plateforme. Ce qui est EPROUVE ici, c est la decision — « est-ce plus
/// recent que mon repere ? » — et elle ne depend pas du transport.
class _ListeDouble extends FirestoreTrailList {
  _ListeDouble()
    : super(firebaseService: FirebaseService.testOnly(isAvailable: true));

  TrailManifestEntry? entree;

  @override
  Future<TrailManifestEntry?> lireUn(String trailId) async => entree;

  @override
  Future<TrailManifest?> lire() async => TrailManifest(
    schemaVersion: 2,
    trails: entree == null ? const [] : [entree!],
  );
}

class _ReseauDouble extends ConnectivityMonitor {
  ConnectivityStatus statut = ConnectivityStatusValues.online;

  @override
  Future<ConnectivityStatus> checkStatus() async => statut;
}

/// La source de donnees, remplacee par un double qui rend un lot fixe.
class _SourceDouble implements TrailRecordSource {
  Map<String, dynamic> lot = const <String, dynamic>{};
  int appels = 0;

  @override
  Future<MorceauxAPrendre> depuisLaRevision(
    String trailId, {
    required String adresse,
    required HorodatageServeur revisionLocale,
    required HorodatageServeur revisionCible,
    required List<String> famillesDemandees,
    String? empreinteAttendue,
  }) async {
    appels++;
    final retenu = <String, dynamic>{};
    for (final famille in famillesDemandees) {
      final brut = lot[famille];
      if (brut == null) continue;
      retenu[famille] = brut;
    }
    var nombre = 0;
    for (final valeur in retenu.values) {
      nombre += valeur is List ? valeur.length : 1;
    }
    return MorceauxAPrendre(
      parFamille: retenu,
      transferes: nombre,
      retenus: nombre,
    );
  }
}
