// TACHE 566 (LOT O) — LA DERNIERE PORTE DE RESURRECTION : LA FICHE MEDICALE.
//
// POURQUOI CE FICHIER EXISTE. `HealthBackupService` fait REDESCENDRE la fiche de
// renseignement medical (groupe sanguin, allergies, traitements, medecin,
// numero d'assure — article 9) depuis un blob chiffre : par le CODE de
// reconnexion, par le miroir cloud anonyme, ou par la cle locale du keystore.
// Elle n'etait gardee que par le consentement sante (tache 562, K3).
//
// OR LE LOT N VIENT DE PROUVER QUE CE N'EST PAS UNE GARDE D'EFFACEMENT. Un
// consentement SE RE-ACCORDE. Le randonneur qui efface tout, continue d'utiliser
// l'application, puis re-accorde la sante, rouvrait la porte sur la donnee la
// plus sensible de l'application. Un consentement dit « j'accepte ce
// traitement » ; il ne dit pas « rendez-moi ce que j'ai efface ».
//
// LE TROU EST ETROIT, ET C'EST EXACTEMENT LA RAISON DE LE FERMER. Il faut
// re-accorder la sante ET avoir recopie son code de reconnexion (l'effacement
// vide le keystore, mais pas le carnet du randonneur), et Firebase n'est pas
// connecte avant la phase 4. C'est le meme raisonnement rassurant — « aucun
// appelant en production, rien ne fuit » — qui avait laisse ouvertes les quatre
// gardes latentes trouvees dans la journee. Il ne se represente pas une
// cinquieme fois.
//
// CE QUE MESURENT CES TESTS : le FAIT, pas l'intention. « La fiche est-elle
// revenue sur l'appareil ? », « le refus porte-t-il le bon nom ? », « le reseau
// a-t-il seulement ete touche ? ». Ecrits AVANT les gardes — l'API posee
// d'abord, pour obtenir un rouge de COMPORTEMENT et non un rouge de
// compilation, qui n'aurait rien prouve.

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
import 'package:moteur_gr/core/services/data_retention_service.dart';
import 'package:moteur_gr/core/services/restore_service.dart';
import 'package:moteur_gr/core/services/secure_vault_service.dart';
import 'package:moteur_gr/features/safety/data/health_backup_service.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';

/// Connectivite pilotable (en ligne par defaut) — meme fake que les gardes
/// precedentes.
class _FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus status = ConnectivityStatusValues.online;
  @override
  Future<ConnectivityStatus> checkStatus() async => status;
}

/// Miroir cloud qui REPOND VRAIMENT.
///
/// Sans lui, `restoreFromCloud` retournerait `null` parce que le transport est
/// absent, et le test serait vert pour la mauvaise raison : il ne prouverait
/// rien de la garde. Ici le blob existe cote miroir, donc un refus ne peut venir
/// que de la garde. [pulls] compte les acces : une garde posee EN PREMIER ne
/// doit meme pas toucher le reseau.
class _MiroirQuiRepond extends CloudSyncService {
  _MiroirQuiRepond({
    required super.progressDao,
    required super.journalDao,
    required super.checklistDao,
    required super.syncQueueDao,
    required super.connectivityMonitor,
    required super.firebaseService,
  });

  String? blob;
  int pulls = 0;

