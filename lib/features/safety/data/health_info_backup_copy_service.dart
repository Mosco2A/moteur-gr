/// La copie sauvegardable de la fiche medicale n'existe QUE si le marcheur a
/// decoche la case de refus — et elle ne sort jamais vers nos serveurs.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/exclusion_sauvegarde_icloud.dart';
import '../../../core/services/sauvegarde_systeme.dart';
import '../presentation/health_info_screen.dart'
    show healthInfoRepositoryProvider;
import 'health_info_repository.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// LA COPIE SAUVEGARDABLE DE LA FICHE MEDICALE — ELLE N'EXISTE QUE SI LE
/// RANDONNEUR A DECOCHE LA CASE DE REFUS (tache 612, decision de Christophe du
/// 28/09 10:49 : « option prechochee, Je refuse la sauvegarde sur le cloud google
/// de mes donnees medicales, quand il se connecte »).
///
/// CE SERVICE N'EST PAS UN CHEMIN DE SORTIE VERS NOS SERVEURS, ET IL NE FAUT PAS
/// LES CONFONDRE. Il n'ouvre aucune connexion, il ne connait ni Firebase ni
/// Firestore : il ecrit ou supprime UN FICHIER LOCAL. Ce fichier-la, et lui seul,
/// est place dans un emplacement que la sauvegarde du telephone par Google ou par
/// Apple emporte. Nos serveurs, eux, ne recoivent rien dans aucun cas — voir
/// [SauvegardeSysteme] pour la distinction, qui est aussi celle que l'ecran doit
/// dire au randonneur.
///
/// POURQUOI UNE COPIE, ET PAS UNE BASCULE DE L'EXCLUSION. L'exclusion de la
/// sauvegarde systeme est declaree A LA COMPILATION (Android) : ce n'est pas un
/// reglage par utilisateur, on ne peut pas l'allumer selon une case. La fiche vit
/// donc en permanence dans [SauvegardeSysteme.dossierExclu] et n'en sort jamais ;
/// la case ne gouverne QUE la presence de cette copie dans
/// [SauvegardeSysteme.dossierSauvegardable]. Le defaut ne fait rien partir.
///
/// LA COPIE NE SURVIT NI A UN REFUS NI A UN EFFACEMENT. [appliquer] est appele a
/// chaque bascule de la case ET a chaque ecriture de la fiche (enregistrement,
/// effacement) : une copie ne peut donc pas rester en arriere d'une fiche effacee
/// ni d'un refus re-coche. C'est la meme exigence que celle des LOTS J a O sur le
/// droit a l'effacement, et c'est la seule facon dont « je refuse » veuille dire
/// quelque chose une fois que quelque chose a deja ete ecrit.
///
/// SUR IPHONE, IL FALLAIT AUSSI LE CHEMIN INVERSE (tache 615). L'exclusion iCloud
/// n'est pas declarative : elle est posee A L'EXECUTION sur chaque fichier de la
/// fiche ([ExclusionSauvegardeIcloud]). Cette copie-ci, elle, doit au contraire
/// NE PAS la porter — c'est tout son objet. [ExclusionSauvegardeIcloud.inclure]
/// la lui retire explicitement a chaque ecriture. Sans ce geste, une copie qui
/// aurait herite de l'attribut par un changement futur du montage serait un FAUX
/// SUCCES : la case se decocherait, la copie apparaitrait, et le randonneur
/// retrouverait un telephone vide en croyant avoir choisi la commodite.
class HealthInfoBackupCopyService {
  HealthInfoBackupCopyService({
    required HealthInfoRepository healthRepository,
    Future<Directory> Function()? baseDirProvider,
    ExclusionSauvegardeIcloud? exclusionIcloud,
  }) : _health = healthRepository,
       _baseDirProvider = baseDirProvider ?? getApplicationSupportDirectory,
       _exclusion = exclusionIcloud ?? ExclusionSauvegardeIcloud();

  final HealthInfoRepository _health;
  final Future<Directory> Function() _baseDirProvider;

  /// L'EXCLUSION iCLOUD, UTILISEE ICI A L'ENVERS : on la RETIRE de la copie.
  final ExclusionSauvegardeIcloud _exclusion;

  /// Le fichier de la copie, dans l'emplacement INCLUS dans la sauvegarde.
  Future<File> _fichierCopie() async {
    final base = await _baseDirProvider();
    return File(
      '${base.path}/${SauvegardeSysteme.dossierSauvegardable}'
      '/${SauvegardeSysteme.fichierCopieFiche}',
    );
  }

