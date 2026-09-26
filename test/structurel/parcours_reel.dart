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

import 'package:flutter/material.dart';
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
Future<void> revenirSurLaRoute(WidgetTester tester, String chemin) async {
  for (var i = 0; i < 2 && messageOuDialogueVisible(tester); i++) {
    await tester.binding.handlePopRoute();
    await stabiliser(tester, coups: 2);
  }
  appRouter.go(chemin);
  await stabiliser(tester, coups: 3);
  erreursDeRendu(tester);
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

bool estGesteEvite(String libelle) {
  final l = libelle.toLowerCase();
  return gestesEvites.any(l.contains);
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
