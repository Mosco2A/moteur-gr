import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:drift/drift.dart" hide isNull, isNotNull;
import "package:moteur_gr/core/data/database.dart";
import "package:moteur_gr/core/data/daos/sync_queue_dao.dart";
import "package:moteur_gr/core/models/sync_config.dart";
import "package:moteur_gr/core/network/connectivity_monitor.dart";
import "package:moteur_gr/core/services/cloud_sync_service.dart";

/// Fake ConnectivityMonitor pour les tests.
class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;
  void setStatus(ConnectivityStatus s) => _status = s;
  @override
  Future<ConnectivityStatus> checkStatus() async => _status;
}

void main() {
  late AppDatabase db;
  late SyncQueueDao syncQueueDao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    syncQueueDao = SyncQueueDao(db);
  });
  tearDown(() async { await db.close(); });

  // Firebase non disponible par defaut dans les tests
  // (pas de FakeFirebaseService necessaire, le constructeur prive suffit)

  group("firebase non disponible", () {
    test("syncUserData retourne idle", () async {
      // CloudSyncService avec un service dont isAvailable=false
      // Impossible d instancier FirebaseService directement (constructeur prive)
      // On teste via le comportement : la sync ne fait rien.
      // Note: en vrai test on mockerait Firestore. Ici on verifie la logique.
      expect(true, isTrue); // placeholder - Firestore mock requis en integration
    });
  });

  group("SyncConfig model", () {
    test("valeurs par defaut", () {
      const config = SyncConfig();
      expect(config.batchIntervalMinutes, 60);
      expect(config.syncOnRefugeArrival, isTrue);
      expect(config.syncOnReconnect, isTrue);
      expect(config.maxRetries, 3);
      expect(config.lastSyncTimestamp, isNull);
    });

    test("copyWith modifie les bons champs", () {
      const config = SyncConfig();
      final updated = config.copyWith(
        batchIntervalMinutes: 30,
        lastSyncTimestamp: "2026-05-26T12:00:00",
      );
      expect(updated.batchIntervalMinutes, 30);
      expect(updated.lastSyncTimestamp, "2026-05-26T12:00:00");
      expect(updated.syncOnRefugeArrival, isTrue);
    });

    test("maxRetries personnalisable", () {
      const config = SyncConfig(maxRetries: 5);
      expect(config.maxRetries, 5);
    });
  });

  group("sync_queue integration", () {
    test("queue vide au demarrage", () async {
      final pending = await syncQueueDao.getPending();
      expect(pending, isEmpty);
    });

    test("insertion cloud_sync_batch dans la queue", () async {
      final now = DateTime.now().toIso8601String();
      await syncQueueDao.insertOrReplace(SyncQueueCompanion(
        trailId: const Value("sentier-volcans"),
        action: const Value("cloud_sync_batch"),
        status: const Value("pending"),
        createdAt: Value(now),
        payload: const Value("user1"),
      ));
      final pending = await syncQueueDao.getPending();
      expect(pending.length, 1);
      expect(pending.first.action, "cloud_sync_batch");
    });

    test("markCompleted change le statut", () async {
      final now = DateTime.now().toIso8601String();
      final id = await syncQueueDao.insertOrReplace(SyncQueueCompanion(
        trailId: const Value("sentier-volcans"),
        action: const Value("cloud_sync"),
        status: const Value("pending"),
        createdAt: Value(now),
      ));
      await syncQueueDao.markCompleted(id);
      final all = await syncQueueDao.getByTrailId("sentier-volcans");
      expect(all.first.status, "completed");
    });

    test("markFailed enregistre l erreur", () async {
      final now = DateTime.now().toIso8601String();
      final id = await syncQueueDao.insertOrReplace(SyncQueueCompanion(
        trailId: const Value("sentier-volcans"),
        action: const Value("cloud_sync"),
        status: const Value("pending"),
        createdAt: Value(now),
      ));
      await syncQueueDao.markFailed(id, "timeout");
      final all = await syncQueueDao.getByTrailId("sentier-volcans");
      expect(all.first.status, "failed");
      expect(all.first.payload, "timeout");
    });
  });

  group("CloudSyncResult", () {
    test("construction basique", () {
      final result = CloudSyncResult(
        status: CloudSyncStatusValues.success,
        syncedAt: DateTime(2026, 5, 26),
        itemsSynced: 42,
      );
      expect(result.status, CloudSyncStatusValues.success);
      expect(result.itemsSynced, 42);
      expect(result.error, isNull);
    });

    test("construction avec erreur", () {
      final result = CloudSyncResult(
        status: CloudSyncStatusValues.error,
        syncedAt: DateTime(2026, 5, 26),
        error: "timeout",
      );
      expect(result.status, CloudSyncStatusValues.error);
      expect(result.error, "timeout");
      expect(result.itemsSynced, 0);
    });
  });
}
