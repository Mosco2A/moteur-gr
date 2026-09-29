/// LA PRISE DE PHOTO DES DEUX CARTES — CARTE VITALE ET MUTUELLE (tache 630).
///
/// ===========================================================================
/// LA DEMANDE, ET LA CONDITION QUI VENAIT AVEC
/// ===========================================================================
///
/// Christophe, le 29/09 11:37, en deux messages : « Telecharger la carte verte et
/// la carte de mutuelle, tout reste sur le tel » puis « photo des 2 ».
///
/// La condition est dans la phrase elle-meme : TOUT RESTE SUR LE TELEPHONE. Ce
/// fichier ne fait donc QUE lire des octets depuis l'appareil photo ou la
/// galerie. C'est [FicheMedicaleFichier.enregistrerCarte] qui les range, et il
/// les range dans le MEME dossier que la fiche medicale — meme exclusion de
/// sauvegarde Android, meme attribut iCloud, meme effacement. Aucune seconde
/// porte n'est ouverte.
///
/// ===========================================================================
/// LA RESOLUTION : LISIBLE PAR UN HUMAIN, PAS PLUS — ET C'EST MESURE
/// ===========================================================================
///
/// Une carte Vitale et une carte de mutuelle sont au format ID-1 de la norme
/// ISO/CEI 7810 : 85,6 mm x 54 mm, comme une carte bancaire.
///
/// LE CALCUL, PLUTOT QU'UN CHIFFRE ROND CHOISI AU HASARD. La numerisation de
/// document de reference est a 300 points par pouce ; a cette densite, le grand
/// cote d'une carte fait 85,6 mm / 25,4 x 300 = 1011 pixels. [kLargeurMaxCarte]
/// vaut 1280 : environ 380 points par pouce, donc une marge confortable sur le
/// texte le plus petit d'une carte (le numero de securite sociale), sans jamais
/// atteindre les 12 millions de pixels d'un capteur de telephone moderne.
///
/// CE QUE CA PESE, ET POURQUOI CE N'EST PAS ANECDOTIQUE. Une photo brute de
/// telephone pese 3 a 6 Mo. Bornee a 1280 pixels et compressee a
/// [kQualiteJpegCarte], une carte tient dans quelques centaines de kilo-octets.
/// Les deux cartes ensemble restent donc sous le megaoctet, dans un dossier qui
/// ne sera JAMAIS sauvegarde nulle part : ce que le randonneur perdrait en
/// changeant de telephone doit rester raisonnable a reprendre, et ce que
/// l'application garde sur un telephone de montagne doit rester petit.
///
/// ===========================================================================
/// LE REFUS DE L'APPAREIL PHOTO N'EST PAS UNE ERREUR
/// ===========================================================================
///
/// Un randonneur a parfaitement le droit de refuser l'acces a son appareil
/// photo, et beaucoup le feront pour une carte d'assurance maladie. Ce cas n'est
/// donc PAS traite comme une panne : [ResultatPhotoCarte.refus] le distingue de
/// [ResultatPhotoCarte.annule] et de la reussite. L'ecran continue de
/// fonctionner, sans photo, et N'INSISTE PAS — pas de second dialogue, pas de
/// renvoi vers les reglages du systeme.
library;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Largeur (et hauteur) maximale d'une photo de carte, en pixels.
///
/// Voir l'en-tete du fichier pour le calcul : ~380 points par pouce sur le grand
/// cote d'une carte au format ID-1.
const double kLargeurMaxCarte = 1280;

/// Qualite JPEG des photos de carte (0-100).
///
/// 85 est le palier au-dela duquel l'oeil ne gagne plus rien sur un aplat imprime
/// alors que le poids, lui, continue de monter.
const int kQualiteJpegCarte = 85;

/// CE QUI EST REVENU DE L'APPAREIL PHOTO — TROIS ISSUES, PAS DEUX.
///
/// Les confondre ferait dire a l'ecran « impossible de prendre la photo » a un
/// randonneur qui a simplement appuye sur Annuler.
enum IssuePhotoCarte {
  /// Des octets sont revenus.
  reussite,

  /// Le randonneur a ferme l'appareil photo sans prendre de photo.
  annule,

  /// L'acces a l'appareil photo (ou a la galerie) a ete REFUSE.
  refus,

  /// Autre echec (aucun appareil photo, canal de plateforme absent...).
  echec,
}

/// Le resultat d'une prise de photo de carte.
class ResultatPhotoCarte {
  const ResultatPhotoCarte._(this.issue, this.octets);

  /// Des octets sont revenus.
  const ResultatPhotoCarte.reussite(List<int> octets)
      : this._(IssuePhotoCarte.reussite, octets);

  /// Le randonneur a annule.
  const ResultatPhotoCarte.annule() : this._(IssuePhotoCarte.annule, null);

  /// L'acces a ete refuse.
  const ResultatPhotoCarte.refus() : this._(IssuePhotoCarte.refus, null);

  /// Echec technique.
  const ResultatPhotoCarte.echec() : this._(IssuePhotoCarte.echec, null);

  final IssuePhotoCarte issue;
  final List<int>? octets;

  /// Vrai si une image exploitable est revenue.
  bool get aUneImage => octets != null && octets!.isNotEmpty;
}

/// Signature de la prise de photo — injectable, donc testable sans appareil.
typedef PriseDePhotoCarte = Future<ResultatPhotoCarte> Function(
  ImageSource source,
);

/// Prise de photo REELLE, par l'appareil photo ou la galerie.
///
/// LES TROIS BORNES SONT POSEES ICI ET PAS APRES COUP : `image_picker` les
/// applique AVANT de rendre le fichier, donc l'image pleine resolution n'existe
/// jamais dans notre stockage, pas meme le temps d'etre redimensionnee.
///
/// LE `catch` NE FAIT PAS QU'AVALER. Il distingue le refus d'autorisation du
/// reste, parce que l'ecran n'en dit pas la meme chose : un refus est une
/// decision du randonneur, un echec est un probleme a signaler.
Future<ResultatPhotoCarte> prendrePhotoDeCarte(ImageSource source) async {
  try {
    final fichier = await ImagePicker().pickImage(
      source: source,
      maxWidth: kLargeurMaxCarte,
      maxHeight: kLargeurMaxCarte,
      imageQuality: kQualiteJpegCarte,
    );
    if (fichier == null) return const ResultatPhotoCarte.annule();
    final octets = await fichier.readAsBytes();
    if (octets.isEmpty) return const ResultatPhotoCarte.echec();
    return ResultatPhotoCarte.reussite(octets);
  } on PlatformException catch (e) {
    // Codes rendus par image_picker quand l'autorisation manque.
    const refus = {
      'camera_access_denied',
      'photo_access_denied',
      'access_denied',
    };
    return refus.contains(e.code)
        ? const ResultatPhotoCarte.refus()
        : const ResultatPhotoCarte.echec();
  } on Object {
    return const ResultatPhotoCarte.echec();
  }
}