  @override
  Future<String?> pullEncryptedBackup(String userId, String docKey) async {
    pulls++;
    return blob;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fiche = HealthInfo(
    bloodType: 'O-',
    allergies: 'Penicilline, arachides',
    treatments: 'Levothyrox 50mg/j',
    doctorContact: 'Dr Dupont 04 95 00 00 00',
    insuranceNumber: '1234567890',
  );

  const code = 'MON-CODE-1234';

  late AppDatabase db;
  late HealthInfoRepository sante;
  late _FakeConnectivityMonitor connectivity;
  late _MiroirQuiRepond miroir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sante = HealthInfoRepository(dao: HealthInfoDao(db));
    connectivity = _FakeConnectivityMonitor();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    miroir = _MiroirQuiRepond(
      progressDao: ProgressDao(db),
      journalDao: JournalDao(db),
      checklistDao: ChecklistDao(db),
      syncQueueDao: SyncQueueDao(db),
      connectivityMonitor: connectivity,
      firebaseService: FirebaseService.testOnly(isAvailable: true),
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// Le service sous test. Le consentement sante est ACCORDE par defaut : c'est
  /// le cas qui nous interesse — celui du randonneur qui a efface puis
  /// re-accorde. Un consentement absent refuserait deja, et ces tests
  /// deviendraient verts sans rien prouver de la garde d'effacement.
  HealthBackupService backup({
    ConsentCheck? consent,
    LocalErasureCheck? erasure,
    bool avecMiroir = false,
  }) =>
      HealthBackupService(
        vault: SecureVaultService(),
        healthRepository: sante,
        cloudSync: avecMiroir ? miroir : null,
        consentCheck: consent ?? (_) async => true,
        localErasureCheck: erasure,
      );

  /// Un blob de fiche sante fabrique SANS passer par le service sous test
  /// (coffre direct, cle derivee du code). Il existe donc independamment de la
  /// garde et SURVIT a l'effacement — comme le vrai blob depose dans le miroir
  /// cloud. Un refus ne pourra pas etre mis sur le compte d'un blob absent.
  Future<String> blobParCode(String motDePasse) async {
    final vault = SecureVaultService();
    final salt = vault.newSalt();
    final key = await vault.deriveKeyFromCode(motDePasse, salt);
    return vault.encryptJson(
      {'kind': 'stepways.health.v1', 'health': fiche.toJson()},
      key: key,
      salt: salt,
    );
  }

  /// Joue l'effacement REEL de l'article 17, par le chemin de l'application —
  /// pas une simulation : c'est lui qui pose le marqueur, en dernier.
  Future<void> effacerVraiment() async {
    final prefs = await SharedPreferences.getInstance();
    await DataRetentionService(database: db, prefs: prefs).deleteAccountData();
  }

  /// Le randonneur continue d'utiliser l'application et RE-ACCORDE la sante.
  /// C'est le geste qui rouvrait la porte.
  Future<void> reAccorderLaSante() async {
    final prefs = await SharedPreferences.getInstance();
    final consent = ConsentService(prefs: prefs);
    await consent.grant(ConsentPurpose.healthData);
    addTearDown(consent.dispose);
  }

  group('LOT O — la fiche medicale ne redescend pas sur un telephone efface',
      () {
    test('restoreWithCode : la fiche NE REVIENT PAS, et le refus est NOMME',
        () async {
      await sante.save(fiche);
      // Le blob est fabrique AVANT l'effacement, comme le vrai : c'est ce qui
      // dort dans le miroir ou dans le cloud de l'OS le jour de l'effacement.
      final blob = await blobParCode(code);

      await effacerVraiment();
      expect((await sante.get()).hasData, isFalse,
          reason: 'le test ne prouve rien si la fiche n avait pas ete effacee');

      await expectLater(
        backup().restoreWithCode(code, blob),
        throwsA(isA<HealthErasedLocallyException>()),
      );
      expect((await sante.get()).hasData, isFalse,
          reason: 'la fiche medicale est revenue sur un telephone ou le '
              'randonneur avait exerce son droit a l effacement');
    });

    test('le refus porte la MEME raison que celle du LOT N, pas une seconde',
        () async {
      await effacerVraiment();
      final blob = await blobParCode(code);

      try {
        await backup().restoreWithCode(code, blob);
        fail('la restauration aurait du refuser');
      } on HealthErasedLocallyException catch (e) {
        expect(e.reason, kRestoreErrorErasedLocally,
            reason: 'deux refus de meme cause doivent se diagnostiquer avec '
                'le meme mot : inventer un second code fabriquerait deux '
                'vocabulaires pour un seul fait');
      }
    });

    test('restoreFromCloud : REFUSE, et le miroir n est meme pas interroge',
        () async {
      miroir.blob = await blobParCode(code);
      await effacerVraiment();

      await expectLater(
        backup(avecMiroir: true).restoreFromCloud('hash-anon', code),
        throwsA(isA<HealthErasedLocallyException>()),
      );
      expect(miroir.pulls, 0,
          reason: 'la garde est posee EN PREMIER : ni reseau, ni lecture de '
              'blob avant d avoir tranche le droit exerce');
      expect((await sante.get()).hasData, isFalse);
    });

    test('restoreWithLocalKey : REFUS D EFFACEMENT, pas un echec de dechiffrement',
        () async {
      await sante.save(fiche);
      final blobLocal = await backup().exportWithLocalKey();
      expect(blobLocal, isNotNull);

      await effacerVraiment();

      // Sans garde, ce chemin echoue tout de meme — l'effacement vide le
      // keystore, donc la cle locale a change. Mais il echouerait en disant
      // « blob illisible », ce qui enverrait l ecran qui posera la question sur
      // la mauvaise piste (« votre code est faux, reessayez ») au lieu de
      // « vous avez efface vos donnees ici ». Le nom du refus est le sujet.
      await expectLater(
        backup().restoreWithLocalKey(blobLocal!),
        throwsA(isA<HealthErasedLocallyException>()),
      );
      expect((await sante.get()).hasData, isFalse);
    });
  });

  group('LOT O — le consentement re-accorde ne rouvre pas la porte', () {
    test('sante RE-ACCORDEE apres l effacement : la fiche ne revient toujours '
        'pas', () async {
      final blob = await blobParCode(code);
      await effacerVraiment();
      await reAccorderLaSante();

      // Consentement RE-ACCORDE pour de vrai : la garde art. 9 laisserait
      // passer. C'est tout le point du lot.
      expect(await consentFromLocalStore(ConsentPurpose.healthData), isTrue,
          reason: 'le test ne prouve rien si le consentement n est pas '
              'reellement re-accorde');

      await expectLater(
        HealthBackupService(
          vault: SecureVaultService(),
          healthRepository: sante,
        ).restoreWithCode(code, blob),
        throwsA(isA<HealthErasedLocallyException>()),
      );
      expect((await sante.get()).hasData, isFalse,
          reason: 'un consentement dit « j accepte ce traitement », il ne dit '
              'pas « rendez-moi ce que j ai efface »');
    });

    test('la garde d effacement passe DEVANT l article 9 : le consentement '
        'n est meme pas interroge', () async {
      await effacerVraiment();
      final blob = await blobParCode(code);
      var consentementInterroge = false;

      await expectLater(
        backup(consent: (_) async {
          consentementInterroge = true;
          return true;
        }).restoreWithCode(code, blob),
        throwsA(isA<HealthErasedLocallyException>()),
      );
      expect(consentementInterroge, isFalse,
          reason: 'un droit exerce se tranche avant toute autre question : le '
              'refus le plus fort doit etre celui qui est NOMME');
    });
  });

  group('LOT O — fermee par defaut, et elle ne bloque rien d autre', () {
    test('marqueur ILLISIBLE -> refus (le doute protege la personne)', () async {
      final blob = await blobParCode(code);

      await expectLater(
        backup(erasure: () async => throw Exception('prefs indisponibles'))
            .restoreWithCode(code, blob),
        throwsA(isA<HealthErasedLocallyException>()),
        reason: 'rendre une fiche medicale a quelqu un qui a peut-etre demande '
            'son effacement est la faute la plus grave des deux',
      );
    });

    test('sans effacement, la fiche se restaure normalement', () async {
      final blob = await blobParCode(code);

      final restauree = await backup().restoreWithCode(code, blob);

      expect(restauree, fiche);
      expect(await sante.get(), fiche,
          reason: 'la garde ne doit rien casser du changement de telephone, '
              'qui reste le scenario normal de ce service');
    });

    test('apres un effacement, une fiche NEUVE peut toujours etre sauvegardee',
        () async {
      await effacerVraiment();
      await reAccorderLaSante();
      // Le randonneur repart de zero et ressaisit sa fiche : c'est SA donnee
      // nouvelle, pas une resurrection. Le lot ferme les chemins qui font
      // REDESCENDRE, jamais ceux qui font monter.
      await sante.save(fiche);

      final blob = await HealthBackupService(
        vault: SecureVaultService(),
        healthRepository: sante,
      ).exportWithCode(code);

      expect(blob, isNotNull,
          reason: 'bloquer aussi la sauvegarde punirait le randonneur pour '
              'avoir exerce un droit');
    });
  });
}
