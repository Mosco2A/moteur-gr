// TACHE 562 (LOT K) — LE TROISIEME ETAGE DE STOCKAGE, CELUI QUE L'EFFACEMENT
// N'AVAIT JAMAIS OUVERT.
//
// L'effacement de l'article 17 ([DataRetentionService.deleteAccountData])
// connaissait deux etages : les tables Drift et les SharedPreferences. Il en
// existe un TROISIEME, et c'est celui qui porte les cles de chiffrement — le
// KEYSTORE DE L'OS (Android Keystore / iOS Keychain), via
// `flutter_secure_storage`.
//
// CE QUI Y DORMAIT, ET QUI SURVIVAIT A UN EFFACEMENT « COMPLET » :
//   - `stepways.recovery.code.v1` — le code de reconnexion. Ce code EST la cle
//     du coffre du randonneur : il ouvre son profil, sa fiche de renseignement
//     medical et son solde d'etapes DEPUIS UN AUTRE TELEPHONE. Le laisser en
//     place apres un effacement, c'est laisser la cle sur la porte.
//   - `stepways.vault.dataKey.v1` — la cle qui dechiffre le backup local de la
//     fiche sante. `SecureVaultService.deleteLocalDataKey()` existait pour
//     l'effacer, et n'avait elle non plus aucun appelant.
//
// POURQUOI UNE INVERSION, ET PAS UNE LISTE DE DEUX NOMS. Le LOT J a montre ce
// que devient une liste recopiee : seize tables sur trente-six, quatre cles de
// prefs sur cinquante-neuf. Deux noms ecrits ici s'oublieraient exactement
// pareil. On enumere donc les EXCEPTIONS ([preservedKeys]) et TOUT LE RESTE du
// keystore part, la liste des cles a effacer etant DERIVEE du store reel
// (`readAll()`). Consequence voulue : une cle ajoutee demain par quelqu'un qui
// n'a jamais lu ce fichier est EFFACEE, pas conservee. Le defaut protege la
// personne, pas la donnee.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Signature de l'effacement du keystore OS, injectable pour les tests (le
/// keystore reel est une ressource de plateforme).
///
/// Retourne le NOMBRE de cles effacees — un effacement RGPD doit etre tracable,
/// pas seulement effectue.
typedef SecureKeystoreErasure = Future<int> Function();

/// Efface le contenu du KEYSTORE DE L'OS au titre du droit a l'effacement.
///
/// Voir l'en-tete du fichier pour le raisonnement. En resume : la liste des
/// cles effacees est DERIVEE de `readAll()`, jamais recopiee, et seules les
/// exceptions nommees dans [preservedKeys] survivent.
class SecureKeystoreEraser {
  SecureKeystoreEraser({FlutterSecureStorage? secureStorage})
      : _storage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// EXCEPTIONS — cles du keystore conservees par l'effacement.
  ///
  /// VIDE, et ce vide est une decision, pas un oubli : rien de ce qui vit dans
  /// le keystore ne subsiste a l'effacement d'un compte. Tout ce qui y est
  /// stocke appartient par construction au RANDONNEUR (la cle de son coffre, le
  /// code de sa reconnexion) ; aucun reglage d'appareil n'y figure,
  /// contrairement aux SharedPreferences ou la langue et le theme justifient des
  /// exceptions.
  ///
  /// Le test `effacement_stockage_securise_test.dart` exige que cet ensemble
  /// reste vide : y ajouter une cle fait ECHOUER la suite, ce qui force a
  /// ecrire la raison au lieu de la supposer.
  static const Set<String> preservedKeys = <String>{};

  /// Efface tout le keystore sauf [preservedKeys]. Retourne le nombre de cles
  /// effacees. Idempotent (rejouer n'efface rien de plus).
  ///
  /// Aucun catch silencieux : si le keystore refuse une suppression, l'erreur
  /// remonte — un effacement RGPD rate en silence serait une non-conformite.
  Future<int> eraseAll() async {
    final all = await _storage.readAll();
    var deleted = 0;
    for (final key in all.keys.toList(growable: false)) {
      if (preservedKeys.contains(key)) continue;
      await _storage.delete(key: key);
      deleted++;
    }
    if (deleted > 0) {
      _log.d('[SecureKeystore] $deleted cle(s) effacee(s) du keystore OS '
          '(art. 17)');
    }
    return deleted;
  }
}
