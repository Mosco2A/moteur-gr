/// SUR IPHONE, TOUT LE STOCKAGE CONFIE SORT DE LA SAUVEGARDE iCLOUD — ET UN SEUL
/// DOSSIER Y RESTE (tache 617, regle generale de Christophe du 28/09 14:31).
///
/// LA REGLE, VERBATIM : « on ne partage aucune donnee confiee sauf si le client
/// decoche volontairement ».
///
/// ---------------------------------------------------------------------------
/// POURQUOI CE FICHIER EXISTE : ANDROID SAIT DIRE « RIEN SAUF CECI », IPHONE NON
/// ---------------------------------------------------------------------------
///
/// Cote Android, une seule ligne suffit et elle est DECLARATIVE : une inclusion
/// desactive le defaut, donc tout le reste est dehors sans avoir a etre nomme
/// ([SauvegardeSysteme.inclusions]). Cote iPhone il n'existe AUCUN equivalent :
/// pas de fichier de regles, pas d'entree `Info.plist`, rien qui dise a l'avance
/// « ne sauvegarde rien sauf ce dossier ». L'exclusion est un ATTRIBUT DU
/// FICHIER, pose a l'execution, chemin par chemin
/// ([ExclusionSauvegardeIcloud], canal natif ouvert par la tache 615).
///
/// LA CONSEQUENCE EST DESAGREABLE MAIS ELLE EST LA : ce qui est declaratif d'un
/// cote doit etre BALAYE de l'autre. Ce fichier est ce balayage. Il ne cherche
/// pas a uniformiser les deux plateformes — la tache 615 avait deja pose que
/// c'etait une erreur — il tient la MEME PROMESSE par l'autre mecanique.
///
/// ---------------------------------------------------------------------------
/// LE PIEGE QUE CE BALAYAGE A DU EVITER, ET IL AURAIT ETE UN FAUX SUCCES
/// ---------------------------------------------------------------------------
///
/// Exclure un DOSSIER est tentant : un appel au lieu de cent. Mais deux faits
/// s'y opposent, et ils tirent en sens inverse :
///
///  a. La page d'Apple citee par la tache 615 ne dit PAS que l'attribut d'un
///     dossier s'applique a son contenu. S'en remettre a cela seul serait
///     construire sur un fait non verifie.
///  b. SI l'attribut se propage — hypothese qu'on ne peut pas exclure non plus —
///     alors exclure `Library/Application Support/` emporterait aussi
///     [SauvegardeSysteme.dossierSauvegardable], qui est DEDANS. La case
///     decochee ferait alors apparaitre une copie que la sauvegarde
///     n'emporterait pas : le randonneur croirait avoir choisi la commodite et
///     retrouverait un telephone vide. C'est exactement le faux succes que la
///     tache 615 avait ferme dans l'autre sens.
///
/// D'OU LA REGLE POSEE ICI, ET ELLE TIENT DANS LES DEUX HYPOTHESES :
///
///  * `Documents/` (la base, les photos du journal, les paquets, les tuiles, les
///    exports) : le DOSSIER LUI-MEME est exclu **et** chacune de ses entrees
///    l'est aussi. Aucun dossier sauvegardable n'y vit, donc la propagation
///    eventuelle ne peut rien casser — et elle devient un second verrou pour les
///    fichiers qui apparaitront APRES le balayage.
///  * `Library/Application Support/` : le dossier lui-meme N'EST JAMAIS EXCLU,
///    chacune de ses entrees l'est SAUF le sous-arbre
///    [SauvegardeSysteme.dossierSauvegardable]. C'est le prix a payer pour que
///    decocher veuille dire quelque chose.
///
/// ---------------------------------------------------------------------------
/// LE SECOND VERROU SERT A QUELQUE CHOSE DE PRECIS : LE JOURNAL DE LA BASE
/// ---------------------------------------------------------------------------
///
/// MESURE, PAS SUPPOSEE : la base reste en mode de journal `delete`, le defaut,
/// et la tache 613 a ecrit pourquoi (`database_provider.dart` : le mode WAL
/// laisserait en permanence un `-wal` et un `-shm` a cote du fichier, et la
/// sauvegarde pourrait emporter l'un sans l'autre). Il n'y a donc PAS de fichier
/// annexe permanent a exclure — c'est une bonne nouvelle pour ce balayage.
///
/// IL EN RESTE UN, TRANSITOIRE : en mode `delete`, SQLite cree un
/// `stepways.sqlite-journal` PENDANT une transaction d'ecriture et le supprime au
/// bout. Un fichier de journal contient de la donnee. S'il existe a l'instant du
/// balayage, il est exclu comme les autres ; s'il nait apres, il ne porte que
/// l'exclusion du dossier `Documents/`, dont Apple ne garantit pas la
/// propagation. C'EST LE RESIDU CONNU DE CE FICHIER, nomme dans le bilan plutot
/// que tu. Sa fenetre est celle d'une transaction, et la fermer demanderait un
/// balayage periodique dont aucune mesure ne justifie le cout aujourd'hui.
///
/// ---------------------------------------------------------------------------
/// HORS IPHONE, RIEN NE PASSE, ET RIEN N'EST MEME LU SUR LE DISQUE
/// ---------------------------------------------------------------------------
///
/// La garde est la MEME que celle mesuree par la tache 612 puis reprise par la
/// 615 : un appel a un canal de plateforme SANS interlocuteur ne rend jamais la
/// main dans le temps feint d'un test de widgets. On ne se contente donc pas de
/// laisser [ExclusionSauvegardeIcloud] repondre « sans objet » : hors iPhone on
/// ne PARCOURT MEME PAS le disque, parce que ce balayage est attendu par l'amorce
/// de l'application et qu'il n'a aucune raison de coûter des entrees-sorties sur
/// les 3381 tests qui ne sont pas sur iPhone.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'exclusion_sauvegarde_icloud.dart';
import 'sauvegarde_systeme.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// CE QUE LE BALAYAGE A REELLEMENT FAIT — compte par compte, sans faux succes.
///
/// Un booleen melangerait « je n'avais rien a faire » (Android, ou aucun
/// fichier) et « j'ai rate ». Les trois compteurs sont separes pour que le
/// journal dise laquelle des trois situations s'est produite.
class BilanBalayageSauvegarde {
  const BilanBalayageSauvegarde({
    required this.exclus,
    required this.epargnes,
    required this.echecs,
    required this.sansObjet,
  });

