// TACHE 565 (LOT N, N2) — LA PORTE DE LA RESURRECTION.
//
// POURQUOI CE FICHIER EXISTE. `RestoreService` relit Firestore et RE-HYDRATE la
// base locale : progression, journal, checklist, fiche randonneur, randos
// passees, note d'experience. Rien ne lui disait que le randonneur venait
// d'exercer son droit a l'effacement. Le jour ou ce chemin sera cable (phase 4),
// la premiere restauration aurait ramene TOUT ce qu'il avait demande d'effacer —
// et la strategie de fusion ne pouvait pas l'en empecher : elle est en
// « dernier ecrit gagne », et apres un effacement le local est vide, donc le
// distant gagne toujours.
//
// AUCUN APPELANT AUJOURD'HUI, ET C'EST EXACTEMENT LA RAISON. C'est la quatrieme
// garde latente de la journee, et les trois autres ont ete posees pour le meme
// motif : une garde qui compte sur la discipline d'un appelant futur n'est pas
// une garde. Elle est donc DANS la methode, et fermee par defaut.
//
// LE CONSENTEMENT ART. 9 NE SUFFIT PAS, ET C'EST LE POINT DE CE FICHIER.
// `restoreHikerProfile` etait deja garde par le consentement sante (LOT J) — ce
// qui la ferme tant que l'effacement vient de retirer tous les consentements.
// Mais un consentement se re-accorde : le randonneur qui continue d'utiliser
// l'application et ré-accorde la sante rouvrait la porte sur des donnees qu'il
// avait fait effacer. Un consentement dit « j'accepte ce traitement » ; il ne
// dit pas « rendez-moi ce que j'ai efface ». Et `restoreFromCloud` n'avait,
// elle, aucune garde du tout.
//
// CE QUE FAIT LA GARDE, ET POURQUOI PAS AUTREMENT. Restaurer ecraserait un
// droit exerce. Ne rien faire en silence serait un autre mensonge — le meme
// defaut que celui de la journee, un code qui ne dit pas ce qu'il fait. Elle
// REFUSE, et elle NOMME son refus ([kRestoreErrorErasedLocally]), pour qu'un
// appelant ne le confonde ni avec un hors-ligne ni avec un « pas de sauvegarde
// cloud ».

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/core/services/data_retention_service.dart';
import 'package:moteur_gr/core/services/restore_service.dart';

