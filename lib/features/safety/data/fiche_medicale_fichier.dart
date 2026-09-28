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
library;

import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/sauvegarde_systeme.dart';
import '../domain/models/health_info.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Le stockage durable de la fiche medicale : UN fichier, dans le dossier
/// declare exclu de la sauvegarde du telephone.
class FicheMedicaleFichier {
  FicheMedicaleFichier({Future<Directory> Function()? dossierApplicatif})
      : _dossierApplicatif =
            dossierApplicatif ?? getApplicationSupportDirectory;

  /// Resolution du stockage applicatif. Sur Android
  /// `getApplicationSupportDirectory()` donne `files/`, donc le domaine `file`
  /// des regles de sauvegarde — celui que [SauvegardeSysteme.exclusions] nomme.
  /// Les tests le pointent sur un repertoire temporaire.
  final Future<Directory> Function() _dossierApplicatif;

  /// Nom du fichier de la fiche.
  static const String nomFichier = 'fiche.json';

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
  Future<void> ecrire(HealthInfo info) async {
    if (!info.hasData) {
      await effacer();
      return;
    }
    final f = await fichier();
    f.parent.createSync(recursive: true);
    final temporaire = File('${f.path}.tmp');
    temporaire.writeAsStringSync(jsonEncode(info.toJson()), flush: true);
    temporaire.renameSync(f.path);
  }

  /// Supprime la fiche du disque. Idempotent, et il emporte AUSSI le fichier
  /// temporaire : une ecriture interrompue juste avant un effacement laisserait
  /// sinon la donnee medicale dans le `.tmp`, hors de portee de la promesse.
  Future<void> effacer() async {
    try {
      final f = await fichier();
      if (f.existsSync()) f.deleteSync();
      final temporaire = File('${f.path}.tmp');
      if (temporaire.existsSync()) temporaire.deleteSync();
    } catch (e) {
      _log.e('[FicheMedicale] Suppression impossible ($e)');
      rethrow;
    }
  }
}
