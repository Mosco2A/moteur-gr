import "package:drift/drift.dart" hide isNull, isNotNull;
import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:moteur_gr/core/data/database.dart";
import "package:moteur_gr/core/data/daos/checklist_dao.dart";
import "package:moteur_gr/core/data/daos/hiker_profile_dao.dart";
import "package:moteur_gr/core/data/daos/journal_dao.dart";
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

/// Tests StepWays LOT 4 — miroir cloud ANONYME du profil (donnee SENSIBLE).
///
/// Firestore reel n'est pas mockable ici : on verifie (1) que les payloads
/// pousses sont ANONYMES (aucun nom/e-mail, AUCUN IMC — donnee derivee), a
/// partir de vraies donnees DAO, et (2) le GRACEFUL NO-OP (Firebase indispo /
/// hors-ligne / DAOs absents).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HikerProfileDao profileDao;
  late PastHikesDao pastHikesDao;
  late _FakeConnectivityMonitor connectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    profileDao = HikerProfileDao(db);
    pastHikesDao = PastHikesDao(db);
    connectivity = _FakeConnectivityMonitor();
  });
  tearDown(() async {
    await db.close();
  });

  CloudSyncService makeService({bool firebaseAvailable = false}) {
    return CloudSyncService(
      progressDao: ProgressDao(db),
      journalDao: JournalDao(db),
      checklistDao: ChecklistDao(db),
      syncQueueDao: SyncQueueDao(db),
      connectivityMonitor: connectivity,
      firebaseService:
          FirebaseService.testOnly(isAvailable: firebaseAvailable),
      hikerProfileDao: profileDao,
      pastHikesDao: pastHikesDao,
    );
  }

  group("payload profil ANONYME (art. 9)", () {
    test("profil -> morpho source + timestamp, AUCUN IMC ni nominatif",
        () async {
      final svc = makeService();
      final now = DateTime(2026, 9, 11, 12);
      await profileDao.upsert(HikerProfileCompanion.insert(
        userId: "hash-anon",
        age: const Value(42),
        heightCm: const Value(178),
        weightKg: const Value(74.5),
        sex: const Value("male"),
        countryIso: const Value("FR"),
        updatedAt: now,
      ));
      final profile = await profileDao.getByUserId("hash-anon");

      final payload = svc.buildHikerProfilePayload(profile!);

      expect(payload["age"], 42);
      expect(payload["height_cm"], 178);
      expect(payload["weight_kg"], 74.5);
      expect(payload["sex"], "male");
      expect(payload["country_iso"], "FR");
      expect(payload["updated_at"], now.toIso8601String());

      // Cle de securite : champs autorises uniquement.
      expect(payload.keys.toSet(), {
        "age",
        "height_cm",
        "weight_kg",
        "sex",
        "country_iso",
        "updated_at",
      });
      // AUCUN nominatif.
      expect(payload.containsKey("name"), isFalse);
      expect(payload.containsKey("email"), isFalse);
      expect(payload.containsKey("user_id"), isFalse);
      expect(payload.containsKey("uid"), isFalse);
      // AUCUN IMC (donnee derivee, recalculable local, jamais poussee).
      expect(payload.containsKey("bmi"), isFalse);
      expect(payload.containsKey("imc"), isFalse);
    });

    test("rando passee -> metriques d'effort + timestamp uniquement", () async {
      final svc = makeService();
      final now = DateTime(2026, 9, 11, 13);
      await pastHikesDao.insertHike(PastHikeEntriesCompanion.insert(
        userId: "hash-anon",
        date: DateTime(2026, 7, 1),
        days: const Value(3),
        avgWalkHoursPerDay: const Value(6),
        totalElevationGain: const Value(2100),
        totalDistanceKm: const Value(42),
        updatedAt: now,
      ));
      final hikes = await pastHikesDao.getByUserId("hash-anon");

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
      final result = await svc.syncHikerProfile("hash-anon");
      expect(result.status, CloudSyncStatusValues.idle);
      expect(result.itemsSynced, 0);
    });

    test("hors ligne -> idle", () async {
      final svc = makeService(firebaseAvailable: true);
      connectivity.status = ConnectivityStatusValues.offline;
      final result = await svc.syncHikerProfile("hash-anon");
      expect(result.status, CloudSyncStatusValues.idle);
    });

    test("DAOs profil non injectes -> idle (retro-compat)", () async {
      final svc = CloudSyncService(
        progressDao: ProgressDao(db),
        journalDao: JournalDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        // hikerProfileDao / pastHikesDao omis volontairement.
      );
      final result = await svc.syncHikerProfile("hash-anon");
      expect(result.status, CloudSyncStatusValues.idle);
      expect(result.itemsSynced, 0);
    });
  });
}
