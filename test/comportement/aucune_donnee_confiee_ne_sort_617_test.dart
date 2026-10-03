// TACHE 617 — AUCUNE DONNEE CONFIEE NE SORT PAR DEFAUT, ET CE N'EST PLUS UNE
// LISTE A TENIR A JOUR.
//
// REGLE GENERALE DE CHRISTOPHE, 28/09 14:31, verbatim : « on ne partage aucune
// donnee confiee sauf si le client decoche volontairement ». Elle repondait a une
// question sur le poids et la taille ; il a repondu par une regle GENERALE.
//
// ---------------------------------------------------------------------------
// CE QUE CE FICHIER PROUVE, DANS L'ORDRE DE CE QUI COMPTE
// ---------------------------------------------------------------------------
//
//  1. QUE LE DEFAUT EST « RIEN ». Les taches 612 et 613 declaraient des
//     EXCLUSIONS, c'est-a-dire une liste de ce qui reste dehors. Une telle liste
//     doit etre tenue a jour, et ce depot a deja paye deux fois ce montage : la
//     613 a trouve une exclusion posee sur un dossier VIDE, la 615 une fiche
//     medicale qui montait dans iCloud. Le montage est inverse : UNE inclusion,
//     donc tout le reste est dehors, y compris ce que personne n'a pense a
//     nommer. Le test « CHAQUE SECTION PORTE AU MOINS UNE INCLUSION » est celui
//     qui donne son nom au lot : sans inclusion, une section sauvegarde TOUT, et
//     la documentation d'Android le dit mot pour mot.
//
//  2. QUE DECOCHER VEUT DIRE QUELQUE CHOSE. Une case qui ne change rien serait
//     pire qu'aucune case. La copie de la base est donc fabriquee ET RELUE au
//     retour : le test « LA PROGRESSION REVIENT SUR LE TELEPHONE SUIVANT » joue
//     le scenario entier, telephone perdu compris.
//
//  3. QUE LE DOSSIER DES COPIES N'EST JAMAIS EXCLU SUR IPHONE. C'est le piege
//     symetrique du precedent : si le balayage iPhone excluait aussi ce
//     dossier-la, decocher produirait une copie que la sauvegarde n'emporterait
//     pas. Le randonneur aurait choisi la commodite et retrouverait un telephone
//     vide.
//
//  4. QUE LA QUESTION EST POSEE A TOUT LE MONDE. La tache 612 ne la posait qu'a
//     la connexion Google et son bilan nommait le trou. Un randonneur qui ne se
//     connecte jamais etait protege par le defaut mais ne pouvait pas choisir.
//
//  5. QUE LE TEXTE DIT CE QUE LA CASE COUTE. Sans enjoliver, dans les cinq
//     langues, sans cadratin.
//
// ---------------------------------------------------------------------------
// CE QUI N'EST PAS TESTE ICI, ET POURQUOI
// ---------------------------------------------------------------------------
//
// L'EFFET REEL d'une inclusion Android ou d'un attribut iCloud ne se verifie que
// sur un telephone : ces tests prouvent que nous DEMANDONS la bonne chose, au bon
// endroit, au bon moment. La garantie elle-meme est celle de Google et d'Apple,
// et les deux sont citees mot pour mot dans les fichiers qu'ils gouvernent.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/copie_sauvegardable_base_service.dart';
import 'package:moteur_gr/core/services/exclusion_sauvegarde_icloud.dart';
import 'package:moteur_gr/core/services/garde_sauvegarde_ios.dart';
import 'package:moteur_gr/core/services/sauvegarde_systeme.dart';
import 'package:moteur_gr/features/safety/presentation/backup_consent_gate.dart';
import 'package:moteur_gr/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart';
import 'package:moteur_gr/features/safety/providers/refus_sauvegarde_systeme_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// LE CANAL ESPION — plus simple que celui du lot 615, il ne lui manque que la
// lecture du disque (l'ORDRE n'est pas le sujet ici, la COUVERTURE l'est).
// ---------------------------------------------------------------------------
class _NatifEspion {
  final List<({String methode, String chemin})> appels = [];

  /// Quand il est vrai, le natif rend `false` : ni succes ni exception. C'est le
  /// cas du faux succes, celui qu'il ne faut jamais compter comme une reussite.
  bool rendFaux = false;

  void brancher() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(ExclusionSauvegardeIcloud.nomDuCanal),
          (appel) async {
            final chemin =
                (appel.arguments
                        as Map)[ExclusionSauvegardeIcloud.argumentChemin]
                    as String;
            appels.add((methode: appel.method, chemin: _n(chemin)));
            return rendFaux ? false : true;
          },
        );
  }

  void debrancher() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(ExclusionSauvegardeIcloud.nomDuCanal),
          null,
        );
  }

  Iterable<String> get exclus => appels
      .where((a) => a.methode == ExclusionSauvegardeIcloud.methodeExclure)
      .map((a) => a.chemin);

  Iterable<String> get inclus => appels
      .where((a) => a.methode == ExclusionSauvegardeIcloud.methodeInclure)
      .map((a) => a.chemin);
}

