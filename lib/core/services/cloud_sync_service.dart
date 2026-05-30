import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:drift/drift.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:logger/logger.dart";

import "../data/database.dart";
import "../data/daos/checklist_dao.dart";
import "../data/daos/journal_dao.dart";
import "../data/daos/progress_dao.dart";
import "../data/daos/sync_queue_dao.dart";
import "../firebase/firebase_service.dart";
import "../models/sync_config.dart";
import "../network/connectivity_monitor.dart";
import "../providers/database_provider.dart";

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Statut d une operation de sync cloud.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef CloudSyncStatus = String;

/// Valeurs connues pour CloudSyncStatus avec fallback generique.
abstract class CloudSyncStatusValues {
  static const String idle = 'idle';
  static const String syncing = 'syncing';
  static const String success = 'success';
  static const String error = 'error';
  static const String fallback = idle;
  static const List<String> values = [idle, syncing, success, error];
  static CloudSyncStatus fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Resultat d une operation de synchronisation.
class CloudSyncResult {
  const CloudSyncResult({
    required this.status,
    required this.syncedAt,
    this.itemsSynced = 0,
    this.error,
  });

  final CloudSyncStatus status;
  final DateTime syncedAt;
  final int itemsSynced;
  final String? error;
}
/// Service de synchronisation des donnees utilisateur vers Firestore.
///
/// Strategie last-write-wins : chaque document porte un updatedAt,
/// le plus recent gagne. Les donnees locales restent la source primaire,
/// la sync est un backup cloud.
class CloudSyncService {
  CloudSyncService({
    required this.progressDao,
    required this.journalDao,
    required this.checklistDao,
    required this.syncQueueDao,
    required this.connectivityMonitor,
    required this.firebaseService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final ProgressDao progressDao;
  final JournalDao journalDao;
  final ChecklistDao checklistDao;
  final SyncQueueDao syncQueueDao;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;
  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init pour les tests)
  FirebaseFirestore get firestore =>
      _firestore ??= FirebaseFirestore.instance;

  /// Synchronise toutes les donnees utilisateur pour un sentier.
  Future<CloudSyncResult> syncUserData(
    String userId,
    String trailId, {
    SyncConfig config = const SyncConfig(),
  }) async {
    // Si Firebase non disponible, graceful no-op
    if (!firebaseService.isAvailable) {
      _log.d("[CloudSync] Firebase non disponible, sync ignoree");
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    // Verifier la connectivite
    final connectivity = await connectivityMonitor.checkStatus();
    if (connectivity == ConnectivityStatusValues.offline) {
      _log.d("[CloudSync] Hors ligne, sync reportee");
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    _log.d("[CloudSync] Debut sync $userId / $trailId");
    int itemsSynced = 0;
    int retryCount = 0;

    while (retryCount <= config.maxRetries) {
      try {
        final basePath = firestore
            .collection("users")
            .doc(userId)
            .collection("trails")
            .doc(trailId);

        // --- 1. Sync progression utilisateur ---
        final progress = await progressDao.getByTrailId(trailId);
        if (progress != null) {
          final now = DateTime.now().toIso8601String();
          final progressData = {
            "trail_id": progress.trailId,
            "current_stage": progress.currentStage,
            "total_distance_walked_km": progress.totalDistanceWalkedKm,
            "total_elevation_gained_m": progress.totalElevationGainedM,
            "total_time_minutes": progress.totalTimeMinutes,
            "is_completed": progress.isCompleted,
            "started_at": progress.startedAt?.toIso8601String(),
            "completed_at": progress.completedAt?.toIso8601String(),
            "updated_at": now,
          };

          // Last-write-wins : ecriture conditionnelle si plus recent
          await _setWithLastWriteWins(
            basePath.collection("user_progress").doc("current"),
            progressData,
          );
          itemsSynced++;
        }

        // --- 2. Sync journal entries ---
        final journalEntries = await journalDao.getByTrailId(trailId);
        for (final entry in journalEntries) {
          final now = DateTime.now().toIso8601String();
          final entryData = {
            "stage_number": entry.stageNumber,
            "content": entry.content,
            "photo_path": entry.photoPath,
            "photo_size_bytes": entry.photoSizeBytes,
            "created_at": entry.createdAt.toIso8601String(),
            "updated_at": entry.updatedAt?.toIso8601String() ?? now,
          };

          await _setWithLastWriteWins(
            basePath
                .collection("journal_entries")
                .doc("entry_${entry.id}"),
            entryData,
          );
          itemsSynced++;
        }

        // --- 3. Sync checklist items ---
        final checklistItems = await checklistDao.getByTrailId(trailId);
        for (final item in checklistItems) {
          final now = DateTime.now().toIso8601String();
          final itemData = {
            "item_id": item.itemId,
            "category": item.category,
            "is_checked": item.isChecked,
            "updated_at": item.updatedAt?.toIso8601String() ?? now,
          };

          await _setWithLastWriteWins(
            basePath
                .collection("checklist_items")
                .doc("item_${item.itemId}"),
            itemData,
          );
          itemsSynced++;
        }

        // --- Marquer la sync dans la queue ---
        final now = DateTime.now().toIso8601String();
        await syncQueueDao.insertOrReplace(SyncQueueCompanion(
          trailId: Value(trailId),
          action: const Value("cloud_sync"),
          status: const Value("completed"),
          createdAt: Value(now),
          completedAt: Value(now),
        ));

        _log.d("[CloudSync] Sync terminee: $itemsSynced items");
        return CloudSyncResult(
          status: CloudSyncStatusValues.success,
          syncedAt: DateTime.now(),
          itemsSynced: itemsSynced,
        );
      } catch (e) {
        retryCount++;
        _log.e("[CloudSync] Erreur sync (tentative $retryCount): $e");

        if (retryCount > config.maxRetries) {
          final now = DateTime.now().toIso8601String();
          await syncQueueDao.insertOrReplace(SyncQueueCompanion(
            trailId: Value(trailId),
            action: const Value("cloud_sync"),
            status: const Value("failed"),
            createdAt: Value(now),
            payload: Value(e.toString()),
          ));

          return CloudSyncResult(
            status: CloudSyncStatusValues.error,
            syncedAt: DateTime.now(),
            error: e.toString(),
          );
        }

        // Attente exponentielle entre les retries
        await Future<void>.delayed(
          Duration(seconds: retryCount * 2),
        );
      }
    }

    return CloudSyncResult(
      status: CloudSyncStatusValues.error,
      syncedAt: DateTime.now(),
      error: "Max retries atteint",
    );
  }

  /// Enqueue une sync batch horaire dans la sync_queue.
  Future<void> pushBatchHourly(String userId, String trailId) async {
    if (!firebaseService.isAvailable) return;

    final now = DateTime.now().toIso8601String();
    await syncQueueDao.insertOrReplace(SyncQueueCompanion(
      trailId: Value(trailId),
      action: const Value("cloud_sync_batch"),
      status: const Value("pending"),
      createdAt: Value(now),
      payload: Value(userId),
    ));
    _log.d("[CloudSync] Batch sync enqueue pour $trailId");
  }

  /// Sync immediate a l arrivee dans un refuge.
  Future<CloudSyncResult> pushOnRefugeArrival(
    String userId,
    String trailId, {
    SyncConfig config = const SyncConfig(),
  }) async {
    if (!config.syncOnRefugeArrival) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }
    _log.d("[CloudSync] Arrivee refuge, sync immediate $trailId");
    return syncUserData(userId, trailId, config: config);
  }

  /// Rattrapage au retour de la connectivite.
  Future<CloudSyncResult> catchUpOnReconnect(
    String userId, {
    SyncConfig config = const SyncConfig(),
  }) async {
    if (!config.syncOnReconnect) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    if (!firebaseService.isAvailable) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    final pending = await syncQueueDao.getPending();
    final syncActions = pending
        .where((a) =>
            a.action == "cloud_sync_batch" || a.action == "cloud_sync")
        .toList();

    if (syncActions.isEmpty) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    _log.d("[CloudSync] Rattrapage: ${syncActions.length} syncs pending");
    int totalSynced = 0;

    for (final action in syncActions) {
      final trailId = action.trailId;
      final uid = action.payload ?? userId;
      final result = await syncUserData(uid, trailId, config: config);
      if (result.status == CloudSyncStatusValues.success) {
        totalSynced += result.itemsSynced;
      }
    }

    return CloudSyncResult(
      status: CloudSyncStatusValues.success,
      syncedAt: DateTime.now(),
      itemsSynced: totalSynced,
    );
  }

  /// Ecriture Firestore avec strategie last-write-wins.
  Future<void> _setWithLastWriteWins(
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> data,
  ) async {
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set(data);
      return;
    }

    final remoteUpdatedAt = snapshot.data()?["updated_at"] as String?;
    final localUpdatedAt = data["updated_at"] as String?;

    if (remoteUpdatedAt == null || localUpdatedAt == null) {
      await docRef.set(data);
      return;
    }

    // Last-write-wins : le plus recent gagne
    if (localUpdatedAt.compareTo(remoteUpdatedAt) >= 0) {
      await docRef.set(data);
    }
  }
}

/// Provider Riverpod pour le service de sync cloud.
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return CloudSyncService(
    progressDao: ProgressDao(db),
    journalDao: JournalDao(db),
    checklistDao: ChecklistDao(db),
    syncQueueDao: SyncQueueDao(db),
    connectivityMonitor: connectivity,
    firebaseService: firebase,
  );
});
