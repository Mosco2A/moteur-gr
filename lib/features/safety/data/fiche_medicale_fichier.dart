/// LA FICHE MEDICALE A DESORMAIS SON PROPRE FICHIER (tache 613, GO-72).
///
/// ---------------------------------------------------------------------------
/// POURQUOI ELLE SORT DE LA BASE, ET CE N'EST PAS UN GOUT D'ARCHITECTE
/// ---------------------------------------------------------------------------
///
/// La tache 612 avait exclu de la sauvegarde du telephone LE DOMAINE `database`
/// TOUT ENTIER, et elle avait nomme son cout : « le jour ou la base devient
/// durable, la progression du trek ne sera pas sauvegardee non plus tant que la
/// fiche medicale n'aura pas son propre stockage ». Ce jour est arrive — la base
/// est durable depuis la tache 613.
///
/// Or le modele economique (paragraphe 6) promet qu'un trek realise garde A VIE
/// sa trace et son carnet. Laisser la base entiere hors sauvegarde ferait perdre
/// la progression et le journal au changement de telephone : la promesse serait
/// fausse. Et un fichier de base ne s'exclut pas table par table — ou il monte
/// chez Google, ou il ne monte pas.
///
/// LES DEUX EXIGENCES NE SE CONCILIENT QU'EN SEPARANT LES FICHIERS. La fiche
/// medicale vit dans [SauvegardeSysteme.dossierExclu], un dossier DECLARE exclu ;
/// la base, qui ne contient plus rien de medical, redevient sauvegardable. Chaque
/// promesse porte sur son propre fichier.
///
/// ---------------------------------------------------------------------------
/// CE FICHIER NE PARLE PAS DE NOS SERVEURS
/// ---------------------------------------------------------------------------
///
/// La fiche n'y va JAMAIS, dans aucun cas — decision de Christophe du 28/09 10:42
/// (« NON ON NE TROUVERAIT RIEN !!! Les donnees medicales RESTENT sur le tel !!! »),
/// acquise par construction ailleurs (transport a liste fermee, tache 612). Ici
/// il n'est question que de l'endroit du DISQUE ou la fiche est ecrite.
///
/// ---------------------------------------------------------------------------
/// DEUX CHOIX D'IMPLEMENTATION, CHACUN POUR UNE RAISON MESUREE
/// ---------------------------------------------------------------------------
///
/// [1] ECRITURE ATOMIQUE (fichier temporaire puis renommage). Une ecriture
/// interrompue au milieu — batterie vide, application tuee — laisserait un JSON
/// tronque, donc une fiche ILLISIBLE alors qu'elle existait. Le renommage est
/// atomique au niveau du systeme de fichiers : ou l'ancienne fiche est intacte,
/// ou la nouvelle est complete. Jamais un entre-deux.
///
/// [2] ENTREES-SORTIES SYNCHRONES, et c'est la mesure du 28/09 de la tache 612
/// qui l'impose : ecrites en asynchrone, elles ne se terminent JAMAIS dans un
/// test de widgets, ou `pump` avance des minuteurs simules sans faire tourner la
/// boucle d'evenements reelle. L'ecran d'enregistrement de la fiche attendrait
/// une ecriture qui ne rend jamais la main. Le fichier pese quelques centaines
/// d'octets et l'ecriture suit un geste explicite : le cout est nul.
///
/// ---------------------------------------------------------------------------
/// SUR IPHONE, « DOSSIER DECLARE EXCLU » NE VEUT RIEN DIRE (tache 615)
/// ---------------------------------------------------------------------------
///
/// Tout ce qui precede reposait sur une exclusion DECLAREE, qui n'existe que sur
/// Android. Sur iPhone, `Library/Application Support/` est sauvegarde par defaut
/// et rien dans `Info.plist` ne l'en retire : l'exclusion est un ATTRIBUT DU
/// FICHIER, pose a l'execution. Le raisonnement entier est dans
/// [ExclusionSauvegardeIcloud] ; ce qui compte ICI est sa consequence sur le
/// choix [1] ci-dessus :
///
/// L'ECRITURE ATOMIQUE EFFACE L'EXCLUSION. L'attribut appartient au FICHIER, pas
/// au chemin. Apres le renommage, le fichier situe a `medical/fiche.json` est
/// l'ancien `.tmp` — qui n'a jamais porte l'attribut. Une exclusion posee une
/// seule fois, a la creation, serait donc perdue des la premiere modification de
/// la fiche, et personne ne s'en apercevrait : les tests de comportement
/// resteraient verts, et la fuite n'apparaitrait que dans une sauvegarde iCloud.
///
/// ELLE EST DONC REPOSEE A CHAQUE ECRITURE, EN TROIS POINTS : sur le dossier, sur
/// le `.tmp` AVANT le renommage (aucune fenetre ou la donnee soit sur le disque
/// sans attribut) et sur le fichier final APRES le renommage. Et
/// [garantirExclusion] la repose au demarrage, pour le randonneur qui avait deja
/// une fiche ecrite par la version precedente.
library;

