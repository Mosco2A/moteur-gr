import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/delta_update.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/update_checker.dart';
import 'package:moteur_gr/core/services/update_downloader.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';

import '../../fixtures/horodatage_de_serveur.dart';

/// LA REVISION N DEVIENT L INSTANT REFERENCE + N JOURS (tache 610).
HorodatageServeur v(int n) => aJPlus(n);

/// Fake ConnectivityMonitor pour les tests (toujours online).
class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;

  void setStatus(ConnectivityStatus status) => _status = status;

  @override
  Future<ConnectivityStatus> checkStatus() async => _status;
}

/// Fake FirebaseService pour les tests.
class FakeFirebaseService extends FirebaseService {
  FakeFirebaseService({required bool available})
    : super.testOnly(isAvailable: available);
}

/// Fake UpdateChecker qui retourne des resultats predetermines.
class FakeUpdateChecker extends UpdateChecker {
  FakeUpdateChecker({
    required super.dao,
    required super.connectivityMonitor,
    required super.firebaseService,
    this.fakeResults = const [],
  });

  final List<UpdateCheckResult> fakeResults;

  @override
  Future<List<UpdateCheckResult>> checkAllForUpdates() async {
    return fakeResults;
  }
}

/// Fake ManifestService qui retourne un manifeste predetermine.
class FakeManifestService extends ManifestService {
  FakeManifestService({
    required super.dao,
    required super.connectivityMonitor,
    this.fakeManifest,
  });

  final TrailManifest? fakeManifest;

  @override
  Future<TrailManifest?> fetchManifest(String url) async => fakeManifest;
}

/// Fake DeltaUpdateService qui trace les appels.
class FakeDeltaUpdateService extends DeltaUpdateService {
  FakeDeltaUpdateService({
    required super.db,
    required super.manifestService,
    required super.trailManifestsDao,
    required super.trailMetaDao,
    required super.trailItinerariesDao,
    required super.trailStagesDao,
    required super.trailAccommodationsDao,
    required super.trailPoisDao,
    required super.trailGpxTracksDao,
    required super.trailGpxPointsDao,
    this.fakeDelta,
  });

  final DeltaUpdate? fakeDelta;

  /// Bilan que la fausse synchronisation rendra.
  ResultatSynchronisation bilan = const ResultatSynchronisation(
    famillesTouchees: [],
    ecrits: 0,
    supprimes: 0,
    revisionAtteinte: HorodatageServeur.origine,
  );

  /// L instant cible demande lors de la derniere synchronisation.
  HorodatageServeur? derniereRevisionCible;

  /// URL demandee lors de la derniere synchronisation.
  String? lastDeltaUrl;

  /// Nombre d appels a synchroniser.
  int downloadCallCount = 0;

  @override
  Future<DeltaUpdate?> checkForUpdates(
    String trailId, {
    required TrailManifest remoteManifest,
  }) async {
    return fakeDelta;
  }

  /// Derniere empreinte annoncee au service (tache 607).
  ///
  /// Elle doit venir de la liste DISTANTE : c est l empreinte que le SERVEUR
  /// annonce pour le fichier qu on va chercher, pas celle du cache local.
  String? derniereEmpreinteAttendue;

  /// Dernier niveau demande au service (tache 616).
  ///
  /// C est ce que le test affirme : la cadence resynchronise chaque sentier AU
  /// NIVEAU OU IL EST DEJA DESCENDU, et ne monte jamais de niveau toute seule.
  NiveauDeTelechargement? dernierNiveauDemande;

  @override
  Future<ResultatSynchronisation> synchroniser(
    String trailId,
    String urlDonnees, {
    required HorodatageServeur revisionCible,
    required String? empreinteAttendue,
    required NiveauDeTelechargement niveau,
    HorodatageServeur? revisionLocaleConnue,
  }) async {
    downloadCallCount++;
    lastDeltaUrl = urlDonnees;
    derniereRevisionCible = revisionCible;
    derniereEmpreinteAttendue = empreinteAttendue;
    dernierNiveauDemande = niveau;
    return bilan;
  }
}

