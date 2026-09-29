// TACHE 561 (LOT J) — LA GARDE DE CONSENTEMENT ART. 9 EXISTE-T-ELLE VRAIMENT ?
//
// POURQUOI CE FICHIER EXISTE. `cloud_sync_service.dart` portait ce commentaire
// au-dessus de `syncHikerProfile` : « GARDE-FOU consentement : l'appelant DOIT
// verifier `ConsentPurpose.healthData` ». Aucune verification n'existait — ni
// dans la methode, ni chez un appelant, puisqu'il n'y a encore AUCUN appelant
// en production. Rien ne fuyait donc aujourd'hui, et rien n'aurait empeche la
// fuite le jour du branchement. Meme situation pour
// `RestoreService.restoreHikerProfile`, qui REDESCEND de la donnee de sante sur
// l'appareil.
//
// Une garde qui compte sur la discipline d'un appelant futur n'est pas une
// garde : ces tests exigent qu'elle soit DANS la methode, et qu'elle soit
// FERMEE PAR DEFAUT (pas de consentement lisible = refus).

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/data/daos/sync_queue_dao.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/cloud_sync_service.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/core/services/restore_service.dart';

/// Connectivite pilotable (en ligne par defaut).
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus status = ConnectivityStatusValues.online;
  @override
  Future<ConnectivityStatus> checkStatus() async => status;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeConnectivityMonitor connectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = _FakeConnectivityMonitor();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await db.close();
  });

  CloudSyncService makeSync({ConsentCheck? consent}) => CloudSyncService(
        progressDao: ProgressDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        pastHikesDao: db.pastHikesDao,
        consentCheck: consent,
      );

  RestoreService makeRestore({ConsentCheck? consent}) => RestoreService(
        progressDao: ProgressDao(db),
        journalDao: JournalDao(db),
        checklistDao: ChecklistDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        hikerProfileDao: db.hikerProfileDao,
        pastHikesDao: db.pastHikesDao,
        consentCheck: consent,
      );

  Future<void> seedRandoPassee() async {
    await db.pastHikesDao.insertHike(PastHikeEntriesCompanion.insert(
      userId: 'local',
      date: DateTime.utc(2026, 6, 15),
      days: const Value(4),
      totalElevationGain: const Value(3200),
      totalDistanceKm: const Value(58),
      updatedAt: DateTime.utc(2026, 6, 20),
    ));
  }

  // LA GARDE A CHANGE DE PORTE, PAS DE NATURE (tache 635). Elle protegeait
  // `syncHikerProfile`, qui poussait la MORPHOLOGIE. Cette montee n existe plus
  // — la morphologie reste sur le telephone, decision de Christophe du 29/09 :
  // « Sauf les donnees persos ». La garde tient desormais `syncPastHikes` : une
  // rando passee decrit l effort physique d une personne, et sans consentement
  // `healthData` EFFECTIF elle ne sort pas plus que le reste.
  group('CloudSyncService.syncPastHikes — garde art. 9 DANS la methode', () {
    test('consentement sante ABSENT -> refus, aucune ecriture tentee',
        () async {
      await seedRandoPassee();
      // Consentement jamais donne (prefs vides) : la garde par defaut lit le
      // stockage reel et doit refuser.
      final result = await makeSync().syncPastHikes('uid-auth');

      expect(result.status, CloudSyncStatusValues.idle);
      expect(result.itemsSynced, 0);
      expect(result.error, kSyncErrorHealthConsentMissing,
          reason: 'le refus doit etre NOMME, pas confondu avec un hors-ligne');
    });

    test('consentement sante REVOQUE -> refus (le retrait est immediat)',
        () async {
      await seedRandoPassee();
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.healthData);
      await consent.revoke(ConsentPurpose.healthData);

      final result = await makeSync().syncPastHikes('uid-auth');

      expect(result.error, kSyncErrorHealthConsentMissing);
      consent.dispose();
    });

    test('une AUTRE finalite accordee n ouvre PAS la porte a la sante',
        () async {
      await seedRandoPassee();
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.locationNavigation);
      await consent.grant(ConsentPurpose.socialSharing);

      final result = await makeSync().syncPastHikes('uid-auth');

      expect(result.error, kSyncErrorHealthConsentMissing,
          reason: 'art. 9 : consentement SEPARE, jamais groupe');
      consent.dispose();
    });

    test('la garde est FERMEE PAR DEFAUT si l etat est illisible', () async {
      await seedRandoPassee();
      // Etat de consentement corrompu : impossible de conclure => on refuse.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'consent_healthData': 'ceci n est pas du JSON',
      });
      final result = await makeSync().syncPastHikes('uid-auth');
      expect(result.error, kSyncErrorHealthConsentMissing,
          reason: 'un doute sur le consentement se tranche par le refus');
    });

    test('consentement ACCORDE -> la garde laisse passer', () async {
      await seedRandoPassee();
      var checked = false;
      final result = await makeSync(consent: (purpose) async {
        checked = purpose == ConsentPurpose.healthData;
        return true;
      }).syncPastHikes('uid-auth');

      expect(checked, isTrue,
          reason: 'la garde doit interroger la finalite SANTE');
      // Firestore n'est pas joignable en test : on n'exige pas un succes, mais
      // on exige que le refus de consentement ne soit PLUS la raison.
      expect(result.error, isNot(kSyncErrorHealthConsentMissing));
    });
  });

  group('RestoreService.restoreHikerProfile — garde art. 9 DANS la methode',
      () {
    test('consentement sante ABSENT -> refus, rien ne redescend', () async {
      final result = await makeRestore().restoreHikerProfile('hash-anon');

      expect(result.success, isFalse);
      expect(result.error, kRestoreErrorHealthConsentMissing);
      expect((await db.select(db.hikerProfile).get()), isEmpty,
          reason: 'aucune donnee de sante ne doit atterrir sur l appareil');
    });

    test('consentement ACCORDE -> la garde laisse passer', () async {
      var checked = false;
      final result = await makeRestore(consent: (purpose) async {
        checked = purpose == ConsentPurpose.healthData;
        return true;
      }).restoreHikerProfile('hash-anon');

      expect(checked, isTrue);
      expect(result.error, isNot(kRestoreErrorHealthConsentMissing));
    });
  });

  // TACHE 562 (LOT K, K3) — LE BLOB DE FICHE SANTE : CE GROUPE N'EXISTE PLUS,
  // ET SON SUJET NON PLUS (retire par la tache 612).
  //
  // CE QU'IL TESTAIT. `HealthBackupService` chiffrait la fiche de renseignement
  // medical (groupe sanguin, allergies, traitements — article 9) et deposait le
  // blob dans le miroir cloud anonyme. Le LOT K y avait pose une garde de
  // consentement, fermee par defaut, et huit tests la tenaient.
  //
  // POURQUOI ILS SONT PARTIS AVEC LUI. Decision de Christophe du 28/09 10:42,
  // verbatim et en majuscules dans son message : « NON ON NE TROUVERAIT RIEN !!!
  // Les donnees medicales RESTENT sur le tel !!! ». Version dure : pas de
  // sauvegarde distante, meme chiffree, MEME AVEC CONSENTEMENT. La garde du LOT K
  // demandait l'accord avant de faire sortir la fiche ; il n'y a plus d'accord a
  // demander parce qu'il n'y a plus de sortie. Le service est supprime, et le
  // transport refuse tout document absent de `DocumentsDuCoffreDistant.autorises`.
  //
  // CE QUI A PRIS LEUR PLACE, ET C'EST PLUS FORT :
  // `test/comportement/fiche_medicale_locale_612_test.dart` ne demande plus
  // « l'accord a-t-il ete demande ? » mais « un chemin de sortie existe-t-il ? »,
  // et il devient ROUGE le jour ou quelqu'un en rouvre un de bonne foi.
  //
  // CE QUI RESTE DANS CE FICHIER : la garde de `syncPastHikes` (les randos
  // passees, seule chose du profil qui monte encore depuis la tache 635) et
  // celle de `restoreHikerProfile`, qui porte la MORPHOLOGIE dans l autre sens
  // — le telephone ne l ENVOIE plus, mais il sait encore RECEVOIR celle qu un
  // compte existant aurait deposee hier. Deux donnees, deux sujets : ne pas les
  // confondre avec la fiche medicale.

  group('ConsentCheck par defaut — lecture du stockage reel', () {
    test('sans decision enregistree -> false', () async {
      expect(await consentFromLocalStore(ConsentPurpose.healthData), isFalse);
    });

    test('apres grant -> true ; apres revoke -> false', () async {
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.healthData);
      expect(await consentFromLocalStore(ConsentPurpose.healthData), isTrue);
      await consent.revoke(ConsentPurpose.healthData);
      expect(await consentFromLocalStore(ConsentPurpose.healthData), isFalse);
      consent.dispose();
    });

    test('etat corrompu -> false (fail-closed, pas d exception qui remonte)',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'consent_healthData': '{{{',
      });
      expect(await consentFromLocalStore(ConsentPurpose.healthData), isFalse);
    });
  });
}
