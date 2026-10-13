import "dart:io";

import "package:drift/drift.dart" hide isNull, isNotNull;
import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:moteur_gr/core/data/database.dart";
import "package:moteur_gr/core/data/daos/checklist_dao.dart";
import "package:moteur_gr/core/data/daos/past_hikes_dao.dart";
import "package:moteur_gr/core/data/daos/progress_dao.dart";
import "package:moteur_gr/core/data/daos/sync_queue_dao.dart";
import "package:moteur_gr/core/firebase/firebase_service.dart";
import "package:moteur_gr/core/network/connectivity_monitor.dart";
import "package:moteur_gr/core/services/cloud_sync_service.dart";

/// Fake ConnectivityMonitor pilotable (online par defaut).
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus status = ConnectivityStatusValues.online;
  @override
  Future<ConnectivityStatus> checkStatus() async => status;
}

/// LES RANDOS PASSEES MONTENT, LA MORPHOLOGIE RESTE SUR LE TELEPHONE
/// (StepWays LOT 4, revu par la tache 635).
///
/// CE QUI A CHANGE LE 29/09. Ce fichier verifiait le miroir cloud du PROFIL :
/// age, taille, poids, sexe, pays, pousses sous `users/{uid}/profile/hiker`.
/// Decision de Christophe le meme jour : « Sauf les donnees persos ». La
/// morphologie est une donnee personnelle — et une donnee de sante au sens de
/// l article 9 — donc elle ne sort plus du telephone, au meme titre que la
/// fiche medicale (tache 612). Seules les RANDOS PASSEES montent : des
/// metriques d effort, sans trace, sans lieu, sans rien qui dise qui.
///
/// Firestore reel n est pas mockable ici : on verifie (1) que la charge utile
/// poussee est ANONYME, a partir de vraies donnees DAO, (2) le GRACEFUL NO-OP
/// (Firebase indispo / hors-ligne / DAO absent), et (3) que le chemin de sortie
/// de la morphologie a bien ete FERME, pas seulement laisse inutilise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PastHikesDao pastHikesDao;
  late _FakeConnectivityMonitor connectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    pastHikesDao = PastHikesDao(db);
    connectivity = _FakeConnectivityMonitor();
  });
  tearDown(() async {
    await db.close();
  });

  CloudSyncService makeService({bool firebaseAvailable = false}) {
    return CloudSyncService(
      progressDao: ProgressDao(db),
      checklistDao: ChecklistDao(db),
      syncQueueDao: SyncQueueDao(db),
      connectivityMonitor: connectivity,
      firebaseService: FirebaseService.testOnly(isAvailable: firebaseAvailable),
      pastHikesDao: pastHikesDao,
    );
  }

  group("la morphologie ne peut plus sortir du telephone (tache 635)", () {
    final service = File("lib/core/services/cloud_sync_service.dart");

    test("le chemin `profile/hiker` n est plus emprunte", () {
      expect(
        service.readAsStringSync(),
        isNot(contains('collection("profile")')),
        reason:
            "age, taille, poids et sexe partaient par la. Ils restent sur "
            "le telephone, comme la fiche medicale (tache 612).",
      );
    });

    test("le constructeur de charge morphologique n existe plus", () {
      expect(
        service.readAsStringSync(),
        isNot(contains("buildHikerProfilePayload")),
        reason:
            "un constructeur de charge qui survit a son chemin de sortie "
            "est une invitation a le rebrancher.",
      );
    });
  });

  group("payload rando passee ANONYME (art. 9)", () {
    test("rando passee -> metriques d'effort + timestamp uniquement", () async {
      final svc = makeService();
      final now = DateTime(2026, 9, 11, 13);
      await pastHikesDao.insertHike(
        PastHikeEntriesCompanion.insert(
          userId: "local",
          date: DateTime(2026, 7, 1),
          days: const Value(3),
          avgWalkHoursPerDay: const Value(6),
          totalElevationGain: const Value(2100),
          totalDistanceKm: const Value(42),
          updatedAt: now,
        ),
      );
      final hikes = await pastHikesDao.getByUserId("local");

      final payload = svc.buildPastHikePayload(hikes.first);

      expect(payload["days"], 3);
      expect(payload["total_elevation_gain"], 2100);
      expect(payload["total_distance_km"], 42);
      expect(payload.keys.toSet(), {
        "date",
        "days",
        "avg_walk_hours_per_day",
        "total_elevation_gain",
        "total_distance_km",
        "updated_at",
      });
      expect(payload.containsKey("name"), isFalse);
      expect(payload.containsKey("user_id"), isFalse);
    });
  });

  group("graceful no-op", () {
    test("Firebase indisponible -> idle, rien pousse", () async {
      final svc = makeService(firebaseAvailable: false);
      final result = await svc.syncPastHikes("uid-auth");
      expect(result.status, CloudSyncStatusValues.idle);
      expect(result.itemsSynced, 0);
    });

    test("hors ligne -> idle", () async {
      final svc = makeService(firebaseAvailable: true);
      connectivity.status = ConnectivityStatusValues.offline;
      final result = await svc.syncPastHikes("uid-auth");
      expect(result.status, CloudSyncStatusValues.idle);
    });

    test("DAO randos non injecte -> idle (retro-compat)", () async {
      final svc = CloudSyncService(
        progressDao: ProgressDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        // pastHikesDao omis volontairement.
      );
      final result = await svc.syncPastHikes("uid-auth");
      expect(result.status, CloudSyncStatusValues.idle);
      expect(result.itemsSynced, 0);
    });
  });
}
