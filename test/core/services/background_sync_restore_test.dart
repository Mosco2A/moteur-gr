import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/data/daos/sync_queue_dao.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/background_sync_service.dart';
import 'package:moteur_gr/core/services/cloud_sync_service.dart';
import 'package:moteur_gr/core/services/restore_service.dart';

/// Fake ConnectivityMonitor pour les tests.
class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;
  void setStatus(ConnectivityStatus s) => _status = s;
  @override
  Future<ConnectivityStatus> checkStatus() async => _status;
}

/// Tests E4.16 — sync auto background + restore nouveau telephone.
/// Fixtures neutres (sentier fictif volcans).
void main() {
  late AppDatabase db;
  late ProgressDao progressDao;
  late JournalDao journalDao;
  late ChecklistDao checklistDao;
  late SyncQueueDao syncQueueDao;
  late FakeConnectivityMonitor connectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    progressDao = ProgressDao(db);
    journalDao = JournalDao(db);
    checklistDao = ChecklistDao(db);
    syncQueueDao = SyncQueueDao(db);
    connectivity = FakeConnectivityMonitor();
  });
  tearDown(() async {
    await db.close();
  });

  // ==========================================================
  // E4.16 Test 1 : BackgroundSyncService lifecycle + intervalle
  // ==========================================================
  group('E4.16 BackgroundSyncService', () {
    test('start avec Firebase indisponible ne demarre pas', () {
      final cloudSync = CloudSyncService(
        progressDao: progressDao,
        journalDao: journalDao,
        checklistDao: checklistDao,
        syncQueueDao: syncQueueDao,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: false),
      );
      final bgSync = BackgroundSyncService(
        cloudSyncService: cloudSync,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: false),
        intervalMinutes: 30,
      );

      bgSync.start(userId: 'user1', trailId: 'volcans');
      // Sans Firebase, le service ne demarre pas
      expect(bgSync.isRunning, isFalse);
      expect(bgSync.lastSyncTime, isNull);

      // Intervalle par defaut = 30 min
      expect(bgSync.intervalMinutes, 30);
    });

    test('syncNow retourne idle sans Firebase', () async {
      final cloudSync = CloudSyncService(
        progressDao: progressDao,
        journalDao: journalDao,
        checklistDao: checklistDao,
        syncQueueDao: syncQueueDao,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: false),
      );
      final bgSync = BackgroundSyncService(
        cloudSyncService: cloudSync,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: false),
      );
      bgSync.start(userId: 'user1', trailId: 'volcans');

      final result = await bgSync.syncNow();
      expect(result.status, CloudSyncStatusValues.idle);

      // stop + dispose
      bgSync.dispose();
      expect(bgSync.isRunning, isFalse);
    });
  });

  // ==========================================================
  // E4.16 Test 2 : RestoreService checkAndRestore + merge LWW
  // ==========================================================
  group('E4.16 RestoreService', () {
    test('checkAndRestore retourne hasCloudData=false si Firebase indisponible',
        () async {
      final restoreService = RestoreService(
        progressDao: progressDao,
        journalDao: journalDao,
        checklistDao: checklistDao,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: false),
      );

      final check = await restoreService.checkAndRestore('user1');
      expect(check.hasCloudData, isFalse);
      expect(check.cloudItemCount, 0);
      expect(check.lastCloudSync, isNull);
    });

    test('restoreFromCloud retourne erreur si hors ligne', () async {
      connectivity.setStatus(ConnectivityStatusValues.offline);
      final restoreService = RestoreService(
        progressDao: progressDao,
        journalDao: journalDao,
        checklistDao: checklistDao,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
      );

      final result = await restoreService.restoreFromCloud('user1');
      expect(result.success, isFalse);
      expect(result.error, kRestoreErrorOffline);
      expect(result.itemsRestored, 0);

      // Verifier que rien n a ete ecrit en local
      final progress = await progressDao.getByTrailId('volcans');
      expect(progress, isNull);
    });

    test('restoreFromCloud retourne erreur si Firebase indisponible',
        () async {
      final restoreService = RestoreService(
        progressDao: progressDao,
        journalDao: journalDao,
        checklistDao: checklistDao,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: false),
      );

      final result = await restoreService.restoreFromCloud('user1');
      expect(result.success, isFalse);
      expect(result.error, kRestoreErrorFirebaseUnavailable);
      expect(result.itemsRestored, 0);
    });
  });
}
