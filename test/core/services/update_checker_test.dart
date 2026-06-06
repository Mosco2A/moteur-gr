import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/update_checker.dart';

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

/// UpdateChecker testable avec donnees distantes simulees.
///
/// Reproduit la logique de checkForUpdate en remplacant la lecture
/// Firestore par une map de documents simules (data_version par
/// trailId, null = document absent). Evite d implementer
/// DocumentSnapshot (classe sealed du SDK).
class TestableUpdateChecker extends UpdateChecker {
  TestableUpdateChecker({
    required super.dao,
    required super.connectivityMonitor,
    required super.firebaseService,
    this.fakeRemoteData = const {},
  });

  /// Donnees distantes simulees : trailId -> document (null = absent).
  final Map<String, Map<String, dynamic>?> fakeRemoteData;

  @override
  Future<UpdateCheckResult> checkForUpdate(String trailId) async {
    if (!firebaseService.isAvailable) {
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }

    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }

    final remoteData = fakeRemoteData[trailId];
    if (remoteData == null) {
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }

    final remoteVersion = remoteData['data_version'] as int? ?? 0;

    final localEntry = await dao.getByTrailId(trailId);
    final localVersion = localEntry?.localVersion ?? 0;

    final hasUpdate = remoteVersion > localVersion;

    return UpdateCheckResult(
      trailId: trailId,
      hasUpdate: hasUpdate,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
    );
  }
}

/// Tests du service UpdateChecker (detection MAJ delta, E4.11b).
/// Fixtures neutres : sentiers fictifs volcans / sentier-bleu.
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

  group('UpdateChecker.checkForUpdate', () {
    test('detecte une nouvelle version quand remote > local', () async {
      await dao.insertOrReplace(const TrailManifestsCompanion(
        trailId: Value('volcans'),
        dataVersion: Value(3),
        hash: Value('abc123'),
        filePath: Value('trails/volcans/data.json'),
        fileSize: Value(524288),
        status: Value('active'),
        lastUpdated: Value('2026-05-26T12:00:00Z'),
        localVersion: Value(2),
      ));

      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeRemoteData: {
          'volcans': {'data_version': 5},
        },
      );

      final result = await checker.checkForUpdate('volcans');

      expect(result.hasUpdate, isTrue);
      expect(result.localVersion, 2);
      expect(result.remoteVersion, 5);
      expect(result.trailId, 'volcans');
    });

    test('pas de MAJ si versions identiques', () async {
      await dao.insertOrReplace(const TrailManifestsCompanion(
        trailId: Value('volcans'),
        dataVersion: Value(3),
        hash: Value('abc123'),
        filePath: Value('p'),
        fileSize: Value(100),
        status: Value('active'),
        lastUpdated: Value('2026-01-01T00:00:00Z'),
        localVersion: Value(3),
      ));

      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeRemoteData: {
          'volcans': {'data_version': 3},
        },
      );

      final result = await checker.checkForUpdate('volcans');
      expect(result.hasUpdate, isFalse);
      expect(result.localVersion, 3);
      expect(result.remoteVersion, 3);
    });

    test('detecte MAJ si sentier jamais telecharge (localVersion null)',
        () async {
      await dao.insertOrReplace(const TrailManifestsCompanion(
        trailId: Value('sentier-bleu'),
        dataVersion: Value(1),
        hash: Value('def456'),
        filePath: Value('p'),
        fileSize: Value(100),
        status: Value('active'),
        lastUpdated: Value('2026-01-01T00:00:00Z'),
      ));

      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeRemoteData: {
          'sentier-bleu': {'data_version': 1},
        },
      );

      final result = await checker.checkForUpdate('sentier-bleu');
      expect(result.hasUpdate, isTrue);
      expect(result.localVersion, 0);
      expect(result.remoteVersion, 1);
    });

    test('retourne hasUpdate false si Firebase non disponible', () async {
      final offlineFirebase = FakeFirebaseService(available: false);
      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: offlineFirebase,
        fakeRemoteData: {
          'volcans': {'data_version': 99},
        },
      );

      final result = await checker.checkForUpdate('volcans');
      expect(result.hasUpdate, isFalse);
    });

    test('retourne hasUpdate false si hors ligne', () async {
      connectivity.setStatus(ConnectivityStatusValues.offline);

      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeRemoteData: {
          'volcans': {'data_version': 99},
        },
      );

      final result = await checker.checkForUpdate('volcans');
      expect(result.hasUpdate, isFalse);
    });

    test('retourne hasUpdate false si document Firestore absent', () async {
      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeRemoteData: {'volcans': null},
      );

      final result = await checker.checkForUpdate('volcans');
      expect(result.hasUpdate, isFalse);
    });
  });
}
