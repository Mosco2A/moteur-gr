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
import 'package:moteur_gr/core/models/delta_update.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/update_checker.dart';
import 'package:moteur_gr/core/services/update_downloader.dart';

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

  /// Tables effectivement demandees lors du dernier downloadAndApplyDelta.
  List<String> lastChangedTables = [];

  /// URL demandee lors du dernier downloadAndApplyDelta.
  String? lastDeltaUrl;

  /// Nombre d appels a downloadAndApplyDelta.
  int downloadCallCount = 0;

  @override
  Future<DeltaUpdate?> checkForUpdates(String trailId,
      {required TrailManifest remoteManifest}) async {
    return fakeDelta;
  }

  @override
  Future<void> downloadAndApplyDelta(String trailId, String deltaUrl,
      {List<String> changedTables = const []}) async {
    downloadCallCount++;
    lastDeltaUrl = deltaUrl;
    lastChangedTables = changedTables;
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
    test('delta download ne retelecharge que les tables changees, pas tout',
        () async {
      // Setup: manifeste avec sentier volcans v5
      const manifest = TrailManifest(
        schemaVersion: 1,
        trails: [
          TrailManifestEntry(
            trailId: 'volcans',
            dataVersion: 5,
            hash: 'new_hash',
            filePath: 'trails/volcans/data.json',
            fileSize: 524288,
            status: 'active',
            lastUpdated: '2026-06-01T12:00:00Z',
          ),
        ],
      );

      // Delta: seulement stages + pois ont change (pas tout)
      const delta = DeltaUpdate(
        trailId: 'volcans',
        fromVersion: 2,
        toVersion: 5,
        changedTables: ['stages', 'pois'],
        downloadSize: 10240,
      );

      final fakeManifestService = FakeManifestService(
        dao: dao,
        connectivityMonitor: connectivity,
        fakeManifest: manifest,
      );

      final fakeDeltaService = FakeDeltaUpdateService(
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
      );

      final fakeChecker = FakeUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeResults: [
          const UpdateCheckResult(
            trailId: 'volcans',
            hasUpdate: true,
            localVersion: 2,
            remoteVersion: 5,
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

      final results = await downloader.downloadAllUpdates(
        manifestUrl: 'https://example.com/manifest.json',
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

      // Verification: seules les tables changees ont ete passees
      expect(fakeDeltaService.lastChangedTables, ['stages', 'pois']);

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
