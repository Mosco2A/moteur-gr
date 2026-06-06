import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../data/database.dart';
import '../data/daos/checklist_dao.dart';
import '../data/daos/journal_dao.dart';
import '../data/daos/progress_dao.dart';
import '../firebase/firebase_service.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Code d erreur : appareil hors ligne.
const kRestoreErrorOffline = 'offline';

/// Code d erreur : Firebase indisponible.
const kRestoreErrorFirebaseUnavailable = 'firebase_unavailable';

/// Resultat de la verification de restauration.
class RestoreCheck {
  const RestoreCheck({
    required this.hasCloudData,
    this.cloudItemCount = 0,
    this.lastCloudSync,
  });
  final bool hasCloudData;
  final int cloudItemCount;
  final DateTime? lastCloudSync;
}

/// Resultat d une operation de restauration.
class RestoreResult {
  const RestoreResult({
    required this.success,
    this.itemsRestored = 0,
    this.error,
  });
  final bool success;
  final int itemsRestored;

  /// Code d erreur technique (kRestoreError*) ou message exception.
  final String? error;
}

/// Service de restauration des donnees depuis Firestore (E4.16).
///
/// Verifie si des donnees cloud existent pour un utilisateur
/// (changement de telephone) et propose la restauration.
/// L utilisateur est identifie par son ID ANONYMISE (E4.15) :
/// se reconnecter avec le meme compte Apple/Google suffit (#81775).
///
/// Strategie de merge : last-write-wins (LWW).
/// Chaque document porte un champ updated_at. Le plus recent
/// entre local et distant est conserve.
class RestoreService {
  RestoreService({
    required this.progressDao,
    required this.journalDao,
    required this.checklistDao,
    required this.connectivityMonitor,
    required this.firebaseService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final ProgressDao progressDao;
  final JournalDao journalDao;
  final ChecklistDao checklistDao;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;
  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init pour les tests).
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// Verifie si des donnees cloud existent pour cet utilisateur.
  Future<RestoreCheck> checkAndRestore(String userId) async {
    if (!firebaseService.isAvailable) {
      _log.d('[Restore] Firebase indisponible');
      return const RestoreCheck(hasCloudData: false);
    }

    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      _log.d('[Restore] Hors ligne, verification impossible');
      return const RestoreCheck(hasCloudData: false);
    }

    try {
      final userDoc = firestore.collection('users').doc(userId);
      int totalItems = 0;
      DateTime? latestSync;

      final trailsSnap = await userDoc.collection('trails').get();
      for (final trailDoc in trailsSnap.docs) {
        final progressSnap =
            await trailDoc.reference.collection('user_progress').get();
        totalItems += progressSnap.docs.length;
        final journalSnap =
            await trailDoc.reference.collection('journal_entries').get();
        totalItems += journalSnap.docs.length;
        final checklistSnap =
            await trailDoc.reference.collection('checklist_items').get();
        totalItems += checklistSnap.docs.length;

        for (final doc in progressSnap.docs) {
          final updatedAt = doc.data()['updated_at'] as String?;
          if (updatedAt != null) {
            final dt = DateTime.tryParse(updatedAt);
            if (dt != null && (latestSync == null || dt.isAfter(latestSync))) {
              latestSync = dt;
            }
          }
        }
      }

      _log.d('[Restore] Check: $totalItems items pour $userId');
      return RestoreCheck(
        hasCloudData: totalItems > 0,
        cloudItemCount: totalItems,
        lastCloudSync: latestSync,
      );
    } catch (e) {
      _log.e('[Restore] Erreur check: $e');
      return const RestoreCheck(hasCloudData: false);
    }
  }

  /// Restaure les donnees depuis Firestore vers la base locale.
  /// Strategie LWW : pour chaque element, compare updated_at.
  Future<RestoreResult> restoreFromCloud(String userId) async {
    if (!firebaseService.isAvailable) {
      return const RestoreResult(
        success: false,
        error: kRestoreErrorFirebaseUnavailable,
      );
    }
    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      return const RestoreResult(success: false, error: kRestoreErrorOffline);
    }

