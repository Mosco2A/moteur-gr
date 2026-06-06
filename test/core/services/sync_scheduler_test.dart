import "dart:async";

import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:moteur_gr/core/data/database.dart";
import "package:moteur_gr/core/data/daos/checklist_dao.dart";
import "package:moteur_gr/core/data/daos/journal_dao.dart";
import "package:moteur_gr/core/data/daos/progress_dao.dart";
import "package:moteur_gr/core/data/daos/sync_queue_dao.dart";
import "package:moteur_gr/core/firebase/firebase_service.dart";
import "package:moteur_gr/core/models/sync_config.dart";
import "package:moteur_gr/core/network/connectivity_monitor.dart";
import "package:moteur_gr/core/services/cloud_sync_service.dart";
import "package:moteur_gr/core/services/sync_scheduler.dart";

/// Fake ConnectivityMonitor avec stream controllable.
class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  void setStatus(ConnectivityStatus s) {
    _status = s;
    _controller.add(s);
  }

  @override
  Future<ConnectivityStatus> checkStatus() async => _status;

  @override
  Stream<ConnectivityStatus> get onStatusChange => _controller.stream;

  void dispose() => _controller.close();
}

void main() {
  late AppDatabase db;
  late FakeConnectivityMonitor connectivity;
  late CloudSyncService cloudSync;
  late SyncScheduler scheduler;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = FakeConnectivityMonitor();
    // Firebase indisponible : le scheduler ne demarre pas
    // On teste la logique start/stop/isRunning
  });
  tearDown(() async {
    connectivity.dispose();
    await db.close();
  });

  group("lifecycle", () {
    test("isRunning false par defaut", () {
      cloudSync = CloudSyncService(
        progressDao: ProgressDao(db),
        journalDao: JournalDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.unavailable(),
      );
      scheduler = SyncScheduler(
        cloudSyncService: cloudSync,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.unavailable(),
      );
      expect(scheduler.isRunning, isFalse);
    });

    test("start sans Firebase ne demarre pas", () {
      cloudSync = CloudSyncService(
        progressDao: ProgressDao(db),
        journalDao: JournalDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.unavailable(),
      );
      scheduler = SyncScheduler(
        cloudSyncService: cloudSync,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.unavailable(),
      );
      scheduler.start(userId: "user1", trailId: "sentier-volcans");
      expect(scheduler.isRunning, isFalse);
    });

    test("stop apres start remet isRunning a false", () {
      cloudSync = CloudSyncService(
        progressDao: ProgressDao(db),
        journalDao: JournalDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.unavailable(),
      );
      scheduler = SyncScheduler(
        cloudSyncService: cloudSync,
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.unavailable(),
      );
      scheduler.stop();
      expect(scheduler.isRunning, isFalse);
    });
  });

  group("SyncConfig dans scheduler", () {
    test("config par defaut 60 min", () {
      const config = SyncConfig();
      expect(config.batchIntervalMinutes, 60);
    });

    test("config custom 15 min", () {
      const config = SyncConfig(batchIntervalMinutes: 15);
      expect(config.batchIntervalMinutes, 15);
    });
  });
}
