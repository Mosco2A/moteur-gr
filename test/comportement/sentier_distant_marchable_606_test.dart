import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/empreinte_de_publication.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/gpx_parser.dart';
import 'package:moteur_gr/core/geo/trace_du_sentier.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/source_de_donnees_sentier.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';
import 'package:moteur_gr/features/trail/providers/catalogue_sentiers_provider.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';

import '../fixtures/horodatage_de_serveur.dart';

/// LA REVISION N DEVIENT L INSTANT REFERENCE + N JOURS (tache 610).
///
/// Les relations d ordre que ce fichier verifie sont inchangees : `v(3) < v(4)`
/// dit exactement ce que `3 < 4` disait. Aucune assertion n est affaiblie.
HorodatageServeur v(int n) => aJPlus(n);

/// TACHE 606 — LA SECONDE MOITIE DU MUR N1 : UN SENTIER 100 % DISTANT EST
/// MARCHABLE.
///
/// CE QUE LE LOT 605 AVAIT LAISSE OUVERT, ET SON PREDECESSEUR L AVAIT NOMME AU
/// LIEU DE LE MASQUER. Le catalogue venait bien du reseau, la donnee portait bien
/// sa revision, la copie etait bien atomique — mais
/// `lib/features/map/providers/gpx_track_provider.dart` lisait la trace depuis les
/// ASSETS, c est-a-dire depuis le BINAIRE. Un sentier connu du SEUL distant
/// apparaissait donc au catalogue, ses donnees descendaient en base, ET SA TRACE
/// NE S AFFICHAIT PAS. Consultable, pas marchable.
///
/// LE CRITERE DE CHRISTOPHE, VERBATIM DU 27/09 19:57 : « Le principe de stepways
/// est justement de faire lire les donnees automatiquement a l appli pour que ca
/// affiche les nouveaux sentiers totalement decrits en base ».
///
/// TROIS DEFAUTS MESURES DANS LE DEPOT AVANT DE TOUCHER A QUOI QUE CE SOIT, ET
/// VERROUILLES ICI :
///
///  1. LA CARTE LISAIT LE BINAIRE. Un sentier absent des assets n avait aucune
///     source de trace, quelle que soit la quantite de donnees copiees en base.
///
///  2. LE GESTE « TELECHARGER » EMPRUNTAIT UN SECOND CHEMIN DE DESCENTE.
///     `CatalogNotifier.downloadTrail` appelait `TrailDownloadService`, que le lot
///     605 n avait pas touche : aucun `rev` lu ni ecrit, marqueurs de suppression
///     inseres comme des donnees, insertion famille par famille hors transaction,
///     et une URL RELATIVE passee a `Uri.parse`. La premiere copie et la mise a
///     jour etaient donc DEUX chemins, dont un qui ignorait le modele de revision.
///
///  3. L AMORCE DEGRADAIT LA TRACE QU ELLE POSAIT EN BASE. `SeedDataLoader`
///     ecrivait le resultat de Douglas-Peucker : 48 points poses pour 53 lus sur
///     `mare_a_mare_centre`. Faire lire la base en premier aurait donc fait PERDRE
///     5 points a un sentier embarque.
///
/// TOUT EST TESTE CONTRE UN DOUBLE. Ni Firestore ni Storage ne sont provisionnes
/// (decision du 27/09 20:11 : Firestore pour la liste et les donnees structurees
/// avec leurs revisions, Storage pour les fichiers lourds). Le double verrouille
/// donc AUSSI la forme exacte de ce qu il faudra deposer.

// ---------------------------------------------------------------------------
// LE DOUBLE
// ---------------------------------------------------------------------------

class _FauxReseau extends ConnectivityMonitor {
  _FauxReseau(this._statut);
  final ConnectivityStatus _statut;
  @override
  Future<ConnectivityStatus> checkStatus() async => _statut;
  @override
  Stream<ConnectivityStatus> get onStatusChange => Stream.value(_statut);
}

