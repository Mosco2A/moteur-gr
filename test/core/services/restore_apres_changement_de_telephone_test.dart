import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/restore_service.dart';

/// Fake ConnectivityMonitor pour les tests.
class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;
  void setStatus(ConnectivityStatus s) => _status = s;
  @override
  Future<ConnectivityStatus> checkStatus() async => _status;
}

/// Tests E4.16 — restauration sur un nouveau telephone.
/// Fixtures neutres (sentier fictif volcans).
void main() {
  // TACHE 565 (LOT N, N2) : `RestoreService` consulte desormais le MARQUEUR
  // D'EFFACEMENT LOCAL avant toute restauration, et ce marqueur vit dans les
  // SharedPreferences. Sans store simule, la lecture leve — et la garde, FERMEE
  // PAR DEFAUT, refuserait la restauration. Ces tests-ci portent sur le
  // hors-ligne et sur Firebase indisponible : ils doivent donc partir d'un
  // appareil ou AUCUN effacement n'a eu lieu, sinon ils mesureraient le refus
  // d'effacement en croyant mesurer le leur.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProgressDao progressDao;
  late JournalDao journalDao;
  late ChecklistDao checklistDao;
  late FakeConnectivityMonitor connectivity;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase(NativeDatabase.memory());
    progressDao = ProgressDao(db);
    journalDao = JournalDao(db);
    checklistDao = ChecklistDao(db);
    connectivity = FakeConnectivityMonitor();
  });
  tearDown(() async {
    await db.close();
  });

  // LE SECOND ORDONNANCEUR A ETE RETIRE (tache 635)
  //
  // Ici vivaient deux tests de `BackgroundSyncService` : son cycle de vie et
  // son `syncNow` sans Firebase. Le service lui-meme n avait AUCUN appelant
  // dans `lib/` — pas plus que `SyncScheduler`, l autre ordonnanceur. Deux
  // horloges mortes pour un seul travail : la montee en base a garde la
  // premiere (`sync_scheduler.dart`, desormais branchee depuis `main.dart`) et
  // supprime celle-ci. Ces deux tests prouvaient le bon fonctionnement d un
  // objet que personne n utilisait ; ce qui compte se prouve maintenant dans
  // `test/comportement/montee_en_base_635_test.dart`.

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
