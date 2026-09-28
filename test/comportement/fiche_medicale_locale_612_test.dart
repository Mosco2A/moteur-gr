// TACHE 612 — LA FICHE MEDICALE NE SORT JAMAIS DU TELEPHONE, ET C'EST TENU PAR
// UN TEST, PAS PAR UNE INTENTION.
//
// DEUX DECISIONS DE CHRISTOPHE, VERBATIM, ET ELLES NE PARLENT PAS DE LA MEME
// CHOSE. Les confondre, dans le code comme a l'ecran, ferait croire au
// randonneur que NOUS recuperons sa fiche quand il decoche une case.
//
//  [28/09 10:42, en majuscules dans son message] « NON ON NE TROUVERAIT RIEN !!!
//  Les donnees medicales RESTENT sur le tel !!! ». C'est NOS SERVEURS. Pas de
//  sauvegarde distante, meme chiffree, meme avec consentement, meme pour le bien
//  de la personne. Si on ouvrait nos serveurs on ne trouverait RIEN — pas des
//  octets illisibles, RIEN.
//
//  [28/09 10:49] « option prechochee, Je refuse la sauvegarde sur le cloud google
//  de mes donnees medicales, quand il se connecte ». C'est LA SAUVEGARDE DU
//  TELEPHONE PAR SON PROPRE SYSTEME, Google ou Apple, qui ne nous appartient pas.
//
// CE QUI A ETE RETIRE, ET CE QUE CA PORTAIT. `HealthBackupService` chiffrait la
// fiche (groupe sanguin, allergies, traitements) en AES-GCM 256 avec une clef
// derivee du CODE DE RECONNEXION (PBKDF2), pour un depot dans le miroir cloud
// anonyme sous hash SHA-256. Or Christophe a assume le 28/09 10:38 que ce code
// puisse etre PARTAGE PAR COURRIEL par l'utilisateur lui-meme : un code dans une
// boite de courriel devenait la clef d'une donnee de sante. Le service est
// supprime, et avec lui ce risque, PAR CONSTRUCTION.
//
// POURQUOI CE FICHIER EST LE COEUR DU LOT ET PAS SON ACCESSOIRE. Une promesse
// publiee doit etre gardee par un test qui devient ROUGE le jour ou quelqu'un
// rouvre la porte DE BONNE FOI, pour rendre service. C'est le motif mesure le
// 27/09 sur les commentaires qui survivaient a la regle qu'ils decrivaient : sans
// garde, une promesse derive. Les tests portent donc sur le COMPORTEMENT et sur
// les DECLARATIONS, jamais sur l'absence d'un fichier — un fichier se recree.
//
// LES TROIS FACONS DONT LA PORTE SE ROUVRIRAIT, ET LEUR GARDE :
//   1. en ajoutant un document au transport -> la liste est FERMEE et une
//      invariante exige qu'elle ne porte rien de medical ;
//   2. en rebranchant la fiche sur le reseau depuis un ecran ou un service ->
//      une invariante balaye `lib/` et refuse qu'un fichier touche a la fois la
//      fiche et le reseau ;
//   3. en retirant l'exclusion de la sauvegarde systeme d'un XML Android ->
//      une invariante compare les deux XML a la declaration Dart, dans les deux
//      sens.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drift/native.dart';

import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/data/daos/sync_queue_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/cloud_sync_service.dart';
import 'package:moteur_gr/core/services/exclusion_sauvegarde_icloud.dart';
import 'package:moteur_gr/core/services/sauvegarde_systeme.dart';
import 'package:moteur_gr/features/safety/data/copie_sauvegardable_fiche_service.dart';
import 'package:moteur_gr/features/safety/data/fiche_medicale_fichier.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';
import 'package:moteur_gr/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart';
import 'package:moteur_gr/features/safety/providers/refus_sauvegarde_systeme_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import '../structurel/parcours_reel.dart';

// ---------------------------------------------------------------------------
// OUTILS DE MESURE
// ---------------------------------------------------------------------------

/// Reseau qui DIT s'il a ete consulte.
///
/// C'est la sonde qui rend les refus VERIFIABLES sans Firebase. Le transport
/// interroge la connectivite APRES la garde de la liste fermee : si la garde
/// disparait, [consulte] passe a vrai et le test devient rouge. Sans cette
/// sonde, un refus muet et une panne muette se ressembleraient.
class _ReseauMouchard extends ConnectivityMonitor {
  bool consulte = false;

  @override
  Future<ConnectivityStatus> checkStatus() async {
    consulte = true;
    return ConnectivityStatusValues.online;
  }

  @override
  Stream<ConnectivityStatus> get onStatusChange =>
      Stream.value(ConnectivityStatusValues.online);
}

/// Tous les `.dart` de production.
List<File> _sourcesDeProduction() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