  /// Balayage sans objet : ce n'est pas un iPhone (sur Android la protection est
  /// DECLARATIVE, voir [SauvegardeSysteme.inclusions]).
  const BilanBalayageSauvegarde.sansObjet()
    : exclus = 0,
      epargnes = 0,
      echecs = 0,
      sansObjet = true;

  /// Nombre de chemins pour lesquels l'attribut a ete pose.
  final int exclus;

  /// Nombre de chemins DELIBEREMENT laisses sauvegardables : le dossier des
  /// copies que le randonneur a acceptees, et lui seul.
  final int epargnes;

  /// Nombre de chemins pour lesquels le natif a refuse. JAMAIS confondu avec un
  /// succes.
  final int echecs;

  /// Vrai quand rien n'avait a etre fait (plateforme non iPhone).
  final bool sansObjet;

  /// Vrai quand tout ce qui devait etre exclu l'a ete.
  bool get complet => echecs == 0;
}

/// BALAYE LE STOCKAGE DE L'APPLICATION ET EN SORT TOUT, SAUF LE DOSSIER DES
/// COPIES ACCEPTEES.
///
/// Voir l'en-tete du fichier pour le raisonnement entier, en particulier pour la
/// raison — mesurable et non cosmetique — pour laquelle les deux racines ne sont
/// PAS traitees de la meme facon.
class GardeSauvegardeIos {
  GardeSauvegardeIos({
    ExclusionSauvegardeIcloud? exclusion,
    Future<Directory> Function()? documents,
    Future<Directory> Function()? support,
    bool? cibleIos,
  }) : _cibleIos = cibleIos ?? Platform.isIOS,
       _exclusion =
           exclusion ??
           ExclusionSauvegardeIcloud(cibleIos: cibleIos ?? Platform.isIOS),
       _documents = documents ?? getApplicationDocumentsDirectory,
       _support = support ?? getApplicationSupportDirectory;

  final bool _cibleIos;
  final ExclusionSauvegardeIcloud _exclusion;
  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _support;

  /// NOMBRE MAXIMAL DE CHEMINS TRAITES EN UN BALAYAGE.
  ///
  /// Ce n'est pas une precaution decorative : `journal_photos/` grandit avec le
  /// randonneur, et l'amorce de l'application ATTEND ce balayage. Une borne
  /// garantit que le demarrage ne depend pas du nombre de photos. Au-dela, c'est
  /// l'exclusion du dossier `Documents/` qui porte — la meme que pour les
  /// fichiers de journal de la base — et le depassement est JOURNALISE, pas
  /// silencieux.
  static const int plafondChemins = 500;