  /// Vrai si une copie sauvegardable existe en ce moment.
  Future<bool> copiePresente() async {
    try {
      return (await _fichierCopie()).existsSync();
    } catch (e) {
      _log.w('[CopieFiche] Lecture impossible ($e) -> copie reputee absente');
      return false;
    }
  }

  /// ALIGNE LE DISQUE SUR LA DECISION DU RANDONNEUR.
  ///
  /// [refuse] vrai (le DEFAUT) : aucune copie ne doit exister, et celle qui
  /// existait est SUPPRIMEE. [refuse] faux : la copie est (re)ecrite avec le
  /// contenu courant de la fiche — sauf si la fiche est vide, auquel cas il n'y a
  /// rien a copier et une copie residuelle est supprimee.
  ///
  /// Retourne vrai si une copie est presente a la sortie. Idempotent.
  ///
  /// L'ORDRE COMPTE : on lit la decision AVANT la fiche. Un refus ne doit meme
  /// pas faire lire la donnee de sante.
  ///
  /// CETTE METHODE NE LEVE JAMAIS, ET CE N'EST PAS UN CATCH PARESSEUX. Elle est
  /// appelee dans le chemin qui CONFIRME au randonneur que sa fiche est
  /// enregistree. Une exception ici avalerait cette confirmation : il aurait
  /// enregistre sa fiche, elle serait bien en base, et l'ecran ne lui dirait
  /// rien. Le pire des deux defauts serait celui-la, pas une copie manquante.
  ///
  /// POURQUOI LES OPERATIONS DE FICHIER SONT SYNCHRONES ICI, ET C'EST MESURE.
  /// Ecrites en asynchrone, elles ne se terminaient JAMAIS dans un test de
  /// widgets : le temps y est feint, `pump` avance des minuteurs simules et ne
  /// fait pas tourner la boucle d'evenements reelle qui acheve une entree-sortie
  /// de fichier. Mesure du 28/09 : le test du LOT X « Sauvegarder confirme sans
  /// vider la pile » est devenu ROUGE des que ce re-alignement est entre dans le
  /// chemin d'enregistrement, parce que l'ecran attendait une ecriture qui ne
  /// rendait jamais la main. En synchrone la chaine se resout dans le battement,
  /// et surtout LA SUPPRESSION DE LA COPIE DEVIENT ATOMIQUE avec l'effacement de
  /// la fiche : c'est la partie qui compte pour la securite, et elle ne peut plus
  /// rester en vol. Le fichier pese quelques centaines d'octets et l'ecriture
  /// suit un geste explicite : le cout est nul, la certitude ne l'est pas.
  Future<bool> appliquer({required bool refuse}) async {
    if (refuse) {
      await _supprimerCopie();
      return false;
    }
    final info = await _health.get();
    if (!info.hasData) {
      await _supprimerCopie();
      return false;
    }
    try {
      final fichier = await _fichierCopie();
      fichier.parent.createSync(recursive: true);
      fichier.writeAsStringSync(jsonEncode(info.toJson()), flush: true);
      // LE CHEMIN INVERSE DE LA TACHE 615, ET IL EST POSE A CHAQUE ECRITURE pour
      // la meme raison que l'exclusion l'est a chaque ecriture de la fiche :
      // l'attribut appartient au FICHIER, donc a celui qui existe MAINTENANT.
      await _exclusion.inclure(fichier.path);
      _log.d('[CopieFiche] Copie sauvegardable ecrite (refus decoche)');
      return true;
    } catch (e) {
      // ON NE FABRIQUE PAS UN FAUX SUCCES. Une copie qu'on n'a pas su ecrire est
      // une copie absente : le randonneur qui a decoche la retrouvera vide au
      // changement de telephone, et c'est une deception, pas une fuite. L'echec
      // est journalise et rendu a l'appelant.
      _log.e('[CopieFiche] Ecriture de la copie impossible ($e)');
      return false;
    }
  }

  /// Supprime la copie si elle existe. Idempotent, jamais bruyant, jamais levant.
  Future<void> _supprimerCopie() async {
    try {
      final fichier = await _fichierCopie();
      if (fichier.existsSync()) {
        fichier.deleteSync();
        _log.d('[CopieFiche] Copie sauvegardable supprimee (refus actif)');
      }
    } catch (e) {
      _log.e('[CopieFiche] Suppression de la copie impossible ($e)');
    }
  }
}

/// Provider Riverpod du service de copie sauvegardable de la fiche medicale.
final copieSauvegardableFicheServiceProvider =
    Provider<HealthInfoBackupCopyService>((ref) {
      return HealthInfoBackupCopyService(
        healthRepository: ref.watch(healthInfoRepositoryProvider),
      );
    });