import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/exclusion_sauvegarde_icloud.dart';
import '../../../core/services/sauvegarde_systeme.dart';
import '../domain/models/health_info.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Le stockage durable de la fiche medicale : UN fichier, dans le dossier
/// declare exclu de la sauvegarde du telephone.
class FicheMedicaleFichier {
  FicheMedicaleFichier({
    Future<Directory> Function()? dossierApplicatif,
    ExclusionSauvegardeIcloud? exclusionIcloud,
  })  : _dossierApplicatif =
            dossierApplicatif ?? getApplicationSupportDirectory,
        _exclusion = exclusionIcloud ?? ExclusionSauvegardeIcloud();

  /// Resolution du stockage applicatif. Sur Android
  /// `getApplicationSupportDirectory()` donne `files/`, donc le domaine `file`
  /// des regles de sauvegarde — celui que [SauvegardeSysteme.exclusions] nomme.
  /// Sur iPhone il rend `Library/Application Support/`, QUE LA SAUVEGARDE iCLOUD
  /// EMPORTE PAR DEFAUT — d'ou [_exclusion]. Les tests le pointent sur un
  /// repertoire temporaire.
  final Future<Directory> Function() _dossierApplicatif;

  /// L'EXCLUSION iCLOUD, POSEE A L'EXECUTION (tache 615). Sur Android elle rend
  /// [ResultatExclusionIcloud.sansObjet] sans toucher au canal natif : la
  /// protection y est declaree dans les deux XML.
  final ExclusionSauvegardeIcloud _exclusion;

  /// Nom du fichier de la fiche.
  static const String nomFichier = 'fiche.json';

  /// Suffixe du fichier temporaire de l'ecriture atomique.
  ///
  /// Nomme ici, et pas recopie a trois endroits, parce que TROIS choses portent
  /// sur lui : l'ecriture atomique le cree, [effacer] doit l'emporter (sinon une
  /// ecriture interrompue laisse la donnee medicale derriere elle) et l'exclusion
  /// iCloud doit le couvrir (sinon il existe une fenetre ou la fiche est sur le
  /// disque sans attribut).
  static const String suffixeTemporaire = '.tmp';

  /// Le fichier de la fiche : `<stockage applicatif>/medical/fiche.json`.
  Future<File> fichier() async {
    final base = await _dossierApplicatif();
    return File(
      '${base.path}/${SauvegardeSysteme.dossierExclu}/$nomFichier',
    );
  }

  /// Lit la fiche. Retourne une fiche VIDE si rien n'a jamais ete ecrit, et
  /// aussi si le contenu est illisible — une fiche corrompue ne doit pas
  /// empecher l'ecran d'urgence de s'ouvrir.
  Future<HealthInfo> lire() async {
    try {
      final f = await fichier();
      if (!f.existsSync()) return const HealthInfo();
      final brut = f.readAsStringSync();
      if (brut.trim().isEmpty) return const HealthInfo();
      return HealthInfo.fromJson(jsonDecode(brut) as Map<String, dynamic>);
    } catch (e) {
      _log.e('[FicheMedicale] Lecture impossible ($e) -> fiche reputee vide');
      return const HealthInfo();
    }
  }

