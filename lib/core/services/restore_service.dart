import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../data/database.dart';
import '../data/daos/checklist_dao.dart';
import '../data/daos/journal_dao.dart';
import '../data/daos/progress_dao.dart';
import '../data/daos/hiker_profile_dao.dart';
import '../data/daos/past_hikes_dao.dart';
import '../firebase/firebase_service.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'consent_service.dart';
import 'data_retention_service.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Code d erreur : appareil hors ligne.
const kRestoreErrorOffline = 'offline';

/// Code d erreur : Firebase indisponible.
const kRestoreErrorFirebaseUnavailable = 'firebase_unavailable';

/// Code d erreur : consentement art. 9 (donnee de sante) absent ou revoque.
///
/// Une restauration FAIT DESCENDRE de la donnee de sante sur l'appareil : sans
/// consentement effectif, elle est refusee (tache 561, J2).
const kRestoreErrorHealthConsentMissing = 'health_consent_missing';

/// Code d erreur : le randonneur a exerce son droit a l'effacement SUR CET
/// APPAREIL (tache 565, LOT N, N2).
///
/// Ce n'est pas une panne, c'est un REFUS — et il est NOMME pour qu'aucun
/// appelant ne le confonde avec un hors-ligne, un Firebase indisponible ou une
/// absence de sauvegarde cloud.
const kRestoreErrorErasedLocally = 'erased_locally';

/// Resultat de la verification de restauration.
class RestoreCheck {
  const RestoreCheck({
    required this.hasCloudData,
    this.cloudItemCount = 0,
    this.lastCloudSync,
    this.erasedLocally = false,
  });
  final bool hasCloudData;
  final int cloudItemCount;
  final DateTime? lastCloudSync;

