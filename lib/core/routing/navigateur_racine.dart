import 'package:flutter/widgets.dart';

/// LA CLE DU NAVIGATEUR RACINE — ET ELLE VIT ICI POUR POUVOIR ETRE LUE AILLEURS
/// QUE DANS LE ROUTEUR (tache 637).
///
/// Elle etait privee dans `app_router.dart`. La sortir n'est pas un confort
/// d'organisation : c'est ce qui permet aux gardes d'ouverture — qui vivent
/// AU-DESSUS du `Navigator` — d'obtenir un contexte qui, lui, est DESSOUS. Voir
/// [contexteDeDialogue] pour le defaut mesure que cela corrige.
final cleNavigateurRacine = GlobalKey<NavigatorState>(debugLabel: 'root');

/// RESOUT UN CONTEXTE QUI PORTE VRAIMENT UN `Navigator`, OU RIEN DU TOUT.
///
/// ---------------------------------------------------------------------------
/// LE DEFAUT QUE CETTE FONCTION CORRIGE, ET IL A ETE MESURE EN PRODUCTION
/// ---------------------------------------------------------------------------
///
/// Crashlytics, builds 6 et 7 (0.1.2 et 0.1.3), 28 plantages, 9 utilisateurs,
/// ZERO session sans plantage sur sept jours :
/// `Null check operator used on a null value`, premiere frame applicative
/// `refus_sauvegarde_systeme_dialog.dart:96` dans `poserSiNecessaire`.
///
/// La pile complete, reproduite a l'identique par
/// `test/comportement/plantage_null_check_refus_sauvegarde_637_test.dart` :
///
///     Navigator.of         (navigator.dart:2937)  -> return navigator!
///     showDialog           (dialog.dart:1504)
///     poserSiNecessaire    (refus_sauvegarde_systeme_dialog.dart:96)
///     _demander            (porte_consentement_sauvegarde.dart:78)
///
/// Le `!` n'etait PAS dans le code de StepWays : il est dans le framework, a
/// `navigator.dart:2937`, et la documentation du SDK le dit mot pour mot —
/// « If there is no Navigator in the given context, this function will throw a
/// FlutterError in debug mode, AND AN EXCEPTION IN RELEASE MODE ». L'assertion
/// qui NOMME le probleme est a la ligne 2927, et elle est RETIREE des builds de
/// release : il ne reste que le `!` de la ligne 2937, dont le message ne dit
/// rien. C'est pour cela que le rapport etait illisible.
///
/// ---------------------------------------------------------------------------
/// POURQUOI IL N'Y AVAIT PAS DE NAVIGATEUR, ET POURQUOI LES TESTS DISAIENT OUI
/// ---------------------------------------------------------------------------
///
/// Les deux gardes d'ouverture (`PorteConsentementSauvegarde`,
/// `OrphanSessionReprise`) sont posees dans le `builder` de
/// `MaterialApp.router` (`main.dart`). Or `WidgetsApp` passe le widget `Router`
/// EN ARGUMENT de ce `builder` : tout ce que le `builder` enveloppe se retrouve
/// donc AU-DESSUS du `Navigator` que GoRouter construit, jamais dessous.
/// `main.dart` le dit d'ailleurs lui-meme a propos de la garde d'amorce
/// (« elle est au-dessus du `Navigator` »), et c'est precisement la propriete
/// qui y est recherchee : une garde qui ne se demonte jamais.
///
/// `Navigator.of` remonte les ANCETRES. Au-dessus du `Router`, il n'y en a
/// aucun : le resultat etait null a TOUS les lancements ou la question restait
/// a poser — d'ou zero session sans plantage. Et comme l'appel partait d'un
/// `addPostFrameCallback`, l'erreur etait avalee par le filet d'erreurs de
/// Flutter : l'application continuait, la question n'etait JAMAIS posee, et
/// seul Crashlytics le savait.
///
/// LES DEUX TESTS EXISTANTS DISAIENT VERT PARCE QU'ILS NE MONTAIENT PAS L'ARBRE
/// DE PRODUCTION : `aucune_donnee_confiee_ne_sort_617_test.dart` posait la
/// porte dans `MaterialApp(home:)`, et `orphan_session_reprise_test.dart` dans
/// un `GoRoute.builder`. Dans les deux cas la garde etait DESSOUS un
/// `Navigator`, c'est-a-dire a l'exact oppose de sa place reelle.
///
/// ---------------------------------------------------------------------------
/// CE QUE RENVOIE CETTE FONCTION
/// ---------------------------------------------------------------------------
///
/// Le contexte du navigateur racine quand il est monte, sinon le contexte
/// fourni S'IL porte vraiment un navigateur, sinon **null**. Null est une
/// reponse, pas un echec : l'appelant renonce a son dialogue au lieu de lever.
///
/// L'ORDRE DE PREFERENCE N'EST PAS ARBITRAIRE. Le contexte du navigateur racine
/// est prefere parce qu'il est le seul dont on sache qu'il est DESSOUS le
/// `Router` — donc le seul qui porte aussi `InheritedGoRouter`, ce qui ferme du
/// meme geste le second `!` de la meme famille : `GoRouter.of` se termine par
/// `return inherited!` (`go_router/src/router.dart:508`), et `context.go` depuis
/// une garde d'ouverture plantait donc exactement pareil.
///
/// `mounted` EST TESTE AVANT CHAQUE REMONTEE D'ANCETRES, et ce n'est pas du
/// style : `findRootAncestorStateOfType` sur un element deja demonte assertionne
/// en debug et lit un arbre mort en release.
BuildContext? contexteDeDialogue(BuildContext context) {
  final racine = cleNavigateurRacine.currentContext;
  if (racine != null && racine.mounted && porteUnNavigateur(racine)) {
    return racine;
  }
  if (context.mounted && porteUnNavigateur(context)) return context;
  return null;
}

/// Vrai si [context] porte VRAIMENT un `Navigator`, sans jamais lever.
///
/// A RAPPELER APRES CHAQUE ATTENTE, et pas seulement avant la premiere : un
/// contexte valide a l'aller ne l'est pas forcement au retour. L'appelant teste
/// `mounted` d'abord — remonter les ancetres d'un element demonte assertionne en
/// debug et lit un arbre mort en release.
bool porteUnNavigateur(BuildContext context) =>
    Navigator.maybeOf(context, rootNavigator: true) != null;
