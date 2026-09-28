/// L'EXCLUSION DE LA SAUVEGARDE iCLOUD, POSEE A L'EXECUTION (tache 615, GO-73).
///
/// ---------------------------------------------------------------------------
/// LE TROU QUE CE FICHIER FERME, ET IL A ETE OUVERT PAR LA TACHE 613
/// ---------------------------------------------------------------------------
///
/// La tache 612 a ecrit dans [SauvegardeSysteme] une exigence iPhone SANS
/// CONSEQUENCE : la base etait alors volatile, donc rien de medical ne
/// persistait, donc rien ne montait nulle part. La tache 613 a donne a la fiche
/// medicale SON PROPRE FICHIER DURABLE (`FicheMedicaleFichier`, sous
/// `medical/`), et son auteur a nomme lui-meme ce que cela ouvrait comme le plus
/// grave de ce qu'il laissait.
///
/// LE FAIT MESURE, ET IL EST DOCUMENTE PAR APPLE. La documentation d'Apple (File
/// System Basics, « File System Programming Guide ») dit, mot pour mot :
/// « Remember that files in `Documents/` and `Application Support/` are backed up
/// by default. You can exclude files from the backup by calling
/// `-[NSURL setResourceValue:forKey:error:]` using the `NSURLIsExcludedFromBackupKey`
/// key. » Or `getApplicationSupportDirectory()` rend precisement
/// `Library/Application Support/` sur iPhone : la fiche medicale de la tache 613
/// MONTE DANS iCLOUD aujourd'hui.
///
/// CE QUE CELA CONTREDIT. Decision de Christophe du 28/09 10:42, verbatim et en
/// majuscules : « NON ON NE TROUVERAIT RIEN !!! Les donnees medicales RESTENT sur
/// le tel !!! ». Et sa case pre-cochee du 10:49. Cote Android le montage
/// declaratif tient ([SauvegardeSysteme.exclusions] + les deux XML) ; cote
/// iPhone la case afficherait une promesse que le systeme ne respecte pas. UNE
/// CASE QUI MENT EST PIRE QUE PAS DE CASE.
///
/// ---------------------------------------------------------------------------
/// POURQUOI CE N'EST PAS UN FICHIER DE CONFIGURATION MAIS UN CANAL NATIF
/// ---------------------------------------------------------------------------
///
/// iOS n'offre AUCUN equivalent declaratif d'`android:dataExtractionRules` :
/// rien dans `Info.plist` n'exclut un dossier de la sauvegarde. L'exclusion est
/// un ATTRIBUT DU FICHIER, pose a l'execution, fichier par fichier. Il faut donc
/// descendre dans le natif — et c'est le premier canal de methode de ce depot.
///
/// ---------------------------------------------------------------------------
/// LE PIEGE PRINCIPAL : L'ECRITURE ATOMIQUE EFFACE L'EXCLUSION
/// ---------------------------------------------------------------------------
///
/// L'attribut appartient AU FICHIER, pas au chemin. `FicheMedicaleFichier.ecrire`
/// est ATOMIQUE (tache 613) : elle ecrit un `.tmp` puis le RENOMME par-dessus la
/// fiche. Apres ce renommage, le fichier situe a `medical/fiche.json` n'est plus
/// celui qui portait l'attribut — c'est l'ancien `.tmp`, qui ne l'a jamais porte.
/// UNE EXCLUSION POSEE UNE SEULE FOIS, A LA CREATION, EST DONC PERDUE A LA
/// PREMIERE MODIFICATION DE LA FICHE. Ce defaut passe tous les tests de
/// comportement et ne se voit que six mois plus tard, dans une sauvegarde iCloud.
///
/// D'OU LA REGLE POSEE ICI : l'exclusion est REPOSEE a chaque creation et a
/// chaque remplacement, sur le `.tmp` AVANT le renommage (pour qu'il n'existe
/// aucune fenetre ou la donnee soit sur le disque sans attribut) ET sur le
/// fichier final APRES le renommage (pour ne pas dependre du fait que l'attribut
/// suive le fichier a travers un `rename`). Les deux poses couvrent chacune
/// l'hypothese de l'autre.
///
/// LE DOSSIER EST EXCLU AUSSI, ET CE N'EST PAS UNE REDONDANCE PARESSEUSE. La
/// page d'Apple citee plus haut ne dit PAS que l'attribut d'un dossier s'applique
/// a son contenu : s'en remettre a cette seule pose serait construire sur un fait
/// non verifie. On pose donc les deux, et c'est le fichier qui fait foi.
///
/// ---------------------------------------------------------------------------
/// LE CHEMIN INVERSE EXISTE AUSSI, ET IL COMPTE AUTANT
/// ---------------------------------------------------------------------------
///
/// Si le randonneur DECOCHE la case — il accepte la sauvegarde —,
/// `CopieSauvegardableFicheService` ecrit une copie dans un emplacement INCLUS.
/// Cette copie doit au contraire NE PAS porter l'exclusion : [inclure] la lui
/// retire explicitement. Sans cela, une copie excluse serait un FAUX SUCCES —
/// decocher la case n'aurait aucun effet et le randonneur retrouverait un
/// telephone vide en croyant avoir choisi la commodite.
///
/// ---------------------------------------------------------------------------
/// HORS IPHONE, RIEN NE PASSE SUR LE CANAL, ET C'EST UNE MESURE
/// ---------------------------------------------------------------------------
///
/// Sur Android l'exclusion est DECLARATIVE (les deux XML) : ce canal n'a rien a
/// y faire. Mais la raison de la garde [_cibleIos] est plus dure que la
/// proprete : la tache 612 a mesure qu'un appel a un canal de plateforme SANS
/// INTERLOCUTEUR rendait trois tests d'ecran rouges, parce qu'il ne rend jamais
/// la main dans le temps feint d'un test de widgets. Dans `flutter test`,
/// `Platform.isIOS` est faux (la suite tourne sur la machine de developpement) :
/// aucun appel n'est emis, et les 3348 tests verts de la tache 613 le restent.
/// Les tests de la tache 615 forcent la cible et branchent un canal espion.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// CE QUI S'EST REELLEMENT PASSE, SANS FAUX SUCCES NI FAUX ECHEC.
///
/// Un simple booleen melangerait « je n'avais rien a faire » et « j'ai rate » :
/// l'appelant journaliserait un echec sur chaque Android, et un vrai echec
/// iPhone se noierait dans ce bruit.
enum ResultatExclusionIcloud {
  /// L'attribut a ete pose (ou retire) par le systeme, sur ce chemin.
  appliquee,