  /// Vrai quand il n'y a rien a proposer PARCE QUE le randonneur a efface ses
  /// donnees ici (tache 565, N2). Un « rien a restaurer » muet serait un autre
  /// mensonge : l'ecran qui posera la question doit pouvoir dire pourquoi.
  final bool erasedLocally;
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
    this.hikerProfileDao,
    this.pastHikesDao,
    ConsentCheck? consentCheck,
    LocalErasureCheck? localErasureCheck,
    FirebaseFirestore? firestore,
  })  : consentCheck = consentCheck ?? consentFromLocalStore,
        localErasureCheck = localErasureCheck ?? localErasureFromStore,
        _firestore = firestore;

  final ProgressDao progressDao;
  final JournalDao journalDao;
  final ChecklistDao checklistDao;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;

  /// DAO du profil randonneur (restauration au changement de tel, LOT 4).
  final HikerProfileDao? hikerProfileDao;

  /// DAO des randos passees + note (restauration au changement de tel, LOT 4).
  final PastHikesDao? pastHikesDao;

  /// Verification de consentement de la garde art. 9 (tache 561, J2). JAMAIS
  /// nulle : a defaut d'injection, lit l'etat REEL du stockage local.
  final ConsentCheck consentCheck;

  /// Verification « ce telephone a-t-il exerce son droit a l'effacement ? »
  /// (tache 565, N2). JAMAIS nulle non plus : a defaut d'injection, lit le
  /// marqueur REEL pose par [DataRetentionService.deleteAccountData].
  final LocalErasureCheck localErasureCheck;

  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init pour les tests).
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// LE DROIT A L'EFFACEMENT A-T-IL ETE EXERCE SUR CET APPAREIL ? (tache 565,
  /// LOT N, N2.)
  ///
  /// Une restauration REECRIT en local ce que le miroir cloud detient encore.
  /// Apres un effacement art. 17, la faire, c'est defaire le droit que le
  /// randonneur vient d'exercer — et la fusion « dernier ecrit gagne » ne peut
  /// rien y faire : le local etant vide, le distant gagne toujours.
  ///
  /// PROTEGEE PAR SA PROPRE ERREUR : si la verification elle-meme echoue, on
  /// considere qu'il Y A EU effacement. Un doute se tranche du cote de la
  /// personne. L'echec est journalise — ce n'est pas un catch silencieux, la
  /// decision prise est explicite.
  Future<bool> _aExerceSonDroitALEffacement() async {
    try {
      return await localErasureCheck();
    } catch (e) {
      _log.e('[Restore] Marqueur d effacement illisible ($e) -> REFUS');
      return true;
    }
  }

  /// Verifie si des donnees cloud existent pour cet utilisateur.
  ///
  /// GARDE D'EFFACEMENT EN PREMIER (N2) : apres un effacement local, on ne
  /// PROPOSE pas de restaurer — et la RAISON est portee par [RestoreCheck],
  /// jamais tue. Un « rien a restaurer » muet ferait croire a une absence de
  /// sauvegarde, alors que la vraie raison est un droit exerce.
  Future<RestoreCheck> checkAndRestore(String userId) async {
    if (await _aExerceSonDroitALEffacement()) {
      _log.w('[Restore] Effacement local -> aucune restauration proposee');
      return const RestoreCheck(hasCloudData: false, erasedLocally: true);
    }
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
  ///
  /// GARDE D'EFFACEMENT (tache 565, N2), EN PREMIER ET DANS LA METHODE : il
  /// n'existe encore aucun appelant en production, et c'est precisement pour
  /// cela qu'elle ne peut pas dependre de lui. Le refus est NOMME
  /// ([kRestoreErrorErasedLocally]), jamais confondu avec un hors-ligne.
  Future<RestoreResult> restoreFromCloud(String userId) async {
    if (await _aExerceSonDroitALEffacement()) {
      _log.w('[Restore] Effacement local -> restauration REFUSEE');
      return const RestoreResult(
        success: false,
        error: kRestoreErrorErasedLocally,
      );
    }
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

  /// Restaure le profil randonneur ANONYME depuis Firestore (StepWays LOT 4).
  ///
  /// Changement de telephone : se reconnecter avec le meme compte Apple/Google
  /// redonne le meme [userId] hash (`anonymous_id_service`) -> on relit
  /// `users/{uid}/profile/hiker`, `users/{uid}/past_hikes/*` et la note, et on
  /// hydrate le miroir Drift local. Donnee SENSIBLE : rien de nominatif cote
  /// serveur (hash seul). GRACEFUL NO-OP si DAOs non injectes / hors-ligne /
  /// Firebase indisponible.
  ///
  /// GARDE ART. 9 (tache 561, J2) : sans consentement `healthData` EFFECTIF,
  /// aucune donnee de sante ne redescend sur l'appareil. La garde est DANS la
  /// methode — il n'existe encore aucun appelant en production, et c'est
  /// precisement pour cela qu'elle ne peut pas dependre de lui.
  ///
  /// GARDE D'EFFACEMENT (tache 565, N2), ET ELLE PASSE DEVANT L'ARTICLE 9. Le
  /// consentement sante NE SUFFISAIT PAS : il ferme bien cette porte tant que
  /// l'effacement vient de retirer tous les consentements, mais un consentement
  /// SE RE-ACCORDE. Le randonneur qui continue d'utiliser l'application et
  /// ré-accorde la sante rouvrait la porte sur des donnees qu'il avait fait
  /// effacer. Un consentement dit « j'accepte ce traitement » ; il ne dit pas
  /// « rendez-moi ce que j'ai efface ». Le refus le plus fort est donc pose en
  /// premier, et c'est lui qui est nomme.
  Future<RestoreResult> restoreHikerProfile(String userId) async {
    if (await _aExerceSonDroitALEffacement()) {
      _log.w('[Restore] Effacement local -> profil NON restaure');
      return const RestoreResult(
        success: false,
        error: kRestoreErrorErasedLocally,
      );
    }
    if (!await consentCheck(ConsentPurpose.healthData)) {
      _log.w('[Restore] Consentement sante absent -> restauration REFUSEE');
      return const RestoreResult(
        success: false,
        error: kRestoreErrorHealthConsentMissing,
      );
    }
    if (hikerProfileDao == null || pastHikesDao == null) {
      return const RestoreResult(success: false, error: 'daos_absent');
    }
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
      int restored = 0;
      final base = firestore.collection('users').doc(userId);

      // 1. Profil (singleton).
      final profileSnap = await base.collection('profile').doc('hiker').get();
      final pdata = profileSnap.data();
      if (pdata != null) {
        await hikerProfileDao!.upsert(HikerProfileCompanion(
          userId: Value(userId),
          age: Value(pdata['age'] as int? ?? 0),
          heightCm: Value(pdata['height_cm'] as int? ?? 0),
          weightKg: Value((pdata['weight_kg'] as num?)?.toDouble() ?? 0),
          sex: Value(pdata['sex'] as String?),
          countryIso: Value(pdata['country_iso'] as String? ?? ''),
          updatedAt: Value(DateTime.tryParse(
                  pdata['updated_at'] as String? ?? '') ??
              DateTime.now()),
        ));
        restored++;
      }

      // 2. Randos passees (remplace la liste locale par la version cloud).
      final hikesSnap = await base.collection('past_hikes').get();
      if (hikesSnap.docs.isNotEmpty) {
        await pastHikesDao!.deleteAllForUser(userId);
        for (final doc in hikesSnap.docs) {
          final h = doc.data();
          await pastHikesDao!.insertHike(PastHikeEntriesCompanion(
            userId: Value(userId),
            date: Value(
                DateTime.tryParse(h['date'] as String? ?? '') ??
                    DateTime.now()),
            days: Value(h['days'] as int? ?? 1),
            avgWalkHoursPerDay:
                Value((h['avg_walk_hours_per_day'] as num?)?.toDouble() ?? 0),
            totalElevationGain: Value(h['total_elevation_gain'] as int? ?? 0),
            totalDistanceKm:
                Value((h['total_distance_km'] as num?)?.toDouble() ?? 0),
            updatedAt: Value(DateTime.tryParse(
                    h['updated_at'] as String? ?? '') ??
                DateTime.now()),
          ));
          restored++;
        }
      }

      // 3. Note d'experience globale.
      final noteSnap =
          await base.collection('profile').doc('experience_note').get();
      final ndata = noteSnap.data();
      if (ndata != null) {
        await pastHikesDao!.upsertNote(HikerExperienceNoteCompanion(
          userId: Value(userId),
          freeTextDifficulties:
              Value(ndata['free_text_difficulties'] as String? ?? ''),
          updatedAt: Value(DateTime.tryParse(
                  ndata['updated_at'] as String? ?? '') ??
              DateTime.now()),
        ));
        restored++;
      }

      _log.d('[Restore] Profil restaure: $restored items');
      return RestoreResult(success: true, itemsRestored: restored);
    } catch (e) {
      _log.e('[Restore] Erreur restauration profil: $e');
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
    hikerProfileDao: db.hikerProfileDao,
    pastHikesDao: db.pastHikesDao,
  );
});
