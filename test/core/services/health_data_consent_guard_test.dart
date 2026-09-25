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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/daos/health_info_dao.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/data/daos/sync_queue_dao.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/cloud_sync_service.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/core/services/restore_service.dart';
import 'package:moteur_gr/core/services/secure_vault_service.dart';
import 'package:moteur_gr/features/safety/data/health_backup_service.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';

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
        journalDao: JournalDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        hikerProfileDao: db.hikerProfileDao,
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

  Future<void> seedProfile() async {
    await db.hikerProfileDao.upsert(HikerProfileCompanion.insert(
      userId: 'hash-anon',
      age: const Value(72),
      heightCm: const Value(172),
      weightKg: const Value(88),
      updatedAt: DateTime.utc(2026, 6, 15),
    ));
  }

  group('CloudSyncService.syncHikerProfile — garde art. 9 DANS la methode', () {
    test('consentement sante ABSENT -> refus, aucune ecriture tentee',
        () async {
      await seedProfile();
      // Consentement jamais donne (prefs vides) : la garde par defaut lit le
      // stockage reel et doit refuser.
      final result = await makeSync().syncHikerProfile('hash-anon');

      expect(result.status, CloudSyncStatusValues.idle);
      expect(result.itemsSynced, 0);
      expect(result.error, kSyncErrorHealthConsentMissing,
          reason: 'le refus doit etre NOMME, pas confondu avec un hors-ligne');
    });

    test('consentement sante REVOQUE -> refus (le retrait est immediat)',
        () async {
      await seedProfile();
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.healthData);
      await consent.revoke(ConsentPurpose.healthData);

      final result = await makeSync().syncHikerProfile('hash-anon');

      expect(result.error, kSyncErrorHealthConsentMissing);
      consent.dispose();
    });

    test('une AUTRE finalite accordee n ouvre PAS la porte a la sante',
        () async {
      await seedProfile();
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.locationNavigation);
      await consent.grant(ConsentPurpose.socialSharing);

      final result = await makeSync().syncHikerProfile('hash-anon');

      expect(result.error, kSyncErrorHealthConsentMissing,
          reason: 'art. 9 : consentement SEPARE, jamais groupe');
      consent.dispose();
    });

    test('la garde est FERMEE PAR DEFAUT si l etat est illisible', () async {
      await seedProfile();
      // Etat de consentement corrompu : impossible de conclure => on refuse.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'consent_healthData': 'ceci n est pas du JSON',
      });
      final result = await makeSync().syncHikerProfile('hash-anon');
      expect(result.error, kSyncErrorHealthConsentMissing,
          reason: 'un doute sur le consentement se tranche par le refus');
    });

    test('consentement ACCORDE -> la garde laisse passer', () async {
      await seedProfile();
      var checked = false;
      final result = await makeSync(consent: (purpose) async {
        checked = purpose == ConsentPurpose.healthData;
        return true;
      }).syncHikerProfile('hash-anon');

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

  // TACHE 562 (LOT K, K3) — LE BLOB DE FICHE SANTE.
  //
  // NEUVIEME OCCURRENCE DU MEME MOTIF. `HealthBackupService` chiffre la fiche de
  // renseignement medical (groupe sanguin, allergies, traitements — article 9)
  // et depose le blob dans le miroir cloud anonyme, SANS aucune verification de
  // consentement. Le chiffrement est zero-knowledge : le serveur ne voit rien.
  // Cela n'en fait pas une exception.
  //
  // DECISION DE SKYNET, PAS DE L'AGENT (tache 562) : on ne sauvegarde pas une
  // donnee de sante sans accord, meme chiffree, meme pour le bien de la
  // personne — l'accord se demande, il ne se suppose pas. La garde est donc
  // posee DANS les methodes, fermee par defaut, et le randonneur lit ce qu'il
  // perd en refusant (`t.consent.healthBackupNote`, cinq langues, affiche sur
  // l'ecran meme ou il refuse).
  //
  // CES TESTS MESURENT LE FAIT, PAS L'INTENTION : ils demandent « un blob de
  // donnee de sante a-t-il ete produit ? », « la fiche est-elle redescendue sur
  // l'appareil ? ». Ecrits avant la correction, les trois premiers etaient
  // ROUGES.
  group('HealthBackupService — garde art. 9 sur le BLOB de fiche sante', () {
    const fiche = HealthInfo(
      bloodType: 'O-',
      allergies: 'Penicilline',
      treatments: 'Levothyrox 50mg/j',
    );

    late HealthInfoRepository sante;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      sante = HealthInfoRepository(dao: HealthInfoDao(db));
    });

    HealthBackupService makeBackup({ConsentCheck? consent}) =>
        HealthBackupService(
          vault: SecureVaultService(),
          healthRepository: sante,
          consentCheck: consent,
        );

    /// Un blob de fiche sante fabrique SANS passer par le service sous test
    /// (coffre direct) : il existe donc independamment de la garde, et un refus
    /// de restauration ne peut pas etre mis sur le compte d'un blob absent.
    Future<String> blobDeFicheSante(String code) async {
      final vault = SecureVaultService();
      final salt = vault.newSalt();
      final key = await vault.deriveKeyFromCode(code, salt);
      return vault.encryptJson(
        {'kind': 'stepways.health.v1', 'health': fiche.toJson()},
        key: key,
        salt: salt,
      );
    }

    /// Execute [action] et retourne son resultat, ou `null` si elle a refuse.
    /// Formulation volontaire : la question posee est « un blob est-il sorti ? »,
    /// et la reponse doit etre non, que le refus prenne la forme d'une exception
    /// ou d'un retour vide.
    Future<T?> tenter<T>(Future<T?> Function() action) async {
      try {
        return await action();
      } catch (_) {
        return null;
      }
    }

    test('consentement ABSENT -> AUCUN blob produit depuis le code', () async {
      await sante.save(fiche);
      final blob = await tenter(() => makeBackup().exportWithCode('MON-CODE'));
      expect(blob, isNull,
          reason: 'un blob de donnee de sante a ete produit sans accord');
    });

    test('consentement ABSENT -> AUCUN blob produit avec la cle locale',
        () async {
      await sante.save(fiche);
      final blob = await tenter(() => makeBackup().exportWithLocalKey());
      expect(blob, isNull,
          reason: 'le blob local peut partir vers le cloud de l OS : meme regle');
    });

    test('consentement ABSENT -> la fiche ne REDESCEND pas sur l appareil',
        () async {
      final blob = await blobDeFicheSante('MON-CODE');
      await tenter(() => makeBackup().restoreWithCode('MON-CODE', blob));
      expect((await sante.get()).hasData, isFalse,
          reason: 'aucune donnee de sante ne doit atterrir sans accord');
    });

    test('consentement ABSENT -> refus NOMME, jamais confondu avec un cloud '
        'absent ou une fiche vide', () async {
      await sante.save(fiche);
      final service = makeBackup();
      await expectLater(service.exportWithCode('MON-CODE'),
          throwsA(isA<HealthConsentMissingException>()));
      await expectLater(service.exportWithLocalKey(),
          throwsA(isA<HealthConsentMissingException>()));
      await expectLater(service.backupToCloud('hash-anon', 'MON-CODE'),
          throwsA(isA<HealthConsentMissingException>()));
      await expectLater(service.restoreFromCloud('hash-anon', 'MON-CODE'),
          throwsA(isA<HealthConsentMissingException>()));
      await expectLater(service.restoreWithLocalKey('peu-importe'),
          throwsA(isA<HealthConsentMissingException>()));
      await expectLater(
          service.restoreWithCode('MON-CODE', await blobDeFicheSante('X')),
          throwsA(isA<HealthConsentMissingException>()));
    });

    test('la garde interroge bien la finalite SANTE, et elle laisse passer '
        'quand l accord est donne', () async {
      await sante.save(fiche);
      final interrogees = <ConsentPurpose>[];
      final service = makeBackup(consent: (purpose) async {
        interrogees.add(purpose);
        return true;
      });

      final blob = await service.exportWithCode('MON-CODE');

      expect(interrogees, contains(ConsentPurpose.healthData));
      expect(blob, isNotNull);
      // Zero-knowledge inchange : le blob ne porte aucun clair.
      expect(blob!.contains('Levothyrox'), isFalse);
    });

    test('FERMEE PAR DEFAUT : un etat de consentement illisible refuse',
        () async {
      await sante.save(fiche);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'consent_healthData': 'ceci n est pas du JSON',
      });
      await expectLater(makeBackup().exportWithCode('MON-CODE'),
          throwsA(isA<HealthConsentMissingException>()));
    });

    test('une AUTRE finalite accordee n ouvre PAS la porte a la fiche sante',
        () async {
      await sante.save(fiche);
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.socialSharing);
      await consent.grant(ConsentPurpose.locationNavigation);

      await expectLater(makeBackup().exportWithCode('MON-CODE'),
          throwsA(isA<HealthConsentMissingException>()));
      consent.dispose();
    });

    test('consentement REVOQUE -> refus immediat (pas d instance en cache)',
        () async {
      await sante.save(fiche);
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.healthData);
      final service = makeBackup();
      expect(await service.exportWithCode('MON-CODE'), isNotNull);

      await consent.revoke(ConsentPurpose.healthData);

      await expectLater(service.exportWithCode('MON-CODE'),
          throwsA(isA<HealthConsentMissingException>()));
      consent.dispose();
    });
  });


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