  /// Sans objet : ce n'est pas un iPhone. Sur Android l'exclusion est declaree
  /// dans les deux XML de [SauvegardeSysteme], pas posee a l'execution.
  sansObjet,

  /// Le natif a refuse, le chemin n'existe pas, ou le canal est absent. JAMAIS
  /// confondu avec [appliquee] : une promesse de sante ne se declare pas tenue
  /// sur la foi d'un appel qu'on n'a pas vu revenir.
  echec,
}

/// POSE ET RETIRE `NSURLIsExcludedFromBackupKey` SUR UN CHEMIN DU DISQUE.
///
/// Voir l'en-tete du fichier pour le raisonnement entier. Cette classe ne sait
/// rien de la fiche medicale : elle prend un CHEMIN. C'est volontaire — ainsi
/// l'invariante de la tache 612 (« aucun fichier ne touche a la fois la fiche
/// medicale et le reseau ») garde un sens, et le meme canal servira le jour ou un
/// autre stockage devra etre exclu.
class ExclusionSauvegardeIcloud {
  ExclusionSauvegardeIcloud({
    MethodChannel? canal,
    bool? cibleIos,
  })  : _canal = canal ?? const MethodChannel(nomDuCanal),
        _cibleIos = cibleIos ?? Platform.isIOS;

  final MethodChannel _canal;

  /// Vrai quand la plateforme est un iPhone. Injectable : les tests forcent la
  /// cible pour exercer le chemin iOS depuis une machine de developpement.
  final bool _cibleIos;

