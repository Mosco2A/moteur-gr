/// LES LIENS DE PARTAGE DU SUIVI — PLUS AUCUNE ADRESSE DANS LE DEPOT, ET PLUS
/// AUCUN LIEN QUI PUISSE MOURIR EN SILENCE (tache 623, GO-73).
///
/// ---------------------------------------------------------------------------
/// CE QUE J'AI MESURE AVANT D'ECRIRE UNE LIGNE, ET CE N'ETAIT PAS UNE FAUTE DE
/// FRAPPE DANS UNE ADRESSE
/// ---------------------------------------------------------------------------
///
/// Ce fichier portait deux adresses en dur, `.../follow` et `.../companion`, sur
/// un domaine de projet Firebase qui N'EXISTE PAS. Skynet l'a mesure le 28/09 :
/// l'adresse rendait 404. J'ai refait la mesure, et j'ai mesure AUSSI le projet
/// Firebase reel de StepWays, le 28/09 vers 23:30, avec le corps ET les en-tetes
/// de la reponse :
///
///  * l'ancien domaine : 404, et le corps est la page « Site Not Found » de
///    l'hebergement Firebase, 21265 octets ;
///  * le domaine du projet REEL : 404, ET LE MEME CORPS, AU MEME OCTET.
///
/// LA CONCLUSION EST DONC L'INVERSE DE CELLE QU'ON ATTENDAIT : ce n'est pas le
/// NOM du projet qui etait faux, c'est que L'HEBERGEMENT N'EXISTE NULLE PART.
/// Deuxieme mesure qui le confirme sans dependre du reseau : `firebase.json`, a
/// la racine de ce depot, ne porte AUCUNE section `hosting` — ni cible, ni
/// dossier public, ni reecriture. Rien n'a jamais ete deploye parce que rien n'a
/// jamais ete configure pour l'etre.
///
/// CORRIGER LE NOM DU PROJET AURAIT DONC REMPLACE UN 404 PAR UN AUTRE 404, en
/// laissant croire le contraire a tout le monde — y compris a la prochaine
/// personne qui lirait ce fichier. C'est precisement ce que Christophe et Skynet
/// refusaient. AUCUNE ADRESSE N'EST DONC ECRITE ICI, et ce n'est pas une
/// prudence de principe : il n'existe aujourd'hui aucune adresse qui reponde.
///
/// ---------------------------------------------------------------------------
/// D'OU VIENT L'ADRESSE MAINTENANT : DU BUILD, COMME TOUT LE RESTE
/// ---------------------------------------------------------------------------
///
/// Meme doctrine que `FirebaseConfig` (tache 596) et `AdConfig` : la valeur
/// arrive par `--dart-define` au moment du build, jamais par le depot. Les trois
/// noms de variables sont PUBLIES et STABLES ([variableAppBase],
/// [variableWebBase], [variableCompagnonBase]) pour que la CI comme Christophe
/// puissent les passer sans lire le code :
///
/// ```
/// flutter build apk \
///   --dart-define=STEPWAYS_FOLLOW_WEB_BASE=https://<hote>/follow
/// ```
///
/// Et cela sert aussi la regle du cadre de la nuit : « AUCUNE valeur de
/// configuration ni identifiant en clair dans le depot, jamais ».
///
/// ---------------------------------------------------------------------------
/// LE VRAI SUJET N'EST PAS L'ADRESSE, C'EST LE SILENCE
/// ---------------------------------------------------------------------------
///
/// Un randonneur qui partage sa position et que PERSONNE ne peut suivre ne
/// decouvre rien : il marche en croyant etre suivi. C'est la pire forme de
/// defaut de ce depot — celle que la tache 615 appelait un FAUX SUCCES — et
/// changer l'adresse ne l'empeche pas de revenir. Deux verrous le ferment, et
/// aucun des deux n'est une adresse :
///
///  [1] PAR CONSTRUCTION, UN CANAL NON CONFIGURE NE PRODUIT PLUS DE LIEN. Les
///      trois methodes rendent `String?` et valent `null` quand leur base est
///      vide. Aucune interface ne peut donc afficher un lien fabrique a partir
///      de rien : avant, `webLink('AB3C7D')` rendait toujours une chaine
///      d'allure parfaite, et c'est exactement ce qui a permis au defaut de
///      vivre. Un appelant qui veut un lien doit maintenant traiter le `null`.
///
///  [2] LA CIBLE EST MESUREE AU MOMENT DU PARTAGE, pas supposee. Voir
///      `VerificateurCibleSuivi` et `FollowService.preparerPartage` : le lien
///      n'est remis qu'avec un VERDICT, et un 404 ne ressort pas en lien.
///
/// ---------------------------------------------------------------------------
/// CE QUE JE N'AI PAS INVENTE, ET POURQUOI JE LE DIS ICI
/// ---------------------------------------------------------------------------
///
/// Les deux autres canaux sont morts eux aussi, et cela n'a rien a voir avec une
/// adresse. MESURE : `android/app/src/main/AndroidManifest.xml` ne declare AUCUN
/// `intent-filter` de lien (seul `MAIN`/`LAUNCHER`), et `ios/Runner/Info.plist`
/// ne declare AUCUN `CFBundleURLTypes`. Un lien `xxx://follow/CODE` n'est donc
/// route vers l'application par AUCUN des deux systemes, et l'application
/// compagnon payante n'existe pas du tout. Ce n'est pas mon mandat, je ne le
/// corrige pas — mais je refuse de rendre pour ces canaux un verdict
/// « joignable » qui serait faux : voir [DisponibiliteCibleSuivi.nonVerifiable].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// LES TROIS CANAUX DE SUIVI (#81753), NOMMES AU LIEU D'ETRE DEVINES.
///
/// `ShareLinkTypeValues` porte deja ces trois noms cote modele, sous forme de
/// chaines extensibles. Cet enum-ci sert aux VERDICTS : un verdict doit porter
/// sur un canal precis, et une chaine libre y laisserait passer un canal dont
/// personne n'a verifie la configuration.
enum CanalSuivi {
  /// Lien profond vers l'application principale (canal gratuit).
  app,

