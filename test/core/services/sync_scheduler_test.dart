import "dart:async";

import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:moteur_gr/core/data/database.dart";
import "package:moteur_gr/core/data/daos/checklist_dao.dart";
import "package:moteur_gr/core/data/daos/progress_dao.dart";
import "package:moteur_gr/core/data/daos/sync_queue_dao.dart";
import "package:moteur_gr/core/firebase/firebase_service.dart";
import "package:moteur_gr/core/models/sync_config.dart";
import "package:moteur_gr/core/network/connectivity_monitor.dart";
import "package:moteur_gr/core/services/cloud_sync_service.dart";
import "package:moteur_gr/core/services/sync_scheduler.dart";

/// Fake ConnectivityMonitor avec flux pilotable.
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

/// CYCLE DE VIE DE LA MONTEE (tache 635).
///
/// Le COMPORTEMENT — une ecriture locale qui arrive au serveur, le rattrapage
/// apres coupure, la fiche technique — se prouve dans
/// `test/comportement/montee_en_base_635_test.dart`, avec une fausse Firestore.
/// Ici on ne tient que les proprietes de l objet lui-meme : s armer, se
/// desarmer, ne pas s armer sans identite, et ne rien faire quand il n y a pas
/// de destinataire.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeConnectivityMonitor connectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = FakeConnectivityMonitor();
  });
  tearDown(() async {
    connectivity.dispose();
    await db.close();
  });

  SyncScheduler fabriquer({bool firebase = false}) {
    final service = FirebaseService.testOnly(isAvailable: firebase);
    return SyncScheduler(
      cloudSyncService: CloudSyncService(
        progressDao: ProgressDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: service,
      ),
      connectivityMonitor: connectivity,
      firebaseService: service,
      progressDao: ProgressDao(db),
      attenteAvantMontee: const Duration(milliseconds: 20),
      observerLeCycleDeVie: false,
    );
  }

  group("cycle de vie", () {
    test("desarmee tant que personne ne l a demarree", () {
      expect(fabriquer().isRunning, isFalse);
    });

    test("un identifiant vide ne l arme pas", () async {
      final m = fabriquer(firebase: true);
      await m.demarrer(userId: "");
      expect(
        m.isRunning,
        isFalse,
        reason:
            "sans identifiant de compte il n y a pas de users/{uid} a "
            "ecrire : s armer serait promettre une montee impossible",
      );
    });

    test("arreter apres demarrer remet tout a zero", () async {
      final m = fabriquer(firebase: true);
      await m.demarrer(userId: "uid-test");
      expect(m.isRunning, isTrue);
      await m.arreter();
      expect(m.isRunning, isFalse);
      expect(m.monteeEnAttente, isFalse);
    });

    test("sans Firebase, une passe ne fait rien et ne leve pas", () async {
      final m = fabriquer();
      await m.demarrer(userId: "uid-test");
      expect(await m.monterMaintenant("test"), 0);
      await m.arreter();
    });

    test("une ecriture signalee avant le demarrage n arme aucun minuteur", () {
      final m = fabriquer(firebase: true);
      m.signalerUneEcritureLocale();
      expect(m.monteeEnAttente, isFalse);
    });

    test(
      "une ecriture signalee apres le demarrage arme le regroupement",
      () async {
        final m = fabriquer(firebase: true);
        await m.demarrer(userId: "uid-test");
        m.signalerUneEcritureLocale();
        expect(m.monteeEnAttente, isTrue);
        await m.arreter();
      },
    );
  });

  group("le delai de regroupement", () {
    test("trois secondes au plus par defaut", () {
      expect(
        SyncScheduler.attenteParDefaut,
        lessThanOrEqualTo(const Duration(seconds: 3)),
      );
    });

    test("le rattrapage au retour du reseau peut etre coupe par la config", () {
      const sans = SyncConfig(syncOnReconnect: false);
      expect(sans.syncOnReconnect, isFalse);
      const parDefaut = SyncConfig();
      expect(parDefaut.syncOnReconnect, isTrue);
    });
  });
}
