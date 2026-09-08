import "package:drift/drift.dart" hide isNull, isNotNull;
import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:moteur_gr/core/data/database.dart";
import "package:moteur_gr/core/data/daos/checklist_dao.dart";
import "package:moteur_gr/core/data/daos/journal_dao.dart";
import "package:moteur_gr/core/data/daos/progress_dao.dart";
import "package:moteur_gr/core/data/daos/sync_queue_dao.dart";
import "package:moteur_gr/core/data/daos/trek_entitlements_dao.dart";
import "package:moteur_gr/core/data/daos/wallet_dao.dart";
import "package:moteur_gr/core/firebase/firebase_service.dart";
import "package:moteur_gr/core/network/connectivity_monitor.dart";
import "package:moteur_gr/core/services/cloud_sync_service.dart";

/// Fake ConnectivityMonitor pilotable (online par defaut).
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus status = ConnectivityStatusValues.online;
  @override
  Future<ConnectivityStatus> checkStatus() async => status;
}

/// Tests ST8 — miroir cloud wallet NON NOMINATIF (A5 / spec §5).
///
/// Firestore reel n'est pas mockable ici (pas de fake_cloud_firestore en
/// stack) : on verifie donc (1) le CONTENU non nominatif des payloads pousses
/// (entiers + timestamps + trailId only ; zero nominatif, zero euro, zero
/// receipt) via les builders purs, a partir de vraies donnees DAO, et (2) le
/// GRACEFUL NO-OP quand Firebase est indispo / DAOs absents.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletDao walletDao;
  late TrekEntitlementsDao entitlementsDao;
  late _FakeConnectivityMonitor connectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    walletDao = WalletDao(db);
    entitlementsDao = TrekEntitlementsDao(db);
    connectivity = _FakeConnectivityMonitor();
  });
  tearDown(() async {
    await db.close();
  });

  /// Fabrique un service avec DAOs wallet injectes (Firebase indispo par
  /// defaut pour le no-op ; les builders purs n'ont pas besoin de reseau).
  CloudSyncService makeService({bool firebaseAvailable = false}) {
    return CloudSyncService(
      progressDao: ProgressDao(db),
      journalDao: JournalDao(db),
      checklistDao: ChecklistDao(db),
      syncQueueDao: SyncQueueDao(db),
      connectivityMonitor: connectivity,
      firebaseService:
          FirebaseService.testOnly(isAvailable: firebaseAvailable),
      walletDao: walletDao,
      entitlementsDao: entitlementsDao,
    );
  }

  group("payload wallet non nominatif", () {
    test("balance -> entiers + updated_at, rien d'autre", () async {
      final svc = makeService();
      final now = DateTime(2026, 9, 8, 12);
      await walletDao.upsert(WalletBalanceCompanion.insert(
        userId: "hash-anon",
        balanceSteps: const Value(42),
        lifetimeEarnedSteps: const Value(100),
        lifetimeSpentSteps: const Value(58),
        updatedAt: now,
      ));
      final wallet = await walletDao.getByUserId("hash-anon");

      final payload = svc.buildWalletPayload(wallet!);

      // Contenu attendu : uniquement entiers + timestamp.
      expect(payload["balance_steps"], 42);
      expect(payload["lifetime_earned"], 100);
      expect(payload["lifetime_spent"], 58);
      expect(payload["updated_at"], now.toIso8601String());

      // Cle de non nominativite : aucun champ interdit.
      expect(payload.keys.toSet(), {
        "balance_steps",
        "lifetime_earned",
        "lifetime_spent",
        "updated_at",
      });
      expect(payload.containsKey("user_id"), isFalse);
      expect(payload.containsKey("uid"), isFalse);
      expect(payload.containsKey("email"), isFalse);
      expect(payload.containsKey("price"), isFalse);
      expect(payload.containsKey("receipt"), isFalse);
      // Toutes les valeurs sont des entiers ou une String (timestamp).
      for (final v in payload.values) {
        expect(v is int || v is String, isTrue);
      }
    });

    test("entitlement -> owned/entiers/updated_at, pas d'euro ni receipt",
        () async {
      final svc = makeService();
      final now = DateTime(2026, 9, 8, 13);
      await entitlementsDao.upsert(TrekEntitlementsCompanion.insert(
        trailId: "gr20",
        owned: const Value(true),
        acquiredStages: const Value(16),
        totalStages: const Value(16),
        consumedComplementSteps: const Value(5),
        purchaseSource: const Value("wallet"),
        purchasedAt: Value(now),
        updatedAt: now,
      ));
      final e = await entitlementsDao.getByTrailId("gr20");

      final payload = svc.buildEntitlementPayload(e!);

      expect(payload["owned"], true);
      expect(payload["acquired_steps"], 16);
      expect(payload["consumed_complement_steps"], 5);
      expect(payload["updated_at"], now.toIso8601String());

      // Non nominatif : pas de purchaseSource/purchasedAt/euro/receipt pousses.
      expect(payload.keys.toSet(), {
        "owned",
        "acquired_steps",
        "consumed_complement_steps",
        "updated_at",
      });
      expect(payload.containsKey("purchase_source"), isFalse);
      expect(payload.containsKey("purchased_at"), isFalse);
      expect(payload.containsKey("price_eur"), isFalse);
      expect(payload.containsKey("receipt"), isFalse);
    });
  });

  group("graceful no-op", () {
    test("Firebase indisponible -> idle, rien pousse", () async {
      final svc = makeService(firebaseAvailable: false);
      final result = await svc.syncWallet("hash-anon");
      expect(result.status, CloudSyncStatusValues.idle);
      expect(result.itemsSynced, 0);
    });

    test("hors ligne -> idle", () async {
      final svc = makeService(firebaseAvailable: true);
      connectivity.status = ConnectivityStatusValues.offline;
      final result = await svc.syncWallet("hash-anon");
      expect(result.status, CloudSyncStatusValues.idle);
    });

    test("DAOs wallet non injectes -> idle (retro-compat)", () async {
      final svc = CloudSyncService(
        progressDao: ProgressDao(db),
        journalDao: JournalDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        // walletDao / entitlementsDao omis volontairement.
      );
      final result = await svc.syncWallet("hash-anon");
      expect(result.status, CloudSyncStatusValues.idle);
      expect(result.itemsSynced, 0);
    });
  });
}
