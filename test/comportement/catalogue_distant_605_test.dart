import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/features/trail/domain/etat_du_sentier.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';
import 'package:moteur_gr/features/treks/providers/entitlements_provider.dart';
import 'package:moteur_gr/features/trail/providers/catalogue_sentiers_provider.dart';

/// TACHE 605 — LE MUR N1 : LE CATALOGUE VIENT DU RESEAU, ET LA DONNEE PORTE SA
/// REVISION.
///
/// TOUT EST TESTE CONTRE UN DOUBLE, PAS CONTRE UN BUCKET. L espace de stockage
/// StepWays n est pas encore provisionne (Christophe doit le creer en console) :
/// le manifeste et les donnees sont donc servis par un faux client HTTP, ce qui a
/// l avantage de verrouiller EN MEME TEMPS la forme exacte du JSON a deposer —
/// celle que decrit `data/apport_stepways/STRUCTURE_BUCKET_605_donnees_sentiers.md`.
/// Le jour ou le bucket existe, il n y a plus qu a y poser ces fichiers.
///
/// LES DEFAUTS QUE CE FICHIER VERROUILLE, TOUS MESURES DANS LE DEPOT :
///
///  1. PERSONNE N APPELAIT LE CHAINAGE DISTANT. `catalogStateProvider` n existait
///     que dans sa definition et dans un COMMENTAIRE de l ecran ; l ecran lisait
///     `availableTrailsProvider`, soit le catalogue COMPILE. Un sentier decrit a
///     distance ne pouvait arriver chez un randonneur que par une republication au
///     magasin.
///
///  2. LE MANIFESTE NE POUVAIT PAS DECRIRE UN SENTIER. Il ne portait que du
///     versionnement : ni nom, ni region, ni distance. Un sentier connu du seul
///     distant etait donc INAFFICHABLE, quoi qu on branche.
///
///  3. LE « DELTA » ETAIT UN RECHARGEMENT INTEGRAL DEGUISE.
///     `_inferChangedTables(int from, int to)` rendait les sept tables en dur sans
///     lire ses deux parametres.
///
///  4. LA REVISION LOCALE N ETAIT JAMAIS REECRITE, alors que `needsUpdate` s en
///     sert pour decider : chaque ouverture retelechargeait tout.
///
///  5. UNE SUPPRESSION A DISTANCE NE POUVAIT PAS SE TRANSMETTRE. Un numero qui
///     monte ne dit pas une absence : un point d eau tari restait a vie.

// ---------------------------------------------------------------------------
// LE DOUBLE DU BUCKET
// ---------------------------------------------------------------------------

/// Reseau pilote a la main.
class FauxReseau extends ConnectivityMonitor {
  FauxReseau(this._statut);
  final ConnectivityStatus _statut;
  @override
  Future<ConnectivityStatus> checkStatus() async => _statut;
  @override
  Stream<ConnectivityStatus> get onStatusChange => Stream.value(_statut);
}

/// Fiche complete d un sentier que le binaire ne connait PAS.
const _ficheSentierInconnu = TrailManifestFiche(
  name: 'GR Aubrac',
  displayName: 'Traversee de l Aubrac',
  tagline: 'Le plateau, le vent, les burons',
  region: 'Aubrac',
  country: 'France',
  totalStages: 6,
  totalDistanceKm: 118.0,
  totalElevationGain: 2900,
  primaryColorValue: 0xFF6D4C41,
  secondaryColorValue: 0xFF0277BD,
  priceStages: 6,
  privacyPolicyUrl: 'https://exemple.org/aubrac/privacy',
  emergencyNumbers: [
    FicheNumeroSecours(name: 'Secours Aubrac', phone: '+33565000000'),
  ],
);

/// Le sentier NEUF, decrit entierement a distance, absent du binaire.
const _sentierDistantSeul = TrailManifestEntry(
  trailId: 'gr-aubrac',
  dataVersion: 3,
  hash: 'h-aubrac-3',
  filePath: 'gr_aubrac/v3.json',
  fileSize: 204_800,
  status: 'active',
  lastUpdated: '2026-09-27T20:00:00Z',
  fiche: _ficheSentierInconnu,
);

