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

import 'dart:io';

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

  CloudSyncService makeSync() => CloudSyncService(
        progressDao: ProgressDao(db),
        checklistDao: ChecklistDao(db),
        syncQueueDao: SyncQueueDao(db),
        connectivityMonitor: connectivity,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        pastHikesDao: db.pastHikesDao,
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

  // LES RANDOS PASSEES SONT SORTIES DE CETTE GARDE, ET C EST CHRISTOPHE QUI A
  // TRANCHE (DEM du 30/09 12:33).
  //
  // HISTORIQUE EN DEUX TEMPS. La garde protegeait `syncHikerProfile`, qui
  // poussait la MORPHOLOGIE ; la tache 635 a supprime cette montee (la
  // morphologie reste sur le telephone) et a REPORTE la garde sur les randos
  // passees, par prudence. Le bilan de ce lot signalait la consequence : tant
  // que la case sante n etait pas cochee, `past_hikes` restait VIDE au serveur.
  // Christophe l a lue et a tranche l inverse — les randos montent comme la
  // progression et le sac, la case garde la fiche medicale seule.
  //
  // CE GROUPE PROUVE DONC MAINTENANT LE CONTRAIRE DE CE QU IL PROUVAIT : que
  // rien, dans ce service, ne subordonne plus les randos passees a un
  // consentement. Et il verifie que le chemin de sortie de la fiche medicale
  // reste FERME, lui — c est la seule chose que la case doit encore garder.
  group('CloudSyncService.syncPastHikes — plus aucune garde de consentement',
      () {
    test('sans consentement sante, les randos passees montent quand meme',
        () async {
      await seedRandoPassee();
      // Prefs vides : AUCUN consentement n a jamais ete donne.
      final result = await makeSync().syncPastHikes('uid-auth');

      // FIREBASE N EST PAS JOIGNABLE EN TEST : on n exige donc pas un succes.
      // Ce qui se mesure ici est que la methode VA JUSQU AU TRANSPORT au lieu
      // de refuser avant — l erreur rendue est celle du cloud absent, plus
      // jamais celle d un consentement manquant.
      expect(result.error, isNot(contains('consent')),
          reason: 'un refus de consentement ne peut plus etre la raison');
      expect(result.error, contains('Firebase'),
          reason: 'la methode est allee jusqu au transport, comme pour la '
              'progression et le sac');
    });

    test('un consentement sante REVOQUE ne bloque plus les randos', () async {
      await seedRandoPassee();
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.healthData);
      await consent.revoke(ConsentPurpose.healthData);

      final result = await makeSync().syncPastHikes('uid-auth');

      expect(result.error, isNot(contains('consent')));
      consent.dispose();
    });

    test('le service ne connait plus aucune verification de consentement',
        () async {
      final source = File('lib/core/services/cloud_sync_service.dart')
          .readAsStringSync();
      // ON CHERCHE LA DECLARATION, PAS LE MOT : les commentaires de ce service
      // expliquent longuement pourquoi la garde a ete retiree, et ils doivent
      // pouvoir le dire sans faire echouer l invariante.
      expect(source, isNot(contains('final ConsentCheck consentCheck')),
          reason: 'un champ de verification qui survit a sa garde laisse '
              'croire qu une garde vit encore ici');
      expect(source, isNot(contains('ConsentCheck? consentCheck')));
      expect(source, isNot(contains('await consentCheck(')));
      expect(source, isNot(contains('ConsentPurpose.healthData)')));
    });

    test('LA FICHE MEDICALE, ELLE, N A TOUJOURS AUCUN CHEMIN DE SORTIE',
        () async {
      // C est ce que la case garde encore, et ce lot n y touche pas : la liste
      // fermee de la tache 612 refuse tout document de sante, consentement ou
      // pas.
      for (final nom in const ['health', 'sante', 'medical', 'fiche_medicale']) {
        expect(DocumentsDuCoffreDistant.autorise(nom), isFalse,
            reason: '« $nom » ne doit avoir aucun chemin vers nos serveurs');
      }
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