    try {
      int itemsRestored = 0;
      final userDoc = firestore.collection('users').doc(userId);
      final trailsSnap = await userDoc.collection('trails').get();

      for (final trailDoc in trailsSnap.docs) {
        final trailId = trailDoc.id;
        final progressSnap =
            await trailDoc.reference.collection('user_progress').get();
        for (final doc in progressSnap.docs) {
          if (await _mergeProgress(trailId, doc.data())) itemsRestored++;
        }
        final journalSnap =
            await trailDoc.reference.collection('journal_entries').get();
        for (final doc in journalSnap.docs) {
          if (await _mergeJournalEntry(trailId, doc.data())) itemsRestored++;
        }
        final checklistSnap =
            await trailDoc.reference.collection('checklist_items').get();
        for (final doc in checklistSnap.docs) {
          if (await _mergeChecklistItem(trailId, doc.data())) itemsRestored++;
        }
      }

      _log.d('[Restore] Restauration terminee: $itemsRestored items');
      return RestoreResult(success: true, itemsRestored: itemsRestored);
    } catch (e) {
      _log.e('[Restore] Erreur restauration: $e');
      return RestoreResult(success: false, error: e.toString());
    }
  }

  /// Merge une progression avec strategie LWW.
  Future<bool> _mergeProgress(
      String trailId, Map<String, dynamic> remoteData) async {
    final remoteUpdatedAt = remoteData['updated_at'] as String?;
    final localProgress = await progressDao.getByTrailId(trailId);
    if (localProgress != null && remoteUpdatedAt != null) {
      final localUpdatedAt = localProgress.completedAt?.toIso8601String() ??
          localProgress.startedAt?.toIso8601String();
      if (localUpdatedAt != null &&
          localUpdatedAt.compareTo(remoteUpdatedAt) > 0) {
        return false;
      }
    }
    await progressDao.upsert(UserProgressEntriesCompanion(
      trailId: Value(trailId),
      currentStage: Value(remoteData['current_stage'] as int? ?? 1),
      totalDistanceWalkedKm: Value(
          (remoteData['total_distance_walked_km'] as num?)?.toDouble() ?? 0.0),
      totalElevationGainedM:
          Value(remoteData['total_elevation_gained_m'] as int? ?? 0),
      totalTimeMinutes: Value(remoteData['total_time_minutes'] as int? ?? 0),
      isCompleted: Value(remoteData['is_completed'] as bool? ?? false),
      startedAt: Value(remoteData['started_at'] != null
          ? DateTime.tryParse(remoteData['started_at'] as String)
          : null),
      completedAt: Value(remoteData['completed_at'] != null
          ? DateTime.tryParse(remoteData['completed_at'] as String)
          : null),
    ));
    return true;
  }

  /// Merge une entree journal avec strategie LWW.
  Future<bool> _mergeJournalEntry(
      String trailId, Map<String, dynamic> remoteData) async {
    final remoteUpdatedAt = remoteData['updated_at'] as String?;
    final stageNumber = remoteData['stage_number'] as int? ?? 0;
    final localEntries = await journalDao.getByTrailId(trailId);
    final localEntry = localEntries.where((e) => e.stageNumber == stageNumber);
    if (localEntry.isNotEmpty && remoteUpdatedAt != null) {
      final local = localEntry.first;
      final localUpdatedAt = local.updatedAt?.toIso8601String() ??
          local.createdAt.toIso8601String();
      if (localUpdatedAt.compareTo(remoteUpdatedAt) > 0) return false;
    }
    await journalDao.insertEntry(JournalEntriesCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      content: Value(remoteData['content'] as String? ?? ''),
      photoPath: Value(remoteData['photo_path'] as String?),
      photoSizeBytes: Value(remoteData['photo_size_bytes'] as int?),
      createdAt: Value(remoteData['created_at'] != null
          ? DateTime.tryParse(remoteData['created_at'] as String) ??
              DateTime.now()
          : DateTime.now()),
      updatedAt: Value(remoteData['updated_at'] != null
          ? DateTime.tryParse(remoteData['updated_at'] as String)
          : null),
    ));
    return true;
  }

  /// Merge un item checklist avec strategie LWW.
  Future<bool> _mergeChecklistItem(
      String trailId, Map<String, dynamic> remoteData) async {
    final remoteUpdatedAt = remoteData['updated_at'] as String?;
    final itemId = remoteData['item_id'] as String? ?? '';
    final localItems = await checklistDao.getByTrailId(trailId);
    final localItem = localItems.where((i) => i.itemId == itemId);
    if (localItem.isNotEmpty && remoteUpdatedAt != null) {
      final local = localItem.first;
      final localUpdatedAt = local.updatedAt?.toIso8601String();
      if (localUpdatedAt != null &&
          localUpdatedAt.compareTo(remoteUpdatedAt) > 0) {
        return false;
      }
    }
    await checklistDao.upsertItem(ChecklistItemsCompanion(
      trailId: Value(trailId),
      itemId: Value(itemId),
      category: Value(remoteData['category'] as String? ?? ''),
      isChecked: Value(remoteData['is_checked'] as bool? ?? false),
      updatedAt: Value(remoteData['updated_at'] != null
          ? DateTime.tryParse(remoteData['updated_at'] as String)
          : null),
    ));
    return true;
  }
}

/// Provider Riverpod pour le service de restauration.
final restoreServiceProvider = Provider<RestoreService>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return RestoreService(
    progressDao: ProgressDao(db),
    journalDao: JournalDao(db),
    checklistDao: ChecklistDao(db),
    connectivityMonitor: connectivity,
    firebaseService: firebase,
  );
});