  /// Page web de suivi (canal du pass payant).
  web,

  /// Application compagnon de suivi (payante).
  compagnon,
}

/// Configuration des liens de partage du suivi trekkeur (E4.11).
///
/// Voir l'en-tete du fichier : AUCUNE valeur par defaut n'est ecrite dans le
/// depot, les trois bases arrivent par `--dart-define`, et un canal non
/// configure ne produit PAS de lien.
class FollowLinksConfig {
  const FollowLinksConfig({
    this.appLinkBase = _appInjecte,
    this.webLinkBase = _webInjecte,
    this.companionLinkBase = _compagnonInjecte,
  });

  /// Nom de la variable `--dart-define` du canal application.
  static const String variableAppBase = 'STEPWAYS_FOLLOW_APP_BASE';

  /// Nom de la variable `--dart-define` du canal web.
  static const String variableWebBase = 'STEPWAYS_FOLLOW_WEB_BASE';

  /// Nom de la variable `--dart-define` du canal application compagnon.
  static const String variableCompagnonBase =
      'STEPWAYS_FOLLOW_COMPANION_BASE';

  static const String _appInjecte = String.fromEnvironment(variableAppBase);
  static const String _webInjecte = String.fromEnvironment(variableWebBase);
  static const String _compagnonInjecte =
      String.fromEnvironment(variableCompagnonBase);

  /// Base du lien profond vers l'application principale (canal app gratuit).
  /// VIDE dans le depot : voir l'en-tete du fichier.
  final String appLinkBase;

  /// Base de l'URL de la page web de suivi (canal web, pass payant).
  /// VIDE dans le depot : voir l'en-tete du fichier.
  final String webLinkBase;

  /// Base du lien vers l'application compagnon de suivi (payante).
  /// VIDE dans le depot : voir l'en-tete du fichier.
  final String companionLinkBase;

  /// La base d'un canal, telle qu'elle a ete injectee au build (vide si rien).
  String base(CanalSuivi canal) => switch (canal) {
        CanalSuivi.app => appLinkBase,
        CanalSuivi.web => webLinkBase,
        CanalSuivi.compagnon => companionLinkBase,
      };

  /// Vrai quand ce canal a recu une base au build. Faux dans le depot.
  bool estConfigure(CanalSuivi canal) => base(canal).trim().isNotEmpty;

  /// Vrai quand AUCUN canal n'est configure — l'etat du depot, et l'etat d'un
  /// build qui a oublie ses `--dart-define`.
  bool get aucunCanalConfigure =>
      CanalSuivi.values.every((c) => !estConfigure(c));

  /// Le lien d'un canal pour un `shareCode`, ou `null` si le canal n'est pas
  /// configure. C'est le verrou [1] de l'en-tete : pas de chaine fabriquee a
  /// partir d'une base vide.
  String? lien(CanalSuivi canal, String shareCode) {
    if (!estConfigure(canal)) return null;
    final racine = base(canal).trim();
    final sansBarre =
        racine.endsWith('/') ? racine.substring(0, racine.length - 1) : racine;
    return '$sansBarre/$shareCode';
  }

  /// Lien profond vers l'application pour un `shareCode`, ou `null`.
  String? appLink(String shareCode) => lien(CanalSuivi.app, shareCode);

  /// Page web de suivi pour un `shareCode`, ou `null`.
  String? webLink(String shareCode) => lien(CanalSuivi.web, shareCode);

  /// Lien de l'application compagnon pour un `shareCode`, ou `null`.
  String? companionLink(String shareCode) =>
      lien(CanalSuivi.compagnon, shareCode);
}

/// Provider de la configuration des liens de suivi.
///
/// Surchargeable par l'application hote, mais ce n'est PLUS la seule facon de
/// renseigner les adresses : les trois variables de build suffisent, et c'est
/// par elles que passe un build de production.
final followLinksConfigProvider = Provider<FollowLinksConfig>((ref) {
  return const FollowLinksConfig();
});
