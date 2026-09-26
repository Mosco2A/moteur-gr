// LE SOCLE DES TESTS STRUCTURELS (tache 573, LOT V).
//
// POURQUOI CE FICHIER EXISTE. Le 26/09 au matin, Chris a trouve vingt defauts
// en quarante minutes, seul, sur un emulateur. 2 760 tests etaient VERTS. Trois
// fonctions entieres n'avaient aucune porte d'entree — l'ecran d'urgence, la
// fiche medicale qui n'etait joignable que depuis lui, et la boutique de cartes
// qui n'avait meme pas de route. Aucun test ne l'a vu, et la raison est toujours
// la meme : NOS TESTS CONSTRUISENT LES ECRANS DIRECTEMENT.
//
//   testWidgets('l ecran d urgence affiche les contacts', (t) async {
//     await t.pumpWidget(MaterialApp(home: EmergencyScreen()));   // <-- ici
//
// Un test qui instancie un ecran ne prouve JAMAIS qu'un utilisateur peut y
// arriver. Il prouve que la classe compile et se peint. C'est la lecon la plus
// importante du chantier, et c'est une lecon d'OUTILLAGE : tant que le seul
// moyen d'atteindre un ecran dans un test est de l'appeler par son nom, la suite
// restera aveugle aux culs-de-sac.
//
// CE QUE CE SOCLE APPORTE : le moyen de monter L APPLICATION REELLE — le vrai
// [appRouter], ses vraies gardes de redirection, ses vraies donnees de sentier —
// et de s'y deplacer comme un doigt sur un ecran. Les trois invariantes du LOT V
// s'appuient dessus, et tout test ecrit apres elles peut s'y appuyer aussi.
//
// CE N'EST PAS UN TEST D INTEGRATION SUR APPAREIL. Les personas de
// `integration_test/` demandent un emulateur, quinze minutes et un humain pour
// lire les captures ; ils ne tournent donc pas a chaque commit. Ce socle tourne
// dans `flutter test`, en secondes, sur la machine de n'importe qui.
library;

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/app_router.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Les drapeaux de l'application (etat de premier lancement)
// ---------------------------------------------------------------------------

/// Etat de l'application au montage, tel que la garde de routage le lit.
///
/// Les deux drapeaux sont des globales de `app_router.dart` alimentees au
/// demarrage depuis les preferences. Les remettre explicitement AVANT chaque
/// montage est indispensable : sans ca un test herite de l'etat du precedent.
enum EtatAppli {
  /// Premier lancement : rien n'est fait, rien n'est telecharge. La garde
  /// renvoie tout sur `/onboarding`.
  premierLancement(onboarding: false, sentiers: false),

  /// Accueil passe, aucun sentier telecharge. La garde renvoie le coeur de
  /// l'appli sur `/catalog` et le reste sur `/no-data`.
  sansSentier(onboarding: true, sentiers: false),

  /// Regime normal : accueil passe, un sentier telecharge. Rien n'est redirige.
  enRoute(onboarding: true, sentiers: true);

  const EtatAppli({required this.onboarding, required this.sentiers});

  final bool onboarding;
  final bool sentiers;

  void appliquer() {
    hasCompletedOnboarding = onboarding;
    hasDownloadedTrails = sentiers;
  }
}

// ---------------------------------------------------------------------------
// Monter l'application REELLE
// ---------------------------------------------------------------------------

/// Monte l'application avec son VRAI routeur et se pose sur [depart].
///
/// [depart] `null` = l'entree reelle de l'application (`initialLocation`), donc
/// exactement ou un utilisateur arrive en ouvrant l'icone.
///
/// Aucun `ProviderScope.overrides` : les providers de production tournent, les
/// donnees de sentier embarquees sont lues, la garde de redirection s'applique.
/// C'est le point : si un ecran ne se monte qu'avec six providers simules, ce
/// n'est pas un ecran que l'utilisateur atteint.
Future<void> monterAppliReelle(
  WidgetTester tester, {
  String? depart,
  EtatAppli etat = EtatAppli.enRoute,
  Map<String, Object> prefs = const {},
}) async {
  etat.appliquer();
  _erreursCaptees.clear();
  _detournerLesErreursDeRendu();
  brancherLesPlugins();
  SharedPreferences.setMockInitialValues(prefs);
  // La taille d'un telephone courant : un ecran trop petit fait deborder des
  // textes et fausse la lecture des gestes disponibles.
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  if (depart != null) appRouter.go(depart);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    ),
  );
  await stabiliser(tester);
}