/// Tests du service UpdateDownloader (telechargement delta background,
/// E4.11c). Fixtures neutres : sentier fictif volcans.
void main() {
  late AppDatabase db;
  late TrailManifestsDao dao;
  late FakeConnectivityMonitor connectivity;
  late FakeFirebaseService firebase;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailManifestsDao(db);
    connectivity = FakeConnectivityMonitor();
    firebase = FakeFirebaseService(available: true);
  });

  tearDown(() async {
    await db.close();
  });

  group('UpdateDownloader delta download', () {
    test('delta download ne retelecharge que les tables changees, pas tout', () async {
      // Setup: manifeste avec sentier volcans v5
      final manifest = TrailManifest(
        schemaVersion: 1,
        trails: [
          TrailManifestEntry(
            trailId: 'volcans',
            dataVersion: v(5),
            hash: 'new_hash',
            filePath: 'trails/volcans/data.json',
            fileSize: 524288,
            status: 'active',
            lastUpdated: '2026-06-01T12:00:00Z',
          ),
        ],
      );

      // Ecart de revision : le telephone est a la revision 2, le sentier est
      // publie a la revision 5.
      final delta = DeltaUpdate(
        trailId: 'volcans',
        fromVersion: v(2),
        toVersion: v(5),
        downloadSize: 10240,
      );

      final fakeManifestService = FakeManifestService(
        dao: dao,
        connectivityMonitor: connectivity,
        fakeManifest: manifest,
      );

      final fakeDeltaService =
          FakeDeltaUpdateService(
              db: db,
              manifestService: fakeManifestService,
              trailManifestsDao: dao,
              trailMetaDao: TrailMetaDao(db),
              trailItinerariesDao: TrailItinerariesDao(db),
              trailStagesDao: TrailStagesDao(db),
              trailAccommodationsDao: TrailAccommodationsDao(db),
              trailPoisDao: TrailPoisDao(db),
              trailGpxTracksDao: TrailGpxTracksDao(db),
              trailGpxPointsDao: TrailGpxPointsDao(db),
              fakeDelta: delta,
            )
            ..bilan = ResultatSynchronisation(
              // SEULES CES DEUX FAMILLES ONT REELLEMENT BOUGE. Avant la tache 605,
              // ces listes venaient de `_inferChangedTables` qui rendait les sept
              // tables en dur : le rapport disait toujours 7/0. Elles viennent
              // desormais du bilan de ce qui a ete pose.
              famillesTouchees: const ['stages', 'pois'],
              ecrits: 3,
              supprimes: 0,
              revisionAtteinte: v(5),
            );

      final fakeChecker = FakeUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeResults: [
          UpdateCheckResult(
            trailId: 'volcans',
            hasUpdate: true,
            localVersion: v(2),
            remoteVersion: v(5),
          ),
        ],
      );

      final downloader = UpdateDownloader(
        updateChecker: fakeChecker,
        deltaUpdateService: fakeDeltaService,
        manifestService: fakeManifestService,
        dao: dao,
        connectivityMonitor: connectivity,
        dataBaseUrl: 'https://data.example.org',
      );

      // LE NIVEAU EST DIT, ET SANS LUI RIEN NE DESCEND (tache 616). Le repli de
      // `downloadAllUpdates` est `NiveauDeTelechargement.regarder` : un sentier
      // dont on ne connait pas le niveau ne fait descendre AUCUNE donnee. C est
      // volontairement l inverse du reflexe — un repli a « realiser » ferait
      // arriver la trace et ses points sur un sentier seulement prepare, toutes
      // les quatre heures, sans que le randonneur l ait demande. Ce test exerce
      // le sentier COMPLET, donc il le dit.
      final results = await downloader.downloadAllUpdates(
        manifestUrl: 'https://example.com/manifest.json',
        levelByTrail: const {'volcans': NiveauDeTelechargement.realiser},
      );

      // Verification: 1 resultat, succes
      expect(results, hasLength(1));
      expect(results.first.success, isTrue);
      expect(results.first.trailId, 'volcans');

      // Verification cle: seules 2 tables ont ete telechargees (delta)
      expect(results.first.tablesUpdated, ['stages', 'pois']);

      // Verification: les 5 autres tables ont ete ignorees
      expect(
        results.first.tablesSkipped,
        containsAll([
          'trail_meta',
          'itineraries',
          'accommodations',
          'gpx_tracks',
          'gpx_points',
        ]),
      );
      expect(results.first.tablesSkipped, hasLength(5));

      // Verification: le service delta n a ete appele qu une fois
      expect(fakeDeltaService.downloadCallCount, 1);

      // Verification: la revision cible transmise est celle de la liste
      expect(fakeDeltaService.derniereRevisionCible, v(5));

      // Verification (tache 607) : l EMPREINTE ANNONCEE PAR LA LISTE DISTANTE
      // voyage avec l adresse. Sans elle, la source refuse la copie — le
      // controle d integrite est a fermeture par defaut, precisement pour qu un
      // nouveau chemin de descente ne puisse pas l oublier comme le second
      // chemin supprime au lot 606 avait oublie tout le modele de revision.
      expect(
        fakeDeltaService.derniereEmpreinteAttendue,
        'new_hash',
        reason:
            'elle vient de la liste DISTANTE (le fichier qu on va '
            'chercher), pas du cache local',
      );

      // Verification: l URL du delta est construite depuis la base
      // injectee + filePath du manifeste (pas de bucket code en dur)
      expect(
        fakeDeltaService.lastDeltaUrl,
        'https://data.example.org/trails/volcans/data.json',
      );
    });

    test('hors ligne : aucun telechargement lance', () async {
      connectivity.setStatus(ConnectivityStatusValues.offline);

      final fakeManifestService = FakeManifestService(
        dao: dao,
        connectivityMonitor: connectivity,
      );

      final fakeDeltaService = FakeDeltaUpdateService(
        db: db,
        manifestService: fakeManifestService,
        trailManifestsDao: dao,
        trailMetaDao: TrailMetaDao(db),
        trailItinerariesDao: TrailItinerariesDao(db),
        trailStagesDao: TrailStagesDao(db),
        trailAccommodationsDao: TrailAccommodationsDao(db),
        trailPoisDao: TrailPoisDao(db),
        trailGpxTracksDao: TrailGpxTracksDao(db),
        trailGpxPointsDao: TrailGpxPointsDao(db),
      );

      final fakeChecker = FakeUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeResults: [
          const UpdateCheckResult(trailId: 'volcans', hasUpdate: true),
        ],
      );

      final downloader = UpdateDownloader(
        updateChecker: fakeChecker,
        deltaUpdateService: fakeDeltaService,
        manifestService: fakeManifestService,
        dao: dao,
        connectivityMonitor: connectivity,
      );

      final results = await downloader.downloadAllUpdates(
        manifestUrl: 'https://example.com/manifest.json',
      );

      expect(results, isEmpty);
      expect(fakeDeltaService.downloadCallCount, 0);
    });
  });
}