/// EMPREINTE DES OCTETS QUE LE DOUBLE SERT, PAR CHEMIN (tache 607).
///
/// Depuis la tache 607, l application VERIFIE l empreinte annoncee par la liste
/// publiee AVANT d ecrire quoi que ce soit (#X6, laisse ouvert par ce lot-ci).
/// Le double annonce donc l empreinte de ce qu il sert reellement — ce qui est
/// aussi la verite de la vraie chaine, ou la liste et le fichier sortent du MEME
/// outil (`tool/publier_sentier.dart`).
final Map<String, String> _empreintesServies = <String, String>{};

String _empreinteServie(String chemin) => _empreintesServies[chemin]!;

/// Client HTTP qui sert le manifeste et les fichiers de donnees du double.
MockClient _fauxStockage(Map<String, Object> parChemin, {List<int>? appels}) {
  for (final entree in parChemin.entries) {
    _empreintesServies[entree.key] = EmpreinteDePublication.duTexte(
      jsonEncode(entree.value),
    );
  }
  return MockClient((requete) async {
    appels?.add(1);
    for (final entree in parChemin.entries) {
      final url = requete.url.toString();
      if (url.contains(Uri.encodeComponent(entree.key)) ||
          url.contains(entree.key)) {
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

const _ficheAubrac = TrailManifestFiche(
  name: 'GR Aubrac',
  displayName: 'Traversee de l Aubrac',
  tagline: 'Le plateau, le vent, les burons',
  region: 'Aubrac',
  country: 'France',
  totalStages: 1,
  totalDistanceKm: 14.0,
  totalElevationGain: 800,
  priceStages: 6,
);

/// Le sentier NEUF : decrit entierement a distance, ABSENT des assets.
///
/// SON EMPREINTE EST CELLE DU FICHIER QU ON SERT (tache 607). Elle valait
/// « h-aubrac-3 » tant que personne ne la verifiait ; elle est maintenant
/// calculee sur les octets du fichier de donnees, comme la produirait
/// `tool/publier_sentier.dart`.
final _entreeAubrac = TrailManifestEntry(
  trailId: 'gr-aubrac',
  dataVersion: v(3),
  hash: EmpreinteDePublication.duTexte(jsonEncode(_donneesAubrac())),
  filePath: 'gr_aubrac/v3.json',
  fileSize: 4096,
  status: 'active',
  lastUpdated: '2026-09-27T20:00:00Z',
  fiche: _ficheAubrac,
);

Map<String, Object> _manifeste(List<TrailManifestEntry> entrees) => {
  'schemaVersion': 2,
  'trails': entrees.map((e) => e.toJson()).toList(),
};

Map<String, Object?> _etape({int elevationGain = 800, int rev = 3}) => {
  'id': 'aubrac-s1',
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
  'rev': v(rev).iso8601,
};

Map<String, Object?> _itineraire({int rev = 3}) => {
  'id': 'aubrac-i1',
  'trail_id': 'gr-aubrac',
  'code': 'AUBRAC-NS',
  'name_fr': 'Aubrac nord-sud',
  'name_en': 'Aubrac north-south',
  'name_de': 'Aubrac Nord-Sud',
  'name_it': 'Aubrac nord-sud',
  'name_es': 'Aubrac norte-sur',
  'distance_km': 14.0,
  'elevation_gain': 800,
  'stage_count': 1,
  'rev': v(rev).iso8601,
};

Map<String, Object?> _poi({
  String id = 'aubrac-p1',
  int rev = 3,
  bool supprime = false,
}) => {
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
  if (rev > 0) 'rev': v(rev).iso8601,
  if (supprime) 'supprime': true,
};

/// La TRACE du sentier distant : l entete et ses points.
Map<String, Object?> _trace({int rev = 3}) => {
  'id': 'aubrac-t1',
  'itinerary_id': 'aubrac-i1',
  'name': 'Trace Aubrac nord-sud',
  'rev': v(rev).iso8601,
};

List<Map<String, Object?>> _pointsDeTrace({int nombre = 5, int rev = 3}) => [
  for (var i = 0; i < nombre; i++)
    {
      'track_id': 'aubrac-t1',
      'sequence_index': i,
      'lat': 44.66 - i * 0.01,
      'lng': 3.04 - i * 0.01,
      'elevation': 1100.0 + i * 10,
      'rev': v(rev).iso8601,
    },
];

/// Le fichier de donnees COMPLET du sentier distant (les cinq familles utiles).
Map<String, Object> _donneesAubrac({
  int revision = 3,
  int elevationGain = 800,
  List<Map<String, Object?>>? pois,
}) => {
  'trail_meta': {
    'id': 'gr-aubrac',
    'code': 'AUBRAC',
    'data_version': v(revision).iso8601,
    'status': 'active',
    'rev': v(revision).iso8601,
  },
  'itineraries': [_itineraire()],
  'stages': [_etape(elevationGain: elevationGain, rev: revision)],
  'pois': pois ?? [_poi()],
  'gpx_tracks': [_trace()],
  'gpx_points': _pointsDeTrace(),
};

void main() {
  // rootBundle : le secours asset des sentiers embarques est lu pour de vrai.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TrailManifestsDao manifestes;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    manifestes = TrailManifestsDao(db);
  });
  tearDown(() async => db.close());

  DeltaUpdateService serviceAvec({
    Map<String, Object> servi = const {},
    SourceDeDonneesSentier? source,
    List<int>? appels,
  }) => DeltaUpdateService(
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
    source: source,
    httpClient: _fauxStockage(servi, appels: appels),
  );

  ProviderContainer conteneur({
    required ConnectivityStatus reseau,
    Map<String, Object> servi = const {},
  }) {
    final reseauDouble = _FauxReseau(reseau);
    final http = _fauxStockage(servi);
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        connectivityMonitorProvider.overrideWithValue(reseauDouble),
        manifestServiceProvider.overrideWithValue(
          ManifestService(
            dao: manifestes,
            connectivityMonitor: reseauDouble,
            httpClient: http,
          ),
        ),
        deltaUpdateServiceProvider.overrideWith(
          (ref) => serviceAvec(servi: servi),
        ),
      ],
    );
  }

  // =========================================================================
  // 1. LE TEST D ACCEPTATION DE CHRISTOPHE
  // =========================================================================
  group('606 — un sentier 100 % distant est MARCHABLE', () {
    test(
      'LE TEST D ACCEPTATION : un sentier absent des assets, decrit '
      'entierement a distance (fiche, etapes, POI, TRACE), apparait au '
      'catalogue, se telecharge, s ouvre, ET SA TRACE S AFFICHE SUR LA CARTE',
      () async {
        final c = conteneur(
          reseau: ConnectivityStatusValues.online,
          servi: {
            'manifest.json': _manifeste([_entreeAubrac]),
            'gr_aubrac/v3.json': _donneesAubrac(),
          },
        );
        addTearDown(c.dispose);

        // PREMISSE DU TEST : le binaire ne connait PAS ce sentier, et il n a
        // AUCUN fichier embarque. Sans cela le test ne prouverait rien.
        expect(TrailCatalog.byId('gr-aubrac'), isNull);

        // --- 1. IL APPARAIT AU CATALOGUE (acquis du lot 605) ---
        c.read(catalogueSentiersProvider);
        await _laisserLaLectureSeFaire(c);
        final auCatalogue = c
            .read(availableTrailsProvider)
            .where((s) => s.id == 'gr-aubrac');
        expect(auCatalogue, hasLength(1));
        expect(
          auCatalogue.single.gpxAssetPath,
          isEmpty,
          reason:
              'une liste distante ne peut pas inventer un fichier embarque '
              '(#F14) : c est precisement pourquoi la carte devait changer de '
              'source',
        );

        // --- 2. IL SE TELECHARGE, PAR LE CHEMIN UNIQUE ---
        await c.read(catalogStateProvider.future);
        await c
            .read(catalogStateProvider.notifier)
            .downloadTrail(
              'gr-aubrac',
              niveau: NiveauDeTelechargement.realiser,
            );

        expect(
          await manifestes.needsUpdate('gr-aubrac'),
          isFalse,
          reason:
              'la revision locale est inscrite DANS la transaction de la '
              'pose, sinon chaque ouverture retelechargerait tout',
        );
        expect(
          (await TrailGpxPointsDao(db).getByTrackId('aubrac-t1')),
          hasLength(5),
          reason:
              'la TRACE est copiee en base comme le reste : c est la '
              'famille gpx_points',
        );

        // --- 3. IL S OUVRE : le moteur suit le sentier choisi ---
        c.read(selectedTrailIdProvider.notifier).state = 'gr-aubrac';
        expect(c.read(trailConfigProvider).id, 'gr-aubrac');

        // --- 4. ET SA TRACE S AFFICHE SUR LA CARTE. C EST LE MUR. ---
        final points = await c.read(gpxTrackProvider('gr-aubrac').future);
        expect(
          points,
          hasLength(5),
          reason:
              'AVANT CE LOT : `GpxParser.parseFromAsset("")` — la carte '
              'allait chercher la trace dans le BINAIRE, donc un sentier connu '
              'du seul distant n avait AUCUNE source de trace. Il etait '
              'consultable et pas MARCHABLE.',
        );
        expect(points.first.altitude, 1100.0);
        expect(
          points.last.distanceFromStart,
          greaterThan(0),
          reason:
              'la distance cumulee est calculee a la lecture : la base ne '
              'la stocke pas',
        );

        final trace = await c.read(traceDuSentierProvider('gr-aubrac').future);
        expect(
          trace.source,
          SourceDeLaTrace.base,
          reason: 'et elle vient de la BASE, pas d un asset de complaisance',
        );
      },
    );

    test('LES QUATRE SENTIERS EMBARQUES NE PERDENT RIEN : base vide, la trace '
        'compilee est lue comme avant', () async {
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );
      addTearDown(c.dispose);

      final points = await c.read(gpxTrackProvider(testTrailConfig.id).future);
      expect(
        points,
        hasLength(27),
        reason:
            'les 27 points de assets/gpx/test_trail.gpx, exactement '
            'comme avant le branchement',
      );

      final trace = await c.read(
        traceDuSentierProvider(testTrailConfig.id).future,
      );
      expect(
        trace.source,
        SourceDeLaTrace.assetCompile,
        reason: 'l asset est le SECOURS, et il sert quand la base n a rien',
      );
    });

    test('L ALLER-RETOUR BASE/ASSET EST NEUTRE : la trace posee en base rend '
        'les MEMES points que l asset, au point pres', () async {
      // LA MESURE QUI A IMPOSE LA CORRECTION DE L AMORCE. Le semeur posait le
      // resultat de Douglas-Peucker : 48 points pour 53 lus sur
      // mare_a_mare_centre. Faire lire la base en premier aurait DEGRADE un
      // sentier embarque — exclu, non negociable.
      final duFichier = await GpxParser.parseFromAsset(
        'assets/data/mare_a_mare_centre/track.gpx',
      );
      expect(duFichier, hasLength(53), reason: 'temoin de la mesure');

      // On pose en base ce que le semeur pose desormais : la trace ENTIERE.
      await TrailGpxTracksDao(db).insertOrReplace(
        const TrailGpxTracksCompanion(
          id: Value('mare-a-mare-centre'),
          itineraryId: Value('mare-a-mare-centre'),
          name: Value('Mare a Mare Centre'),
        ),
      );
      await TrailGpxPointsDao(db).insertAll([
        for (var i = 0; i < duFichier.length; i++)
          TrailGpxPointsCompanion(
            trackId: const Value('mare-a-mare-centre'),
            lat: Value(duFichier[i].lat),
            lng: Value(duFichier[i].lng),
            elevation: Value(duFichier[i].altitude),
            sequenceIndex: Value(i),
          ),
      ]);

      final deLaBase = await LecteurDeTrace(db: db).lire(
        trailId: 'mare-a-mare-centre',
        cheminAsset: 'assets/data/mare_a_mare_centre/track.gpx',
      );

      expect(deLaBase.source, SourceDeLaTrace.base);
      expect(
        deLaBase.points,
        hasLength(duFichier.length),
        reason:
            'AUCUN point perdu : c est la condition non negociable du '
            'branchement',
      );
      for (var i = 0; i < duFichier.length; i++) {
        expect(deLaBase.points[i].lat, duFichier[i].lat);
        expect(deLaBase.points[i].lng, duFichier[i].lng);
        expect(deLaBase.points[i].altitude, duFichier[i].altitude);
        expect(
          deLaBase.points[i].distanceFromStart,
          closeTo(duFichier[i].distanceFromStart, 0.01),
          reason:
              'la distance cumulee est recalculee, elle doit retomber '
              'sur celle du parseur',
        );
      }
    });

    test(
      'UN SENTIER AU CATALOGUE MAIS PAS ENCORE COPIE : l absence est NOMMEE, '
      'pas jetee ni deguisee en carte vide',
      () async {
        final trace = await LecteurDeTrace(
          db: db,
        ).lire(trailId: 'gr-aubrac', cheminAsset: '');

        expect(trace.source, SourceDeLaTrace.aucune);
        expect(
          trace.estVide,
          isTrue,
          reason:
              'l ecran carte sait deja traiter une trace vide '
              '(`t.map.noTrack`) : c est un etat, pas une panne',
        );
      },
    );

    test(
      'L ASSET DECLARE QUI NE SE LIT PAS RESTE UNE ERREUR — mesure : '
      'gr-pyrenees declare un fichier qui N EXISTE PAS dans le depot',
      () async {
        await expectLater(
          LecteurDeTrace(db: db).lire(
            trailId: 'gr-pyrenees',
            cheminAsset: 'assets/gpx/gr_pyrenees.gpx',
          ),
          throwsA(anything),
          reason:
              'la carte affiche « impossible de charger la trace » avec un '
              'bouton reessayer dans ce cas, et avaler l echec transformerait un '
              'fichier manquant en carte silencieusement vide',
        );
      },
    );
  });

  // =========================================================================
  // 2. LE TRANSFERT UNITAIRE — « DONNE-MOI CE QUI DEPASSE MA REVISION »
  // =========================================================================
  group('606 — le transfert unitaire', () {
    Future<void> poserLeManifeste({int revision = 3}) {
      return manifestes.insertOrReplace(
        TrailManifestsCompanion(
          trailId: const Value('gr-aubrac'),
          dataVersion: Value(v(revision)),
          hash: const Value('h'),
          filePath: const Value('gr_aubrac/v3.json'),
          fileSize: const Value(4096),
          status: const Value('active'),
          lastUpdated: const Value('2026-09-27T20:00:00Z'),
        ),
      );
    }

    test('UNE SOURCE INTERROGEABLE NE FAIT DESCENDRE QUE L ENREGISTREMENT '
        'CORRIGE — une etape, pas un fichier de sentier', () async {
      await poserLeManifeste();

      // Etat initial a la revision 3, par le chemin du fichier entier.
      await serviceAvec(servi: {'v3': _donneesAubrac()}).synchroniser(
        'gr-aubrac',
        'https://double/v3',
        niveau: NiveauDeTelechargement.realiser,
        revisionCible: v(3),
        empreinteAttendue: _empreinteServie('v3'),
      );
      expect(await TrailGpxPointsDao(db).getAll(), hasLength(5));

      // Revision 4 : SEULE l altitude de l etape a bouge. La source
      // interrogeable pose la question au serveur, famille par famille.
      final interrogees = <String>[];
      final source = SourceInterrogeable((trailId, famille, revMin) async {
        interrogees.add('$trailId/$famille>${revMin.iso8601}');
        if (famille != MorceauxDeSentier.etapes) return const [];
        return [Map<String, dynamic>.from(_etape(elevationGain: 915, rev: 4))];
      });

      final aPrendre = await source.depuisLaRevision(
        'gr-aubrac',
        adresse: 'ignoree',
        revisionLocale: v(3),
        famillesDemandees: MorceauxDeSentier.tous,
        revisionCible: v(4),
      );

      expect(
        aPrendre.transferes,
        1,
        reason:
            'C EST LE TRANSFERT UNITAIRE : un seul enregistrement a '
            'traverse le reseau. Avec un fichier entier, les 10 '
            'enregistrements du sentier descendent pour en retenir 1.',
      );
      expect(aPrendre.retenus, 1);
      expect(aPrendre.transferesEnTrop, 0);
      expect(
        interrogees,
        hasLength(MorceauxDeSentier.tous.length),
        reason: 'une question par famille, toutes familles comprises',
      );
      // LA QUESTION PORTE L INSTANT DU TELEPHONE, ET SON PERIMETRE EST LE
      // SENTIER : `trailId` est le premier parametre de la requete, donc elle ne
      // peut pas partir sur tout le catalogue (perimetre precise par Christophe,
      // 28/09 — tache 610).
      expect(interrogees, contains('gr-aubrac/gpx_points>${v(3).iso8601}'));

      // Et la POSE ne change pas d une ligne : c est le code du lot 605.
      final bilan = await serviceAvec(source: source).synchroniser(
        'gr-aubrac',
        'ignoree',
        niveau: NiveauDeTelechargement.realiser,
        revisionCible: v(4),
        // UNE SOURCE INTERROGEABLE NE RECOIT PAS DE FICHIER : il n y a rien
        // dont l empreinte du fichier publie pourrait certifier l integrite, et
        // le dire vaut mieux que de l ignorer en silence.
        empreinteAttendue: null,
      );
      expect(bilan.famillesTouchees, [MorceauxDeSentier.etapes]);
      expect(bilan.ecrits, 1);
      expect(
        (await TrailStagesDao(
          db,
        ).getByItineraryId('aubrac-i1')).single.elevationGain,
        915,
      );
      expect(
        await TrailGpxPointsDao(db).getAll(),
        hasLength(5),
        reason: 'la trace n a pas bouge : elle est restee a la revision 3',
      );
    });

    test('LE MEME RESULTAT PAR LES DEUX SOURCES, ET LA DIFFERENCE EST EN '
        'OCTETS — pas en comportement', () async {
      // La mesure du lot 605, verrouillee : « le modele de revision tourne a
      // l identique sur les deux, la difference est en octets ». On le prouve au
      // lieu de l affirmer.
      final fichier = SourceFichierEntier(
        httpClient: _fauxStockage({'v4': _donneesAubrac(revision: 4)}),
      );
      final parFichier = await fichier.depuisLaRevision(
        'gr-aubrac',
        adresse: 'https://double/v4',
        revisionLocale: v(3),
        famillesDemandees: MorceauxDeSentier.tous,
        revisionCible: v(4),
        empreinteAttendue: _empreinteServie('v4'),
      );

      final interrogeable = SourceInterrogeable((
        trailId,
        famille,
        revMin,
      ) async {
        final donnees = _donneesAubrac(revision: 4);
        final brut = donnees[famille];
        final tous = <Map<String, dynamic>>[
          if (brut is Map<String, dynamic>) brut,
          if (brut is List)
            ...brut.map((e) => Map<String, dynamic>.from(e as Map)),
        ];
        // LE DOUBLE INTERROGEABLE COMPARE DES INSTANTS, comme le ferait
        // `where('rev','>',Timestamp)` cote Firestore : un horodatage se compare
        // NATIVEMENT, ce qu un compteur n obtenait qu au prix d une coordination
        // entre producteurs (tache 610).
        return tous
            .where(
              (e) =>
                  (HorodatageServeur.annonceParLeServeur(e['rev']) ?? v(4)) >
                  revMin,
            )
            .toList();
      });
      final parRequete = await interrogeable.depuisLaRevision(
        'gr-aubrac',
        adresse: 'ignoree',
        revisionLocale: v(3),
        famillesDemandees: MorceauxDeSentier.tous,
        revisionCible: v(4),
      );

      expect(
        parRequete.parFamille.keys,
        parFichier.parFamille.keys,
        reason: 'MEME comportement : les memes familles sont retenues',
      );
      expect(parRequete.retenus, parFichier.retenus);
      expect(
        parFichier.octetsRecus,
        greaterThan(0),
        reason: 'le fichier entier a un cout en octets, et on le MESURE',
      );
      expect(
        parRequete.octetsRecus,
        0,
        reason: 'la source interrogeable ne transfere pas de fichier',
      );
    });

    test('RIEN DE PLUS RECENT : la source ne retient rien et la pose n ecrit '
        'rien', () async {
      await poserLeManifeste();
      await serviceAvec(servi: {'v3': _donneesAubrac()}).synchroniser(
        'gr-aubrac',
        'https://double/v3',
        niveau: NiveauDeTelechargement.realiser,
        revisionCible: v(3),
        empreinteAttendue: _empreinteServie('v3'),
      );

      final bilan = await serviceAvec(servi: {'v3': _donneesAubrac()})
          .synchroniser(
            'gr-aubrac',
            'https://double/v3',
            niveau: NiveauDeTelechargement.realiser,
            revisionCible: v(3),
            empreinteAttendue: _empreinteServie('v3'),
          );

      expect(bilan.rienAFaire, isTrue);
      expect(bilan.famillesTouchees, isEmpty);
    });

    test('LE MARQUEUR DE SUPPRESSION : un point d eau retire a distance '
        'DISPARAIT du telephone', () async {
      await poserLeManifeste();
      await serviceAvec(servi: {'v3': _donneesAubrac()}).synchroniser(
        'gr-aubrac',
        'https://double/v3',
        niveau: NiveauDeTelechargement.realiser,
        revisionCible: v(3),
        empreinteAttendue: _empreinteServie('v3'),
      );
      expect(await TrailPoisDao(db).getByStageId('aubrac-s1'), hasLength(1));

      final bilan =
          await serviceAvec(
            servi: {
              'v5': _donneesAubrac(
                revision: 3,
                pois: [
                  {'id': 'aubrac-p1', 'rev': v(5).iso8601, 'supprime': true},
                ],
              ),
            },
          ).synchroniser(
            'gr-aubrac',
            'https://double/v5',
            niveau: NiveauDeTelechargement.realiser,
            revisionCible: v(5),
            empreinteAttendue: _empreinteServie('v5'),
          );

      expect(bilan.supprimes, 1);
      expect(
        await TrailPoisDao(db).getByStageId('aubrac-s1'),
        isEmpty,
        reason:
            'un numero qui monte ne transmet pas une ABSENCE : sans le '
            'marqueur, un point d eau tari resterait A VIE sur le telephone',
      );
    });

    test('LE TRANSFERT EST REPRIS TROIS FOIS, PUIS L ECHEC EST FRANC : rien en '
        'base, revision inchangee', () async {
      await poserLeManifeste();
      final appels = <int>[];
      final svc = serviceAvec(servi: const {}, appels: appels); // 404 sur tout

      await expectLater(
        svc.synchroniser(
          'gr-aubrac',
          'https://double/absent',
          niveau: NiveauDeTelechargement.realiser,
          revisionCible: v(3),
          empreinteAttendue: EmpreinteDePublication.duTexte(
            jsonEncode(_donneesAubrac()),
          ),
        ),
        throwsA(anything),
      );

      expect(
        appels,
        hasLength(3),
        reason:
            'la reprise sur echec reseau etait la seule chose que le '
            'second chemin de descente apportait de plus : elle est reprise '
            'ici, donc pour la premiere copie COMME pour une mise a jour',
      );
      expect(await TrailStagesDao(db).getByItineraryId('aubrac-i1'), isEmpty);
      expect(
        (await manifestes.getByTrailId('gr-aubrac'))!.localVersion,
        isNull,
        reason:
            'la revision locale n avance pas : le sentier reste « a '
            'prendre » plutot qu a moitie copie (#C1)',
      );
    });

    test('PREMIERE COPIE ET MISE A JOUR SONT LE MEME CHEMIN : le geste '
        '« telecharger » passe par la synchronisation, pas par un second '
        'service', () async {
      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: {
          'manifest.json': _manifeste([_entreeAubrac]),
          'gr_aubrac/v3.json': _donneesAubrac(),
        },
      );
      addTearDown(c.dispose);

      await c.read(catalogStateProvider.future);
      await c
          .read(catalogStateProvider.notifier)
          .downloadTrail('gr-aubrac', niveau: NiveauDeTelechargement.realiser);

      // LA PREUVE QUE LE CHEMIN A CHANGE : `rev` est ECRIT sur chaque
      // enregistrement. L ancien `TrailDownloadService` n en ecrivait aucun,
      // donc la premiere mise a jour reprenait TOUT.
      final etape = (await TrailStagesDao(
        db,
      ).getByItineraryId('aubrac-i1')).single;
      expect(
        etape.rev,
        v(3),
        reason:
            'le second chemin de descente ecrivait rev = NULL sur les '
            'sept familles : le versionnage unitaire etait donc mort des la '
            'premiere copie',
      );
      expect((await TrailGpxPointsDao(db).getAll()).first.rev, v(3));
      expect(await manifestes.needsUpdate('gr-aubrac'), isFalse);
    });

    test(
      'A LA REVISION ZERO TOUT DESCEND, ET C EST LA MEME QUESTION',
      () async {
        final source = SourceFichierEntier(
          httpClient: _fauxStockage({'v3': _donneesAubrac()}),
        );
        final aPrendre = await source.depuisLaRevision(
          'gr-aubrac',
          adresse: 'https://double/v3',
          revisionLocale: RevisionDeDonnee.revisionInitiale,
          famillesDemandees: MorceauxDeSentier.tous,
          revisionCible: v(3),
          empreinteAttendue: _empreinteServie('v3'),
        );

        expect(
          aPrendre.retenus,
          10,
          reason:
              '1 fiche + 1 itineraire + 1 etape + 1 POI + 1 entete de '
              'trace + 5 points de trace = 10, tous plus recents que la '
              'revision zero',
        );
        expect(
          aPrendre.transferesEnTrop,
          0,
          reason:
              'a la premiere copie, un fichier entier ne transfere rien '
              'pour rien : c est la mise a jour qui coute',
        );
        expect(
          aPrendre.parFamille.keys,
          MorceauxDeSentier.tous.where(
            (f) => f != MorceauxDeSentier.hebergements,
          ),
          reason:
              'les six familles publiees, DANS L ORDRE DES CLES '
              'ETRANGERES ; ce sentier ne declare pas d hebergement, et une '
              'famille absente est absente — pas vide, pas fatale',
        );
      },
    );
  });

  // =========================================================================
  // 3. HORS LIGNE
  // =========================================================================
  group('606 — hors ligne, ce qui est deja la reste entier', () {
    test('HORS LIGNE, LA TRACE D UN SENTIER DISTANT DEJA COPIE S AFFICHE '
        'TOUJOURS — c est la raison d etre du produit', () async {
      // Premier passage EN LIGNE : catalogue lu, sentier telecharge.
      final enLigne = conteneur(
        reseau: ConnectivityStatusValues.online,
        servi: {
          'manifest.json': _manifeste([_entreeAubrac]),
          'gr_aubrac/v3.json': _donneesAubrac(),
        },
      );
      enLigne.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(enLigne);
      await enLigne.read(catalogStateProvider.future);
      await enLigne
          .read(catalogStateProvider.notifier)
          .downloadTrail('gr-aubrac', niveau: NiveauDeTelechargement.realiser);
      enLigne.dispose();

      // Second passage HORS LIGNE, MEME base : rien n est demande au reseau.
      final horsLigne = conteneur(reseau: ConnectivityStatusValues.offline);
      addTearDown(horsLigne.dispose);
      horsLigne.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(horsLigne);

      expect(
        horsLigne.read(availableTrailsProvider).map((s) => s.id),
        contains('gr-aubrac'),
        reason: 'la fiche conservee tient le catalogue hors ligne (lot 605)',
      );

      horsLigne.read(selectedTrailIdProvider.notifier).state = 'gr-aubrac';
      final points = await horsLigne.read(gpxTrackProvider('gr-aubrac').future);
      expect(
        points,
        hasLength(5),
        reason:
            'la trace est EN BASE : le randonneur sans reseau, sur le '
            'sentier, voit sa trace',
      );

      final trace = await horsLigne.read(
        traceDuSentierProvider('gr-aubrac').future,
      );
      expect(trace.source, SourceDeLaTrace.base);
    });
  });
}

/// Laisse la lecture asynchrone du catalogue se terminer.
///
/// Le provider rend son etat de secours SYNCHRONEMENT puis ecrase l etat quand
/// les couches superieures arrivent : il faut rendre la main a la boucle
/// d evenements.
Future<void> _laisserLaLectureSeFaire(ProviderContainer c) async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