// ---------------------------------------------------------------------------
// LE TELEPHONE DE CE TEST : un appareil qui ne sait rien faire de sortant
// ---------------------------------------------------------------------------

/// Branche des reponses aux canaux de plateforme utilises par l'application.
///
/// POURQUOI, ET C'EST LA DECOUVERTE LA PLUS COUTEUSE DU LOT X (tache 579).
/// Dans un test de widgets, le temps est FEINT : `tester.pump` avance des
/// minuteurs simules, il ne fait pas tourner la boucle d'evenements reelle. Or
/// c'est cette boucle-la qui rapporte la reponse d'un canal de plateforme. Sans
/// interlocuteur declare, un appel a `launchUrl`, `Share.share`,
/// `getApplicationDocumentsDirectory` ou `Geolocator` NE REVIENT JAMAIS : il ne
/// leve pas, il ne rend pas, il reste suspendu jusqu'a la fin du test.
///
/// Consequence directe sur la mesure : tout bouton dont l'action commence par un
/// appel de plugin etait declare MORT par l'invariante — « Partager », « Voir le
/// site », « Telecharger », « Demarrer le test ». Et il l'etait a tort : sur un
/// telephone, ces appels reviennent. On mesurait un gel de l'environnement de
/// test, pas un defaut de l'application.
///
/// CE QU'ON MODELISE ICI est un appareil HONNETE ET DEMUNI : il repond toujours,
/// et il repond « je ne sais pas faire ». Aucune application capable d'ouvrir un
/// lien, aucune feuille de partage, aucun service de localisation. C'est le pire
/// telephone plausible — exactement celui sur lequel un bouton muet se voit. Le
/// stockage local, lui, REPOND VRAIMENT (un dossier temporaire) : il existe sur
/// tous les appareils, et le simuler en panne masquerait les vrais parcours.
void brancherLesPlugins() {
  final messager =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void repondre(String canal, Future<Object?> Function(MethodCall) reponse) {
    messager.setMockMethodCallHandler(MethodChannel(canal), reponse);
    addTearDown(
      () => messager.setMockMethodCallHandler(MethodChannel(canal), null),
    );
  }

  // Aucune application ne peut ouvrir un lien ni composer un numero. Le
  // `url_launcher` rend `false` — c'est son contrat quand rien ne peut ouvrir
  // l'URL — et l'ecran doit le DIRE a l'utilisateur.
  repondre('plugins.flutter.io/url_launcher', (appel) async => false);

  // Aucune feuille de partage : l'appel echoue, et l'echec doit se voir.
  repondre('dev.fluttercommunity.plus/share', (appel) async {
    throw PlatformException(
      code: 'indisponible',
      message: 'aucune application de partage sur cet appareil',
    );
  });

  // Pas de service de localisation. Le test de marche doit l'annoncer au lieu
  // de rester fige sur son ecran d'accueil.
  Future<Object?> pasDeGps(MethodCall appel) async {
    switch (appel.method) {
      case 'isLocationServiceEnabled':
        return false;
      case 'checkPermission':
      case 'requestPermission':
        return 0; // LocationPermission.denied
      default:
        return null;
    }
  }

  for (final canal in const [
    'flutter.baseflow.com/geolocator',
    'flutter.baseflow.com/geolocator_android',
    'flutter.baseflow.com/geolocator_apple',
  ]) {
    repondre(canal, pasDeGps);
  }

  // Le stockage local existe (dossier temporaire reel) : c'est le cas sur tout
  // appareil, et le simuler absent ferait echouer des parcours pour une raison
  // qui n'arrive jamais en vrai.
  final dossier = Directory.systemTemp
      .createTempSync('stepways_parcours_reel_')
      .path;
  repondre('plugins.flutter.io/path_provider', (appel) async => dossier);
  repondre('plugins.flutter.io/path_provider_android', (appel) async => dossier);
}

