// TACHE 615 — SUR IPHONE, LA FICHE MEDICALE MONTAIT DANS iCLOUD, ET LA CASE
// PRE-COCHEE DE CHRISTOPHE AURAIT AFFICHE UNE PROMESSE QUE LE SYSTEME NE TENAIT
// PAS.
//
// ---------------------------------------------------------------------------
// LE TROU, ET QUI L'A OUVERT
// ---------------------------------------------------------------------------
//
// Le lot 612 avait NOMME l'exigence iPhone sans consequence : la base etait
// volatile, donc rien de medical ne persistait, donc rien ne montait nulle part.
// Le lot 613 a donne a la fiche SON PROPRE FICHIER DURABLE sous `medical/`, et il
// a rendu cet ecart REEL — son auteur l'a nomme lui-meme comme le plus grave de
// ce qu'il laissait. Sur iPhone, `Library/Application Support/` est sauvegarde
// par defaut (documentation Apple, « File System Basics ») et rien dans
// `Info.plist` ne permet de l'en exclure.
//
// CE QUE CELA CONTREDIT. Decision de Christophe du 28/09 10:42, verbatim et en
// majuscules : « NON ON NE TROUVERAIT RIEN !!! Les donnees medicales RESTENT sur
// le tel !!! ». Et sa case pre-cochee du 10:49. UNE CASE QUI MENT EST PIRE QUE
// PAS DE CASE.
//
// ---------------------------------------------------------------------------
// CE QUE CE FICHIER PROUVE, ET DANS QUEL ORDRE D'IMPORTANCE
// ---------------------------------------------------------------------------
//
//  1. QUE L'EXCLUSION SURVIT A L'ECRITURE ATOMIQUE. C'est le piege principal du
//     lot. L'attribut appartient AU FICHIER, pas au chemin ; l'ecriture de la
//     fiche est atomique (`.tmp` puis renommage, choix du lot 613) ; le fichier
//     final est donc l'ancien `.tmp`, qui n'a jamais porte l'attribut. Une
//     exclusion posee UNE SEULE FOIS a la creation passerait tous les tests de
//     comportement du depot et ne se verrait que six mois plus tard, dans une
//     sauvegarde iCloud.
//
//  2. QUE LES DEUX BOUTS DU CANAL DISENT LA MEME CHOSE. Un canal mal nomme echoue
//     EN SILENCE. C'est la meme invariante que celle du lot 612 sur les XML
//     Android, appliquee au Swift — et elle verifie AUSSI que le fichier Swift est
//     COMPILE, parce qu'un fichier hors de la phase `Sources` ne dit rien du tout.
//
//  3. QUE LE CHEMIN INVERSE EXISTE. Si le randonneur DECOCHE la case, la copie
//     autorisee doit NE PAS porter l'exclusion, sinon decocher n'a aucun effet.
//
//  4. QUE RIEN NE PASSE SUR LE CANAL HORS IPHONE. Ce n'est pas de la proprete :
//     le lot 612 a mesure qu'un appel a un canal sans interlocuteur rendait trois
//     tests d'ecran rouges. Cette garde-la protege les 3348 tests verts du depot.
//
// ---------------------------------------------------------------------------
// COMMENT L'ORDRE EST PROUVE, ET PAS SEULEMENT SUPPOSE
// ---------------------------------------------------------------------------
//
// Le canal espion, a l'instant ou on lui demande d'exclure un chemin, LIT LE
// FICHIER qui s'y trouve et retient son contenu. Un test peut donc affirmer non
// seulement « l'exclusion a ete demandee sur ce chemin » mais « elle a ete
// demandee alors que ce chemin portait DEJA la nouvelle fiche » — c'est-a-dire
// APRES le renommage. Sans cette lecture, un appel pose avant le renommage
// passerait pour un appel pose apres.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/exclusion_sauvegarde_icloud.dart';
import 'package:moteur_gr/core/services/sauvegarde_systeme.dart';
import 'package:moteur_gr/features/safety/data/copie_sauvegardable_fiche_service.dart';
import 'package:moteur_gr/features/safety/data/fiche_medicale_fichier.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';

// ---------------------------------------------------------------------------
// LE CANAL ESPION
// ---------------------------------------------------------------------------

/// UN APPEL VU PAR LE NATIF, AVEC L'ETAT DU DISQUE A CET INSTANT.
class _Appel {
  _Appel({
    required this.methode,
    required this.chemin,
    required this.contenuAuMomentDeLAppel,
    required this.existaitAuMomentDeLAppel,
  });

  final String methode;
  final String chemin;

  /// Le contenu du fichier situe a [chemin] QUAND l'appel a ete recu, ou null si
  /// ce n'est pas un fichier lisible. C'est ce qui permet de prouver un ORDRE.
  final String? contenuAuMomentDeLAppel;

  final bool existaitAuMomentDeLAppel;

  @override
  String toString() => '$methode($chemin)';
}

/// Un faux natif qui NOTE tout et peut ECHOUER a la demande.
class _NatifEspion {
  final List<_Appel> appels = [];