  /// SORT TOUT LE STOCKAGE CONFIE DE LA SAUVEGARDE iCLOUD.
  ///
  /// Idempotent : reposer un attribut deja pose ne coûte rien et c'est
  /// exactement ce qu'il faut faire a chaque demarrage (un fichier remplace ne
  /// porte plus l'attribut de celui qu'il remplace — mesure de la tache 615).
  ///
  /// NE LEVE JAMAIS. Elle est appelee par l'amorce : une exception ici
  /// empecherait l'application de demarrer pour un attribut de sauvegarde.
  Future<BilanBalayageSauvegarde> balayer() async {
    if (!_cibleIos) return const BilanBalayageSauvegarde.sansObjet();

    var exclus = 0;
    var epargnes = 0;
    var echecs = 0;
    var traites = 0;

    Future<void> exclure(String chemin) async {
      if (traites >= plafondChemins) return;
      traites++;
      final r = await _exclusion.exclure(chemin);
      if (r == ResultatExclusionIcloud.appliquee) {
        exclus++;
      } else if (r == ResultatExclusionIcloud.echec) {
        echecs++;
      }
    }

    // --- Documents/ : la base, les photos, les paquets, les tuiles ----------
    //
    // AUCUN dossier sauvegardable n'y vit : on exclut donc le dossier LUI-MEME
    // (second verrou pour les fichiers qui naitront apres ce balayage, dont les
    // journaux de la base) PUIS chacune de ses entrees (le verrou principal, qui
    // ne depend d'aucune hypothese de propagation).
    try {
      final docs = await _documents();
      if (docs.existsSync()) {
        await exclure(docs.path);
        for (final entree in _entrees(docs)) {
          await exclure(entree);
        }
      }
    } catch (e) {
      echecs++;
      _log.e('[GardeSauvegardeIos] Documents/ inaccessible ($e)');
    }

    // --- Library/Application Support/ : la fiche medicale ET les copies ------
    //
    // ICI LE DOSSIER RACINE N'EST JAMAIS EXCLU. Il contient le dossier des
    // copies que le randonneur a acceptees : si l'attribut se propageait, les
    // exclure toutes les deux ferait de « decocher » un faux succes.
    try {
      final support = await _support();
      if (support.existsSync()) {
        final racineCopies = _memeForme(
          '${support.path}/${SauvegardeSysteme.dossierSauvegardable}',
        );
        for (final entree in _entrees(support)) {
          // LA COMPARAISON EST FAITE SUR DES CHEMINS DE MEME FORME, ET CE N'EST
          // PAS UN DETAIL DE CONFORT : c'est un defaut MESURE. La premiere
          // version comparait le chemin rendu par `listSync` a un chemin
          // fabrique avec des barres obliques. Sur la machine de developpement
          // `listSync` rend des CONTRE-obliques, la comparaison echouait
          // toujours, et le dossier des copies acceptees se faisait EXCLURE avec
          // le reste — le faux succes exact que ce fichier pretend eviter. Le
          // defaut ne se serait pas vu sur un iPhone (ou tout est en barres
          // obliques), donc il aurait survecu a l'execution reelle et serait
          // revenu le jour d'un portage. On compare des formes normalisees, et
          // on passe au natif le chemin D'ORIGINE.
          if (_estDans(entree, racineCopies)) {
            epargnes++;
            continue;
          }
          await exclure(entree);
        }
      }
    } catch (e) {
      echecs++;
      _log.e('[GardeSauvegardeIos] Application Support/ inaccessible ($e)');
    }

    if (traites >= plafondChemins) {
      _log.w(
        '[GardeSauvegardeIos] Plafond de $plafondChemins chemins atteint : '
        'les suivants ne portent que l exclusion de leur dossier parent',
      );
    }
    if (echecs > 0) {
      _log.e('[GardeSauvegardeIos] $echecs chemin(s) NON exclus de iCloud');
    } else {
      _log.d(
        '[GardeSauvegardeIos] $exclus chemin(s) exclus, '
        '$epargnes epargne(s) (copies acceptees)',
      );
    }

    return BilanBalayageSauvegarde(
      exclus: exclus,
      epargnes: epargnes,
      echecs: echecs,
      sansObjet: false,
    );
  }

  /// Un chemin ramene a une forme comparable : separateurs uniformes, casse
  /// ignoree.
  ///
  /// La casse compte parce que le systeme de fichiers d'un iPhone ne la distingue
  /// pas : deux ecritures du meme dossier ne doivent pas donner deux verdicts.
  static String _memeForme(String chemin) =>
      chemin.replaceAll(r'\', '/').toLowerCase();

  /// Vrai si [chemin] est [racine] ou vit dessous.
  static bool _estDans(String chemin, String racineNormalisee) {
    final c = _memeForme(chemin);
    return c == racineNormalisee || c.startsWith('$racineNormalisee/');
  }

  /// Les chemins contenus dans [racine], en profondeur, liens NON suivis.
  ///
  /// `followLinks: false` n'est pas un detail : suivre un lien ferait sortir du
  /// stockage de l'application et poser un attribut sur un fichier qui n'est pas
  /// a nous. Les erreurs de parcours sont avalees par entree — un dossier
  /// illisible ne doit pas faire perdre les 200 autres.
  Iterable<String> _entrees(Directory racine) {
    try {
      return racine
          .listSync(recursive: true, followLinks: false)
          .map((e) => e.path);
    } catch (e) {
      _log.e(
        '[GardeSauvegardeIos] Parcours de « ${racine.path} » impossible '
        '($e)',
      );
      return const [];
    }
  }
}

/// Provider Riverpod de la garde iPhone.
final gardeSauvegardeIosProvider = Provider<GardeSauvegardeIos>((ref) {
  return GardeSauvegardeIos();
});