/// Demonte l'application PROPREMENT a la fin d'un test.
///
/// Les flux Drift des providers posent un minuteur en se fermant : si l'arbre
/// est detruit par le cadre de test sans qu'on lui laisse le temps de le
/// declencher, `flutter test` echoue sur « Pending timers » — un echec qui
/// n'apprend rien sur l'application. On demonte donc dans le test, puis on pompe
/// assez pour que ces minuteurs s'eteignent.
Future<void> demonterAppli(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  _ramasser(tester);
  await tester.pump(const Duration(seconds: 1));
  _ramasser(tester);
  restaurerLesErreursDeRendu();
}

/// Laisse l'ecran se poser SANS `pumpAndSettle`.
///
/// `pumpAndSettle` boucle indefiniment sur un ecran qui anime en continu (la
/// carte, un indicateur de chargement, un degrade qui respire) et fait echouer
/// le test pour une raison qui n'a rien a voir avec ce qu'il verifie. On pompe
/// donc un nombre BORNE de fois.
Future<void> stabiliser(WidgetTester tester, {int coups = 6}) async {
  for (var i = 0; i < coups; i++) {
    await tester.pump(const Duration(milliseconds: 120));
    _ramasser(tester);
  }
}

/// Va sur [chemin] dans l'application deja montee, et laisse l'ecran se poser.
Future<void> allerA(WidgetTester tester, String chemin) async {
  appRouter.go(chemin);
  await stabiliser(tester);
}

/// Remet l'application sur [chemin] en fermant ce qu'un geste a pu ouvrir.
///
/// Un dialogue ou une feuille modale est pousse sur le navigateur racine :
/// `go()` ne le referme pas. On le fait donc sauter par le geste retour du
/// systeme, au plus deux fois, avant de renavigeur.
///
/// LES MESSAGES SONT BALAYES AUSSI (tache 579). Un `SnackBar` vit quatre
/// secondes et ne part pas avec `handlePopRoute` : celui qu'un geste vient
/// d'afficher etait donc TOUJOURS LA quand le geste suivant etait mesure,
/// present avant comme apres — donc invisible dans la comparaison, et le geste
/// suivant declare mort. C'est la mesure qui mentait, pas le bouton.
Future<void> revenirSurLaRoute(WidgetTester tester, String chemin) async {
  fermerLesMessages(tester);
  for (var i = 0; i < 2 && messageOuDialogueVisible(tester); i++) {
    await tester.binding.handlePopRoute();
    await stabiliser(tester, coups: 2);
  }
  appRouter.go(chemin);
  await stabiliser(tester, coups: 3);
  erreursDeRendu(tester);
}

/// Retire les messages (`SnackBar`) encore affiches, sans attendre leur duree.
void fermerLesMessages(WidgetTester tester) {
  for (final m
      in tester.stateList<ScaffoldMessengerState>(
        find.byType(ScaffoldMessenger),
      )) {
    m.clearSnackBars();
  }
}

/// Amene [f] SOUS LE DOIGT : fait defiler l'ecran jusqu'a lui si besoin.
///
/// POURQUOI CE PAS EN PLUS, ET IL EST DECISIF (tache 579). Un ecran de
/// preparation mesure deux mille pixels de haut ; le telephone en montre sept
/// cent quatre-vingts. « Sauvegarder », « Valider mon sac », « Voir mon
/// diplome », le choix de la main dominante etaient TOUS sous la ligne de
/// flottaison. Le balayage tapait leurs coordonnees reelles — donc dans le
/// vide, bien en dessous de la vitre — et `warnIfMissed: false` avalait
/// l'echec : l'ecran ne changeait pas, le bouton etait declare mort. CINQ des
/// douze routes rouges du LOT X etaient ce defaut de mesure, pas un defaut de
/// l'application. Un utilisateur, lui, fait defiler avant d'appuyer.
///
/// Retourne `false` quand le geste reste hors de l'ecran malgre le defilement
/// (aucun `Scrollable` parent, ou position figee) : l'appelant le declare alors
/// NON JOUE. Jamais mort — on ne condamne pas un bouton qu'on n'a pas presse.
Future<bool> amenerALEcran(WidgetTester tester, Finder f) async {
  if (!_existe(f)) return false;
  if (estSousLeDoigt(tester, f)) return true;
  try {
    await tester.ensureVisible(f);
    await stabiliser(tester, coups: 2);
  } catch (_) {
    return false;
  }
  return _existe(f) && estSousLeDoigt(tester, f);
}