/// Connectivite pilotable (en ligne par defaut) — meme fake que la garde art. 9.
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
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(() async {
    await db.close();
  });

  RestoreService makeRestore({
    ConsentCheck? consent,
    LocalErasureCheck? erasure,
  }) =>
      RestoreService(
        progressDao: ProgressDao(db),
        journalDao: JournalDao(db),
        checklistDao: ChecklistDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        hikerProfileDao: db.hikerProfileDao,
        pastHikesDao: db.pastHikesDao,
        consentCheck: consent,
        localErasureCheck: erasure,
      );

  /// Joue l'effacement REEL de l'article 17, par le chemin de l'application.
  Future<void> effacerVraiment() async {
    final prefs = await SharedPreferences.getInstance();
    await DataRetentionService(database: db, prefs: prefs).deleteAccountData();
  }

  group('N2 — l effacement laisse une trace que la restauration peut lire', () {
    test('l effacement pose le marqueur, et il SURVIT a sa propre purge de cles',
        () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLocalErasureMarkerPrefsKey), isNull,
          reason: 'le test ne prouve rien si le marqueur etait deja la');

      await effacerVraiment();

      final marqueur = prefs.getString(kLocalErasureMarkerPrefsKey);
      expect(marqueur, isNotNull,
          reason: 'sans cette trace, aucune garde ne peut savoir');
      expect(DateTime.tryParse(marqueur!), isNotNull,
          reason: 'une date lisible, pas un drapeau muet : on doit pouvoir dire '
              'QUAND le droit a ete exerce');
    });

    test('la lecture par defaut du marqueur dit la verite dans les deux sens',
        () async {
      expect(await localErasureFromStore(), isFalse,
          reason: 'aucun effacement : rien ne doit etre refuse');

      await effacerVraiment();

      expect(await localErasureFromStore(), isTrue,
          reason: 'c est cette lecture que branche la garde par defaut');
    });
  });

  group('N2 — la restauration refuse ce qui vient d etre efface', () {
    test('restoreFromCloud REFUSE, et le refus est nomme', () async {
      await effacerVraiment();

      final result = await makeRestore().restoreFromCloud('hash-anon');

      expect(result.success, isFalse);
      expect(result.error, kRestoreErrorErasedLocally,
          reason: 'le refus ne doit se confondre ni avec un hors-ligne ni '
              'avec un Firebase indisponible');
      expect((await db.select(db.userProgressEntries).get()), isEmpty,
          reason: 'aucune ligne ne doit avoir ete re-hydratee');
      expect((await db.select(db.journalEntries).get()), isEmpty);
    });

    test('restoreHikerProfile REFUSE MEME SI le consentement sante est '
        're-accorde', () async {
      await effacerVraiment();
      // Le randonneur continue d'utiliser l'application et ré-accorde la sante.
      // C'est le cas qui rouvrait la porte : le consentement n'est pas une
      // autorisation de ressusciter ce qui a ete efface.
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.healthData);
      addTearDown(consent.dispose);

      final result = await makeRestore().restoreHikerProfile('hash-anon');

      expect(result.error, kRestoreErrorErasedLocally,
          reason: 'la garde art. 9 n est pas une garde d effacement');
      expect((await db.select(db.hikerProfile).get()), isEmpty,
          reason: 'aucune donnee de sante ne doit redescendre');
      expect((await db.select(db.pastHikeEntries).get()), isEmpty);
    });

    test('checkAndRestore ne PROPOSE plus, et dit pourquoi', () async {
      await effacerVraiment();

      final check = await makeRestore().checkAndRestore('hash-anon');

      expect(check.hasCloudData, isFalse,
          reason: 'proposer une restauration apres un effacement, c est '
              'proposer de defaire le droit qu on vient d exercer');
      expect(check.erasedLocally, isTrue,
          reason: 'un « rien a restaurer » muet serait un autre mensonge : '
              'l appelant doit pouvoir dire au randonneur POURQUOI');
    });
  });

  group('N2 — la garde est fermee par defaut, et elle ne bloque rien d autre',
      () {
    test('etat du marqueur ILLISIBLE -> refus (le doute protege la personne)',
        () async {
      final result = await makeRestore(
        erasure: () async => throw Exception('prefs indisponibles'),
      ).restoreFromCloud('hash-anon');

      expect(result.error, kRestoreErrorErasedLocally,
          reason: 'un doute sur l effacement se tranche par le refus, jamais '
              'par la restauration');
    });

    test('sans effacement, la garde laisse passer les deux chemins', () async {
      final restore = makeRestore();

      final cloud = await restore.restoreFromCloud('hash-anon');
      final profil = await makeRestore(consent: (_) async => true)
          .restoreHikerProfile('hash-anon');
      final check = await restore.checkAndRestore('hash-anon');

      // Firestore n'est pas joignable en test : on n'exige pas un succes, on
      // exige que l'effacement ne soit PAS la raison de l'echec.
      expect(cloud.error, isNot(kRestoreErrorErasedLocally));
      expect(profil.error, isNot(kRestoreErrorErasedLocally));
      expect(check.erasedLocally, isFalse);
    });

    test('la garde est consultee AVANT le consentement art. 9', () async {
      await effacerVraiment();
      var consentementInterroge = false;

      final result = await makeRestore(consent: (_) async {
        consentementInterroge = true;
        return true;
      }).restoreHikerProfile('hash-anon');

      expect(result.error, kRestoreErrorErasedLocally);
      expect(consentementInterroge, isFalse,
          reason: 'un droit exerce se tranche avant toute autre question : '
              'le refus le plus fort doit etre celui qui est NOMME');
    });
  });
}