  /// Quand il est non nul, le natif rend cette erreur au lieu d'un succes.
  ///
  /// [PlatformException] est CE QUE LE DART RECOIT quand le Swift repond un
  /// `FlutterError` : l'espion imite donc le natif tel qu'il se presente de ce
  /// cote-ci du canal, pas tel qu'il s'ecrit de l'autre.
  PlatformException? erreur;

  /// Quand il est vrai, le natif rend `false` : ni succes ni exception, le cas
  /// exact du « faux succes » qu'il ne faut pas confondre avec un succes.
  bool rendFaux = false;

  void brancher() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(ExclusionSauvegardeIcloud.nomDuCanal),
      (appel) async {
        final chemin =
            (appel.arguments as Map)[ExclusionSauvegardeIcloud.argumentChemin]
                as String;
        final fichier = File(chemin);
        String? contenu;
        var existait = false;
        try {
          existait = fichier.existsSync() || Directory(chemin).existsSync();
          if (fichier.existsSync()) contenu = fichier.readAsStringSync();
        } on FileSystemException {
          contenu = null;
        }
        appels.add(_Appel(
          methode: appel.method,
          chemin: chemin.replaceAll(r'\', '/'),
          contenuAuMomentDeLAppel: contenu,
          existaitAuMomentDeLAppel: existait,
        ));
        final e = erreur;
        if (e != null) throw e;
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

  void oublier() => appels.clear();

  List<_Appel> exclusionsDe(String chemin) => appels
      .where((a) =>
          a.methode == ExclusionSauvegardeIcloud.methodeExclure &&
          a.chemin == chemin.replaceAll(r'\', '/'))
      .toList();

  List<_Appel> inclusionsDe(String chemin) => appels
      .where((a) =>
          a.methode == ExclusionSauvegardeIcloud.methodeInclure &&
          a.chemin == chemin.replaceAll(r'\', '/'))
      .toList();
}

String _n(String chemin) => chemin.replaceAll(r'\', '/');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const laFiche = HealthInfo(
    bloodType: 'O-',
    allergies: 'Penicilline',
    treatments: 'Levothyrox 50mg/j',
  );
  const laFicheCorrigee = HealthInfo(
    bloodType: 'AB+',
    allergies: 'Arachides, penicilline',
    treatments: 'Ventoline',
  );

  // =========================================================================
  // 1. LES DEUX BOUTS DU CANAL DISENT LA MEME CHOSE, ET LE SWIFT EST COMPILE
  // =========================================================================
  group('615 — INVARIANTE : le canal natif existe, il est nomme pareil des deux '
      'cotes, et il est VRAIMENT compile', () {
    String lire(String chemin) {
      final f = File(chemin);
      expect(f.existsSync(), isTrue,
          reason: 'le fichier « $chemin » est declare par '
              'ExclusionSauvegardeIcloud mais il n existe pas sur le disque');
      return f.readAsStringSync();
    }

    test('le Swift porte EXACTEMENT le nom de canal declare en Dart', () {
      final swift = lire(ExclusionSauvegardeIcloud.fichierNatif);
      expect(swift, contains(ExclusionSauvegardeIcloud.nomDuCanal),
          reason: 'un canal dont les deux bouts ne portent pas le meme nom '
              'echoue EN SILENCE : le Dart recoit MissingPluginException, '
              'l application continue, et la fiche medicale monte dans iCloud '
              'sans que rien ne le dise. C est exactement le defaut que ce lot '
              'ferme — il ne doit pas revenir par un renommage.');
    });

    test('le Swift traite les DEUX methodes, et sous leurs noms Dart', () {
      final swift = lire(ExclusionSauvegardeIcloud.fichierNatif);
      for (final methode in const [
        ExclusionSauvegardeIcloud.methodeExclure,
        ExclusionSauvegardeIcloud.methodeInclure,
      ]) {
        expect(swift, contains('"$methode"'),
            reason: 'le natif ne sait pas repondre a « $methode ». Les DEUX '
                'sens existent : « ${ExclusionSauvegardeIcloud.methodeExclure} » '
                'protege la fiche, '
                '« ${ExclusionSauvegardeIcloud.methodeInclure} » rend '
                'sauvegardable la copie que le randonneur a acceptee en '
                'decochant la case.');
      }
      expect(swift, contains('"${ExclusionSauvegardeIcloud.argumentChemin}"'),
          reason: 'le natif lit un autre nom d argument que celui envoye : il ne '
              'recevrait jamais de chemin');
    });

    test('le Swift pose bien l ATTRIBUT d Apple, et pas autre chose', () {
      final swift = lire(ExclusionSauvegardeIcloud.fichierNatif);
      expect(swift, contains('isExcludedFromBackup'),
          reason: 'c est la seule facon d exclure de la sauvegarde iCloud : iOS '
              'n offre AUCUN equivalent declaratif de dataExtractionRules');
      expect(swift, contains('setResourceValues'));
      expect(swift, contains('fileExists'),
          reason: 'le natif ne doit rien CREER : poser l attribut sur un chemin '
              'absent ferait apparaitre un dossier « medical » vide sur le '
              'telephone d un randonneur qui n a jamais rempli de fiche, et le '
              'lot 612 a decide qu on ne laissait pas de trace de passage');
    });

    test('LE FICHIER SWIFT EST DANS LA PHASE « Sources » DU PROJET XCODE — sans '
        'ca il ne compile pas, ne s execute pas, et NE DIT RIEN', () {
      final pbxproj = lire(ExclusionSauvegardeIcloud.phaseSourcesXcode);
      final nom = ExclusionSauvegardeIcloud.fichierNatif.split('/').last;
      expect(pbxproj, contains('$nom in Sources'),
          reason: 'C EST LA VERIFICATION LA PLUS IMPORTANTE DE CE GROUPE. Un '
              'fichier Swift absent de la phase « Sources » n est pas compile : '
              'le canal serait muet, la fiche medicale monterait dans iCloud, et '
              'TOUS les tests Dart de ce fichier resteraient verts puisqu ils '
              'parlent a un canal espion. C est la raison pour laquelle le code '
              'natif vit dans AppDelegate.swift, deja compile, et pas dans un '
              'fichier neuf qu il faudrait declarer a la main dans le pbxproj.');
    });

    test('Info.plist ne PRETEND PAS declarer une exclusion — il n y a rien a y '
        'declarer', () {
      final plist = lire('ios/Runner/Info.plist');
      for (final mensonge in const [
        'ExcludedFromBackup',
        'dataExtractionRules',
        'fullBackupContent',
      ]) {
        expect(plist.contains(mensonge), isFalse,
            reason: 'Info.plist annonce « $mensonge », ce qui ferait croire a une '
                'exclusion declarative cote iPhone. Il n en existe AUCUNE : '
                'l exclusion se pose a l execution, et c est tout l objet de ce '
                'lot. Une declaration decorative ferait exactement le mal que la '
                'case qui mentait faisait.');
      }
    });

    test('l exigence du lot 612 est TENUE, et son texte dit le piege', () {
      // Le lot 612 avait ecrit cette exigence sans pouvoir la tenir. Elle reste
      // le CONTRAT, et son texte porte desormais ce que le lot 615 a mesure.
      const exigence = SauvegardeSysteme.exigenceIosExclusion;
      expect(exigence, contains('NSURLIsExcludedFromBackupKey'));
      expect(exigence, contains(SauvegardeSysteme.dossierExclu));
      expect(exigence.toLowerCase(), contains('remplacement'),
          reason: 'l exigence doit NOMMER le piege qu elle ferme : « a sa '
              'creation » ne suffisait pas, une ecriture atomique remplace le '
              'fichier et l attribut ne suit pas');
    });
  });

  // =========================================================================
  // 2. LE COEUR DU LOT — L'EXCLUSION SURVIT A L'ECRITURE ATOMIQUE
  // =========================================================================
  group('615 — L EXCLUSION EST REPOSEE A CHAQUE ECRITURE, et le piege de '
      'l ecriture atomique est ferme', () {
    late Directory racine;
    late _NatifEspion natif;
    late FicheMedicaleFichier fiche;

    setUp(() {
      racine = Directory.systemTemp.createTempSync('sw615_');
      natif = _NatifEspion()..brancher();
      fiche = FicheMedicaleFichier(
        dossierApplicatif: () async => racine,
        // LA CIBLE EST FORCEE : la suite tourne sur une machine de
        // developpement, ou `Platform.isIOS` est faux. Sans ce forcage ces tests
        // ne mesureraient rien du chemin iPhone.
        exclusionIcloud: ExclusionSauvegardeIcloud(cibleIos: true),
      );
    });

    tearDown(() {
      natif.debrancher();
      if (racine.existsSync()) racine.deleteSync(recursive: true);
    });

    String cheminFiche() => _n(
        '${racine.path}/${SauvegardeSysteme.dossierExclu}/'
        '${FicheMedicaleFichier.nomFichier}');
    String cheminTemporaire() =>
        '${cheminFiche()}${FicheMedicaleFichier.suffixeTemporaire}';
    String cheminDossier() =>
        _n('${racine.path}/${SauvegardeSysteme.dossierExclu}');

    test('PREMIERE ECRITURE : le dossier, le fichier temporaire ET le fichier '
        'final sont tous les trois exclus', () async {
      await fiche.ecrire(laFiche);

      expect(natif.exclusionsDe(cheminDossier()), isNotEmpty,
          reason: 'le dossier est exclu aussi. La documentation d Apple ne dit '
              'PAS que l attribut d un dossier s applique a son contenu : on ne '
              'construit donc pas sur cette seule pose, mais on ne s en prive '
              'pas non plus');
      expect(natif.exclusionsDe(cheminTemporaire()), isNotEmpty,
          reason: 'sans cette pose, la fiche existe en clair sur le disque, sans '
              'attribut, pendant tout le temps de l ecriture — une fenetre '
              'courte est une fenetre');
      expect(natif.exclusionsDe(cheminFiche()), isNotEmpty,
          reason: 'et surtout : le fichier que le randonneur garde');
    });

    test('LE TEST QUI DONNE SON NOM AU LOT — UNE SECONDE ECRITURE REPOSE '
        'L EXCLUSION SUR LE FICHIER FINAL', () async {
      await fiche.ecrire(laFiche);
      natif.oublier();

      // Le randonneur corrige sa fiche. C EST ICI que le defaut vivait : le
      // renommage remplace le fichier, donc l attribut pose a la premiere
      // ecriture ne concerne plus le fichier qui porte maintenant la donnee.
      await fiche.ecrire(laFicheCorrigee);

      expect(natif.exclusionsDe(cheminFiche()), isNotEmpty,
          reason: 'L EXCLUSION N A PAS ETE REPOSEE APRES LA SECONDE ECRITURE. '
              'L attribut appartient au FICHIER, pas au chemin : apres le '
              'renommage, « ${FicheMedicaleFichier.nomFichier} » est l ancien '
              'fichier temporaire, qui n a jamais porte l attribut. Ce defaut '
              'passe tous les tests de comportement du depot et ne se voit que '
              'dans une sauvegarde iCloud, des mois plus tard.');
    });

    test('ET ELLE EST POSEE APRES LE RENOMMAGE — preuve par le contenu du '
        'fichier a l instant de l appel', () async {
      await fiche.ecrire(laFiche);
      natif.oublier();
      await fiche.ecrire(laFicheCorrigee);

      final derniere = natif.exclusionsDe(cheminFiche()).last;
      expect(derniere.contenuAuMomentDeLAppel, isNotNull);
      expect(derniere.contenuAuMomentDeLAppel, contains('AB+'),
          reason: 'AU MOMENT DE L APPEL, le chemin de la fiche portait deja la '
              'NOUVELLE fiche : l exclusion a donc ete posee APRES le '
              'renommage, sur le fichier qui vit vraiment. Posee avant, elle '
              'aurait concerne un fichier que le renommage venait de remplacer — '
              'et ce test-la serait rouge, alors que le precedent serait vert.');
      expect(derniere.contenuAuMomentDeLAppel!.contains('O-'), isFalse);
    });

    test('LE FICHIER TEMPORAIRE EST EXCLU AVANT LE RENOMMAGE, donc il n existe '
        'aucune fenetre sans attribut', () async {
      await fiche.ecrire(laFiche);
      natif.oublier();
      await fiche.ecrire(laFicheCorrigee);

      final surLeTemporaire = natif.exclusionsDe(cheminTemporaire());
      expect(surLeTemporaire, isNotEmpty);
      expect(surLeTemporaire.last.contenuAuMomentDeLAppel, contains('AB+'),
          reason: 'le temporaire doit etre exclu QUAND IL PORTE DEJA la nouvelle '
              'fiche, c est-a-dire apres son ecriture et avant son renommage');

      // ET L ORDRE DES DEUX POSES : le temporaire AVANT le fichier final.
      final indexTemporaire = natif.appels.indexOf(surLeTemporaire.last);
      final indexFinal =
          natif.appels.indexOf(natif.exclusionsDe(cheminFiche()).last);
      expect(indexTemporaire, lessThan(indexFinal),
          reason: 'l ordre des gestes n est pas interchangeable : ecrire, '
              'exclure le temporaire, renommer, exclure le final');
    });

    test('DIX ECRITURES, DIX EXCLUSIONS DU FICHIER FINAL — la pose n est pas '
        'conditionnee a une premiere fois', () async {
      for (var i = 0; i < 10; i++) {
        await fiche.ecrire(HealthInfo(bloodType: 'O-', allergies: 'essai $i'));
      }
      expect(natif.exclusionsDe(cheminFiche()), hasLength(10),
          reason: 'une pose gardee derriere un « si le dossier n existe pas '
              'encore » laisserait la fiche sans attribut des la deuxieme '
              'ecriture. Le compte doit suivre les ecritures, un pour un.');
    });

    test('effacer la fiche ne demande AUCUNE exclusion — il n y a plus rien a '
        'exclure', () async {
      await fiche.ecrire(laFiche);
      natif.oublier();
      await fiche.ecrire(const HealthInfo()); // fiche vide = effacement
      expect(natif.appels, isEmpty,
          reason: 'poser un attribut sur un chemin qu on vient de supprimer '
              'rendrait une erreur, donc du bruit dans les journaux, pour rien');
      expect(File(cheminFiche()).existsSync(), isFalse);
    });

    test('LA FICHE EST ECRITE CORRECTEMENT, et l exclusion n a rien casse',
        () async {
      await fiche.ecrire(laFiche);
      await fiche.ecrire(laFicheCorrigee);
      final relue = await fiche.lire();
      expect(relue, laFicheCorrigee,
          reason: 'le lot ajoute une protection, il ne touche pas a ce que la '
              'fiche contient');
      expect(File(cheminTemporaire()).existsSync(), isFalse,
          reason: 'le temporaire ne doit pas survivre au renommage');
    });
  });

  // =========================================================================
  // 3. LE CHEMIN INVERSE — LA COPIE AUTORISEE NE PORTE PAS L'EXCLUSION
  // =========================================================================
  group('615 — DECOCHER LA CASE : la copie autorisee se voit RETIRER '
      'l exclusion', () {
    late Directory racine;
    late _NatifEspion natif;
    late HealthInfoRepository depot;
    late CopieSauvegardableFicheService copie;

    setUp(() {
      racine = Directory.systemTemp.createTempSync('sw615c_');
      natif = _NatifEspion()..brancher();
      depot = HealthInfoRepository(
        fichier: FicheMedicaleFichier(
          dossierApplicatif: () async => racine,
          exclusionIcloud: ExclusionSauvegardeIcloud(cibleIos: true),
        ),
      );
      copie = CopieSauvegardableFicheService(
        healthRepository: depot,
        baseDirProvider: () async => racine,
        exclusionIcloud: ExclusionSauvegardeIcloud(cibleIos: true),
      );
    });

    tearDown(() {
      natif.debrancher();
      if (racine.existsSync()) racine.deleteSync(recursive: true);
    });

    String cheminCopie() => _n('${racine.path}/'
        '${SauvegardeSysteme.dossierSauvegardable}/'
        '${SauvegardeSysteme.fichierCopieFiche}');

    test('la copie recoit « inclure », et JAMAIS « exclure »', () async {
      await depot.save(laFiche);
      natif.oublier();

      expect(await copie.appliquer(refuse: false), isTrue);

      expect(natif.inclusionsDe(cheminCopie()), isNotEmpty,
          reason: 'une copie qui porterait l exclusion ne serait jamais '
              'sauvegardee : decocher la case n aurait AUCUN effet sur iPhone, '
              'et le randonneur retrouverait un telephone vide en croyant avoir '
              'choisi la commodite. C est le faux succes symetrique de la fuite.');
      expect(natif.exclusionsDe(cheminCopie()), isEmpty,
          reason: 'ce serait contredire la decision meme du randonneur');
    });

    test('LA FICHE, ELLE, NE RECOIT JAMAIS « inclure » — les deux fichiers ne '
        'se confondent pas', () async {
      await depot.save(laFiche);
      await copie.appliquer(refuse: false);

      final cheminFiche = _n('${racine.path}/'
          '${SauvegardeSysteme.dossierExclu}/'
          '${FicheMedicaleFichier.nomFichier}');
      expect(natif.inclusionsDe(cheminFiche), isEmpty,
          reason: 'la fiche ne monte JAMAIS, case cochee ou non : decision de '
              'Christophe du 28/09 10:42. Seule la COPIE est gouvernee par la '
              'case.');
      expect(natif.exclusionsDe(cheminFiche), isNotEmpty);
    });

    test('re-cocher le refus supprime la copie et ne demande rien au natif',
        () async {
      await depot.save(laFiche);
      await copie.appliquer(refuse: false);
      natif.oublier();

      expect(await copie.appliquer(refuse: true), isFalse);
      expect(natif.appels, isEmpty,
          reason: 'un fichier supprime n a pas d attribut a regler');
      expect(File(cheminCopie()).existsSync(), isFalse);
    });

    test('la copie est ecrite MEME si le natif refuse l inclusion — une copie '
        'manquante serait pire', () async {
      await depot.save(laFiche);
      natif.erreur = PlatformException(code: 'attribut_refuse', message: 'non');

      expect(await copie.appliquer(refuse: false), isTrue,
          reason: 'le randonneur a decoche : la copie doit exister. Un attribut '
              'non retire est au pire une copie non sauvegardee, ce que ce lot '
              'journalise ; une copie absente serait une deception silencieuse.');
      expect(File(cheminCopie()).existsSync(), isTrue);
    });
  });

  // =========================================================================
  // 4. LE TELEPHONE DEJA MIS A JOUR — CELUI QUE « A CHAQUE ECRITURE » RATE
  // =========================================================================
  group('615 — garantirExclusion : le randonneur qui avait DEJA rempli sa fiche '
      'avec la version precedente', () {
    late Directory racine;
    late _NatifEspion natif;
    late FicheMedicaleFichier fiche;

    setUp(() {
      racine = Directory.systemTemp.createTempSync('sw615g_');
      natif = _NatifEspion()..brancher();
      fiche = FicheMedicaleFichier(
        dossierApplicatif: () async => racine,
        exclusionIcloud: ExclusionSauvegardeIcloud(cibleIos: true),
      );
    });

    tearDown(() {
      natif.debrancher();
      if (racine.existsSync()) racine.deleteSync(recursive: true);
    });

    Directory dossier() =>
        Directory('${racine.path}/${SauvegardeSysteme.dossierExclu}');

    /// Pose une fiche SANS passer par [FicheMedicaleFichier.ecrire] : c'est
    /// exactement l'etat du telephone d'un randonneur qui a rempli sa fiche avec
    /// le binaire de la tache 613, ou aucune exclusion n'existait.
    File poserUneFicheHeriteeDuLot613() {
      final d = dossier()..createSync(recursive: true);
      final f = File('${d.path}/${FicheMedicaleFichier.nomFichier}');
      f.writeAsStringSync(jsonEncode(laFiche.toJson()));
      return f;
    }

    test('UNE FICHE HERITEE EST RATTRAPEE AU DEMARRAGE — sans elle, celui qui ne '
        'modifie plus jamais sa fiche n aurait jamais ete protege', () async {
      final f = poserUneFicheHeriteeDuLot613();
      natif.oublier();

      await fiche.garantirExclusion();

      expect(natif.exclusionsDe(_n(f.path)), isNotEmpty,
          reason: 'on remplit sa fiche medicale une fois. Si seule l ecriture '
              'posait l exclusion, la mise a jour de l application ne '
              'protegerait personne de ceux qui l avaient deja remplie — et leur '
              'fiche est DEJA dans iCloud.');
      expect(natif.exclusionsDe(_n(dossier().path)), isNotEmpty);
    });

    test('UN FICHIER TEMPORAIRE ORPHELIN EST RATTRAPE AUSSI — une ecriture '
        'interrompue laisse la donnee medicale dedans', () async {
      final d = dossier()..createSync(recursive: true);
      final orphelin = File('${d.path}/${FicheMedicaleFichier.nomFichier}'
          '${FicheMedicaleFichier.suffixeTemporaire}');
      orphelin.writeAsStringSync(jsonEncode(laFiche.toJson()));
      natif.oublier();

      await fiche.garantirExclusion();

      expect(natif.exclusionsDe(_n(orphelin.path)), isNotEmpty,
          reason: 'batterie vide au milieu d une ecriture : le .tmp contient la '
              'fiche entiere et il attend le prochain demarrage');
    });

    test('ELLE NE CREE RIEN sur le telephone de qui n a jamais rempli de fiche',
        () async {
      await fiche.garantirExclusion();

      expect(natif.appels, isEmpty,
          reason: 'aucun appel : il n y a rien a exclure');
      expect(dossier().existsSync(), isFalse,
          reason: 'un dossier « medical » vide n est pas une fuite, mais c est '
              'une trace de passage — le lot 612 a decide qu on n en laissait '
              'pas');
    });

    test('ELLE EST IDEMPOTENTE, et elle ne leve jamais meme si le natif casse',
        () async {
      poserUneFicheHeriteeDuLot613();
      natif.erreur = PlatformException(code: 'attribut_refuse', message: 'non');

      await expectLater(fiche.garantirExclusion(), completes,
          reason: 'elle est ATTENDUE par l amorce de l application : un attribut '
              'de sauvegarde ne doit pas empecher un randonneur de demarrer');
      await fiche.garantirExclusion();
      await fiche.garantirExclusion();
    });
  });

  // =========================================================================
  // 5. HORS IPHONE, RIEN NE PASSE — LA GARDE QUI PROTEGE TOUTE LA SUITE
  // =========================================================================
  group('615 — sur Android et en test, le canal natif n est JAMAIS sollicite',
      () {
    late Directory racine;
    late _NatifEspion natif;

    setUp(() {
      racine = Directory.systemTemp.createTempSync('sw615a_');
      natif = _NatifEspion()..brancher();
    });

    tearDown(() {
      natif.debrancher();
      if (racine.existsSync()) racine.deleteSync(recursive: true);
    });

    test('cible non-iPhone : le resultat est « sans objet », pas « echec »',
        () async {
      final service = ExclusionSauvegardeIcloud(cibleIos: false);
      expect(await service.exclure('/peu/importe'),
          ResultatExclusionIcloud.sansObjet);
      expect(await service.inclure('/peu/importe'),
          ResultatExclusionIcloud.sansObjet);
      expect(natif.appels, isEmpty);
    });

    test('POURQUOI « sans objet » ET PAS « echec » : sinon chaque Android '
        'journaliserait une erreur, et un vrai echec iPhone se noierait dans ce '
        'bruit', () {
      expect(ResultatExclusionIcloud.values, contains(ResultatExclusionIcloud.sansObjet));
      expect(ResultatExclusionIcloud.sansObjet,
          isNot(ResultatExclusionIcloud.echec));
      expect(ResultatExclusionIcloud.sansObjet,
          isNot(ResultatExclusionIcloud.appliquee),
          reason: 'et surtout pas « appliquee » : sur Android rien n est pose a '
              'l execution, et le dire serait un faux succes');
    });

    test('LA GARDE REELLE : par DEFAUT, une ecriture de fiche n emet AUCUN appel '
        'de plateforme', () async {
      // C EST CE TEST QUI PROTEGE LES 3348 TESTS VERTS DU DEPOT. Le lot 612 a
      // mesure qu un appel a un canal de plateforme sans interlocuteur rendait
      // trois tests d ecran ROUGES : dans le temps feint d un test de widgets, il
      // ne rend jamais la main. Ici aucune cible n est forcee : le service prend
      // `Platform.isIOS`, faux sur la machine de developpement.
      final fiche = FicheMedicaleFichier(dossierApplicatif: () async => racine);
      await fiche.ecrire(laFiche);
      await fiche.garantirExclusion();

      expect(natif.appels, isEmpty,
          reason: 'un appel emis ici voudrait dire que TOUS les tests d ecran '
              'qui enregistrent une fiche parlent a un canal de plateforme, et '
              'c est precisement ce que le lot 612 a paye en trois tests rouges');
      expect((await fiche.lire()), laFiche,
          reason: 'et la fiche est ecrite quand meme, evidemment');
    });
  });

  // =========================================================================
  // 6. UN NATIF ABSENT OU CASSE NE FAIT JAMAIS PERDRE LA FICHE
  // =========================================================================
  group('615 — aucun faux succes, et aucune fiche perdue quand le natif refuse',
      () {
    late Directory racine;

    setUp(() => racine = Directory.systemTemp.createTempSync('sw615e_'));
    tearDown(() {
      if (racine.existsSync()) racine.deleteSync(recursive: true);
    });

    test('le natif rend « false » : c est un ECHEC, jamais « appliquee »',
        () async {
      final natif = _NatifEspion()
        ..brancher()
        ..rendFaux = true;
      addTearDown(natif.debrancher);

      final service = ExclusionSauvegardeIcloud(cibleIos: true);
      expect(await service.exclure(racine.path), ResultatExclusionIcloud.echec,
          reason: 'une promesse de sante ne se declare pas tenue sur la foi d un '
              'appel qui a repondu non');
    });

    test('le natif leve : ECHEC journalise, pas d exception qui remonte',
        () async {
      final natif = _NatifEspion()
        ..brancher()
        ..erreur = PlatformException(code: 'attribut_refuse', message: 'non');
      addTearDown(natif.debrancher);

      final service = ExclusionSauvegardeIcloud(cibleIos: true);
      expect(await service.exclure(racine.path), ResultatExclusionIcloud.echec);
    });

    test('AUCUN CANAL BRANCHE (MissingPluginException) : ECHEC, et la fiche est '
        'ecrite quand meme', () async {
      // Aucun `_NatifEspion` : le canal n a pas d interlocuteur, exactement comme
      // sur un iPhone ou le Swift n aurait pas ete compile.
      final fiche = FicheMedicaleFichier(
        dossierApplicatif: () async => racine,
        exclusionIcloud: ExclusionSauvegardeIcloud(cibleIos: true),
      );

      await expectLater(fiche.ecrire(laFiche), completes,
          reason: 'l enregistrement de la fiche ne doit PAS dependre du canal : '
              'un enregistrement reussi qui ne se dit pas est le pire des deux '
              'defauts (lecon du 28/09, lot 612)');
      expect(await fiche.lire(), laFiche);
    });

    test('un delai maximal est declare — un canal qui ne repond pas ne doit pas '
        'bloquer le demarrage', () {
      expect(ExclusionSauvegardeIcloud.delaiMax.inSeconds, greaterThan(0));
      expect(ExclusionSauvegardeIcloud.delaiMax.inSeconds, lessThan(30),
          reason: 'garantirExclusion est ATTENDUE par l amorce : un delai long '
              'serait un ecran de chargement bloque');
    });
  });

  // =========================================================================
  // 7. UN SEUL PORTEUR DURABLE — LA VERIFICATION DEMANDEE AVANT DE CODER
  // =========================================================================
  group('615 — INVARIANTE : la fiche medicale n a QU UN SEUL porteur durable, et '
      'c est son fichier', () {
    // POURQUOI CE GROUPE EXISTE. Tout ce lot repose sur une premisse : le fichier
    // du lot 613 est le SEUL endroit durable ou la donnee medicale atterrit.
    // Exclure ce fichier d iCloud ne protegerait rien s il en existait un second
    // — et sur iPhone, les PREFERENCES (`UserDefaults`) comme le fichier de la
    // BASE sont emportes par la sauvegarde. La premisse est donc verifiee ici, et
    // verrouillee, plutot que supposee.

    /// Le code seul, sans les commentaires — meme precaution que le lot 612 : les
    /// commentaires de ce depot sont sa memoire, une garde ne doit pas forcer a
    /// effacer l histoire pour rester verte.
    String codeSeul(String source) {
      var s = source.replaceAll('://', '\u0000URL\u0000');
      s = s.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ');
      s = s
          .split('\n')
          .map((ligne) {
            final i = ligne.indexOf('//');
            return i == -1 ? ligne : ligne.substring(0, i);
          })
          .join('\n');
      return s.replaceAll('\u0000URL\u0000', '://');
    }

    List<File> sourcesDeProduction() => Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('AUCUN code de production n utilise la table de sante — la base est '
        'desormais SAUVEGARDEE, une seule ligne y partirait chez Google ou Apple',
        () {
      // Les seules apparitions legitimes : la definition du DAO lui-meme, son
      // enregistrement dans la base, et le code genere par Drift.
      const tolerees = [
        'lib/core/data/daos/health_info_dao.dart',
        'lib/core/data/database.dart',
      ];
      final coupables = <String>[];
      for (final f in sourcesDeProduction()) {
        final chemin = _n(f.path);
        if (chemin.endsWith('.g.dart') || chemin.endsWith('.freezed.dart')) {
          continue;
        }
        if (tolerees.any(chemin.endsWith)) continue;
        if (codeSeul(f.readAsStringSync()).contains('HealthInfoDao')) {
          coupables.add(chemin);
        }
      }
      expect(coupables, isEmpty,
          reason: 'ces fichiers rebranchent la fiche medicale sur la base :\n  '
              '${coupables.join("\n  ")}\n'
              'Le lot 613 l en a sortie POUR QUE la base redevienne '
              'sauvegardable. Y remettre une ligne de sante la ferait monter dans '
              'le nuage avec la progression, et l exclusion iCloud de ce lot ne '
              'la protegerait pas : elle ne porte que sur « '
              '${SauvegardeSysteme.dossierExclu}/ ».');
    });

    test('AUCUN champ de la fiche n atteint les preferences ni le keystore — '
        'sur iPhone les preferences aussi montent dans iCloud', () {
      const champsDeLaFiche = [
        'bloodType',
        'allergies',
        'treatments',
        'doctorContact',
        'insuranceNumber',
      ];
      const stockagesDurables = [
        'prefs.set',
        'SharedPreferences',
        'FlutterSecureStorage',
        'secureStorage.write',
      ];
      final coupables = <String>[];
      for (final f in sourcesDeProduction()) {
        final chemin = _n(f.path);
        if (chemin.endsWith('.g.dart') || chemin.endsWith('.freezed.dart')) {
          continue;
        }
        final code = codeSeul(f.readAsStringSync());
        if (!champsDeLaFiche.any(code.contains)) continue;
        final sinks = stockagesDurables.where(code.contains).toList();
        if (sinks.isNotEmpty) coupables.add('$chemin : ${sinks.join(", ")}');
      }
      expect(coupables, isEmpty,
          reason: 'ces fichiers touchent un champ de la fiche ET un stockage '
              'durable autre que son fichier :\n  ${coupables.join("\n  ")}\n'
              'Les preferences (`UserDefaults` sur iPhone) sont emportees par la '
              'sauvegarde iCloud, et rien ne permet d en exclure une cle. Le seul '
              'porteur durable autorise est FicheMedicaleFichier, plus la copie '
              'que le randonneur accepte explicitement en decochant la case.');
    });

    test('LE WIDGET DE VERROUILLAGE N ECRIT RIEN DE DURABLE — le paquet iOS reste '
        'en memoire', () {
      // MESURE DE LA TACHE 615. Le commentaire de `_updateIosWidget` annoncait
      // « via UserDefaults », ce qui aurait designe un SECOND porteur durable — et
      // `UserDefaults` monte dans iCloud. Verification faite : rien n est ecrit,
      // le paquet reste dans un champ en memoire. Le commentaire a ete corrige ;
      // cette garde empeche que l ecriture apparaisse sans qu on y repense.
      final code = codeSeul(
        File('lib/features/safety/data/lockscreen_widget_service.dart')
            .readAsStringSync(),
      );
      for (final sink in const [
        'SharedPreferences',
        'prefs.set',
        'writeAsString',
        'UserDefaults',
      ]) {
        expect(code.contains(sink), isFalse,
            reason: 'le widget de verrouillage porte groupe sanguin, allergies et '
                'traitements. Les ecrire dans « $sink » en ferait un second '
                'porteur durable, hors de portee de l exclusion de ce lot — et '
                'donc hors de la decision de Christophe du 28/09 10:42.');
      }
    });

    test('LE WIDGET iOS NE LIT AUCUN CHAMP DE SANTE — il ne lit que la '
        'progression', () {
      final swift = File('ios/TrekWidget/TrekWidget.swift');
      expect(swift.existsSync(), isTrue);
      final source = swift.readAsStringSync().toLowerCase();
      for (final champ in const [
        'bloodtype',
        'allerg',
        'treatment',
        'health_info',
        'healthinfo',
      ]) {
        expect(source.contains(champ), isFalse,
            reason: 'le widget iOS lit « $champ » depuis le conteneur partage du '
                'groupe d applications. Ce conteneur est emporte par la '
                'sauvegarde iCloud et l exclusion de ce lot ne le couvre PAS : ce '
                'serait un second porteur durable de donnee medicale, invisible '
                'depuis le Dart.');
      }
    });

    test('la COPIE autorisee est le seul AUTRE fichier, et le randonneur l a '
        'demandee', () {
      // Il y a donc bien DEUX fichiers possibles, et ce n est pas une
      // contradiction : le second n existe QUE si le randonneur a decoche la
      // case, il vit dans l emplacement sauvegardable, et il se voit RETIRER
      // l exclusion (groupe 3). La difference entre les deux est un CHOIX
      // explicite, pas un oubli.
      expect(SauvegardeSysteme.dossierSauvegardable,
          isNot(SauvegardeSysteme.dossierExclu));
      expect(
          SauvegardeSysteme.exclusions
              .any((e) => e.chemin.contains(SauvegardeSysteme.dossierSauvegardable)),
          isFalse);
    });
  });
}