/// Un client HTTP qui sert le manifeste et les fichiers de donnees du double.
MockClient _faussesDonnees(Map<String, Object> parChemin) {
  return MockClient((requete) async {
    for (final entree in parChemin.entries) {
      if (requete.url.toString().contains(Uri.encodeComponent(entree.key)) ||
          requete.url.toString().contains(entree.key)) {
        return http.Response(
          jsonEncode(entree.value),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    }
    return http.Response('non trouve', 404);
  });
}

/// Manifeste tel qu il sera depose dans l espace de stockage.
Map<String, Object> _manifeste(List<TrailManifestEntry> entrees) => {
      'schemaVersion': 2,
      'trails': entrees.map((e) => e.toJson()).toList(),
    };

/// Une etape, dans le schema MONOLITHE (MODOP 603 §3.5) + sa revision.
Map<String, Object?> _etape({
  required String id,
  required int elevationGain,
  int? rev,
  bool supprime = false,
}) =>
    {
      'id': id,
      'itinerary_id': 'aubrac-i1',
      'stage_number': 1,
      'name_fr': 'Nasbinals - Aubrac',
      'name_en': 'Nasbinals - Aubrac',
      'name_de': 'Nasbinals - Aubrac',
      'name_it': 'Nasbinals - Aubrac',
      'name_es': 'Nasbinals - Aubrac',
      'start_lat': 44.66,
      'start_lng': 3.04,
      'end_lat': 44.63,
      'end_lng': 2.98,
      'distance_km': 14.0,
      'elevation_gain': elevationGain,
      'elevation_loss': 210,
      'duration_minutes': 240,
      'difficulty': 'moyen',
      if (rev != null) 'rev': rev,
      if (supprime) 'supprime': true,
    };

Map<String, Object?> _poi({
  required String id,
  int? rev,
  bool supprime = false,
}) =>
    {
      'id': id,
      'stage_id': 'aubrac-s1',
      'name_fr': 'Fontaine des Rajas',
      'name_en': 'Rajas spring',
      'name_de': 'Rajas-Quelle',
      'name_it': 'Fonte Rajas',
      'name_es': 'Fuente Rajas',
      'type': 'water',
      'lat': 44.65,
      'lng': 3.0,
      if (rev != null) 'rev': rev,
      if (supprime) 'supprime': true,
    };

void main() {
  // =========================================================================
  // 1. LES TROIS TESTS QUI COMPTENT
  // =========================================================================
  group('605 — l ordre des sources : distant, dernier recu, compile', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    ProviderContainer conteneur({
      required ConnectivityStatus reseau,
      Map<String, Object>? servi,
    }) {
      final reseauDouble = FauxReseau(reseau);
      return ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        connectivityMonitorProvider.overrideWithValue(reseauDouble),
        manifestServiceProvider.overrideWithValue(ManifestService(
          dao: TrailManifestsDao(db),
          connectivityMonitor: reseauDouble,
          httpClient: _faussesDonnees(servi ?? const {}),
        )),
      ]);
    }

    test('TEST 1 — UN SENTIER CONNU SEULEMENT DU DISTANT APPARAIT AU CATALOGUE, '
        'sans republication au magasin', () async {
      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: {'manifest.json': _manifeste([_sentierDistantSeul])},
      );
      addTearDown(c.dispose);

      // Le binaire ne connait PAS ce sentier : c est tout le sujet.
      expect(TrailCatalog.byId('gr-aubrac'), isNull,
          reason: 'si le compile le connaissait, le test ne prouverait rien');

      c.read(catalogueSentiersProvider); // declenche la lecture distante
      await _laisserLaLectureSeFaire(c);

      final catalogue = c.read(availableTrailsProvider);
      final aubrac = catalogue.where((s) => s.id == 'gr-aubrac');

      expect(aubrac, hasLength(1),
          reason: 'C EST LE CRITERE DE REUSSITE DU LOT : un sentier decrit '
              'entierement a distance doit arriver chez le randonneur sans '
              'passer par le magasin.');
      expect(aubrac.single.displayName, 'Traversee de l Aubrac');
      expect(aubrac.single.region, 'Aubrac');
      expect(aubrac.single.totalStages, 6);
      expect(aubrac.single.totalDistanceKm, 118.0);
      expect(aubrac.single.emergencyNumbers.single.phone, '+33565000000',
          reason: 'un sentier neuf apporte ses propres secours regionaux');
      expect(c.read(catalogueSentiersProvider).source,
          SourceDuCatalogue.distant);
    });

    test('TEST 2 — HORS LIGNE, LE CATALOGUE DEJA RECU RESTE ENTIER, y compris '
        'les sentiers que le binaire ne connait pas', () async {
      // Premier passage EN LIGNE : la liste est recue et conservee.
      final enLigne = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: {'manifest.json': _manifeste([_sentierDistantSeul])},
      );
      enLigne.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(enLigne);
      expect(enLigne.read(availableTrailsProvider).map((s) => s.id),
          contains('gr-aubrac'));
      enLigne.dispose();

      // Second passage HORS LIGNE, meme base : rien n est demande au reseau.
      final horsLigne = conteneur(reseau: ConnectivityStatusValues.offline);
      addTearDown(horsLigne.dispose);
      horsLigne.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(horsLigne);

      final etat = horsLigne.read(catalogueSentiersProvider);
      expect(etat.sentiers.map((s) => s.id), contains('gr-aubrac'),
          reason: 'le randonneur sans reseau GARDE le catalogue qu il avait — '
              'sans la conservation de la fiche, ce sentier disparaitrait');
      expect(etat.source, SourceDuCatalogue.dernierDistantRecu);
      expect(etat.echec, EchecDuCatalogue.horsLigne,
          reason: 'la cause est nommee pour que l ecran dise « liste non '
              'rafraichie » — ce n est PAS une panne');
      // Les sentiers compiles restent la eux aussi.
      for (final compile in TrailCatalog.all) {
        expect(etat.sentiers.map((s) => s.id), contains(compile.id));
      }
    });

    test('TEST 3 — PREMIERE OUVERTURE SANS RESEAU : le compile prend le relais, '
        'sans un mot d erreur et sans ecran vide', () async {
      final c = conteneur(reseau: ConnectivityStatusValues.offline);
      addTearDown(c.dispose);

      // AVANT toute attente : l etat initial est deja utilisable. C est la
      // raison d etre de l etat synchrone — aucun ecran n attend.
      final immediat = c.read(catalogueSentiersProvider);
      expect(immediat.sentiers, isNotEmpty);
      expect(immediat.source, SourceDuCatalogue.compile);
      expect(immediat.echec, isNull);

      await _laisserLaLectureSeFaire(c);

      final apres = c.read(catalogueSentiersProvider);
      expect(apres.sentiers.map((s) => s.id), TrailCatalog.ids,
          reason: 'les quatre sentiers embarques sont tous la : le lot '
              'precedent avait refuse de brancher precisement pour ne pas les '
              'remplacer par un ecran d erreur');
      expect(apres.source, SourceDuCatalogue.compile);
      expect(apres.sentiers, isNotEmpty,
          reason: 'JAMAIS d ecran vide quand un secours existe');
    });

    test('la liste distante INJOIGNABLE ne vide pas le catalogue et nomme sa '
        'cause', () async {
      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: const {}, // 404 sur tout : bucket non provisionne
      );
      addTearDown(c.dispose);

      c.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(c);

      final etat = c.read(catalogueSentiersProvider);
      expect(etat.sentiers, isNotEmpty,
          reason: 'l espace de stockage n existe pas encore : c est exactement '
              'l etat du produit aujourd hui, et le catalogue doit tenir');
      expect(etat.echec, EchecDuCatalogue.listeInjoignable);
      expect(etat.source, SourceDuCatalogue.compile);
    });

    test('LE DISTANT GAGNE SUR LES DONNEES d un sentier que le compile connait '
        'aussi, et l identifiant reste la cle', () async {
      final compile = TrailCatalog.all.first;
      final corrige = TrailManifestEntry(
        trailId: compile.id,
        dataVersion: 9,
        hash: 'h9',
        filePath: '${compile.id}/v9.json',
        fileSize: 1024,
        status: 'active',
        lastUpdated: '2026-09-27T20:00:00Z',
        fiche: TrailManifestFiche(
          name: compile.name,
          displayName: compile.displayName,
          tagline: compile.tagline,
          region: compile.region,
          country: compile.country,
          totalStages: compile.totalStages,
          totalDistanceKm: compile.totalDistanceKm,
          // LA CORRECTION SANS REPUBLICATION : un denivele faux se corrige a
          // distance. C est le second critere de reussite du lot.
          totalElevationGain: compile.totalElevationGain + 500,
        ),
      );

      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: {'manifest.json': _manifeste([corrige])},
      );
      addTearDown(c.dispose);
      c.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(c);

      final resolu = c
          .read(availableTrailsProvider)
          .where((s) => s.id == compile.id)
          .single;

      expect(resolu.totalElevationGain, compile.totalElevationGain + 500,
          reason: 'le distant est la source de verite sur les DONNEES');
      expect(resolu.gpxAssetPath, compile.gpxAssetPath,
          reason: 'mais le compile garde ses ASSETS : un manifeste ne peut pas '
              'inventer un fichier embarque dans le binaire');
      expect(c.read(availableTrailsProvider).where((s) => s.id == compile.id),
          hasLength(1),
          reason: 'un sentier present des deux cotes n est pas deux sentiers');
    });

    test('un sentier ARCHIVE a distance quitte le catalogue, meme s il est '
        'compile — le retrait est DIT, jamais par omission', () async {
      final compile = TrailCatalog.all.first;
      final retire = TrailManifestEntry(
        trailId: compile.id,
        dataVersion: 9,
        hash: 'h9',
        filePath: 'x.json',
        fileSize: 1,
        status: 'archived',
        lastUpdated: '2026-09-27T20:00:00Z',
      );

      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: {'manifest.json': _manifeste([retire])},
      );
      addTearDown(c.dispose);
      c.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(c);

      expect(c.read(availableTrailsProvider).map((s) => s.id),
          isNot(contains(compile.id)));
    });

    test('une entree SANS fiche et inconnue du binaire est ecartee, et elle est '
        'NOMMEE — jamais une carte vide', () async {
      const muette = TrailManifestEntry(
        trailId: 'sentier-sans-nom',
        dataVersion: 1,
        hash: 'h',
        filePath: 'x.json',
        fileSize: 1,
        status: 'active',
        lastUpdated: '2026-09-27T20:00:00Z',
      );

      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: {'manifest.json': _manifeste([muette])},
      );
      addTearDown(c.dispose);
      c.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(c);

      final etat = c.read(catalogueSentiersProvider);
      expect(etat.sentiers.map((s) => s.id),
          isNot(contains('sentier-sans-nom')));
      expect(etat.ignores, contains('sentier-sans-nom'),
          reason: 'un sentier silencieusement absent est indiagnosticable : '
              'la lecon de la tache 604');
    });

    test('un sentier venu du SEUL distant est resoluble comme sentier ACTIF',
        () async {
      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: {'manifest.json': _manifeste([_sentierDistantSeul])},
      );
      addTearDown(c.dispose);
      c.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(c);

      c.read(selectedTrailIdProvider.notifier).state = 'gr-aubrac';

      expect(c.read(resolvedTrailConfigProvider).id, 'gr-aubrac',
          reason: 'le resolveur ne lisait que le catalogue COMPILE : un '
              'randonneur choisissant un sentier distant etait silencieusement '
              'ramene sur le sentier par defaut, et tout le moteur suivait le '
              'mauvais sentier');
    });
  });

  // =========================================================================
  // 2. LA REVISION PORTEE PAR LA DONNEE
  // =========================================================================
  group('605 — une seule info de version, portee par la donnee', () {
    late AppDatabase db;
    late TrailManifestsDao manifestes;

    /// Service cable sur un double qui sert le fichier de donnees.
    DeltaUpdateService service(Map<String, Object> servi) => DeltaUpdateService(
          db: db,
          manifestService: ManifestService(
            dao: manifestes,
            connectivityMonitor: FauxReseau(ConnectivityStatusValues.online),
          ),
          trailManifestsDao: manifestes,
          trailMetaDao: TrailMetaDao(db),
          trailItinerariesDao: TrailItinerariesDao(db),
          trailStagesDao: TrailStagesDao(db),
          trailAccommodationsDao: TrailAccommodationsDao(db),
          trailPoisDao: TrailPoisDao(db),
          trailGpxTracksDao: TrailGpxTracksDao(db),
          trailGpxPointsDao: TrailGpxPointsDao(db),
          httpClient: _faussesDonnees(servi),
        );

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      manifestes = TrailManifestsDao(db);
    });
    tearDown(() async => db.close());

    Future<void> poserLeManifeste({int revision = 3}) {
      return manifestes.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('gr-aubrac'),
        dataVersion: Value(revision),
        hash: const Value('h'),
        filePath: const Value('gr_aubrac/v3.json'),
        fileSize: const Value(1024),
        status: const Value('active'),
        lastUpdated: const Value('2026-09-27T20:00:00Z'),
      ));
    }

    test('PREMIERE COPIE ET MISE A JOUR SONT LE MEME CHEMIN : a la revision '
        'zero, tout est plus recent, donc tout descend', () async {
      await poserLeManifeste();
      final svc = service({
        'gr_aubrac/v3.json': {
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 800, rev: 3)],
          'pois': [_poi(id: 'aubrac-p1', rev: 3)],
        },
      });

      expect(await svc.revisionLocale('gr-aubrac'),
          RevisionDeDonnee.revisionInitiale);

      final bilan = await svc.synchroniser(
        'gr-aubrac',
        'https://double/gr_aubrac/v3.json',
        revisionCible: 3,
      );

      expect(bilan.ecrits, 2);
      expect(bilan.famillesTouchees, ['stages', 'pois']);
      expect((await TrailStagesDao(db).getByItineraryId('aubrac-i1')),
          hasLength(1));
    });

    test('LE DEFAUT MESURE EST FERME : la revision locale est REELLEMENT '
        'REECRITE apres une copie reussie', () async {
      await poserLeManifeste();
      final svc = service({
        'gr_aubrac/v3.json': {
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 800, rev: 3)],
        },
      });

      expect(await manifestes.needsUpdate('gr-aubrac'), isTrue);

      await svc.synchroniser('gr-aubrac', 'https://double/gr_aubrac/v3.json',
          revisionCible: 3);

      expect(await svc.revisionLocale('gr-aubrac'), 3,
          reason: 'PERSONNE n ecrivait localVersion : `UpdateDownloader` '
              'recevait meme un TrailManifestsDao inutilise. Comme '
              '`needsUpdate` s en sert pour decider, chaque ouverture '
              'retelechargeait TOUT.');
      expect(await manifestes.needsUpdate('gr-aubrac'), isFalse,
          reason: 'sans cette ligne, l application retelechargeait a chaque '
              'demarrage');
    });

    test('UNE ALTITUDE CORRIGEE FAIT REDESCENDRE UNE ETAPE, PAS SEPT TABLES — '
        'c est la mort de `_inferChangedTables`', () async {
      await poserLeManifeste();
      // Etat initial : tout est a la revision 3.
      await service({
        'v3': {
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 800, rev: 3)],
          'pois': [_poi(id: 'aubrac-p1', rev: 3)],
        },
      }).synchroniser('gr-aubrac', 'https://double/v3', revisionCible: 3);

      // Revision 4 : SEULE l etape a bouge (denivele corrige). Le point
      // d interet est republie tel quel, avec son ancienne revision.
      final bilan = await service({
        'v4': {
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 915, rev: 4)],
          'pois': [_poi(id: 'aubrac-p1', rev: 3)],
        },
      }).synchroniser('gr-aubrac', 'https://double/v4', revisionCible: 4);

      expect(bilan.famillesTouchees, ['stages'],
          reason: 'AVANT : `_inferChangedTables(from, to)` rendait les sept '
              'tables en dur sans lire ses parametres, et le journal annoncait '
              'toujours « 7 tables a MAJ, 0 ignorees ».');
      expect(bilan.ecrits, 1);
      expect(bilan.supprimes, 0);

      final etape =
          (await TrailStagesDao(db).getByItineraryId('aubrac-i1')).single;
      expect(etape.elevationGain, 915, reason: 'la correction est bien posee');
      expect(etape.rev, 4, reason: 'la donnee porte sa propre revision');
    });

    test('rien de plus recent : rien n est reecrit', () async {
      await poserLeManifeste(revision: 3);
      final donnees = {
        'v3': {
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 800, rev: 3)],
        },
      };
      await service(donnees)
          .synchroniser('gr-aubrac', 'https://double/v3', revisionCible: 3);

      final bilan = await service(donnees)
          .synchroniser('gr-aubrac', 'https://double/v3', revisionCible: 3);

      expect(bilan.rienAFaire, isTrue);
      expect(bilan.famillesTouchees, isEmpty);
    });

    test('LE MARQUEUR DE SUPPRESSION : un point d eau retire a distance '
        'DISPARAIT du telephone', () async {
      await poserLeManifeste();
      await service({
        'v3': {
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 800, rev: 3)],
          'pois': [_poi(id: 'aubrac-p1', rev: 3)],
        },
      }).synchroniser('gr-aubrac', 'https://double/v3', revisionCible: 3);

      expect(await TrailPoisDao(db).getByStageId('aubrac-s1'), hasLength(1));

      // Revision 5 : le point d eau est tari. Il redescend avec sa revision ET
      // sa marque de suppression — une ABSENCE ne se transmet pas.
      final bilan = await service({
        'v5': {
          'pois': [
            {'id': 'aubrac-p1', 'rev': 5, 'supprime': true},
          ],
        },
      }).synchroniser('gr-aubrac', 'https://double/v5', revisionCible: 5);

      expect(bilan.supprimes, 1);
      expect(await TrailPoisDao(db).getByStageId('aubrac-s1'), isEmpty,
          reason: 'SANS marqueur de suppression, la correction de donnees ne '
              'marcherait que dans un sens : un point d eau tari, un refuge '
              'ferme resteraient A VIE sur le telephone du randonneur.');
      expect(await service(const {}).revisionLocale('gr-aubrac'), 5);
    });

    test('LA COPIE EST ATOMIQUE : une donnee invalide en cours de route ne '
        'laisse RIEN, et la revision n avance pas', () async {
      await poserLeManifeste();
      final svc = service({
        'casse': {
          // L etape passe, l hebergement est invalide (`lat` manquant) : la
          // transaction doit tout annuler.
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 800, rev: 3)],
          'accommodations': [
            {'id': 'a1', 'stage_id': 'aubrac-s1', 'rev': 3},
          ],
        },
      });

      await expectLater(
        svc.synchroniser('gr-aubrac', 'https://double/casse', revisionCible: 3),
        throwsA(anything),
      );

      expect(await TrailStagesDao(db).getByItineraryId('aubrac-i1'), isEmpty,
          reason: 'POINT 1 DE CHRISTOPHE : « il faut la copie du sentier sur le '
              'tel ». Un sentier a moitie copie ne doit jamais exister — sur le '
              'GR20 il n y a pas de reseau pour finir le travail.');
      expect(await svc.revisionLocale('gr-aubrac'),
          RevisionDeDonnee.revisionInitiale,
          reason: 'la revision ne doit pas certifier des donnees absentes');
    });

    test('une donnee SANS revision est rattachee a la revision du sentier — les '
        'fichiers deja deposes restent copiables', () async {
      await poserLeManifeste();
      final bilan = await service({
        'sansrev': {
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 800)],
        },
      }).synchroniser('gr-aubrac', 'https://double/sansrev', revisionCible: 3);

      expect(bilan.ecrits, 1);
      expect(
        (await TrailStagesDao(db).getByItineraryId('aubrac-i1')).single.rev,
        3,
      );
    });

    test('une famille inconnue de cette version de l application est ignoree, '
        'pas fatale', () async {
      await poserLeManifeste();
      final bilan = await service({
        'inconnue': {
          'stages': [_etape(id: 'aubrac-s1', elevationGain: 800, rev: 3)],
          'tuiles_de_carte': [
            {'id': 'x', 'rev': 3},
          ],
        },
      }).synchroniser('gr-aubrac', 'https://double/inconnue', revisionCible: 3);

      expect(bilan.famillesTouchees, ['stages']);
    });
  });

  // =========================================================================
  // 3. LES TROIS ETATS, ET LA SUPPRESSION INTERDITE SUR UN SENTIER ACHETE
  // =========================================================================
  group('605 — trois etats, deux gestes, et une interdiction', () {
    test('ETAT 1 — au catalogue, pas sur le telephone : on peut telecharger, '
        'il n y a rien a supprimer', () {
      const d = DisponibiliteDuSentier(
        trailId: 'gr-aubrac',
        copieComplete: false,
        achete: false,
      );
      expect(d.etat, EtatDuSentier.auCatalogue);
      expect(d.peutTelecharger, isTrue);
      expect(d.peutSupprimer, isFalse);
      expect(d.refusDeSuppression, RefusDeSuppression.pasSurLeTelephone,
          reason: 'un bouton indisponible doit DIRE pourquoi — pas etre grise '
              'sans explication');
    });

    test('ETAT 2 — telecharge, non achete : la suppression est PERMISE', () {
      const d = DisponibiliteDuSentier(
        trailId: 'gr-aubrac',
        copieComplete: true,
        achete: false,
      );
      expect(d.etat, EtatDuSentier.telecharge);
      expect(d.peutTelecharger, isFalse);
      expect(d.peutSupprimer, isTrue);
      expect(d.refusDeSuppression, isNull);
    });

    test('ETAT 3 — ACHETE : LA SUPPRESSION EST INTERDITE, et la cause est dite',
        () {
      const d = DisponibiliteDuSentier(
        trailId: 'gr-aubrac',
        copieComplete: true,
        achete: true,
      );
      expect(d.etat, EtatDuSentier.achete);
      expect(d.peutSupprimer, isFalse,
          reason: 'REGLE DE CHRISTOPHE, 27/09 20:41 : « on peut aussi le '
              'supprimer sauf si on l a achete ». Un randonneur ne doit pas '
              'pouvoir effacer, la veille du depart, ce qu il a paye et se '
              'retrouver sans donnees sur un sentier sans reseau.');
      expect(d.refusDeSuppression, RefusDeSuppression.sentierAchete);
    });

    test('TELECHARGER N EST PAS ACHETER : un sentier achete mais pas encore '
        'copie se telecharge, et reste deja insupprimable', () {
      const d = DisponibiliteDuSentier(
        trailId: 'gr-aubrac',
        copieComplete: false,
        achete: true,
      );
      expect(d.peutTelecharger, isTrue,
          reason: 'le niveau gratuit du modele eco (§2) consulte et PREPARE, et '
              'le sentier demo est gratuit et jouable : les deux verrous sont '
              'independants');
      expect(d.refusDeSuppression, RefusDeSuppression.sentierAchete,
          reason: 'l interdiction porte sur le DROIT acquis, pas sur la '
              'presence des fichiers');
    });

    // -----------------------------------------------------------------------
    // LE GESTE REEL, PAS SEULEMENT LA REGLE
    // -----------------------------------------------------------------------
    group('le geste de suppression passe par le notifier, et il refuse', () {
      late AppDatabase db;
      late TrailManifestsDao manifestes;

      setUp(() async {
        db = AppDatabase(NativeDatabase.memory());
        manifestes = TrailManifestsDao(db);
        // Sentier COPIE sur le telephone (revision locale au niveau publie).
        await manifestes.insertOrReplace(const TrailManifestsCompanion(
          trailId: Value('gr-aubrac'),
          dataVersion: Value(3),
          hash: Value('h'),
          filePath: Value('gr_aubrac/v3.json'),
          fileSize: Value(1024),
          status: Value('active'),
          lastUpdated: Value('2026-09-27T20:00:00Z'),
          localVersion: Value(3),
        ));
        await TrailMetaDao(db).insertOrReplace(const TrailMetaCompanion(
          id: Value('gr-aubrac'),
          code: Value('AUBRAC'),
          dataVersion: Value(3),
        ));
      });
      tearDown(() async => db.close());

      ProviderContainer conteneur({required Set<String> possedes}) {
        final reseau = FauxReseau(ConnectivityStatusValues.offline);
        return ProviderContainer(overrides: [
          databaseProvider.overrideWithValue(db),
          connectivityMonitorProvider.overrideWithValue(reseau),
          manifestServiceProvider.overrideWithValue(ManifestService(
            dao: manifestes,
            connectivityMonitor: reseau,
            httpClient: _faussesDonnees(const {}),
          )),
          ownedTrailIdsProvider.overrideWith((ref) async => possedes),
        ]);
      }

      test('UN SENTIER ACHETE RESISTE A UNE DEMANDE DE SUPPRESSION — et ses '
          'donnees sont toujours la apres le refus', () async {
        final c = conteneur(possedes: {'gr-aubrac'});
        addTearDown(c.dispose);

        await c.read(catalogStateProvider.future);
        final refus = await c
            .read(catalogStateProvider.notifier)
            .deleteTrailData('gr-aubrac');

        expect(refus, RefusDeSuppression.sentierAchete,
            reason: 'LA REGLE EST PORTEE PAR LE NOTIFIER, pas seulement par un '
                'bouton masque : un bouton protege le randonneur qui regarde '
                'l ecran, une garde ici protege ses donnees quel que soit '
                'l appelant.');
        expect(await TrailMetaDao(db).getById('gr-aubrac'), isNotNull,
            reason: 'les donnees du sentier paye ne doivent PAS avoir bouge');
        expect((await manifestes.getByTrailId('gr-aubrac'))!.localVersion, 3,
            reason: 'la revision locale reste : le sentier est toujours copie');
      });

      test('un sentier NON achete se supprime, et il redevient « a '
          'telecharger » — revision remise a zero', () async {
        final c = conteneur(possedes: const {});
        addTearDown(c.dispose);

        await c.read(catalogStateProvider.future);
        final refus = await c
            .read(catalogStateProvider.notifier)
            .deleteTrailData('gr-aubrac');

        expect(refus, isNull, reason: 'rien ne s y oppose');
        expect(await TrailMetaDao(db).getById('gr-aubrac'), isNull);
        expect((await manifestes.getByTrailId('gr-aubrac'))!.localVersion,
            isNull,
            reason: 'oublier la revision fait redescendre TOUT au prochain '
                'telechargement, par le meme chemin que la premiere copie');
        expect(await manifestes.needsUpdate('gr-aubrac'), isTrue);
      });
    });
  });
}

/// Laisse la lecture asynchrone du catalogue se terminer.
///
/// Le provider rend son etat de secours SYNCHRONEMENT puis ecrase l etat quand
/// les couches superieures arrivent : il faut donc rendre la main a la boucle
/// d evenements. Deux tours suffisent (lecture base, puis lecture reseau), on en
/// laisse davantage pour ne pas dependre du nombre exact d await.
Future<void> _laisserLaLectureSeFaire(ProviderContainer c) async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
