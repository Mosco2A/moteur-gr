import 'dart:convert';

import 'package:crypto/crypto.dart';

/// L EMPREINTE D UN FICHIER DE DONNEES PUBLIE — UNE SEULE DEFINITION.
///
/// POURQUOI CE FICHIER EXISTE, ET C EST UNE AFFAIRE DE SECURITE PAS DE CONFORT.
/// La specification serveur annonce depuis le lot 605 que `hash` (#M3) garantit
/// que « ce qui a ete recu est bien ce qui a ete publie » (#C4). Le lot 606 a
/// MESURE que personne ne le calculait et que personne ne le comparait : un
/// fichier TRONQUE mais syntaxiquement valide passait la copie, et le randonneur
/// partait en montagne avec un sentier incomplet QUI SE CROYAIT COMPLET — sa
/// revision locale inscrite, donc plus aucune raison de retelecharger. Sur un
/// sentier de montagne, des etapes manquantes ou une trace coupee ne sont pas un
/// defaut d affichage.
///
/// UNE SEULE DEFINITION, DES DEUX COTES. L outil de publication
/// (`tool/publier_sentier.dart`) calcule l empreinte avec ce code, et
/// l application la verifie avec ce MEME code. C est deliberе : le lot 606 a
/// trouve TROIS definitions concurrentes de la lecture d une trace et DEUX
/// chemins de descente des donnees, qui derivaient sans que rien ne le dise. Une
/// empreinte calculee ici et verifiee ailleurs aurait la meme fragilite, en pire —
/// elle echouerait silencieusement du bon cote.
///
/// L EMPREINTE PORTE SUR LES OCTETS, PAS SUR LE SENS. On hache le corps recu tel
/// quel, avant tout decodage : re-serialiser du JSON pour le hacher reviendrait a
/// verifier notre propre encodeur, et laisserait passer exactement ce qu on veut
/// attraper (un fichier coupe qui se reparse).
abstract final class EmpreinteDePublication {
  EmpreinteDePublication._();

  /// Prefixes toleres devant l empreinte dans la liste publiee.
  ///
  /// L exemple de la specification s ecrivait `sha256-…` : on accepte donc la
  /// forme prefixee comme la forme nue, plutot que de refuser un manifeste pour
  /// une question de presentation.
  static const List<String> prefixesToleres = <String>['sha256-', 'sha256:'];

  /// Longueur d une empreinte SHA-256 en hexadecimal.
  static const int longueurHex = 64;

  /// Empreinte SHA-256 de [octets], en hexadecimal minuscule.
  static String de(List<int> octets) => sha256.convert(octets).toString();

  /// Empreinte SHA-256 du texte [contenu] encode en UTF-8.
  static String duTexte(String contenu) => de(utf8.encode(contenu));

  /// Ramene [brut] a une empreinte comparable, ou `null` si ce n en est pas une.
  ///
  /// RENDRE `null` N EST PAS UNE TOLERANCE, C EST UN REFUS. Une empreinte
  /// absente, vide, mal prefixee ou de mauvaise longueur ne vaut pas « pas de
  /// verification » : elle vaut « ce manifeste ne permet pas de verifier », et
  /// l appelant doit refuser la copie. C est le seul moyen de fermer le trou
  /// evident — un editeur qui ecrit n importe quoi dans `hash` desactiverait
  /// sinon le controle sans que personne ne s en apercoive.
  static String? normaliser(String? brut) {
    if (brut == null) return null;
    var valeur = brut.trim().toLowerCase();
    for (final prefixe in prefixesToleres) {
      if (valeur.startsWith(prefixe)) {
        valeur = valeur.substring(prefixe.length);
        break;
      }
    }
    if (valeur.length != longueurHex) return null;
    if (!_estHexadecimal(valeur)) return null;
    return valeur;
  }

  /// Vrai si [octets] correspond a l empreinte annoncee [attendue].
  ///
  /// Une empreinte annoncee illisible ([normaliser] rend `null`) ne correspond
  /// JAMAIS : le doute se tranche du cote du refus.
  static bool correspond(List<int> octets, String? attendue) {
    final reference = normaliser(attendue);
    if (reference == null) return false;
    return de(octets) == reference;
  }

  static bool _estHexadecimal(String valeur) {
    for (final unite in valeur.codeUnits) {
      final chiffre = unite >= 0x30 && unite <= 0x39; // 0-9
      final lettre = unite >= 0x61 && unite <= 0x66; // a-f
      if (!chiffre && !lettre) return false;
    }
    return true;
  }
}

/// L ECHEC D INTEGRITE, NOMME — parce qu il doit se DIRE, pas se deviner.
///
/// Levee AVANT la moindre ecriture : la pose transactionnelle n est jamais
/// ouverte, la revision locale n avance pas, et le sentier reste « a prendre »
/// (garantie #C1). C est la contrepartie de la copie atomique, et elle vaut
/// mieux qu un sentier incomplet presente comme disponible.
class EmpreinteInvalide implements Exception {
  const EmpreinteInvalide({
    required this.trailId,
    required this.adresse,
    required this.attendue,
    required this.obtenue,
    required this.octets,
  });

  /// Sentier dont la copie est refusee.
  final String trailId;

  /// Adresse du fichier de donnees recu.
  final String adresse;

  /// Empreinte annoncee par la liste publiee (telle quelle, non normalisee).
  final String? attendue;

  /// Empreinte reellement calculee sur les octets recus, `null` si l annonce
  /// etait elle-meme illisible (rien a comparer).
  final String? obtenue;

  /// Taille du corps recu, en octets — c est ce qui trahit une troncature.
  final int octets;

  @override
  String toString() {
    if (EmpreinteDePublication.normaliser(attendue) == null) {
      return 'Copie de $trailId REFUSEE : la liste publiee n annonce aucune '
          'empreinte exploitable pour $adresse (« $attendue »). Le champ '
          '`hash` est obligatoire (#M3) et doit porter un SHA-256 : sans lui, '
          'rien ne distingue un fichier complet d un fichier tronque.';
    }
    return 'Copie de $trailId REFUSEE : empreinte non conforme pour $adresse. '
        'Annoncee ${EmpreinteDePublication.normaliser(attendue)}, calculee '
        '$obtenue sur $octets octet(s) recu(s). Rien n a ete ecrit et la '
        'revision locale n a pas bouge.';
  }
}
