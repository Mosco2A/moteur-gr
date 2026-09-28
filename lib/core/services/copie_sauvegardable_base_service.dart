/// LA COPIE SAUVEGARDABLE DE LA BASE — ELLE N'EXISTE QUE SI LE RANDONNEUR A
/// DECOCHE LA CASE (tache 617, regle generale de Christophe du 28/09 14:31 :
/// « on ne partage aucune donnee confiee sauf si le client decoche
/// volontairement »).
///
/// ---------------------------------------------------------------------------
/// POURQUOI CE FICHIER EXISTE, ET CE N'EST PAS UN CONFORT
/// ---------------------------------------------------------------------------
///
/// La tache 612 avait donne une copie sauvegardable a la SEULE fiche medicale.
/// Depuis la tache 617, plus rien ne monte par defaut : la base est dehors elle
/// aussi (une inclusion unique cote Android, un balayage d'attributs cote
/// iPhone). Sans ce fichier, decocher la case n'aurait donc AUCUN effet sur ce
/// qui fait tout le prix du geste — la progression, le journal, les treks
/// realises, le solde, les sentiers telecharges vivent tous dans la base.
///
/// UNE CASE QUI NE CHANGE RIEN EST PIRE QU'AUCUNE CASE : c'est la phrase de la
/// tache 615, et elle vaut dans ce sens-la aussi. Le texte montre au randonneur
/// dit « decoche si tu preferes retrouver tes donnees sur ton prochain
/// telephone » ; il faut que ce soit vrai.
///
/// ---------------------------------------------------------------------------
/// LE CHEMIN DE RETOUR FAIT PARTIE DU LOT, SINON LA COPIE EST DECORATIVE
/// ---------------------------------------------------------------------------
///
/// Ecrire une copie ne suffit pas. Au changement de telephone, le systeme
/// restaure ce qu'il avait emporte : la copie revient A SON CHEMIN, mais la base
/// elle-meme non, puisqu'elle n'a jamais ete sauvegardee. Sans lecture au retour,
/// le randonneur qui a decoche retrouverait quand meme un telephone vide, et
/// aurait paye la commodite sans rien recevoir.
///
/// [adopterCopieSiBaseAbsente] est ce retour. Elle est appelee par
/// `ouvrirBaseDurable()`, AVANT l'ouverture, et pas depuis l'amorce : c'est le
/// seul endroit ou l'on est certain qu'aucune requete n'a encore cree un fichier
/// de base vide. Un appel depuis l'amorce aurait dependu de l'ordre des
/// providers, c'est-a-dire de la vigilance de celui qui en ajoutera un demain.
///
/// SA GARDE EST LA PARTIE IMPORTANTE : elle n'adopte QUE si aucune base n'existe.
/// Elle ne peut donc jamais ecraser la progression reelle d'un randonneur avec
/// une copie plus vieille, meme si elle etait appelee deux fois, meme si la copie
/// restait la pour toujours.
///
/// ET ELLE VERIFIE QUE LA COPIE EST UNE BASE. Un fichier tronque par une
/// restauration interrompue, adopte tel quel, donnerait une application qui ne
/// demarre plus du tout — on aurait echange une perte de donnees contre une
/// panne. Tout fichier SQLite commence par la chaine `SQLite format 3` (quinze
/// octets, suivis d'un octet nul, documentation SQLite « Database File Format ») :
/// c'est ce qui est verifie avant d'adopter, et un fichier qui ne la porte pas
/// est laisse ou il est (jamais supprime en silence : il sera ecrase au prochain
/// enregistrement de copie, et sa presence reste visible).
///
/// ---------------------------------------------------------------------------
/// POURQUOI `VACUUM INTO` ET PAS UNE COPIE D'OCTETS
/// ---------------------------------------------------------------------------
///
/// La base est OUVERTE quand on fabrique la copie. Une copie d'octets prise
/// pendant une transaction donnerait un fichier incoherent, et c'est precisement
/// le genre de defaut qui ne se voit qu'au changement de telephone, six mois plus
/// tard, chez quelqu'un d'autre. `VACUUM INTO` produit une base COMPLETE et
/// COHERENTE en une seule instruction, du point de vue de la transaction en
/// cours.
///
/// AUCUN REPLI SUR UNE COPIE D'OCTETS EN CAS D'ECHEC, ET C'EST DELIBERE. Un repli
/// donnerait deux comportements a tester et, surtout, il pourrait produire une
/// copie CORROMPUE qu'[adopterCopieSiBaseAbsente] adopterait ensuite. Mieux vaut
/// pas de copie — le randonneur perd ce qu'il aurait perdu de toute facon — qu'une
/// copie qui casse son application. L'echec est journalise et RENDU.
///
/// ---------------------------------------------------------------------------
/// CE QUE LA COPIE NE COUVRE PAS, ET IL FAUT LE DIRE AU RANDONNEUR
/// ---------------------------------------------------------------------------
///
/// LES PHOTOS DU JOURNAL NE SONT PAS COPIEES. Elles vivent en fichiers sous
/// `journal_photos/` et leur copie DOUBLERAIT l'espace occupe sur le telephone —
/// une application de randonnee qui double la place prise par les photos est un
/// defaut, pas une protection. Le texte des cinq langues le dit franchement au
/// lieu de le taire.
///
/// LES PREFERENCES NE SONT PAS COPIEES NON PLUS, et la raison est differente : y
/// vivent le SOLDE D'ETAPES et les decisions de consentement elles-memes. Les
/// reinjecter depuis une sauvegarde ferait revivre un solde deja depense et
/// reecrirait par-dessus la decision que le randonneur vient de prendre. Sur
/// Android elles sont dehors depuis ce lot ; sur iPhone elles ne peuvent PAS en
/// sortir (voir [SauvegardeSysteme.trouUserDefaultsIos]).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';
import 'exclusion_sauvegarde_icloud.dart';
import 'sauvegarde_systeme.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// LA CHAINE D'EN-TETE DE TOUT FICHIER SQLITE, quinze octets.
///
/// Documentee par SQLite (« Database File Format », en-tete de 100 octets : « The
/// header string: "SQLite format 3\000" » — quinze caracteres et un octet nul).
/// C'est ce qui distingue une base d'un fichier tronque par une restauration
/// interrompue.
const String kEnteteFichierSqlite = 'SQLite format 3';