/// Les separateurs de Windows ramenes a ceux du telephone, pour comparer des
/// chemins sans que la machine de developpement s'en melle.
String _n(String chemin) => chemin.replaceAll(r'\', '/');

final _langues = {
  for (final l in AppLocale.values) l.languageTag: l.buildSync(),
};

/// Les dix textes de la case, pour une langue donnee.
List<String> _textesDeLaCase(Translations tr) => [
  tr.systemBackup.title,
  tr.systemBackup.refuseGoogle,
  tr.systemBackup.refuseApple,
  tr.systemBackup.explainGoogle,
  tr.systemBackup.explainApple,
  tr.systemBackup.cost,
  tr.systemBackup.whatComesBack,
  tr.systemBackup.notOurServers,
  tr.systemBackup.confirm,
  tr.systemBackup.a11yCheckbox,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. LES REGLES ANDROID NE DISENT PLUS « TOUT SAUF », ELLES DISENT « RIEN
  //    SAUF » — ET C'EST LA SEULE FACON QUE CELA TIENNE DANS SIX MOIS
  // =========================================================================
  group('617 — INVARIANTE : le defaut Android est RIEN, et les XML disent la '
      'MEME chose que le code', () {
    /// LE FICHIER DE REGLES, SANS SES COMMENTAIRES — ET C'EST INDISPENSABLE ICI.
    ///
    /// Ces fichiers CITENT la documentation d'Android mot pour mot, et cette
    /// documentation parle de `<include>`, de `<cloud-backup>` et de
    /// `<device-transfer>`. Un test qui cherche ces chaines dans le fichier
    /// ENTIER les trouve dans la prose : il passerait au vert sur un fichier qui
    /// ne declare RIEN mais qui EXPLIQUE bien. C'est le defaut exact que la
    /// premiere version de ce test avait, et il a ete mesure (un decompte de
    /// sections a trois au lieu de deux dans l invariante de la tache 612).
    String lire(String chemin) {
      final f = File(chemin);
      expect(
        f.existsSync(),
        isTrue,
        reason:
            'le fichier de regles « $chemin » est declare par '
            'SauvegardeSysteme mais il n existe pas sur le disque',
      );
      return f.readAsStringSync().replaceAll(
        RegExp(r'<!--.*?-->', dotAll: true),
        '',
      );
    }

    Set<String> inclusionsDuXml(String xml) {
      final motif = RegExp(
        r'<include\s+domain="([^"]+)"(?:\s+path="([^"]*)")?\s*/>',
      );
      return motif
          .allMatches(xml)
          .map((m) => '${m.group(1)}|${m.group(2) ?? ''}')
          .toSet();
    }

    final attendues = SauvegardeSysteme.inclusions
        .map((e) => '${e.domaine}|${e.chemin}')
        .toSet();

    test('LE TEST QUI DONNE SON NOM AU LOT : chaque section porte AU MOINS une '
        'inclusion, sinon elle sauvegarde TOUT', () {
      // SOURCE VERIFIEE, mot pour mot (documentation Android, « Back up user
      // data with Auto Backup ») : « By default, Auto Backup includes almost all
      // app files. If you specify an <include> element, the system no longer
      // includes any files by default and backs up ONLY the files specified. »
      //
      // Et, pour les sections : « If there are no rules for a particular backup
      // mode, such as if the <device-transfer> section is missing, that mode is
      // fully enabled for all content ».
      //
      // C'est donc la PRESENCE d'une inclusion, dans CHAQUE section, qui fait le
      // defaut « rien ». La retirer ne casse aucun autre test du depot : tout
      // redeviendrait sauvegarde en silence, et c'est exactement le defaut que ce
      // test attrape.
      final xml12 = lire(SauvegardeSysteme.reglesAndroid12EtPlus);
      for (final section in SauvegardeSysteme.sectionsAndroid12EtPlus) {
        expect(
          xml12,
          contains('<$section>'),
          reason:
              'la section « $section » manque : ce mode de transfert '
              'sauvegarderait TOUT',
        );
        final debut = xml12.indexOf('<$section>');
        final fin = xml12.indexOf('</$section>');
        expect(fin, greaterThan(debut));
        final contenu = xml12.substring(debut, fin);
        expect(
          inclusionsDuXml(contenu),
          isNotEmpty,
          reason:
              'une section SANS inclusion sauvegarde tout le contenu de '
              'l application : progression, journal, photos, profil',
        );
        expect(
          inclusionsDuXml(contenu),
          attendues,
          reason:
              'les inclusions de « $section » doivent etre EXACTEMENT '
              'celles de SauvegardeSysteme.inclusions',
        );
      }

      final xmlAvant12 = lire(SauvegardeSysteme.reglesAndroidAvant12);
      expect(
        inclusionsDuXml(xmlAvant12),
        isNotEmpty,
        reason:
            'sans inclusion, les telephones Android 11 et anterieurs '
            'sauvegardent tout, et c est le randonneur au telephone le plus '
            'vieux qui y perd',
      );
      expect(inclusionsDuXml(xmlAvant12), attendues);
    });

    test('LA SEULE inclusion est le dossier des copies acceptees', () {
      expect(
        SauvegardeSysteme.inclusions.length,
        1,
        reason:
            'chaque inclusion ajoutee est une famille de donnees qui '
            'repart chez Google. Il n y en a qu une, et c est le dossier que '
            'le randonneur remplit lui-meme en decochant',
      );
      final seule = SauvegardeSysteme.inclusions.single;
      expect(seule.chemin, contains(SauvegardeSysteme.dossierSauvegardable));
      expect(
        seule.domaine,
        'file',
        reason:
            'le dossier des copies vit sous getApplicationSupportDirectory, '
            'c est-a-dire files/ sur Android, domaine « file »',
      );
    });

    test(
      'AUCUNE inclusion ne couvre un stockage confie, ni un domaine entier',
      () {
        // LES DOMAINES ONT ETE MESURES, PAS SUPPOSES (la tache 613 avait prouve
        // qu un domaine pouvait designer autre chose que ce qu on croyait) :
        //  * root       -> app_flutter/ : la base, les photos, les paquets, les
        //                  tuiles, les exports ;
        //  * sharedpref -> le profil randonneur (age, taille, poids), le solde ;
        //  * external   -> aucun appel dans lib/, mais une inclusion y ouvrirait
        //                  le stockage partage ;
        //  * database   -> vide (mesure de la 613), mais une inclusion serait un
        //                  mensonge de plus.
        const domainesInterdits = [
          'root',
          'sharedpref',
          'external',
          'database',
        ];
        for (final inclusion in SauvegardeSysteme.inclusions) {
          expect(
            domainesInterdits,
            isNot(contains(inclusion.domaine)),
            reason:
                'inclure le domaine « ${inclusion.domaine} » ferait repartir '
                'des donnees confiees chez Google',
          );
          expect(
            inclusion.chemin.trim(),
            isNot(anyOf('', '.', '/')),
            reason:
                'un chemin vide ou « . » designe LE DOMAINE ENTIER : ce '
                'serait « tout sauf rien », le montage qu on vient de quitter',
          );
        }
      },
    );

    test('le dossier de la fiche medicale n est ni inclus, ni oublie', () {
      for (final inclusion in SauvegardeSysteme.inclusions) {
        expect(
          inclusion.chemin.contains(SauvegardeSysteme.dossierExclu),
          isFalse,
          reason:
              'la decision du 28/09 10:42 est en majuscules dans le '
              'message de Christophe : les donnees medicales RESTENT sur le tel',
        );
      }
      // ET ELLE RESTE EXPLICITEMENT EXCLUE, en plus de l etre par defaut : c est
      // le second verrou pour le jour ou une inclusion trop large serait ajoutee.
      // Source : « <exclude> takes precedence » (documentation Android).
      expect(
        SauvegardeSysteme.exclusions.any(
          (e) => e.chemin.contains(SauvegardeSysteme.dossierExclu),
        ),
        isTrue,
        reason:
            'retirer cette exclusion ne changerait rien aujourd hui, et '
            'rouvrirait la porte le jour ou quelqu un inclut plus large',
      );
    });

    test('le trou de la troisieme section est NOMME, pas tu', () {
      // Une section <cross-platform-transfer> absente vaut autorisation complete
      // depuis Android 16 QPR2. Nous ne pouvons pas la declarer (elle exige
      // l identifiant d equipe Apple, absent du depot). CE QU ON NE PEUT PAS
      // FERMER, ON L ECRIT : c est la difference entre un point ouvert et un
      // oubli, et c est aussi ce qui permet a Christophe de le fermer d un chiffre.
      expect(
        SauvegardeSysteme.trouCrossPlatformTransfer,
        contains('cross-platform-transfer'),
      );
      expect(SauvegardeSysteme.trouCrossPlatformTransfer, contains('teamId'));
      final xml12 = File(
        SauvegardeSysteme.reglesAndroid12EtPlus,
      ).readAsStringSync();
      expect(
        xml12,
        contains('cross-platform-transfer'),
        reason:
            'le fichier de regles doit porter la trace ecrite de ce qu il '
            'ne ferme pas, sinon le prochain lecteur croira que tout est ferme',
      );
    });

    test('le trou iPhone des preferences est NOMME avec son inventaire', () {
      // MESURE : NSUserDefaults n est pas un fichier de l application mais un
      // domaine du systeme ; NSURLIsExcludedFromBackupKey s applique a une URL.
      // Les valeurs de NSUserDefaults ne peuvent donc pas en etre exclues. Sur
      // Android les memes cles sont dehors (domaine sharedpref non inclus).
      const trou = SauvegardeSysteme.trouUserDefaultsIos;
      expect(trou, contains('NSUserDefaults'));
      expect(trou, contains('taille'));
      expect(trou, contains('poids'));
    });
  });

  // =========================================================================
  // 2. PERSONNE N'ECRIT DE DONNEE CONFIEE DANS LE DOSSIER SAUVEGARDABLE
  // =========================================================================
  group('617 — INVARIANTE : le dossier sauvegardable n est rempli QUE par les '
      'services de copie', () {
    test('trois fichiers de production seulement connaissent ce dossier', () {
      // LE DEFAUT QUE CE TEST ATTRAPE : quelqu un qui, cherchant un endroit pour
      // ecrire, tombe sur ce dossier-la. Il est le SEUL emplacement inclus dans
      // la sauvegarde du telephone : une donnee ecrite dedans part chez Google
      // sans que la case du randonneur y soit pour rien, et aucune invariante
      // declarative ne peut le voir.
      final attendus = {
        'lib/core/services/sauvegarde_systeme.dart',
        'lib/core/services/copie_sauvegardable_base_service.dart',
        'lib/core/services/garde_sauvegarde_ios.dart',
        'lib/features/safety/data/health_info_backup_copy_service.dart',
      };
      final trouves = <String>{};
      for (final f
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final code = _codeSeul(f.readAsStringSync());
        if (code.contains('dossierSauvegardable')) {
          trouves.add(_n(f.path));
        }
      }
      expect(
        trouves,
        attendus,
        reason:
            'un fichier de plus qui ecrit dans le dossier sauvegardable '
            'fait sortir une donnee sans passer par la decision du randonneur ; '
            'un fichier de moins veut dire que le montage a bouge',
      );
    });
  });

  // =========================================================================
  // 3. LA COPIE DE LA BASE — ET SON RETOUR, QUI EST LA MOITIE QUI COMPTE
  // =========================================================================
  group('617 — decocher fait une copie de la base, et la copie REVIENT', () {
    late Directory bac;
    late Directory documents;
    late Directory support;
    late AppDatabase db;
    late _NatifEspion natif;

    setUp(() async {
      bac = Directory.systemTemp.createTempSync('confie617');
      documents = Directory('${bac.path}/documents')
        ..createSync(recursive: true);
      support = Directory('${bac.path}/support')..createSync(recursive: true);
      db = AppDatabase(NativeDatabase.memory());
      await db.customStatement('SELECT 1');
      natif = _NatifEspion()..brancher();
    });

    tearDown(() async {
      natif.debrancher();
      await db.close();
      if (bac.existsSync()) {
        try {
          bac.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows tient parfois le fichier quelques millisecondes. Le bac est
          // temporaire : un menage rate ne doit pas faire echouer une mesure.
        }
      }
    });

    CopieSauvegardableBaseService service() => CopieSauvegardableBaseService(
      db: db,
      supportDirProvider: () async => support,
      exclusionIcloud: ExclusionSauvegardeIcloud(cibleIos: true),
    );

    File laCopie() => File(cheminCopieBase(support));

    test(
      'PAR DEFAUT, aucune copie : le refus est le defaut et il ne laisse rien',
      () async {
        expect(await service().appliquer(refuse: true), isFalse);
        expect(laCopie().existsSync(), isFalse);
        expect(await service().copiePresente(), isFalse);
      },
    );

    test('decocher produit une copie, et c est une VRAIE base', () async {
      await ProgressDao(db).upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'gr20',
          currentStage: const Value(9),
        ),
      );

      expect(await service().appliquer(refuse: false), isTrue);
      final copie = laCopie();
      expect(copie.existsSync(), isTrue);
      expect(copie.lengthSync(), greaterThan(0));
      // PAS SEULEMENT UN FICHIER NON VIDE : une base lisible. Une copie qui
      // n en serait pas une serait adoptee au retour et casserait l application.
      final relue = AppDatabase(NativeDatabase(copie));
      addTearDown(relue.close);
      final progression = await ProgressDao(relue).getByTrailId('gr20');
      expect(progression?.currentStage, 9);
    });

    test(
      're-cocher le refus SUPPRIME la copie : un refus ne laisse pas de trace',
      () async {
        await ProgressDao(
          db,
        ).upsert(UserProgressEntriesCompanion.insert(trailId: 'gr20'));
        expect(await service().appliquer(refuse: false), isTrue);
        expect(laCopie().existsSync(), isTrue);

        expect(await service().appliquer(refuse: true), isFalse);
        expect(
          laCopie().existsSync(),
          isFalse,
          reason:
              'une copie laissee derriere un refus continuerait d etre '
              'emportee par la sauvegarde du telephone',
        );
      },
    );

    test('la copie est RAFRAICHIE, pas figee a la premiere fois', () async {
      final dao = ProgressDao(db);
      await dao.upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'gr20',
          currentStage: const Value(3),
        ),
      );
      expect(await service().appliquer(refuse: false), isTrue);

      await dao.upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'gr20',
          currentStage: const Value(11),
        ),
      );
      expect(await service().appliquer(refuse: false), isTrue);

      final relue = AppDatabase(NativeDatabase(laCopie()));
      addTearDown(relue.close);
      expect(
        (await ProgressDao(relue).getByTrailId('gr20'))?.currentStage,
        11,
        reason:
            'VACUUM INTO refuse d ecrire par-dessus un fichier existant : '
            'sans la suppression prealable, la copie resterait celle du jour '
            'ou le randonneur a decoche',
      );
    });

    test(
      'la copie se voit RETIRER l exclusion iCloud, sinon decocher ne sert a '
      'rien sur iPhone',
      () async {
        await ProgressDao(
          db,
        ).upsert(UserProgressEntriesCompanion.insert(trailId: 'gr20'));
        await service().appliquer(refuse: false);

        expect(natif.inclus, contains(_n(laCopie().path)));
        expect(
          natif.exclus,
          isNot(contains(_n(laCopie().path))),
          reason:
              'une copie EXCLUE serait un faux succes : la case decochee, la '
              'copie ecrite, et un telephone vide a l arrivee',
        );
      },
    );

    test('LA PROGRESSION REVIENT SUR LE TELEPHONE SUIVANT — le scenario entier', () async {
      // CE QUE CE TEST JOUE, ET C EST LA MOITIE DU LOT : le randonneur decoche,
      // sa progression est copiee, il perd son telephone, le nouveau restaure la
      // sauvegarde (donc la COPIE revient a son chemin, mais pas la base, qui n a
      // jamais ete sauvegardee), et l application doit retrouver sa progression.
      // Sans ce chemin de retour, la copie serait decorative et le texte montre
      // au randonneur serait faux.
      await ProgressDao(db).upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'gr20',
          currentStage: const Value(14),
        ),
      );
      await service().appliquer(refuse: false);
      expect(laCopie().existsSync(), isTrue);

      // LE TELEPHONE NEUF : la copie est la (restauree par le systeme), la base
      // ne l est pas.
      final baseNeuve = File('${documents.path}/$kFichierBaseStepWays');
      expect(baseNeuve.existsSync(), isFalse);

      expect(
        await adopterCopieSiBaseAbsente(documents: documents, support: support),
        isTrue,
      );
      expect(baseNeuve.existsSync(), isTrue);

      final apres = AppDatabase(NativeDatabase(baseNeuve));
      addTearDown(apres.close);
      expect(
        (await ProgressDao(apres).getByTrailId('gr20'))?.currentStage,
        14,
        reason:
            'le randonneur avait decoche : il doit retrouver sa '
            'progression, sinon la case lui a coûte sa vie privee pour rien',
      );
    });

    test('l adoption NE PEUT PAS ecraser une base reelle', () async {
      // LA GARDE QUI REND CE CHEMIN SUR. Appelee deux fois, appelee alors que le
      // randonneur a deja marche, elle ne doit jamais remplacer du reel par du
      // vieux. C est ce qui autorise a la placer sur le chemin d ouverture de la
      // base sans autre precaution.
      await ProgressDao(db).upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'gr20',
          currentStage: const Value(2),
        ),
      );
      await service().appliquer(refuse: false);

      final baseReelle = File('${documents.path}/$kFichierBaseStepWays');
      final enCours = AppDatabase(NativeDatabase(baseReelle));
      await ProgressDao(enCours).upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'gr20',
          currentStage: const Value(21),
        ),
      );
      await enCours.close();

      expect(
        await adopterCopieSiBaseAbsente(documents: documents, support: support),
        isFalse,
        reason: 'la base existe : la copie ne doit pas la remplacer',
      );

      final relue = AppDatabase(NativeDatabase(baseReelle));
      addTearDown(relue.close);
      expect((await ProgressDao(relue).getByTrailId('gr20'))?.currentStage, 21);
    });

    test('une copie qui n est PAS une base est refusee, pas adoptee', () async {
      // Une restauration interrompue laisse un fichier tronque. Adopte tel quel,
      // il donnerait une application qui ne demarre plus du tout : on aurait
      // echange une perte de donnees contre une panne.
      final copie = laCopie();
      copie.parent.createSync(recursive: true);
      copie.writeAsStringSync('ceci n est pas une base de donnees');

      expect(
        await adopterCopieSiBaseAbsente(documents: documents, support: support),
        isFalse,
      );
      expect(
        File('${documents.path}/$kFichierBaseStepWays').existsSync(),
        isFalse,
      );
      expect(
        copie.existsSync(),
        isTrue,
        reason:
            'le fichier douteux n est pas supprime en silence : il reste '
            'visible et sera ecrase par la prochaine copie',
      );
    });

    test(
      'sans copie du tout, l adoption ne fait rien et ne leve pas',
      () async {
        expect(
          await adopterCopieSiBaseAbsente(
            documents: documents,
            support: support,
          ),
          isFalse,
        );
        expect(
          File('${documents.path}/$kFichierBaseStepWays').existsSync(),
          isFalse,
        );
      },
    );

    test('LE CHEMIN REEL : ouvrir l application adopte la copie, sans que '
        'personne ne l appelle', () async {
      // CE QUE CE TEST AJOUTE AUX PRECEDENTS, ET IL EST INDISPENSABLE. Les tests
      // d au-dessus appellent `adopterCopieSiBaseAbsente` EUX-MEMES : ils
      // prouvent qu elle fait ce qu il faut, pas qu elle est BRANCHEE. Retirer
      // l appel de `ouvrirBaseDurable()` les laisserait tous verts et le
      // randonneur qui a decoche retrouverait un telephone vide.
      //
      // Celui-ci passe par le TELEPHONE SIMULE de la suite entiere
      // (`flutter_test_config.dart`) : il ecrit la copie a l endroit ou le
      // systeme la restaurerait, puis lit `databaseProvider` comme
      // l application le fait, sans rien surcharger.
      final vraiSupport = await getApplicationSupportDirectory();
      final vraisDocuments = await getApplicationDocumentsDirectory();
      expect(
        File('${vraisDocuments.path}/$kFichierBaseStepWays').existsSync(),
        isFalse,
        reason:
            'telephone neuf : la base n a pas ete sauvegardee, donc elle '
            'ne revient pas',
      );

      // La copie telle que le systeme la rend : une vraie base, avec une
      // progression dedans.
      final atelier = File('${bac.path}/atelier.sqlite');
      final source = AppDatabase(NativeDatabase(atelier));
      await ProgressDao(source).upsert(
        UserProgressEntriesCompanion.insert(
          trailId: 'gr20',
          currentStage: const Value(17),
        ),
      );
      await source.close();
      final copie = File(cheminCopieBase(vraiSupport));
      copie.parent.createSync(recursive: true);
      atelier.copySync(copie.path);

      final session = ProviderContainer();
      addTearDown(session.dispose);
      final base = session.read(databaseProvider);
      expect(
        (await ProgressDao(base).getByTrailId('gr20'))?.currentStage,
        17,
        reason:
            'l adoption doit se faire sur le chemin d ouverture de la '
            'base, pas dans une methode que personne n appelle',
      );
    });
  });

  // =========================================================================
  // 4. LE BALAYAGE IPHONE — TOUT SORT, SAUF LE DOSSIER DES COPIES
  // =========================================================================
  group('617 — sur iPhone, tout le stockage confie sort de iCloud', () {
    late Directory bac;
    late Directory documents;
    late Directory support;
    late _NatifEspion natif;

    setUp(() {
      bac = Directory.systemTemp.createTempSync('garde617');
      documents = Directory('${bac.path}/documents')
        ..createSync(recursive: true);
      support = Directory('${bac.path}/support')..createSync(recursive: true);
      natif = _NatifEspion()..brancher();
    });

    tearDown(() {
      natif.debrancher();
      if (bac.existsSync()) {
        try {
          bac.deleteSync(recursive: true);
        } on FileSystemException {
          // Voir plus haut : le menage d un bac temporaire n est pas la mesure.
        }
      }
    });

    GardeSauvegardeIos garde({bool cibleIos = true}) => GardeSauvegardeIos(
      cibleIos: cibleIos,
      exclusion: ExclusionSauvegardeIcloud(cibleIos: cibleIos),
      documents: () async => documents,
      support: () async => support,
    );

    void poser(Directory racine, String relatif, [String contenu = 'x']) {
      final f = File('${racine.path}/$relatif');
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(contenu);
    }

    test(
      'LA GARDE REELLE : hors iPhone, AUCUN appel et AUCUNE lecture de disque',
      () async {
        // Ce n est pas de la proprete. La tache 612 a mesure qu un appel a un canal
        // de plateforme SANS interlocuteur rendait trois tests d ecran ROUGES :
        // dans le temps feint d un test de widgets, il ne rend jamais la main. Le
        // fournisseur de repertoire LEVE ici : si le balayage le consultait, le
        // test le dirait.
        final sansDisque = GardeSauvegardeIos(
          cibleIos: false,
          exclusion: ExclusionSauvegardeIcloud(cibleIos: false),
          documents: () async => throw StateError('le disque a ete lu'),
          support: () async => throw StateError('le disque a ete lu'),
        );
        final bilan = await sansDisque.balayer();
        expect(bilan.sansObjet, isTrue);
        expect(natif.appels, isEmpty);
      },
    );

    test(
      'la base, son journal, les photos et les paquets sortent tous',
      () async {
        poser(documents, kFichierBaseStepWays);
        poser(documents, '$kFichierBaseStepWays-journal');
        poser(documents, 'journal_photos/2026-09-28-col.jpg');
        poser(documents, 'packs/gr20/etapes.json');
        poser(documents, 'mbtiles/gr20.mbtiles');

        final bilan = await garde().balayer();
        expect(bilan.sansObjet, isFalse);
        expect(bilan.complet, isTrue);

        for (final relatif in [
          kFichierBaseStepWays,
          '$kFichierBaseStepWays-journal',
          'journal_photos/2026-09-28-col.jpg',
          'packs/gr20/etapes.json',
          'mbtiles/gr20.mbtiles',
        ]) {
          expect(
            natif.exclus,
            contains(_n('${documents.path}/$relatif')),
            reason:
                '« $relatif » contient de la donnee confiee et resterait '
                'dans iCloud',
          );
        }
      },
    );

    test(
      'Documents est exclu LUI-MEME, en plus de chacune de ses entrees',
      () async {
        // LE SECOND VERROU. Apple ne garantit pas que l attribut d un dossier
        // s applique a son contenu, donc on ne construit pas sur ce point ; mais un
        // fichier qui NAIT APRES le balayage (le journal de la base, pendant une
        // transaction) n a que celui-la. Les deux poses couvrent chacune ce que
        // l autre laisse.
        poser(documents, kFichierBaseStepWays);
        await garde().balayer();
        expect(natif.exclus, contains(_n(documents.path)));
      },
    );

    test('LE DOSSIER DES COPIES ACCEPTEES N EST JAMAIS EXCLU, NI LUI NI SON '
        'PARENT', () async {
      // LE PIEGE SYMETRIQUE DE TOUT LE LOT. Si ce balayage excluait le dossier
      // des copies, ou le dossier applicatif qui le contient, decocher la case
      // produirait une copie que la sauvegarde n emporterait pas : le randonneur
      // aurait choisi la commodite et retrouverait un telephone vide. Poser
      // l attribut est irreversible du point de vue du test : il faut donc que
      // l appel n ait JAMAIS lieu.
      poser(
        support,
        '${SauvegardeSysteme.dossierSauvegardable}/'
        '${SauvegardeSysteme.fichierCopieBase}',
      );
      poser(
        support,
        '${SauvegardeSysteme.dossierSauvegardable}/'
        '${SauvegardeSysteme.healthSheetCopyFile}',
      );
      poser(support, '${SauvegardeSysteme.dossierExclu}/fiche.json');

      final bilan = await garde().balayer();

      final dossierCopies = _n(
        '${support.path}/${SauvegardeSysteme.dossierSauvegardable}',
      );
      for (final chemin in natif.exclus) {
        expect(
          chemin.startsWith(dossierCopies),
          isFalse,
          reason: '« $chemin » est dans le dossier des copies acceptees',
        );
      }
      expect(
        natif.exclus,
        isNot(contains(_n(support.path))),
        reason:
            'exclure le dossier applicatif emporterait le dossier des '
            'copies avec lui si l attribut se propage',
      );
      expect(
        bilan.epargnes,
        greaterThanOrEqualTo(3),
        reason:
            'le dossier des copies, et ses deux fichiers, sont epargnes '
            'DELIBEREMENT et le bilan le compte',
      );
      // La fiche medicale, elle, sort comme tout le reste.
      expect(
        natif.exclus,
        contains(
          _n(
            '${support.path}/${SauvegardeSysteme.dossierExclu}'
            '/fiche.json',
          ),
        ),
      );
    });

    test(
      'un refus du natif est compte comme ECHEC, jamais comme succes',
      () async {
        poser(documents, kFichierBaseStepWays);
        natif.rendFaux = true;

        final bilan = await garde().balayer();
        expect(bilan.echecs, greaterThan(0));
        expect(bilan.exclus, 0);
        expect(
          bilan.complet,
          isFalse,
          reason:
              'une promesse de confidentialite ne se declare pas tenue sur '
              'la foi d un appel qu on n a pas vu revenir',
        );
      },
    );

    test(
      'le nombre de chemins est BORNE : le demarrage ne depend pas du nombre '
      'de photos',
      () async {
        for (var i = 0; i < GardeSauvegardeIos.plafondChemins + 20; i++) {
          poser(documents, 'journal_photos/photo_$i.jpg');
        }
        final bilan = await garde().balayer();
        expect(
          natif.appels.length,
          lessThanOrEqualTo(GardeSauvegardeIos.plafondChemins),
        );
        expect(
          bilan.exclus,
          lessThanOrEqualTo(GardeSauvegardeIos.plafondChemins),
        );
      },
    );
  });

  // =========================================================================
  // 5. LA CASE — UNE SEULE, PRE-COCHEE, ET SA CLE EST NEUVE
  // =========================================================================
  group('617 — une seule case, pre-cochee, et le consentement de la 612 n est '
      'PAS elargi a la place du randonneur', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('la cle n est PAS celle de la tache 612', () {
      expect(
        kRefusSauvegardeSystemeKey,
        isNot(kRefusSauvegardeSystemeKeyLegacy),
        reason:
            'reutiliser la cle ferait qu un randonneur ayant decoche POUR '
            'SA SEULE FICHE MEDICALE aurait, sans rien faire, accepte la '
            'sauvegarde de son journal, de son profil et de ses photos',
      );
    });

    test('le refus est le defaut, avant meme que la case ait ete vue', () {
      expect(kRefusSauvegardeSystemeParDefaut, isTrue);
    });

    test(
      'un randonneur qui avait DECOCHE en 612 n a PAS accepte pour le reste',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          kRefusSauvegardeSystemeKeyLegacy: false,
        });
        final conteneur = ProviderContainer();
        addTearDown(conteneur.dispose);

        expect(
          conteneur.read(refusSauvegardeSystemeProvider),
          isTrue,
          reason:
              'la decision ancienne ne dit rien de la nouvelle question : le '
              'refus s applique jusqu a ce qu il reponde',
        );
        // La question doit etre REPOSEE.
        expect(
          await conteneur.read(decisionSauvegardeSystemePriseProvider.future),
          isFalse,
        );
      },
    );

    test('l ancienne cle est EFFACEE, pas seulement ignoree', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kRefusSauvegardeSystemeKeyLegacy: false,
      });
      final conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);
      conteneur.read(refusSauvegardeSystemeProvider);
      // Laisse la relecture asynchrone s achever.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(kRefusSauvegardeSystemeKeyLegacy),
        isFalse,
        reason:
            'une cle laissee derriere elle est une trace du geste passe, '
            'et elle ferait croire a deux decisions quand il n y en a qu une',
      );
    });
  });

  // =========================================================================
  // 6. LA QUESTION EST POSEE A L'OUVERTURE, A TOUT LE MONDE, UNE SEULE FOIS
  // =========================================================================
  group('617 — la porte de l ouverture pose la question a qui ne se connecte '
      'jamais', () {
    // LE VERROU DE LA TACHE 637 EST UN ETAT DE PROCESSUS, DONC IL SE REMET A
    // ZERO ENTRE DEUX TESTS. `poserSiNecessaire` ne laisse qu'un seul dialogue en
    // vol dans toute l'application — c'est ce qui ferme la course entre la porte
    // de l'ouverture et l'ecran de profil. Un test qui laisse son dialogue OUVERT
    // (aucun ne le referme ici) laisse donc le verrou pris, et le test suivant ne
    // verrait aucune question posee. En production c'est le comportement voulu
    // (la question EST en train d'etre posee) ; dans une suite de tests, c'est une
    // fuite d'etat, et elle se soigne ici.
    setUp(RefusSauvegardeSystemeDialog.reinitialiserLeVerrou);

    Widget appli(Widget corps) => ProviderScope(
      child: MaterialApp(home: BackupConsentGate(child: corps)),
    );

    testWidgets('aucune decision enregistree : la question est posee', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(appli(const Scaffold(body: Text('accueil'))));
      await tester.pumpAndSettle();

      expect(
        find.byKey(RefusSauvegardeSystemeDialog.cleCase),
        findsOneWidget,
        reason:
            'la tache 612 ne la posait qu a la connexion Google : le '
            'randonneur anonyme ne la voyait jamais et ne pouvait pas choisir',
      );
    });

    testWidgets('decision deja prise : la question ne revient PAS', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kRefusSauvegardeSystemeKey: true,
      });
      await tester.pumpWidget(appli(const Scaffold(body: Text('accueil'))));
      await tester.pumpAndSettle();

      expect(find.byKey(RefusSauvegardeSystemeDialog.cleCase), findsNothing);
    });

    testWidgets('la case est PRE-COCHEE a l ouverture', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(appli(const Scaffold(body: Text('accueil'))));
      await tester.pumpAndSettle();

      final caseCochee = tester.widget<CheckboxListTile>(
        find.byKey(RefusSauvegardeSystemeDialog.cleCase),
      );
      expect(caseCochee.value, isTrue);
    });

    testWidgets('LA CASE EST ATTEIGNABLE : sur un telephone courant, un appui '
        'SANS defilement la decoche', (tester) async {
      // CE TEST EXISTE PARCE QUE LE DEFAUT A ETE MESURE, DEUX FOIS.
      //
      // Le texte de ce lot est long : il nomme neuf familles de donnees et dit ce
      // que la case coûte. Les deux premieres mises en page l'ont paye :
      //  * prix et retour AVANT la case : celle-ci tombait a plus de deux ecrans
      //    sous le pli ;
      //  * prix en sous-titre de la case : la ligne faisait 644 pixels de haut et
      //    son centre restait hors ecran.
      // Dans les deux cas un appui la ou le randonneur cherche la case NE
      // CHANGEAIT RIEN. La tache 612 avait nomme comme trou le fait qu il « ne
      // peut pas choisir la commodite » : une case hors d'atteinte le rouvre.
      //
      // 393x851 est la taille d'un telephone courant (Pixel 5). Sur plus petit
      // (375x667, 360x640) un petit defilement reste necessaire, et c'est dit
      // dans le bilan plutot que tu.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(appli(const Scaffold(body: Text('accueil'))));
      await tester.pumpAndSettle();

      final laCase = find.byKey(RefusSauvegardeSystemeDialog.cleCase);
      expect(tester.widget<CheckboxListTile>(laCase).value, isTrue);
      await tester.tap(laCase, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        tester.widget<CheckboxListTile>(laCase).value,
        isFalse,
        reason:
            'une case qu on ne peut pas decocher sans deviner qu il faut '
            'faire defiler n est pas un choix. Remonter le prix au-dessus de la '
            'case, ou le remettre en sous-titre, rend ce test ROUGE.',
      );
    });

    testWidgets('un seul dialogue, meme si l arbre se reconstruit', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(appli(const Scaffold(body: Text('accueil'))));
      await tester.pumpAndSettle();
      await tester.pumpWidget(appli(const Scaffold(body: Text('accueil'))));
      await tester.pumpAndSettle();

      expect(
        find.byKey(RefusSauvegardeSystemeDialog.cleCase),
        findsOneWidget,
        reason:
            'deux dialogues empiles seraient impossibles a fermer : le '
            'second est barrierDismissible: false lui aussi',
      );
    });
  });

  // =========================================================================
  // 7. CE QUE LE RANDONNEUR LIT — LE PRIX EST DIT, SANS ENJOLIVER
  // =========================================================================
  group('617 — les cinq langues nomment les familles ET disent le prix', () {
    for (final entree in _langues.entries) {
      final langue = entree.key;
      final tr = entree.value;

      test('$langue : les dix textes existent et aucun n est vide', () {
        for (final texte in _textesDeLaCase(tr)) {
          expect(texte.trim(), isNotEmpty);
        }
      });

      test('$langue : le PRIX de la case cochee est dit en entier', () {
        expect(
          tr.systemBackup.cost.trim().length,
          greaterThan(200),
          reason:
              'le prix doit etre dit en entier : changer de telephone, '
              'c est repartir de zero, et le produit promet par ailleurs qu un '
              'trek realise garde sa trace A VIE',
        );
      });

      test('$langue : ce que decocher rend, ET ce qu il ne rend pas', () {
        expect(
          tr.systemBackup.whatComesBack.trim().length,
          greaterThan(150),
          reason:
              'promettre les photos serait faux : les copier doublerait la '
              'place prise sur le telephone, et le texte doit le dire',
        );
      });

      test('$langue : le texte DIT que nos serveurs ne sont pas concernes', () {
        expect(
          tr.systemBackup.notOurServers.trim().length,
          greaterThan(100),
          reason:
              'sans cette phrase, le randonneur qui decoche croira que '
              'NOUS recuperons son journal. Nous ne l avons jamais.',
        );
      });

      test('$langue : la case existe dans ses DEUX formulations', () {
        expect(
          tr.systemBackup.refuseGoogle,
          isNot(tr.systemBackup.refuseApple),
          reason:
              'une case qui parle de Google sur un iPhone decredibilise '
              'tout le reste',
        );
        expect(
          tr.systemBackup.explainGoogle,
          isNot(tr.systemBackup.explainApple),
        );
      });

      test('$langue : AUCUN cadratin (tache 599)', () {
        for (final texte in _textesDeLaCase(tr)) {
          expect(texte.contains('—'), isFalse, reason: 'cadratin : « $texte »');
          expect(
            texte.contains('–'),
            isFalse,
            reason: 'demi-cadratin : « $texte »',
          );
        }
      });
    }

    test(
      'le texte francais NOMME les familles, il ne dit pas « mes donnees »',
      () {
        // « Mes donnees » ne veut rien dire pour un randonneur. Ce test verifie la
        // langue de base, la seule dont le contenu puisse etre affirme mot pour
        // mot ici ; les quatre autres sont gardees par le test de non-repli.
        final explique = _langues['fr']!.systemBackup.explainGoogle
            .toLowerCase();
        for (final famille in [
          'profil',
          'taille',
          'poids',
          'randonnées passées',
          'progression',
          'journal',
          'photos',
          'médicale',
        ]) {
          expect(
            explique,
            contains(famille),
            reason:
                'la famille « $famille » doit etre nommee : Christophe a '
                'repondu par une regle GENERALE a une question sur le poids et '
                'la taille',
          );
        }
      },
    );

    test(
      'les quatre traductions sont REELLES, pas un repli sur le francais',
      () {
        final fr = _langues['fr']!;
        for (final entree in _langues.entries) {
          if (entree.key == 'fr') continue;
          expect(
            entree.value.systemBackup.cost,
            isNot(fr.systemBackup.cost),
            reason:
                '${entree.key} se rabat sur le francais : Slang le fait en '
                'silence quand une cle manque',
          );
          expect(
            entree.value.systemBackup.whatComesBack,
            isNot(fr.systemBackup.whatComesBack),
            reason: '${entree.key} se rabat sur le francais',
          );
        }
      },
    );

    test('plus AUCUN texte de la case ne parle de la SEULE fiche medicale', () {
      // La tache 612 formulait la case pour les seules donnees medicales. Un
      // texte qui survit a la regle qu il decrit est le defaut que les taches 612
      // et 615 ont trouve deux fois. La case parle maintenant de TOUT.
      final libelle = _langues['fr']!.systemBackup.refuseGoogle.toLowerCase();
      expect(
        libelle.contains('médicales'),
        isFalse,
        reason:
            'la case gouverne toutes les familles, pas la seule sante : '
            'son libelle doit le dire',
      );
    });
  });
}

/// LE CODE SEUL, SANS LES COMMENTAIRES.
///
/// Reprise du helper de la tache 612, et pour la meme raison mesuree : la
/// premiere version de son invariante accusait un fichier dont un COMMENTAIRE
/// racontait l histoire. Une garde qui force a effacer l histoire pour rester
/// verte est une mauvaise garde.
String _codeSeul(String source) {
  final sansBlocs = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return sansBlocs
      .split('\n')
      .where(
        (l) =>
            !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'),
      )
      .join('\n');
}