  /// Ecrit la fiche, en remplacant la precedente. Une fiche VIDE n'est pas
  /// ecrite : elle EFFACE le fichier. Sans cela, « tout effacer puis
  /// enregistrer » laisserait un fichier de champs vides sur le disque, ce qui
  /// est une trace de passage la ou le randonneur a demande qu'il n'y en ait
  /// plus.
  /// L'ORDRE DES QUATRE GESTES EST LA PARTIE QUI COMPTE, ET IL N'EST PAS
  /// INTERCHANGEABLE :
  ///
  ///  1. le dossier est cree PUIS exclu — un dossier qui n'existe pas ne peut
  ///     pas porter d'attribut ;
  ///  2. le `.tmp` est ecrit PUIS exclu, AVANT le renommage — sinon la fiche
  ///     existe sur le disque, en clair, sans attribut, pendant tout le temps de
  ///     l'ecriture ;
  ///  3. le renommage ;
  ///  4. le fichier final est exclu APRES le renommage — c'est CE geste qui ferme
  ///     le piege de l'ecriture atomique, et il ne suppose pas que l'attribut ait
  ///     suivi le fichier a travers le `rename`.
  ///
  /// Les poses sont attendues (`await`) : elles rendent la main immediatement
  /// hors iPhone, et sur iPhone elles sont bornees par
  /// [ExclusionSauvegardeIcloud.delaiMax]. Aucune ne leve jamais.
  Future<void> ecrire(HealthInfo info) async {
    if (!info.hasData) {
      await effacer();
      return;
    }
    final f = await fichier();
    f.parent.createSync(recursive: true);
    await _exclusion.exclure(f.parent.path);

    final temporaire = File('${f.path}$suffixeTemporaire');
    temporaire.writeAsStringSync(jsonEncode(info.toJson()), flush: true);
    await _exclusion.exclure(temporaire.path);

    temporaire.renameSync(f.path);
    await _exclusion.exclure(f.path);
  }

  /// REPOSE L'EXCLUSION SUR CE QUI EST DEJA SUR LE DISQUE, SANS RIEN ECRIRE.
  ///
  /// POURQUOI ELLE EXISTE, ET ELLE N'EST PAS UNE CEINTURE DE PLUS. [ecrire]
  /// protege ce qu'ELLE ecrit. Mais le randonneur qui a rempli sa fiche avec la
  /// version de la tache 613, puis met l'application a jour, a sur son iPhone un
  /// `fiche.json` DEJA dans iCloud et sans attribut. S'il ne modifie plus jamais
  /// sa fiche — le cas le plus courant : on la remplit une fois —, [ecrire] ne
  /// passera plus jamais et rien ne le protegerait.
  ///
  /// Elle est appelee par l'amorce de l'application (`appBootstrapProvider`),
  /// donc a chaque demarrage, et elle est idempotente. Meme discipline que le
  /// re-alignement de la copie sauvegardable : « le disque converge vers la
  /// decision a chaque ouverture », ce qui tient meme apres un plantage ou une
  /// mise a jour.
  ///
  /// ELLE NE CREE RIEN. Poser l'attribut sur un dossier absent le ferait
  /// apparaitre sur le telephone d'un randonneur qui n'a jamais rempli de fiche :
  /// un dossier `medical/` vide n'est pas une fuite, mais c'est une trace de
  /// passage, et ce depot a decide au lot 612 qu'on n'en laissait pas.
  Future<void> garantirExclusion() async {
    try {
      final f = await fichier();
      final dossier = f.parent;
      if (!dossier.existsSync()) return;
      await _exclusion.exclure(dossier.path);
      if (f.existsSync()) await _exclusion.exclure(f.path);
      final temporaire = File('${f.path}$suffixeTemporaire');
      if (temporaire.existsSync()) await _exclusion.exclure(temporaire.path);
    } catch (e) {
      // ELLE NE LEVE JAMAIS : elle est attendue par l'amorce de l'application.
      // Un attribut de sauvegarde ne doit pas empecher un randonneur de demarrer
      // son telephone.
      _log.e('[FicheMedicale] Exclusion iCloud impossible ($e)');
    }
  }

  /// Supprime la fiche du disque. Idempotent, et il emporte AUSSI le fichier
  /// temporaire : une ecriture interrompue juste avant un effacement laisserait
  /// sinon la donnee medicale dans le `.tmp`, hors de portee de la promesse.
  Future<void> effacer() async {
    try {
      final f = await fichier();
      if (f.existsSync()) f.deleteSync();
      final temporaire = File('${f.path}$suffixeTemporaire');
      if (temporaire.existsSync()) temporaire.deleteSync();
    } catch (e) {
      _log.e('[FicheMedicale] Suppression impossible ($e)');
      rethrow;
    }
  }
}