/// Chemin de la copie sauvegardable de la base, sous le dossier INCLUS.
String cheminCopieBase(Directory support) =>
    '${support.path}/${SauvegardeSysteme.dossierSauvegardable}'
    '/${SauvegardeSysteme.fichierCopieBase}';

/// ADOPTE LA COPIE SAUVEGARDABLE SI, ET SEULEMENT SI, AUCUNE BASE N'EXISTE.
///
/// Voir l'en-tete du fichier. Retourne vrai si une base a ete restauree depuis la
/// copie. Ne leve JAMAIS : elle est sur le chemin d'ouverture de la base, et une
/// exception ici empecherait l'application de demarrer.
///
/// LES DEUX GARDES, ET AUCUNE DES DEUX N'EST DECORATIVE :
///  * la base ne doit PAS exister (sinon on ecraserait du reel par du vieux) ;
///  * la copie doit porter l'en-tete SQLite (sinon on echangerait une perte de
///    donnees contre une application qui ne demarre plus).
Future<bool> adopterCopieSiBaseAbsente({
  required Directory documents,
  required Directory support,
}) async {
  try {
    final base = File('${documents.path}/$kFichierBaseStepWays');
    if (base.existsSync()) return false;

    final copie = File(cheminCopieBase(support));
    if (!copie.existsSync()) return false;

    if (!_porteEnteteSqlite(copie)) {
      _log.e('[CopieBase] La copie restauree n est pas une base SQLite : elle '
          'n est PAS adoptee (une base tronquee empecherait le demarrage)');
      return false;
    }

    copie.copySync(base.path);
    _log.i('[CopieBase] Base restauree depuis la copie sauvegardable '
        '(${copie.lengthSync()} octets) : le randonneur avait decoche la case');
    return true;
  } catch (e) {
    _log.e('[CopieBase] Adoption de la copie impossible ($e) : l application '
        'demarre sur une base neuve');
    return false;
  }
}

/// Vrai si [fichier] commence par l'en-tete d'un fichier SQLite.
bool _porteEnteteSqlite(File fichier) {
  try {
    final attendu = Uint8List.fromList(kEnteteFichierSqlite.codeUnits);
    if (fichier.lengthSync() < attendu.length) return false;
    final debut = fichier.openSync();
    try {
      final lus = debut.readSync(attendu.length);
      for (var i = 0; i < attendu.length; i++) {
        if (lus[i] != attendu[i]) return false;
      }
      return true;
    } finally {
      debut.closeSync();
    }
  } catch (_) {
    return false;
  }
}