String _cheminNormalise(File f) => f.path.replaceAll(r'\', '/');

/// LE CODE SEUL, SANS LES COMMENTAIRES.
///
/// POURQUOI CETTE PRECAUTION EXISTE, ET ELLE A ETE APPRISE ICI. Le premier
/// balayage ecrit pour ce lot declarait coupable `coffre_de_reconnexion.dart`,
/// dont un commentaire RACONTE la suppression de `HealthBackupService` : la garde
/// accusait la documentation de son propre travail. Un balayage qui ne distingue
/// pas une ligne de code d'une phrase d'explication force a effacer l'histoire
/// pour rester vert, et c'est exactement le contraire de ce qu'on veut — les
/// commentaires de ce depot sont sa memoire.
///
/// Les adresses web sont mises a l'abri avant la coupe : sans cela la fin de leur
/// ligne disparaitrait avec elles, et un vrai appel ecrit apres une adresse
/// passerait inapercu.
String _codeSeul(String source) {
  const abri = '\u0000URL\u0000';
  var s = source.replaceAll('://', abri);
  s = s.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ');
  s = s
      .split('\n')
      .map((ligne) {
        final i = ligne.indexOf('//');
        return i == -1 ? ligne : ligne.substring(0, i);
      })
      .join('\n');
  return s.replaceAll(abri, '://');
}

/// Les mots qui trahissent une donnee de sante dans un nom de document.
///
/// Volontairement LARGE et dans plusieurs langues : la porte ne se rouvrira pas
/// avec le mot `health`, elle se rouvrira avec `sante`, `medical` ou `fiche`.
const _motsDeSante = [
  'health',
  'sante',
  'santé',
  'medic',
  'médic',
  'blood',
  'sanguin',
  'allerg',
  'traitement',
  'treatment',
  'ordonnance',
  'fiche',
];

bool _sentLaSante(String texte) {
  final bas = texte.toLowerCase();
  return _motsDeSante.any(bas.contains);
}

/// Les cinq langues, construites pour de vrai.
final _langues = {
  for (final l in AppLocale.values) l.languageTag: l.buildSync(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. NOS SERVEURS — IL N'Y A PLUS DE CHEMIN DE SORTIE, ET IL NE PEUT PLUS Y
  //    EN AVOIR SANS CROISER CETTE DECISION
  // =========================================================================
  group('612 — le transport du coffre distant REFUSE la fiche medicale', () {
    late AppDatabase db;
    late _ReseauMouchard reseau;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      reseau = _ReseauMouchard();
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    tearDown(() async => db.close());

    CloudSyncService transport() => CloudSyncService(
          progressDao: ProgressDao(db),
          journalDao: JournalDao(db),
          checklistDao: ChecklistDao(db),
          syncQueueDao: SyncQueueDao(db),
          connectivityMonitor: reseau,
          // FIREBASE DECLARE DISPONIBLE, ET C'EST VOULU : on ne veut pas d'un
          // refus qui viendrait d'un cloud absent. Le seul refus acceptable ici
          // est celui de la decision.
          firebaseService: FirebaseService.testOnly(isAvailable: true),
        );

    /// Les noms sous lesquels quelqu'un redeposerait une fiche medicale.
    const nomsPlausibles = [
      'health',
      'sante',
      'medical',
      'fiche_medicale',
      'health_v2',
      'stepways.health.v1',
      'secure_health',
    ];

    for (final nom in nomsPlausibles) {
      test('deposer « $nom » est REFUSE, et le reseau n est meme pas consulte',
          () async {
        final res = await transport()
            .pushEncryptedBackup('hash-anon', nom, 'blob-chiffre');

        expect(res.error, kSyncErrorDocumentNonAutorise,
            reason: 'le refus doit porter SON nom, pas celui d une panne');
        expect(res.status, CloudSyncStatusValues.idle,
            reason: 'un refus assume n est pas une erreur technique');
        expect(res.itemsSynced, 0);
        expect(reseau.consulte, isFalse,
            reason: 'la garde doit passer AVANT le reseau : un chemin de sortie '
                'de la fiche medicale ne se refuse pas selon l etat du telephone');
      });

      test('lire « $nom » est REFUSE, et le reseau n est pas consulte non plus',
          () async {
        final blob = await transport().pullEncryptedBackup('hash-anon', nom);

        expect(blob, isNull);
        expect(reseau.consulte, isFalse,
            reason: 'fermer la montee sans fermer la descente laisserait le '
                'telephone aller chercher une fiche deposee par une version '
                'anterieure');
      });
    }

    test('le document du COMPTE, lui, passe la garde (on ne casse pas le reste)',
        () async {
      // Il n'ira pas au bout (aucun Firebase reel), mais il doit FRANCHIR la
      // garde : la preuve est que le reseau a ete consulte. Sans cette
      // verification, une liste fermee vide passerait pour une liste correcte.
      await transport().pushEncryptedBackup(
        'hash-anon',
        DocumentsDuCoffreDistant.compte,
        'blob-chiffre',
      );
      expect(reseau.consulte, isTrue,
          reason: 'le coffre profil + solde d etapes n est pas concerne par la '
              'decision du 28/09 : il ne doit pas etre ferme par erreur');
    });
  });

  group('612 — INVARIANTE : la liste des documents autorises est fermee et ne '
      'porte RIEN de medical', () {
    test('aucun document autorise ne sent la donnee de sante', () {
      for (final doc in DocumentsDuCoffreDistant.autorises) {
        expect(_sentLaSante(doc), isFalse,
            reason: 'le document « $doc » a ete ajoute a la liste des documents '
                'que le coffre distant peut porter, et son nom evoque une '
                'donnee de sante. Decision de Christophe du 28/09 10:42 : les '
                'donnees medicales ne sortent JAMAIS du telephone. Si ce n est '
                'pas une donnee de sante, renommez-le sans ambiguite.');
      }
    });

    test('la liste est REELLEMENT fermee : tout ce qui n y est pas est refuse',
        () {
      expect(DocumentsDuCoffreDistant.autorise('health'), isFalse);
      expect(DocumentsDuCoffreDistant.autorise(''), isFalse);
      expect(DocumentsDuCoffreDistant.autorise('n importe quoi'), isFalse);
      expect(DocumentsDuCoffreDistant.autorise(DocumentsDuCoffreDistant.compte),
          isTrue);
    });

    test('le service de sauvegarde distante de la fiche N EXISTE PLUS en '
        'production, sous aucun nom', () {
      final coupables = <String>[];
      for (final f in _sourcesDeProduction()) {
        final contenu = _codeSeul(f.readAsStringSync());
        for (final trace in const [
          'HealthBackupService',
          'healthBackupServiceProvider',
          'backupToCloud',
          'stepways.health.v1',
        ]) {
          if (contenu.contains(trace)) {
            coupables.add('${_cheminNormalise(f)} : $trace');
          }
        }
      }
      expect(coupables, isEmpty,
          reason: 'un chemin de sauvegarde distante de la fiche medicale est '
              'reapparu :\n  ${coupables.join("\n  ")}');
    });
  });

  group('612 — INVARIANTE : aucun fichier de production ne touche a la fois la '
      'fiche medicale et le reseau', () {
    // C'EST LA GARDE CONTRE LE RETOUR DE BONNE FOI. Le jour ou quelqu'un voudra
    // « rendre service » en sauvegardant la fiche, il devra ecrire, dans un meme
    // fichier, la lecture de la fiche et un appel sortant. Ce test devient rouge
    // a cet instant, et il NOMME le fichier.
    //
    // Il ne mesure pas l'absence d'un fichier : il mesure un VOISINAGE interdit,
    // qui est la forme que prend toujours ce defaut.
    const lectureDeLaFiche = [
      'health_info_repository.dart',
      'HealthInfoRepository',
      'healthInfoRepositoryProvider',
      'HealthInfoDao',
      // TACHE 613 : la fiche a change de stockage (son propre fichier, sous le
      // dossier exclu). L invariante suit le DEPLACEMENT, sinon elle aurait
      // continue a surveiller une porte qui ne mene plus nulle part.
      'fiche_medicale_fichier.dart',
      'FicheMedicaleFichier',
      'ficheMedicaleFichierProvider',
    ];
    const sortieReseau = [
      'cloud_firestore',
      'firebase_storage',
      'package:http/',
      'HttpClient',
      'pushEncryptedBackup',
      'CloudSyncService',
    ];

    test('la fiche et le reseau ne se rencontrent dans AUCUN fichier', () {
      final coupables = <String>[];
      for (final f in _sourcesDeProduction()) {
        final chemin = _cheminNormalise(f);
        // La copie sauvegardable lit la fiche, et c'est son travail : elle
        // n'ouvre AUCUNE connexion (verifie juste en dessous, sur le contenu).
        final contenu = _codeSeul(f.readAsStringSync());
        final lit = lectureDeLaFiche.any(contenu.contains);
        if (!lit) continue;
        final sort = sortieReseau.where(contenu.contains).toList();
        if (sort.isNotEmpty) coupables.add('$chemin : ${sort.join(", ")}');
      }
      expect(coupables, isEmpty,
          reason: 'ces fichiers lisent la fiche medicale ET portent une sortie '
              'reseau :\n  ${coupables.join("\n  ")}\n'
              'Decision de Christophe du 28/09 10:42 : la fiche medicale ne '
              'part JAMAIS vers nos serveurs. Si le besoin est la sauvegarde du '
              'telephone par Google ou Apple, c est un AUTRE sujet, et il passe '
              'par CopieSauvegardableFicheService, qui n ouvre aucune connexion.');
    });

    test('le service de copie sauvegardable n ouvre AUCUNE connexion', () {
      final source = _codeSeul(File(
        'lib/features/safety/data/copie_sauvegardable_fiche_service.dart',
      ).readAsStringSync());
      for (final sortie in sortieReseau) {
        expect(source.contains(sortie), isFalse,
            reason: 'la copie destinee a la sauvegarde du telephone doit rester '
                'un FICHIER LOCAL : « $sortie » en ferait un chemin vers un '
                'serveur, et les deux sujets se confondraient');
      }
    });
  });

  // =========================================================================
  // 2. LA SAUVEGARDE DU TELEPHONE PAR SON PROPRE SYSTEME
  // =========================================================================
  group('612 — l exclusion de la sauvegarde systeme est DECLAREE, et les XML '
      'disent la MEME chose que le code', () {
    String lire(String chemin) {
      final f = File(chemin);
      expect(f.existsSync(), isTrue,
          reason: 'le fichier de regles « $chemin » est declare par '
              'SauvegardeSysteme mais il n existe pas sur le disque');
      return f.readAsStringSync();
    }

    /// Les exclusions REELLEMENT ecrites dans un fichier de regles Android.
    Set<String> exclusionsDuXml(String xml) {
      final motif = RegExp(
        r'<exclude\s+domain="([^"]+)"(?:\s+path="([^"]*)")?\s*/>',
      );
      return motif
          .allMatches(xml)
          .map((m) => '${m.group(1)}|${m.group(2) ?? ''}')
          .toSet();
    }

    final attendues = SauvegardeSysteme.exclusions
        .map((e) => '${e.domaine}|${e.chemin}')
        .toSet();

    test('le manifeste Android REFERENCE les deux fichiers de regles', () {
      final manifeste = lire(SauvegardeSysteme.manifesteAndroid);
      expect(manifeste, contains('android:dataExtractionRules'),
          reason: 'sans cet attribut, Android 12 et au-dela sauvegardent tout');
      expect(manifeste, contains('android:fullBackupContent'),
          reason: 'sans cet attribut, Android 11 et en dessous sauvegardent '
              'tout, et c est le randonneur au telephone le plus vieux qui y '
              'perd');
      expect(manifeste, contains('@xml/regles_sauvegarde_donnees'));
      expect(manifeste, contains('@xml/regles_sauvegarde_complete'));
    });

    test('Android 12 et au-dela : les exclusions du XML sont EXACTEMENT celles '
        'declarees, dans les deux sens', () {
      final xml = lire(SauvegardeSysteme.reglesAndroid12EtPlus);
      expect(exclusionsDuXml(xml), attendues,
          reason: 'le XML et SauvegardeSysteme.exclusions ont divergé. Retirer '
              'une exclusion du XML rouvre la sauvegarde de la fiche medicale '
              'chez Google ; en ajouter une sans la declarer fait mentir la '
              'declaration.');
    });

    test('la MONTEE et le TRANSFERT direct sont exclus tous les deux', () {
      final xml = lire(SauvegardeSysteme.reglesAndroid12EtPlus);
      // Une fiche qui refuse le nuage mais passe par le cable d un telephone a
      // l autre n aurait pas quitte le telephone : elle aurait quitte CE
      // telephone-la, ce qui est exactement ce que la decision interdit.
      expect(xml, contains('<cloud-backup>'));
      expect(xml, contains('<device-transfer>'));
      final sections = xml.split('<device-transfer>');
      expect(sections.length, 2);
      for (final section in sections) {
        expect(exclusionsDuXml(section), attendues,
            reason: 'les deux sections doivent porter les MEMES exclusions');
      }
    });

    test('Android 11 et en dessous : mêmes exclusions, même source de verite',
        () {
      final xml = lire(SauvegardeSysteme.reglesAndroidAvant12);
      expect(exclusionsDuXml(xml), attendues);
    });

    test('la fiche medicale est bien dans ce qui est EXCLU', () {
      final exclus = SauvegardeSysteme.exclusions
          .map((e) => '${e.domaine}/${e.chemin}')
          .join(' ');
      expect(exclus, contains(SauvegardeSysteme.dossierExclu),
          reason: 'le dossier ou vit la fiche medicale doit figurer dans les '
              'exclusions, sinon la declaration ne protege rien');
      // TACHE 613 — CETTE EXIGENCE A ETE RENVERSEE, ET LA RAISON EST ECRITE.
      // Le lot 612 exigeait ici l exclusion du domaine `database` TOUT ENTIER,
      // parce que la table de la fiche partageait le fichier de la progression.
      // La fiche a desormais SON PROPRE FICHIER sous `medical/` : le motif a
      // disparu, et garder l exclusion ferait perdre la progression et le carnet
      // au changement de telephone — alors que le modele economique promet qu un
      // trek realise garde A VIE sa trace et son carnet.
      expect(
          SauvegardeSysteme.exclusions
              .any((e) => e.domaine == 'database'),
          isFalse,
          reason: 'la base ne contient plus rien de medical (tache 613) et doit '
              'redevenir sauvegardable, sinon le randonneur perd sa progression '
              'et son journal en changeant de telephone');
    });

    test('l emplacement de la COPIE sauvegardable n est PAS exclu, sinon la '
        'case ne servirait a rien', () {
      final exclus = SauvegardeSysteme.exclusions
          .map((e) => e.chemin)
          .where((c) => c.isNotEmpty)
          .toList();
      for (final chemin in exclus) {
        expect(chemin.contains(SauvegardeSysteme.dossierSauvegardable), isFalse,
            reason: 'decocher la case doit produire une copie que la sauvegarde '
                'du telephone emporte VRAIMENT');
      }
    });

    test('l exigence iPhone est DECLAREE et ACTIONNABLE — et elle est TENUE '
        'depuis la tache 615', () {
      // MESURE DU 28/09 : sur iOS, l exclusion de la sauvegarde iCloud n est PAS
      // declarative. Il n existe aucun equivalent de dataExtractionRules dans
      // Info.plist : elle se pose a l execution, fichier par fichier, avec
      // NSURLIsExcludedFromBackupKey. Le lot 612 ne pouvait donc que NOMMER
      // l exigence, comme CoffreDeReconnexion nomme ce qui manque.
      //
      // TACHE 615 : ELLE N EST PLUS SEULEMENT NOMMEE. Le canal natif existe
      // (`ExclusionSauvegardeIcloud`) et l exclusion est reposee a CHAQUE
      // ecriture, parce que l ecriture est atomique et qu un fichier remplace ne
      // porte plus l attribut de celui qu il remplace. Cette verification-ci
      // garde le CONTRAT ; `exclusion_icloud_615_test.dart` garde le MECANISME.
      const exigence = SauvegardeSysteme.exigenceIosExclusion;
      expect(exigence, contains('NSURLIsExcludedFromBackupKey'));
      expect(exigence, contains(SauvegardeSysteme.dossierExclu));
      expect(exigence.length, greaterThan(80),
          reason: 'une exigence trop courte pour etre suivie ne sera pas suivie');
      expect(File(ExclusionSauvegardeIcloud.fichierNatif).existsSync(), isTrue,
          reason: 'l exigence est devenue un CANAL : sans le fichier natif qui en '
              'tient l autre bout, elle redeviendrait une intention');
    });
  });

  group('612 — LA CASE PILOTE LA PRESENCE D UNE COPIE, et le refus est le '
      'DEFAUT', () {
    late HealthInfoRepository fiche;
    late Directory racine;
    late CopieSauvegardableFicheService copie;

    const laFiche = HealthInfo(
      bloodType: 'O-',
      allergies: 'Penicilline',
      treatments: 'Levothyrox 50mg/j',
    );

    setUp(() async {
      racine = await Directory.systemTemp.createTemp('sw612_');
      // TACHE 613 : la fiche ne vit plus dans la base mais dans son propre
      // fichier, sous le dossier declare exclu. Le depot est donc branche sur le
      // meme bac temporaire que la copie sauvegardable — ce qui met les DEUX
      // emplacements cote a cote dans ces tests, l exclu et le sauvegardable.
      fiche = HealthInfoRepository(
        fichier: FicheMedicaleFichier(dossierApplicatif: () async => racine),
      );
      copie = CopieSauvegardableFicheService(
        healthRepository: fiche,
        baseDirProvider: () async => racine,
      );
    });

    tearDown(() async {
      if (racine.existsSync()) await racine.delete(recursive: true);
    });

    File fichierCopie() => File(
          '${racine.path}/${SauvegardeSysteme.dossierSauvegardable}'
          '/${SauvegardeSysteme.fichierCopieFiche}',
        );

    test('LE DEFAUT EST LE REFUS, avant meme que la case ait ete vue', () {
      expect(kRefusSauvegardeSystemeParDefaut, isTrue,
          reason: 'Christophe a demande une case PRE-COCHEE : la protection ne '
              'doit pas dependre de la vigilance du randonneur');
    });

    test('refus (le defaut) : AUCUNE copie, meme avec une fiche remplie',
        () async {
      await fiche.save(laFiche);
      final presente = await copie.appliquer(refuse: true);
      expect(presente, isFalse);
      expect(fichierCopie().existsSync(), isFalse,
          reason: 'le defaut ne fait RIEN partir');
    });

    test('decoche : une copie apparait, et elle porte la fiche', () async {
      await fiche.save(laFiche);
      final presente = await copie.appliquer(refuse: false);

      expect(presente, isTrue);
      expect(fichierCopie().existsSync(), isTrue);
      final relu = HealthInfo.fromJson(
        jsonDecode(fichierCopie().readAsStringSync()) as Map<String, dynamic>,
      );
      expect(relu, laFiche,
          reason: 'une copie vide ou partielle serait une deception au '
              'changement de telephone, pas une protection');
    });

    test('RE-COCHER LE REFUS SUPPRIME LA COPIE DEJA ECRITE', () async {
      await fiche.save(laFiche);
      await copie.appliquer(refuse: false);
      expect(fichierCopie().existsSync(), isTrue);

      await copie.appliquer(refuse: true);

      expect(fichierCopie().existsSync(), isFalse,
          reason: 'un refus qui laisse une trace de passage n est pas un refus : '
              'c est le defaut mesure au LOT Y, et il vaut ici aussi');
    });

    test('EFFACER LA FICHE EMPORTE SA COPIE, meme si le randonneur avait '
        'decoche', () async {
      await fiche.save(laFiche);
      await copie.appliquer(refuse: false);
      expect(fichierCopie().existsSync(), isTrue);

      await fiche.delete();
      // Le re-alignement, c est ce que fait l ecran apres un effacement.
      await copie.appliquer(refuse: false);

      expect(fichierCopie().existsSync(), isFalse,
          reason: 'effacer la fiche en laissant sa copie dans l emplacement '
              'sauvegarde, c est un effacement qui ne tient pas : le changement '
              'de telephone la ferait revenir');
    });

    test('fiche vide et case decochee : rien a copier, donc rien de copie',
        () async {
      final presente = await copie.appliquer(refuse: false);
      expect(presente, isFalse);
      expect(fichierCopie().existsSync(), isFalse);
    });

    test('la copie est ecrite dans l emplacement SAUVEGARDABLE, jamais dans '
        'l emplacement exclu', () async {
      await fiche.save(laFiche);
      await copie.appliquer(refuse: false);

      final chemin = fichierCopie().path.replaceAll(r'\', '/');
      expect(chemin, contains(SauvegardeSysteme.dossierSauvegardable));
      expect(chemin.contains('/${SauvegardeSysteme.dossierExclu}/'), isFalse,
          reason: 'une copie ecrite dans l emplacement exclu ne serait jamais '
              'sauvegardee : decocher la case n aurait aucun effet, et ce serait '
              'un faux succes');
    });

    test('idempotent dans les deux sens (une case se bascule plusieurs fois)',
        () async {
      await fiche.save(laFiche);
      await copie.appliquer(refuse: false);
      await copie.appliquer(refuse: false);
      expect(fichierCopie().existsSync(), isTrue);
      await copie.appliquer(refuse: true);
      await copie.appliquer(refuse: true);
      expect(fichierCopie().existsSync(), isFalse);
    });

    test('UNE COPIE ORPHELINE EST RAMASSEE : le disque CONVERGE vers la '
        'decision', () async {
      // POURQUOI CE TEST EXISTE, ET IL GARDE UNE REGLE, PAS UN DETAIL. Les
      // ecrans lancent le re-alignement SANS L'ATTENDRE : la confirmation d'un
      // enregistrement ne doit dependre de rien d'autre que de l'enregistrement
      // (mesure du 28/09 : l'attendre a rendu trois tests d'ecran rouges sur un
      // canal de plateforme sans interlocuteur, qui ne rend jamais la main).
      //
      // Le prix de ce choix serait un trou : une application fermee juste apres
      // un effacement laisserait sa copie derriere elle. La regle n'est donc pas
      // « chaque geste est transactionnel » mais « le disque converge vers la
      // decision ». Ici on simule exactement ce trou : une copie ecrite par une
      // session precedente, alors que le refus est actif.
      final orpheline = fichierCopie();
      orpheline.parent.createSync(recursive: true);
      orpheline.writeAsStringSync('{"bloodType":"O-"}');
      expect(orpheline.existsSync(), isTrue);

      await copie.appliquer(refuse: kRefusSauvegardeSystemeParDefaut);

      expect(orpheline.existsSync(), isFalse,
          reason: 'une copie qui a survecu a une session doit disparaitre des '
              'que la decision est relue : sans cette convergence, le fait de ne '
              'pas attendre le re-alignement ouvrirait un trou durable');
    });

    test('ELLE NE LEVE JAMAIS, meme si le stockage est inaccessible', () async {
      // LECON DU 28/09, PAYEE PAR UN TEST ROUGE. Ce re-alignement est appele
      // dans le chemin qui CONFIRME au randonneur que sa fiche est enregistree.
      // La premiere version levait et attendait une ecriture asynchrone : la
      // confirmation du LOT X a disparu de l ecran, alors que la fiche etait
      // bien en base. Un enregistrement reussi qui ne se dit pas est le pire
      // des deux defauts, pire qu une copie manquante.
      await fiche.save(laFiche);
      final cassee = CopieSauvegardableFicheService(
        healthRepository: fiche,
        baseDirProvider: () async =>
            throw const FileSystemException('stockage indisponible'),
      );

      expect(await cassee.appliquer(refuse: false), isFalse,
          reason: 'elle doit RENDRE faux, pas lever : l appelant doit pouvoir '
              'confirmer l enregistrement quand meme');
      expect(await cassee.appliquer(refuse: true), isFalse);
      expect(await cassee.copiePresente(), isFalse);
    });
  });

  // =========================================================================
  // 3. CE QUE LE RANDONNEUR LIT — LES DEUX SUJETS NE SE CONFONDENT PAS, ET LE
  //    PRIX EST DIT AU MOMENT OU IL REMPLIT SA FICHE
  // =========================================================================
  group('612 — les cinq langues portent le prix et la case, sans cadratin', () {
    for (final entree in _langues.entries) {
      final langue = entree.key;
      final tr = entree.value;

      test('$langue : le prix de la promesse est ecrit', () {
        expect(tr.health.localOnlyPriceTitle.trim(), isNotEmpty);
        expect(tr.health.localOnlyPrice.trim().length, greaterThan(80),
            reason: 'le prix doit etre dit en entier : changer de telephone, '
                'c est ressaisir groupe sanguin, allergies et traitements');
      });

      test('$langue : la case de refus existe dans ses DEUX formulations', () {
        final sb = tr.health.systemBackup;
        expect(sb.refuseGoogle.trim(), isNotEmpty);
        expect(sb.refuseApple.trim(), isNotEmpty);
        expect(sb.refuseGoogle, isNot(sb.refuseApple),
            reason: 'une case qui parle de Google sur un iPhone decredibilise '
                'tout le reste');
        expect(sb.explainGoogle, isNot(sb.explainApple));
      });

      test('$langue : le texte DIT que nos serveurs ne sont pas concernes', () {
        expect(tr.health.systemBackup.notOurServers.trim().length,
            greaterThan(80),
            reason: 'sans cette phrase, le randonneur qui decoche croira que '
                'NOUS recuperons sa fiche. Nous ne l avons jamais.');
      });

      test('$langue : AUCUN cadratin dans les textes de ce lot (tache 599)', () {
        final textes = <String>[
          tr.health.localOnlyPriceTitle,
          tr.health.localOnlyPrice,
          tr.health.systemBackup.title,
          tr.health.systemBackup.refuseGoogle,
          tr.health.systemBackup.refuseApple,
          tr.health.systemBackup.explainGoogle,
          tr.health.systemBackup.explainApple,
          tr.health.systemBackup.notOurServers,
          tr.health.systemBackup.confirm,
          tr.health.systemBackup.a11yCheckbox,
          tr.consent.healthBackupNote,
        ];
        for (final texte in textes) {
          expect(texte.contains('—'), isFalse,
              reason: 'cadratin dans « $texte »');
          expect(texte.contains('–'), isFalse,
              reason: 'demi-cadratin dans « $texte »');
        }
      });
    }

    test('les quatre traductions sont REELLES, pas un repli sur le francais',
        () {
      final fr = _langues['fr']!;
      for (final entree in _langues.entries) {
        if (entree.key == 'fr') continue;
        expect(entree.value.health.localOnlyPrice,
            isNot(fr.health.localOnlyPrice),
            reason: '${entree.key} se rabat sur le francais : Slang le fait en '
                'silence quand une cle manque');
        expect(entree.value.health.systemBackup.refuseGoogle,
            isNot(fr.health.systemBackup.refuseGoogle),
            reason: '${entree.key} se rabat sur le francais');
      }
    });

    test('LE TEXTE QUI MENTAIT NE MENT PLUS : le consentement ne promet plus de '
        'retrouver la fiche ailleurs', () {
      // AVANT LA TACHE 612 ce texte disait, dans les cinq langues : « Sans cette
      // autorisation, votre fiche de renseignement medical n est pas sauvegardee :
      // vous ne pourrez pas la retrouver sur un autre telephone ». Il promettait
      // donc l inverse en creux : AVEC l autorisation, elle serait retrouvable.
      // C est exactement le motif du 27/09 — un texte qui survit a la regle qu il
      // decrit. Il n y a plus AUCUNE sauvegarde, autorisation ou pas.
      for (final entree in _langues.entries) {
        final note = entree.value.consent.healthBackupNote.toLowerCase();
        expect(note.contains('sans cette autorisation'), isFalse,
            reason: '${entree.key} : le texte suggere encore que '
                'l autorisation changerait quelque chose a la sauvegarde de la '
                'fiche medicale');
        expect(note.trim(), isNotEmpty);
      }
    });

    test('LA MINE DU COFFRE EST DESAMORCEE : le code de reconnexion ne promet '
        'plus la fiche medicale', () {
      // LA TROUVAILLE LA PLUS DANGEREUSE DE CE LOT, ET ELLE N ETAIT PAS DANS LA
      // TACHE. `recovery.intro` disait, dans les cinq langues : « Ce code ouvre
      // votre coffre (profil, FICHE DE RENSEIGNEMENT et solde d etapes) sur un
      // autre telephone ». Or « fiche de renseignement » est le nom que ce depot
      // donne a la fiche MEDICALE : le meme mot figurait dans l en-tete du
      // service supprime (« la fiche de renseignement medical »).
      //
      // POURQUOI C ETAIT UNE MINE ET PAS SEULEMENT UNE ERREUR. Ce texte n est
      // PAS affiche aujourd hui : l ecran du code ne le montre que si
      // `CoffreDeReconnexion.alimente` est vrai, et il est faux. Il attendait
      // donc son heure. Le jour ou quelqu un branchera un ecrivain du coffre
      // — ce que l invariante du LOT 596 l invite explicitement a faire —, ce
      // texte serait revenu a l ecran et aurait promis la fiche medicale dans le
      // coffre. Aucun test ne l aurait vu, puisque le texte etait deja ecrit.
      //
      // IL NOMME DESORMAIS CE QU IL CONTIENT (pseudonyme, avatar, solde) ET CE
      // QU IL NE CONTIENT PAS.
      for (final entree in _langues.entries) {
        final intro = entree.value.recovery.intro.toLowerCase();
        for (final piege in const [
          'fiche de renseignement',
          'personal info',
          'persönliche angaben',
          'ficha personal',
          'scheda informativa',
        ]) {
          expect(intro.contains(piege), isFalse,
              reason: '${entree.key} : le coffre de reconnexion annonce encore '
                  '« $piege », qui designe la fiche medicale dans ce depot. '
                  'Decision du 28/09 10:42 : elle ne quitte jamais le '
                  'telephone, donc elle n est pas dans le coffre.');
        }
        expect(intro.trim(), isNotEmpty);
      }
    });
  });

  group('612 — l ecran de la fiche DIT le prix, au moment ou on la remplit', () {
    testWidgets('/health affiche le prix de la promesse, avant les champs',
        (tester) async {
      await monterAppliReelle(tester, depart: '/health');

      final prix = find.byKey(const ValueKey('health-local-only-price'));
      expect(prix, findsOneWidget,
          reason: 'le prix doit etre lu AU MOMENT OU la fiche se remplit, pas '
              'decouvert le jour du changement d appareil');

      final textes = textesVisibles(tester);
      final tr = _langues['fr']!;
      expect(textes, contains(tr.health.localOnlyPriceTitle));
      expect(textes, contains(tr.health.localOnlyPrice));

      // LE BANDEAU DE CONFIANCE RESTE : les deux vont ensemble. L un dit ce que
      // nous ne faisons pas, l autre ce que cela coute.
      expect(textes, contains(tr.health.privacyBanner));

      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets('/health garde ses champs et son geste d effacement (on ne '
        'casse pas la fiche)', (tester) async {
      await monterAppliReelle(tester, depart: '/health');
      final tr = _langues['fr']!;
      final textes = textesVisibles(tester);

      // LA FICHE RESTE ENTIERE ET LOCALE : c est celle qu on montre aux secours,
      // c est sa raison d etre. On a retire un chemin de sortie, pas la fiche.
      expect(find.byKey(const ValueKey('health-blood-type-field')),
          findsOneWidget);
      expect(textes, contains(tr.health.field.allergies));
      expect(textes, contains(tr.health.field.treatments));
      expect(textes, contains(tr.health.advice.title),
          reason: 'les conseils du LOT Q restent : la fiche doit etre '
              'applicable sur le sentier');

      await demonterAppli(tester);
      erreursDeRendu(tester);
    });
  });

  group('612 — la case, telle que le randonneur la voit a la connexion', () {
    Widget dialogue(TargetPlatform plateforme) => ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: ThemeData(platform: plateforme),
              home: const Scaffold(
                body: RefusSauvegardeSystemeDialog(),
              ),
            ),
          ),
        );

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      brancherLesPlugins();
    });

    testWidgets('elle est PRE-COCHEE (decision de Christophe, mot pour mot)',
        (tester) async {
      await tester.pumpWidget(dialogue(TargetPlatform.android));
      await tester.pumpAndSettle();

      final caseALocher = tester.widget<CheckboxListTile>(
        find.byKey(RefusSauvegardeSystemeDialog.cleCase),
      );
      expect(caseALocher.value, isTrue,
          reason: 'le refus est le DEFAUT, coche d avance : le randonneur peut '
              'le decocher s il prefere la commodite, c est son choix, eclaire');
    });

    testWidgets('sur Android elle parle du cloud GOOGLE', (tester) async {
      await tester.pumpWidget(dialogue(TargetPlatform.android));
      await tester.pumpAndSettle();
      final tr = _langues['fr']!;
      final textes = textesVisibles(tester);

      expect(textes, contains(tr.health.systemBackup.refuseGoogle));
      expect(textes, isNot(contains(tr.health.systemBackup.refuseApple)));
      expect(textes, contains(tr.health.systemBackup.explainGoogle));
    });

    testWidgets('sur iPhone elle parle d iCLOUD', (tester) async {
      await tester.pumpWidget(dialogue(TargetPlatform.iOS));
      await tester.pumpAndSettle();
      final tr = _langues['fr']!;
      final textes = textesVisibles(tester);

      expect(textes, contains(tr.health.systemBackup.refuseApple));
      expect(textes, isNot(contains(tr.health.systemBackup.refuseGoogle)));
      expect(textes, contains(tr.health.systemBackup.explainApple));
    });

    testWidgets('elle DIT que nos serveurs ne sont pas concernes, dans les deux '
        'plateformes', (tester) async {
      final tr = _langues['fr']!;
      for (final plateforme in [TargetPlatform.android, TargetPlatform.iOS]) {
        await tester.pumpWidget(dialogue(plateforme));
        await tester.pumpAndSettle();
        expect(textesVisibles(tester),
            contains(tr.health.systemBackup.notOurServers),
            reason: 'sans cette phrase, decocher voudrait dire « StepWays '
                'recupere ma fiche » dans la tete du randonneur, et ce serait '
                'faux');
      }
    });

    testWidgets('valider ENREGISTRE la decision (elle ne reste pas en vol)',
        (tester) async {
      await tester.pumpWidget(dialogue(TargetPlatform.android));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(RefusSauvegardeSystemeDialog.cleValider));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kRefusSauvegardeSystemeKey), isTrue,
          reason: 'sans ecriture, la question serait reposee a chaque connexion '
              'et la decision du randonneur ne vaudrait rien');
    });

    testWidgets('decocher puis valider enregistre le CHOIX INVERSE (la case '
        'n est pas decorative)', (tester) async {
      await tester.pumpWidget(dialogue(TargetPlatform.android));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(RefusSauvegardeSystemeDialog.cleCase));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(RefusSauvegardeSystemeDialog.cleValider));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kRefusSauvegardeSystemeKey), isFalse,
          reason: 'le randonneur qui accepte la commodite doit etre entendu : '
              'une case qu on ne peut pas decocher n est pas un choix');
    });
  });
}