/// Le geste designe par [f] est-il ENCORE dans l'arbre ?
///
/// Un finder de RANG (`find.byType(X).at(3)`) ne rend pas une liste vide quand
/// l'ecran s'est raccourci : il LEVE un `RangeError`. Le defilement peut
/// justement raccourcir une liste paresseuse, donc ce cas arrive.
bool _existe(Finder f) {
  try {
    return f.evaluate().isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// UN DOIGT POSE AU CENTRE DE [f] ATTEINDRAIT-IL VRAIMENT [f] ?
///
/// PAS « son centre est-il dans l'ecran » — ce raccourci s'est fait prendre
/// (tache 579). Le bouton « J'ai lu ces conseils » se posait a cheval sur le
/// haut de la page : son centre tombait trois pixels sous le bord, donc « dans
/// l'ecran », mais SOUS LA BARRE DE TITRE. L'appui touchait la barre, le bouton
/// ne recevait rien, et il etait declare mort. Seul un test de collision reel
/// repond a la question : on pose le doigt, et on regarde ce qu'il rencontre.
///
/// La pile de collision va de la feuille vers la racine ; on remonte les parents
/// de chaque element touche, car l'appui atterrit souvent sur un descendant (le
/// texte du bouton) et non sur le bouton lui-meme.
bool estSousLeDoigt(WidgetTester tester, Finder f) {
  final RenderObject? cible;
  final Offset centre;
  try {
    cible = f.evaluate().first.renderObject;
    centre = tester.getCenter(f);
  } catch (_) {
    return false;
  }
  if (cible == null) return false;
  final resultat = HitTestResult();
  tester.binding.hitTestInView(resultat, centre, tester.view.viewId);
  for (final entree in resultat.path) {
    final touche = entree.target;
    if (touche is! RenderObject) continue;
    RenderObject? noeud = touche;
    while (noeud != null) {
      if (identical(noeud, cible)) return true;
      noeud = noeud.parent;
    }
  }
  return false;
}

/// Le chemin REELLEMENT affiche (apres application des gardes de redirection).
///
/// C'est la difference entre « le bouton a navigue » et « l'utilisateur est
/// arrive » : `go('/catalog')` suivi d'une garde qui renvoie sur `/onboarding`
/// laisse cette valeur a `/onboarding`.
String cheminAffiche() {
  final config = appRouter.routerDelegate.currentConfiguration;
  return config.uri.path;
}

// ---------------------------------------------------------------------------
// Lire ce que l'ecran montre
// ---------------------------------------------------------------------------

/// Le journal des erreurs de rendu, vide a chaque montage.
final List<String> _erreursCaptees = <String>[];

/// Detourne les erreurs de rendu vers [_erreursCaptees], UNE PAR UNE.
///
/// POURQUOI PAS `tester.takeException()`. Quand une meme passe de mise en page
/// produit trois debordements, le cadre de test les regroupe et ne rend qu'un
/// resume — « Multiple exceptions (3) were detected » — ou la NATURE des erreurs
/// a disparu : impossible de distinguer trois textes qui debordent d'un ecran qui
/// plante. En se placant sur [FlutterError.onError], on recoit chaque erreur avec
/// son message, donc son diagnostic.
///
/// Rien n'est avale en douce : tout ce qui est capte est rendu par
/// [erreursDeRendu], et c'est au test d'en decider. Un test qui ne regarde pas
/// ce journal est un test qui ferme les yeux — exactement ce que ce lot corrige.
void Function(FlutterErrorDetails)? _handlerDOrigine;

void _detournerLesErreursDeRendu() {
  _handlerDOrigine ??= FlutterError.onError;
  final precedent = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    _erreursCaptees.add(msg.length > 600 ? msg.substring(0, 600) : msg);
    // SEULS les debordements sont retenus ici. Tout le reste est RENVOYE au
    // cadre de test : un ecran qui plante doit faire echouer son test, et le
    // cadre verifie d'ailleurs qu'on ne lui vole pas ses erreurs (il leve
    // « A test overrode FlutterError.onError » si on garde tout).
    if (!estDebordement(msg)) precedent?.call(details);
  };
  addTearDown(restaurerLesErreursDeRendu);
}

/// Rend `FlutterError.onError` au cadre de test.
///
/// A APPELER AVANT TOUT `expect` : le cadre refuse qu'un test appelle `expect`
/// alors qu'il detient encore le gestionnaire d'erreurs. [demonterAppli] le fait,
/// c'est la raison pour laquelle chaque test demonte avant de conclure.
void restaurerLesErreursDeRendu() {
  if (_handlerDOrigine != null) FlutterError.onError = _handlerDOrigine;
}

/// Ramasse aussi ce que le cadre de test aurait mis de cote malgre tout.
void _ramasser(WidgetTester tester) {
  while (true) {
    final e = tester.takeException();
    if (e == null) break;
    final msg = e.toString();
    _erreursCaptees.add(msg.length > 600 ? msg.substring(0, 600) : msg);
  }
}

/// Vide et rend les erreurs de rendu vues depuis le montage.
///
/// Un debordement de texte (`A RenderFlex overflowed by 117 pixels`) arrive ici.
/// Les laisser s'accumuler fait echouer le test sur la premiere venue, sans dire
/// lesquelles ; les collecter permet de les RAPPORTER TOUTES.
List<String> erreursDeRendu(WidgetTester tester) {
  _ramasser(tester);
  final out = List<String>.of(_erreursCaptees);
  _erreursCaptees.clear();
  return out;
}

/// Une erreur de rendu est-elle un DEBORDEMENT (texte coupe, ligne trop large) ?
bool estDebordement(String erreur) =>
    erreur.contains('overflowed by') || erreur.contains('overflow');

/// Tous les textes VISIBLES a l'ecran, dans l'ordre de l'arbre.
List<String> textesVisibles(WidgetTester tester) {
  final out = <String>[];
  for (final w in tester.widgetList<Text>(find.byType(Text))) {
    final s = w.data ?? w.textSpan?.toPlainText();
    if (s != null && s.trim().isNotEmpty) out.add(s.trim());
  }
  return out;
}

/// Une EMPREINTE de ce que l'utilisateur voit : chemin, textes, icones, champs.
///
/// Sert a repondre a la seule question qui compte pour un bouton : « est-ce que
/// quelque chose a change ? ». Deux empreintes identiques avant et apres un
/// geste, sans message ni dialogue, signifient que le geste n'a rien produit.
/// UNE EMPREINTE VISUELLE, PAS SEULEMENT TEXTUELLE. C'est la lecon du retour 14
/// de Chris (« pas de difference de peau ») et du retour 13 (les numeros d'etape
/// caches) : la campagne LISAIT les textes sans REGARDER l'ecran. Un choix de
/// selection — km ou mi, une categorie de commerce, un onglet — ne change pas les
/// textes affiches : il en change la COULEUR et la GRAISSE. Une empreinte qui
/// ignore la couleur declarerait morts des boutons qui marchent, et une
/// invariante qui crie au loup ne sert plus a rien.
String empreinteEcran(WidgetTester tester) {
  final textes = <String>[];
  for (final w in tester.widgetList<Text>(find.byType(Text))) {
    final s = w.data ?? w.textSpan?.toPlainText() ?? '';
    textes.add('$s#${w.style?.color?.toARGB32() ?? '-'}'
        '#${w.style?.fontWeight?.value ?? '-'}');
  }
  final icones = tester
      .widgetList<Icon>(find.byType(Icon))
      .map((i) => '${i.icon?.codePoint ?? '?'}#${i.color?.toARGB32() ?? '-'}')
      .toList();
  final fonds = tester.widgetList<Container>(find.byType(Container)).map((c) {
    final deco = c.decoration;
    final fond = deco is BoxDecoration ? deco.color : null;
    final bord = deco is BoxDecoration ? deco.border?.top.color : null;
    return '${c.color?.toARGB32() ?? '-'}/${fond?.toARGB32() ?? '-'}'
        '/${bord?.toARGB32() ?? '-'}';
  }).toList();
  final champs = tester
      .widgetList<EditableText>(find.byType(EditableText))
      .map((e) => e.controller.text)
      .toList();
  final interrupteurs = tester
      .widgetList<Switch>(find.byType(Switch))
      .map((s) => s.value.toString())
      .toList();
  final coches = tester
      .widgetList<Checkbox>(find.byType(Checkbox))
      .map((c) => c.value.toString())
      .toList();
  // LES SELECTEURS. Choisir « mi » a la place de « km » ne change aucun texte :
  // ca change la SELECTION d'un `SegmentedButton`. Sans cette ligne, les quatre
  // boutons d'unites des reglages seraient declares morts alors qu'ils marchent.
  final selections = <String>[
    for (final w in tester.allWidgets)
      if (w is SegmentedButton) 'seg:${w.selected.join('+')}'
      else if (w is ToggleButtons) 'tog:${w.isSelected.join('+')}'
      else if (w is ChoiceChip) 'cho:${w.selected}'
      else if (w is FilterChip) 'fil:${w.selected}'
      else if (w is Tab) 'tab:${w.text}',
  ];
  return '${cheminAffiche()}|T${textes.join('~')}|I${icones.join(',')}'
      '|F${fonds.join(',')}|C${champs.join('~')}'
      '|S${interrupteurs.join(',')}|K${coches.join(',')}'
      '|X${selections.join(',')}';
}

/// Vrai si un message, un dialogue ou une feuille vient d'apparaitre.
///
/// Un geste qui ouvre un `SnackBar` ou un dialogue a produit un effet meme si le
/// fond de l'ecran n'a pas bouge.
bool messageOuDialogueVisible(WidgetTester tester) =>
    tester.any(find.byType(SnackBar)) ||
    tester.any(find.byType(Dialog)) ||
    tester.any(find.byType(AlertDialog)) ||
    tester.any(find.byType(BottomSheet)) ||
    tester.any(find.byType(PopupMenuButton)) &&
        tester.any(find.byType(PopupMenuItem));

// ---------------------------------------------------------------------------
// Les gestes disponibles a l'ecran
// ---------------------------------------------------------------------------

/// Un geste que l'utilisateur peut faire : un bouton, une tuile, une carte.
class GesteDisponible {
  GesteDisponible({
    required this.libelle,
    required this.type,
    required this.finder,
  });

  /// Ce que l'utilisateur lit sur le geste (texte du bouton, ou le nom de son
  /// icone a defaut). C'est le libelle qui apparait dans un rapport d'echec :
  /// « le bouton "Parcourir le catalogue" ne produit rien ».
  final String libelle;

  /// Le type de widget, pour distinguer un bouton d'une tuile de liste.
  final String type;

  /// De quoi retrouver CE geste apres un nouveau montage.
  ///
  /// C'est un rang dans son type (`find.byType(IconButton).at(3)`) et non une
  /// recherche par texte : un bouton a icone n'a pas de texte, et deux boutons
  /// peuvent porter le meme libelle. Le rang est stable d'un montage a l'autre
  /// puisque le meme ecran rend le meme arbre.
  final Finder finder;

  @override
  String toString() => '$type "$libelle"';
}

/// Le vocabulaire des gestes qu'on ne tape PAS automatiquement.
///
/// Un balayage qui tape tout finirait par effacer le compte, quitter la
/// randonnee ou declencher un appel d'urgence. Ces gestes sont testes
/// NOMMEMENT ailleurs (LOT J a LOT O pour l'effacement) ; ici on les saute et on
/// le DIT — un saut silencieux serait un trou de plus.
const gestesEvites = <String>[
  'supprim',
  'effac',
  'delete',
  'desinstall',
  'quitter',
  'terminer la rando',
  'abandonner',
  'appeler',
  'appel',
  '112',
  '15',
  'deconnex',
  'reinitialis',
  'sos',
  // LE VOCABULAIRE DOIT COUVRIR LES CINQ LANGUES. Mesure du 26/09 : l'ecran de
  // profil s'affichait en espagnol pendant le balayage et « Eliminar mi cuenta »
  // a ete tape, parce que la liste ne connaissait que le francais. Un garde qui
  // ne parle qu'une langue n'est pas un garde.
  'eliminar',
  'borrar',
  'borrad',
  'löschen',
  'loschen',
  'cancella',
  'elimina',
  'remove',
  'wipe',
  'llamar',
  'anrufen',
  'chiamare',
];

/// Les gestes SANS TEXTE qu'on ne tape pas non plus : ils n'ont qu'une icone.
///
/// LE TROU QUE LE LOT X A TROUVE (tache 579). Le garde [gestesEvites] lit un
/// LIBELLE. Le bouton d'appel de l'ecran d'urgence n'en a pas : c'est un
/// `IconButton` nu, et son libelle de rapport est « icone-58530 ». Aucun mot de
/// la liste ne s'y trouve — le balayage a donc APPELE le numero d'urgence, et
/// l'a fait a chaque execution. Un garde qui ne sait pas lire une icone n'est
/// pas un garde, exactement comme celui qui ne parlait que francais (tache 573).
/// Ces gestes sont testes NOMMEMENT (cf. `test/comportement/`).
final Set<int> iconesEvitees = <int>{
  Icons.phone.codePoint,
  Icons.phone_in_talk.codePoint,
  Icons.call.codePoint,
  Icons.local_phone.codePoint,
  Icons.sos.codePoint,
  Icons.emergency.codePoint,
  Icons.delete.codePoint,
  Icons.delete_outline.codePoint,
  Icons.delete_forever.codePoint,
};

bool estGesteEvite(String libelle) {
  final l = libelle.toLowerCase();
  if (gestesEvites.any(l.contains)) return true;
  final code = int.tryParse(
    l.startsWith('icone-') ? l.substring('icone-'.length) : '',
  );
  return code != null && iconesEvitees.contains(code);
}

/// Le geste designe par [f] appartient-il a un SELECTEUR (un groupe d'options
/// dont une seule est active a la fois) ?
///
/// POURQUOI CETTE QUESTION. Appuyer sur « km » quand « km » est deja choisi ne
/// change rien, et c'est NORMAL. Sans cette distinction, les quatre boutons
/// d'unites des reglages seraient declares morts — et une invariante qui crie au
/// loup finit desactivee, donc inutile.
bool estDansUnSelecteur(Finder f) {
  final els = f.evaluate();
  if (els.isEmpty) return false;
  var trouve = false;
  els.first.visitAncestorElements((a) {
    final w = a.widget;
    if (w is SegmentedButton ||
        w is ToggleButtons ||
        w is TabBar ||
        w is ChoiceChip ||
        w is FilterChip) {
      trouve = true;
      return false;
    }
    return true;
  });
  return trouve;
}

/// Enumere les gestes VISIBLES et ACTIFS de l'ecran courant.
///
/// « Actif » veut dire que le widget porte un callback non nul : un bouton
/// grise (`onPressed: null`) est un refus assume, pas un geste mort. « Visible »
/// veut dire present dans l'arbre rendu — on ne tape pas ce qui est hors ecran.
List<GesteDisponible> gestesDisponibles(WidgetTester tester) {
  final out = <GesteDisponible>[];
  final vus = <String>{};

  String libelleDe(Element e) {
    // Le texte porte par le sous-arbre du geste, sinon son icone.
    final textes = <String>[];
    void visiter(Element child) {
      final w = child.widget;
      if (w is Text) {
        final s = w.data ?? w.textSpan?.toPlainText();
        if (s != null && s.trim().isNotEmpty) textes.add(s.trim());
      }
      child.visitChildren(visiter);
    }

    e.visitChildren(visiter);
    if (textes.isNotEmpty) return textes.join(' / ');
    final icones = <String>[];
    void visiterIcones(Element child) {
      final w = child.widget;
      if (w is Icon && w.icon != null) {
        icones.add('icone-${w.icon!.codePoint}');
      }
      child.visitChildren(visiterIcones);
    }

    e.visitChildren(visiterIcones);
    if (icones.isNotEmpty) return icones.first;
    final semantics = e.widget.key?.toString();
    return semantics ?? 'sans libelle';
  }

  void collecter<T extends Widget>(bool Function(T w) actif) {
    final finder = find.byType(T);
    final elements = finder.evaluate().toList();
    for (var i = 0; i < elements.length; i++) {
      final e = elements[i];
      if (!actif(e.widget as T)) continue;
      final libelle = libelleDe(e);
      final cle = '$T|$libelle';
      if (!vus.add(cle)) continue;
      out.add(GesteDisponible(
        libelle: libelle,
        type: T.toString(),
        finder: find.byType(T).at(i),
      ));
    }
  }

  collecter<ElevatedButton>((w) => w.onPressed != null);
  collecter<FilledButton>((w) => w.onPressed != null);
  collecter<OutlinedButton>((w) => w.onPressed != null);
  collecter<TextButton>((w) => w.onPressed != null);
  collecter<IconButton>((w) => w.onPressed != null);
  collecter<FloatingActionButton>((w) => w.onPressed != null);
  collecter<ListTile>((w) => w.onTap != null);
  collecter<InkWell>((w) => w.onTap != null);
  return out;
}

// ---------------------------------------------------------------------------
// Les routes de l'application, lues sur le routeur (jamais recopiees)
// ---------------------------------------------------------------------------

/// Une route telle que le routeur la declare.
class RouteDeclaree {
  const RouteDeclaree({required this.gabarit, required this.nom});

  /// Le chemin COMPLET avec ses parametres : `/trail/:id/weather`.
  final String gabarit;

  /// Le nom GoRouter, quand la route en a un.
  final String? nom;

  @override
  String toString() => gabarit;
}

/// Toutes les routes declarees, sous-routes comprises, lues sur [appRouter].
///
/// LE POINT CAPITAL : cette liste est LUE, jamais recopiee. Le jour ou
/// quelqu'un ajoute un ecran et sa route, il entre ici tout seul — et les trois
/// invariantes du LOT V le couvrent sans que personne y pense. Le test de
/// routage existant (`app_router_test.dart`) recopie au contraire la liste a la
/// main : il dit ce qu'on a ecrit, pas ce qu'on peut atteindre.
List<RouteDeclaree> routesDeclarees() {
  final out = <RouteDeclaree>[];
  void descendre(List<RouteBase> routes, String prefixe) {
    for (final r in routes) {
      if (r is GoRoute) {
        final chemin = r.path.startsWith('/')
            ? r.path
            : '${prefixe == '/' ? '' : prefixe}/${r.path}';
        out.add(RouteDeclaree(gabarit: chemin, nom: r.name));
        if (r.routes.isNotEmpty) descendre(r.routes, chemin);
      } else if (r is ShellRouteBase) {
        descendre(r.routes, prefixe);
      }
    }
  }

  descendre(appRouter.configuration.routes, '/');
  return out;
}

/// Les valeurs de parametres utilisees pour rendre un gabarit CONCRET.
///
/// Ce sont les donnees REELLES embarquees dans l'application (le sentier
/// Mare a Mare Centre et sa premiere etape), pas des valeurs inventees : une
/// route testee avec un identifiant bidon peut tomber sur un ecran vide et
/// passer pour saine.
const parametresReels = <String, String>{
  'id': 'mare-a-mare-centre',
  'num': '1',
  'code': 'TESTCODE',
  'guideId': 'corte',
};

/// Rend un gabarit concret en substituant [parametresReels].
///
/// Retourne `null` quand un parametre du gabarit n'a pas de valeur reelle
/// connue : mieux vaut declarer le trou que tester un chemin invente.
String? cheminConcret(String gabarit) {
  final segments = gabarit.split('/');
  final out = <String>[];
  for (final s in segments) {
    if (!s.startsWith(':')) {
      out.add(s);
      continue;
    }
    final v = parametresReels[s.substring(1)];
    if (v == null) return null;
    out.add(v);
  }
  return out.join('/');
}