/// FABRIQUE ET SUPPRIME LA COPIE SAUVEGARDABLE DE LA BASE, selon la case.
class CopieSauvegardableBaseService {
  CopieSauvegardableBaseService({
    required AppDatabase db,
    Future<Directory> Function()? supportDirProvider,
    ExclusionSauvegardeIcloud? exclusionIcloud,
  })  : _db = db,
        _support = supportDirProvider ?? getApplicationSupportDirectory,
        _exclusion = exclusionIcloud ?? ExclusionSauvegardeIcloud();

  final AppDatabase _db;
  final Future<Directory> Function() _support;

  /// L'EXCLUSION iCLOUD, UTILISEE ICI A L'ENVERS : on la RETIRE de la copie.
  /// Meme geste que pour la copie de la fiche medicale (tache 615) et pour la
  /// meme raison : sans lui, decocher n'aurait aucun effet sur iPhone.
  final ExclusionSauvegardeIcloud _exclusion;

  Future<File> _fichierCopie() async =>
      File(cheminCopieBase(await _support()));

  /// Vrai si une copie sauvegardable de la base existe en ce moment.
  Future<bool> copiePresente() async {
    try {
      return (await _fichierCopie()).existsSync();
    } catch (e) {
      _log.w('[CopieBase] Lecture impossible ($e) -> copie reputee absente');
      return false;
    }
  }

  /// ALIGNE LE DISQUE SUR LA DECISION DU RANDONNEUR.
  ///
  /// [refuse] vrai (le DEFAUT) : aucune copie ne doit exister, celle qui existait
  /// est SUPPRIMEE. [refuse] faux : la copie est refaite depuis l'etat courant de
  /// la base.
  ///
  /// Retourne vrai si une copie est presente a la sortie. Idempotent.
  ///
  /// NE LEVE JAMAIS, pour la meme raison que son homologue de la fiche medicale :
  /// elle est appelee dans des chemins qui doivent confirmer autre chose au
  /// randonneur. Un echec est journalise et rendu, jamais deguise en succes.
  Future<bool> appliquer({required bool refuse}) async {
    if (refuse) {
      await _supprimerCopie();
      return false;
    }
    try {
      final fichier = await _fichierCopie();
      fichier.parent.createSync(recursive: true);
      // VACUUM INTO REFUSE D'ECRIRE PAR-DESSUS UN FICHIER EXISTANT : on retire
      // l'ancienne copie d'abord. Ce n'est pas un detail de confort — sans cela
      // la copie ne serait JAMAIS rafraichie apres la premiere, et le randonneur
      // restaurerait la progression qu'il avait le jour ou il a decoche.
      if (fichier.existsSync()) fichier.deleteSync();
      await _db.customStatement("VACUUM INTO '${_echapper(fichier.path)}'");
      // LE CHEMIN INVERSE DE LA TACHE 615, POSE A CHAQUE ECRITURE parce que
      // l'attribut appartient au FICHIER, donc a celui qui existe MAINTENANT.
      await _exclusion.inclure(fichier.path);
      _log.d('[CopieBase] Copie sauvegardable de la base ecrite (refus decoche)');
      return true;
    } catch (e) {
      // ON NE FABRIQUE NI FAUX SUCCES NI COPIE DOUTEUSE. Voir l'en-tete : pas de
      // repli sur une copie d'octets, qui pourrait etre incoherente et serait
      // ensuite ADOPTEE au changement de telephone.
      _log.e('[CopieBase] Copie de la base impossible ($e)');
      return false;
    }
  }

  /// Supprime la copie si elle existe. Idempotent, jamais levant.
  Future<void> _supprimerCopie() async {
    try {
      final fichier = await _fichierCopie();
      if (fichier.existsSync()) {
        fichier.deleteSync();
        _log.d('[CopieBase] Copie de la base supprimee (refus actif)');
      }
    } catch (e) {
      _log.e('[CopieBase] Suppression de la copie impossible ($e)');
    }
  }

  /// Double les apostrophes simples, la seule echappement qu'attend un litteral
  /// de chaine SQL. Les chemins viennent de `path_provider`, mais un nom
  /// d'utilisateur peut contenir une apostrophe et cela suffirait a casser
  /// l'instruction.
  String _echapper(String chemin) => chemin.replaceAll("'", "''");
}

/// Provider Riverpod du service de copie sauvegardable de la base.
final copieSauvegardableBaseServiceProvider =
    Provider<CopieSauvegardableBaseService>((ref) {
  return CopieSauvegardableBaseService(db: ref.watch(databaseProvider));
});
