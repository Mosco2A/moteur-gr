import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/update_checker.dart';

import '../../fixtures/horodatage_de_serveur.dart';

/// LA REVISION N DEVIENT L INSTANT « REFERENCE + N JOURS » (tache 610).
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

    // CE DOUBLE REPRODUIT LA LOGIQUE DE `lib/`, DONC IL DOIT LA REPRODUIRE
    // EXACTEMENT — horodatage compris. C est la faiblesse connue de ce fichier :
    // `UpdateChecker.checkForUpdate` parle directement a `cloud_firestore`, qu on
    // ne peut pas doubler ici, donc le test reecrit la decision. Il verifie la
    // REGLE, pas le code qui l applique.
    final remoteVersion =
        HorodatageServeur.annonceParLeServeur(remoteData['data_version']) ??
        HorodatageServeur.origine;

    final localEntry = await dao.getByTrailId(trailId);
    final localVersion = localEntry?.localVersion ?? HorodatageServeur.origine;

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
      await dao.insertOrReplace(
        TrailManifestsCompanion(
          trailId: const Value('volcans'),
          dataVersion: Value(v(3)),
          hash: const Value('abc123'),
          filePath: const Value('trails/volcans/data.json'),
          fileSize: const Value(524288),
          status: const Value('active'),
          lastUpdated: const Value('2026-05-26T12:00:00Z'),
          localVersion: Value(v(2)),
        ),
      );

      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeRemoteData: {
          'volcans': {'data_version': v(5).iso8601},
        },
      );

      final result = await checker.checkForUpdate('volcans');

      expect(result.hasUpdate, isTrue);
      expect(result.localVersion, v(2));
      expect(result.remoteVersion, v(5));
      expect(result.trailId, 'volcans');
    });

    test('pas de MAJ si versions identiques', () async {
      await dao.insertOrReplace(
        TrailManifestsCompanion(
          trailId: const Value('volcans'),
          dataVersion: Value(v(3)),
          hash: const Value('abc123'),
          filePath: const Value('p'),
          fileSize: const Value(100),
          status: const Value('active'),
          lastUpdated: const Value('2026-01-01T00:00:00Z'),
          localVersion: Value(v(3)),
        ),
      );

      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeRemoteData: {
          'volcans': {'data_version': v(3).iso8601},
        },
      );

      final result = await checker.checkForUpdate('volcans');
      expect(result.hasUpdate, isFalse);
      expect(result.localVersion, v(3));
      expect(result.remoteVersion, v(3));
    });

    test(
      'detecte MAJ si sentier jamais telecharge (localVersion null)',
      () async {
        await dao.insertOrReplace(
          TrailManifestsCompanion(
            trailId: const Value('sentier-bleu'),
            dataVersion: Value(v(1)),
            hash: const Value('def456'),
            filePath: const Value('p'),
            fileSize: const Value(100),
            status: const Value('active'),
            lastUpdated: const Value('2026-01-01T00:00:00Z'),
          ),
        );

        final checker = TestableUpdateChecker(
          dao: dao,
          connectivityMonitor: connectivity,
          firebaseService: firebase,
          fakeRemoteData: {
            'sentier-bleu': {'data_version': v(1).iso8601},
          },
        );

        final result = await checker.checkForUpdate('sentier-bleu');
        expect(result.hasUpdate, isTrue);
        expect(result.localVersion, HorodatageServeur.origine);
        expect(result.remoteVersion, v(1));
      },
    );

    test('retourne hasUpdate false si Firebase non disponible', () async {
      final offlineFirebase = FakeFirebaseService(available: false);
      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: offlineFirebase,
        fakeRemoteData: {
          'volcans': {'data_version': v(99).iso8601},
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
          'volcans': {'data_version': v(99).iso8601},
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

  /// LE PERIMETRE DE LA MISE A JOUR PERIODIQUE — « SES SENTIERS » (tache 610).
  ///
  /// Precision de Christophe du 28/09 : « on telecharge tout ce qui concerne SES
  /// sentiers ». La lecture du catalogue distant ecrit une ligne de
  /// `trail_manifests` par sentier PUBLIE, pour survivre au hors-ligne ; ces lignes
  /// ont `localVersion` a NULL. Sans filtre, un randonneur qui possede UN sentier
  /// declenchait la synchronisation de TOUS les sentiers du catalogue.
  group('UpdateChecker.checkAllForUpdates — perimetre', () {
    /// Une entree de catalogue : vue, pas copiee (`localVersion` nul).
    Future<void> auCatalogue(String trailId) => dao.insertOrReplace(
      TrailManifestsCompanion(
        trailId: Value(trailId),
        dataVersion: Value(v(1)),
        hash: const Value('h'),
        filePath: const Value('p'),
        fileSize: const Value(100),
        status: const Value('active'),
        lastUpdated: const Value('2026-01-01T00:00:00Z'),
      ),
    );

    /// Un sentier reellement copie sur ce telephone.
    Future<void> possede(String trailId) => dao.insertOrReplace(
      TrailManifestsCompanion(
        trailId: Value(trailId),
        dataVersion: Value(v(1)),
        hash: const Value('h'),
        filePath: const Value('p'),
        fileSize: const Value(100),
        status: const Value('active'),
        lastUpdated: const Value('2026-01-01T00:00:00Z'),
        localVersion: Value(v(1)),
      ),
    );

    test('ne verifie QUE les sentiers copies sur ce telephone', () async {
      await possede('volcans');
      await auCatalogue('sentier-bleu');
      await auCatalogue('cantal');
      await auCatalogue('tmb');

      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        // Les quatre sentiers ont une publication plus recente cote serveur : sans
        // le filtre de perimetre, les quatre remonteraient.
        fakeRemoteData: {
          'volcans': {'data_version': v(9).iso8601},
          'sentier-bleu': {'data_version': v(9).iso8601},
          'cantal': {'data_version': v(9).iso8601},
          'tmb': {'data_version': v(9).iso8601},
        },
      );

      final resultats = await checker.checkAllForUpdates();
      expect(resultats.length, 1);
      expect(resultats.single.trailId, 'volcans');
    });

    test('un telephone qui ne possede rien ne demande rien', () async {
      await auCatalogue('sentier-bleu');
      await auCatalogue('cantal');

      final checker = TestableUpdateChecker(
        dao: dao,
        connectivityMonitor: connectivity,
        firebaseService: firebase,
        fakeRemoteData: {
          'sentier-bleu': {'data_version': v(9).iso8601},
          'cantal': {'data_version': v(9).iso8601},
        },
      );

      expect(await checker.checkAllForUpdates(), isEmpty);
    });
  });
}