  /// NOM DU CANAL — LA MEME CHAINE EN DART ET EN SWIFT.
  ///
  /// Un canal dont les deux bouts ne portent pas le meme nom echoue EN SILENCE :
  /// le Dart recoit `MissingPluginException`, l'application continue, et la fiche
  /// medicale monte dans iCloud sans que rien ne le dise. L'invariante de la
  /// tache 615 lit [fichierNatif] et exige qu'il contienne cette chaine — comme
  /// celle de la tache 612 compare les XML Android a la declaration Dart.
  static const String nomDuCanal = 'stepways/exclusion_sauvegarde_icloud';

  /// Methode native qui POSE l'exclusion.
  static const String methodeExclure = 'exclure';

  /// Methode native qui RETIRE l'exclusion (le chemin inverse, pour la copie
  /// autorisee).
  static const String methodeInclure = 'inclure';

  /// Nom de l'argument porte par les deux methodes.
  static const String argumentChemin = 'chemin';

  /// LE FICHIER SWIFT QUI TIENT L'AUTRE BOUT DU CANAL.
  ///
  /// C'est `AppDelegate.swift` et PAS un fichier dedie, pour une raison qui n'est
  /// pas un gout : un nouveau fichier Swift doit etre ajoute a la main dans
  /// quatre endroits de `Runner.xcodeproj/project.pbxproj`, et cela ne se verifie
  /// qu'en compilant sur un Mac. Un fichier absent de la phase `Sources` ne
  /// compile pas, ne s'execute pas, et NE DIT RIEN : le canal serait muet et la
  /// fiche monterait dans iCloud pendant que les tests Dart resteraient verts.
  /// `AppDelegate.swift` est deja dans la phase `Sources` — l'invariante de la
  /// tache 615 le verifie dans le pbxproj, pour que ce raisonnement reste vrai.
  static const String fichierNatif = 'ios/Runner/AppDelegate.swift';

  /// Reference Xcode qui prouve que [fichierNatif] est COMPILE.
  static const String phaseSourcesXcode = 'ios/Runner.xcodeproj/project.pbxproj';

  /// DELAI MAXIMAL D'UN ALLER-RETOUR NATIF.
  ///
  /// Poser un attribut etendu sur un fichier de quelques centaines d'octets est
  /// instantane. Ce delai n'est donc pas un reglage de performance : c'est le
  /// refus qu'un canal qui ne repond pas puisse BLOQUER le demarrage de
  /// l'application, puisque [garantirExclusion] est attendu par l'amorce.
  static const Duration delaiMax = Duration(seconds: 5);

  /// Pose l'exclusion de sauvegarde sur [chemin] (fichier OU dossier).
  Future<ResultatExclusionIcloud> exclure(String chemin) =>
      _appeler(methodeExclure, chemin);

  /// RETIRE l'exclusion de [chemin] — le chemin inverse, pour la copie que le
  /// randonneur a explicitement acceptee de voir sauvegardee.
  Future<ResultatExclusionIcloud> inclure(String chemin) =>
      _appeler(methodeInclure, chemin);

  /// L'APPEL NE LEVE JAMAIS, ET CE N'EST PAS UN CATCH PARESSEUX.
  ///
  /// Il est appele DANS le chemin d'ecriture de la fiche medicale et DANS
  /// l'amorce de l'application. Une exception ici ferait perdre au randonneur
  /// l'enregistrement de sa fiche — ou empecherait l'application de demarrer —
  /// pour un attribut de sauvegarde. L'echec est journalise et RENDU
  /// ([ResultatExclusionIcloud.echec]), jamais avale en se faisant passer pour un
  /// succes.
  Future<ResultatExclusionIcloud> _appeler(String methode, String chemin) async {
    if (!_cibleIos) return ResultatExclusionIcloud.sansObjet;
    try {
      final pose = await _canal
          .invokeMethod<bool>(methode, <String, dynamic>{argumentChemin: chemin})
          .timeout(delaiMax);
      if (pose == true) return ResultatExclusionIcloud.appliquee;
      _log.e('[ExclusionIcloud] $methode refuse par le natif sur « $chemin »');
      return ResultatExclusionIcloud.echec;
    } catch (e) {
      _log.e('[ExclusionIcloud] $methode impossible sur « $chemin » ($e)');
      return ResultatExclusionIcloud.echec;
    }
  }
}
