// LE GRAPHE DE NAVIGATION DE L'APPLICATION (tache 573, LOT V).
//
// CE QU'IL REPOND. « Depuis l'icone de l'application, quels ecrans un doigt
// peut-il atteindre ? » Aucun test du depot ne savait repondre a cette question,
// et c'est pour ca que trois fonctions entieres ont vecu sans porte d'entree
// pendant des semaines : l'ecran d'urgence (aucun `push('/emergency')` dans tout
// `lib/`), la fiche medicale (joignable UNIQUEMENT depuis cet ecran
// inatteignable, donc inatteignable elle aussi), la boutique de cartes
// (`pack_store_screen.dart` ecrit, sans meme une route declaree).
//
// COMMENT IL EST CONSTRUIT, et pourquoi de cette facon. On lit le code source
// plutot que de taper 49 ecrans a la main, pour UNE raison : l'exhaustivite. Un
// balayage a la main teste ce a quoi on a pense ; une lecture du source teste
// tout, y compris l'ecran que quelqu'un ajoutera demain. Les trois sources :
//
//   1. LES ROUTES viennent du routeur lui-meme, a l'execution (jamais recopiees).
//   2. LES ECRANS de chaque route viennent de `app_router.dart`, lu comme texte.
//   3. LES GESTES de navigation viennent de tout `lib/` : chaque `context.go`,
//      `context.push`, `goNamed`, `pushNamed` est une ARETE du graphe.
//
// LA PARTIE DELICATE, ET ELLE EST TRAITEE. Un geste de navigation ne vit pas
// toujours dans un fichier d'ecran : la carte du HUB, l'entete partagee, une
// tuile reutilisee portent des `push` pour le compte des ecrans qui les
// affichent. Une arete trouvee dans un widget partage est donc attribuee aux
// ecrans qui IMPORTENT ce widget, en remontant le graphe des imports jusqu'a
// tomber sur des fichiers qui portent une route. Sans cette remontee, la moitie
// des portes de l'application passerait pour inexistante.
//
// CE QUE CE GRAPHE NE VOIT PAS, et il faut le dire. Un chemin calcule a
// l'execution (`context.go(variableCalculeeAilleurs)`) est invisible a une
// lecture de source. Les aretes non resolues sont donc COMPTEES et rapportees :
// un chemin dynamique vers une route la rendrait atteignable sans que le graphe
// le sache. C'est la limite honnete de la methode — et elle se voit, au lieu de
// se cacher.
library;

import 'dart:io';

import 'package:moteur_gr/core/routing/app_router.dart';

import 'parcours_reel.dart';

// ---------------------------------------------------------------------------
// Lecture des sources
// ---------------------------------------------------------------------------

/// Tous les fichiers Dart de `lib/`, hors code genere.
///
/// Le code genere (`*.g.dart`, `*.freezed.dart`) ne contient pas de navigation
/// et represente la moitie du volume : l'exclure rend le balayage lisible.
List<File> fichiersSourceLib() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    throw StateError('lib/ introuvable depuis ${Directory.current.path}');
  }
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .map((f) => File(_normal(f.path)))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _normal(String p) => p.replaceAll('\\', '/');

/// LE CODE SANS SES COMMENTAIRES — parce qu'UN COMMENTAIRE N'EST PAS UNE PORTE.
///
/// POURQUOI CETTE FONCTION EXISTE (tache 580, Y2). L'invariante V2 declare
/// qu'un ecran est atteignable des qu'un AUTRE fichier de `lib/` cite son nom :
/// c'est la facon d'attraper les ecrans ouverts en modale, qui n'ont pas de
/// route. Mais le balayage lisait le fichier ENTIER, commentaires compris. Une
/// simple phrase de documentation — « ce libelle ne vivait que sur
/// `TelEcranScreen` » — suffisait donc a declarer joignable un ecran que
/// personne ne peut ouvrir. La garde pouvait etre eteinte en ECRIVANT SON NOM.
/// Le defaut a ete trouve en le declenchant : la doc du refus global (Y1) cite
/// l'ecran d'accueil du consentement, et l'invariante a aussitot considere cet
/// ecran comme cable.
///
/// CE QU'ELLE PRESERVE : les CHAINES. `'/trail/$id/weather'` et
/// `"https://..."` restent intacts — y compris les chaines contenant `//`,
/// qu'un retrait naif de commentaires amputerait, faisant disparaitre de
/// vraies portes.
String sansCommentaires(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      final fin = source.indexOf('\n', i);
      if (fin < 0) break;
      out.write('\n');
      i = fin + 1;
      continue;
    }
    if (source.startsWith('/*', i)) {
      final fin = source.indexOf('*/', i + 2);
      out.write(' ');
      i = fin < 0 ? source.length : fin + 2;
      continue;
    }
    final delim = _delimiteurDeChaine(source, i);
    if (delim != null) {
      final fin = _finDeChaine(source, i, delim);
      out.write(source.substring(i, fin));
      i = fin;
      continue;
    }
    out.write(source[i]);
    i++;
  }
  return out.toString();
}

/// Le delimiteur de la chaine qui COMMENCE en [i], `null` si aucune.
String? _delimiteurDeChaine(String s, int i) {
  var j = i;
  if (s[j] == 'r') {
    // `r` n'est un prefixe de chaine brute que s'il ne termine pas un
    // identifiant (`super`, `color`, une variable nommee `r`...).
    final avant = i == 0 ? '' : s[i - 1];
    if (RegExp(r'[\w$]').hasMatch(avant)) return null;
    j++;
    if (j >= s.length) return null;
  }
  final q = s[j];
  if (q != "'" && q != '"') return null;
  final triple = q * 3;
  return s.startsWith(triple, j) ? triple : q;
}

/// L'index qui suit la chaine commencant en [i] avec le delimiteur [delim].
int _finDeChaine(String s, int i, String delim) {
  final brute = s[i] == 'r';
  var j = i + (brute ? 1 : 0) + delim.length;
  while (j < s.length) {
    if (!brute && s[j] == r'\') {
      j += 2;
      continue;
    }
    if (s.startsWith(delim, j)) return j + delim.length;
    j++;
  }
  return s.length;
}

/// Resout un import RELATIF (`'widgets/x.dart'`, `'../../core/y.dart'`) vers un
/// chemin de depot (`lib/...`).
///
/// Ecrit a la main plutot que via `Uri` : sous Windows, `File.uri` melange les
/// separateurs et prefixe le chemin, et une resolution fausse ici rendrait
/// INVISIBLES tous les gestes portes par les widgets partages — donc la moitie
/// des portes de l'application.
String resoudreRelatif(String fichierSource, String relatif) {
  final base = _normal(fichierSource).split('/')..removeLast();
  for (final seg in relatif.split('/')) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (base.isNotEmpty) base.removeLast();
      continue;
    }
    base.add(seg);
  }
  return base.join('/');
}

/// Les classes de widget definies par fichier : `MaClasse` -> `lib/.../x.dart`.
Map<String, String> classesDeWidgetParFichier(List<File> fichiers) {
  final re = RegExp(
    r'class\s+(\w+)\s+extends\s+'
    r'(StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget|'
    r'HookWidget|HookConsumerWidget)\b',
  );
  final out = <String, String>{};
  for (final f in fichiers) {
    final src = f.readAsStringSync();
    for (final m in re.allMatches(src)) {
      out[m.group(1)!] = f.path;
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Quel ECRAN derriere quelle ROUTE
// ---------------------------------------------------------------------------

/// Associe chaque route declaree aux fichiers qui la CONSTRUISENT.
///
/// METHODE, et elle est auto-verifiante. `app_router.dart` declare ses routes
/// dans l'ordre, chaque `path:` etant suivi de son `builder` puis, s'il y en a,
/// de ses sous-routes. C'est exactement l'ordre d'un parcours en profondeur du
/// routeur a l'execution. On peut donc APPARIER la i-eme occurrence textuelle de
/// `path:` avec la i-eme route du parcours, et attribuer a cette route les
/// classes citees entre son `path:` et le suivant.
///
/// Si l'appariement derapait (une refonte du fichier, une route construite
/// autrement), les deux comptes differeraient et [routesEtLeursFichiers] leve :
/// le test echoue bruyamment au lieu de rendre un graphe faux.
Map<String, Set<String>> routesEtLeursFichiers(
  List<RouteDeclaree> routes,
  Map<String, String> classeVersFichier,
) {
  final src = File('lib/core/routing/app_router.dart').readAsStringSync();
  final lignes = src.split('\n');

  // Les lignes qui declarent un chemin, dans l'ordre du fichier.
  final indices = <int>[];
  final rePath = RegExp(r"""^\s*path:\s*['"]""");
  for (var i = 0; i < lignes.length; i++) {
    if (rePath.hasMatch(lignes[i])) indices.add(i);
  }
  if (indices.length != routes.length) {
    throw StateError(
      'appariement route/source rompu : ${indices.length} declarations '
      "'path:' dans app_router.dart pour ${routes.length} routes au "
      'routeur. Le graphe de navigation ne peut pas etre construit sans '
      'corriger cette lecture.',
    );
  }

  final reClasse = RegExp(r'\b([A-Z_]\w*Screen|[A-Z_]\w*Page|[A-Z_]\w*View)\b');
  final out = <String, Set<String>>{};
  for (var i = 0; i < indices.length; i++) {
    final debut = indices[i];
    final fin = i + 1 < indices.length ? indices[i + 1] : lignes.length;
    final bloc = lignes.sublist(debut, fin).join('\n');
    final fichiers = <String>{};
    for (final m in reClasse.allMatches(bloc)) {
      final f = classeVersFichier[m.group(1)!];
      if (f != null) fichiers.add(f);
    }
    out[routes[i].gabarit] = fichiers;
  }
  return out;
}

/// Les routes qui ne construisent AUCUN ecran : elles ne font que rediriger.
///
/// `/trails` est de celles-la — un alias historique qui renvoie sur `/catalog`.
/// Exiger un ecran ou une porte pour une redirection pure serait un faux
/// positif, et un faux positif rend une invariante inutilisable.
Set<String> routesDeRedirectionPure(List<RouteDeclaree> routes) {
  final src = File('lib/core/routing/app_router.dart').readAsStringSync();
  final lignes = src.split('\n');
  final indices = <int>[];
  final rePath = RegExp(r"""^\s*path:\s*['"]""");
  for (var i = 0; i < lignes.length; i++) {
    if (rePath.hasMatch(lignes[i])) indices.add(i);
  }
  if (indices.length != routes.length) return const <String>{};
  final out = <String>{};
  for (var i = 0; i < indices.length; i++) {
    final fin = i + 1 < indices.length ? indices[i + 1] : lignes.length;
    final bloc = lignes.sublist(indices[i], fin).join('\n');
    final construit = bloc.contains('builder:') || bloc.contains('pageBuilder:');
    if (!construit && bloc.contains('redirect:')) out.add(routes[i].gabarit);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Les gestes de navigation = les aretes
// ---------------------------------------------------------------------------

/// Une arete : un geste de navigation trouve dans un fichier.
class AreteNavigation {
  const AreteNavigation({
    required this.fichier,
    required this.ligne,
    required this.geste,
    required this.cible,
    required this.parNom,
  });

  /// Le fichier qui porte le geste.
  final String fichier;
  final int ligne;

  /// `go`, `push`, `replace`, `pushReplacement`...
  final String geste;

  /// Le gabarit de route vise, ou le nom GoRouter quand [parNom].
  final String cible;
  final bool parNom;

  @override
  String toString() => '$fichier:$ligne $geste -> $cible';
}

/// Normalise un chemin ecrit dans le code vers un GABARIT de route.
///
/// `'/trail/${trail.id}/weather'` et `'/trail/$id/weather'` designent la meme
/// route que `/trail/:id/weather` : toute interpolation devient un parametre.
String gabaritDe(String chemin) {
  var s = chemin;
  s = s.replaceAll(RegExp(r'\$\{[^}]*\}'), ':p');
  s = s.replaceAll(RegExp(r'\$\w+'), ':p');
  // Une eventuelle chaine de requete ne fait pas partie de la route.
  final q = s.indexOf('?');
  if (q >= 0) s = s.substring(0, q);
  if (s.length > 1 && s.endsWith('/')) s = s.substring(0, s.length - 1);
  return s;
}

/// Deux gabarits designent-ils la meme route ? (un parametre vaut un parametre)
bool memeRoute(String a, String b) {
  final sa = a.split('/');
  final sb = b.split('/');
  if (sa.length != sb.length) return false;
  for (var i = 0; i < sa.length; i++) {
    final pa = sa[i].startsWith(':');
    final pb = sb[i].startsWith(':');
    if (pa || pb) continue;
    if (sa[i] != sb[i]) return false;
  }
  return true;
}

/// Tous les gestes de navigation de `lib/`.
///
/// Les formes couvertes sont celles que le depot emploie reellement :
/// `context.go/push/replace/pushReplacement` et leurs variantes `...Named`,
/// appelees sur `context`, sur `GoRouter.of(context)` ou sur un routeur garde
/// en variable.
({List<AreteNavigation> aretes, List<String> nonResolues}) aretesDeNavigation(
  List<File> fichiers,
) {
  final aretes = <AreteNavigation>[];
  final nonResolues = <String>[];

  // Chemin litteral : go('/x'), push("/x"), pushReplacement('/x')...
  final reChemin = RegExp(
    r'\.(go|push|replace|pushReplacement)\(\s*'
    r"""(['"])(/[^'"]*)\2""",
  );
  // GESTE INDIRECT : une route litterale passee a un rappel ou a une aide dont
  // le NOM evoque la navigation — `onOpenStep('/trail/$id/walk-test')`,
  // `_goToCatalog('/catalog')`, `naviguerVers('/settings')`. Sans cette famille,
  // l'invariante crierait au loup sur des routes reellement atteignables : le
  // parcours guide de la faisabilite ouvre ses trois etapes de cette facon.
  final reIndirect = RegExp(
    r'\b\w*(?:[Oo]pen|[Pp]ush|[Gg]o[A-Z]|[Nn]avig|[Rr]oute)\w*\(\s*'
    r"""(['"])(/[^'"]*)\1""",
  );
  // Par nom : goNamed('x'), pushNamed('x'), replaceNamed('x')...
  final reNom = RegExp(
    r'\.(goNamed|pushNamed|replaceNamed|pushReplacementNamed)\(\s*'
    r"""(['"])([^'"]+)\2""",
  );
  // Un geste de navigation dont la cible n'est PAS une chaine litterale :
  // invisible a une lecture de source, donc compte et rapporte.
  final reDynamique = RegExp(
    r"""\.(go|push|goNamed|pushNamed)\(\s*(?!['"])[A-Za-z_]""",
  );

  for (final f in fichiers) {
    // Le routeur lui-meme ne « navigue » pas : ses `go` sont des redirections
    // de garde, deja couvertes par [redirectForPath].
    if (f.path.endsWith('core/routing/app_router.dart')) continue;
    final lignes = f.readAsStringSync().split('\n');
    for (var i = 0; i < lignes.length; i++) {
      final l = lignes[i];
      if (l.trimLeft().startsWith('//') || l.trimLeft().startsWith('///')) {
        continue;
      }
      for (final m in reChemin.allMatches(l)) {
        aretes.add(AreteNavigation(
          fichier: f.path,
          ligne: i + 1,
          geste: m.group(1)!,
          cible: gabaritDe(m.group(3)!),
          parNom: false,
        ));
      }
      for (final m in reIndirect.allMatches(l)) {
        aretes.add(AreteNavigation(
          fichier: f.path,
          ligne: i + 1,
          geste: 'indirect',
          cible: gabaritDe(m.group(2)!),
          parNom: false,
        ));
      }
      for (final m in reNom.allMatches(l)) {
        aretes.add(AreteNavigation(
          fichier: f.path,
          ligne: i + 1,
          geste: m.group(1)!,
          cible: m.group(3)!,
          parNom: true,
        ));
      }
      if (reDynamique.hasMatch(l)) {
        nonResolues.add('${f.path}:${i + 1} ${l.trim()}');
      }
    }
  }
  return (aretes: aretes, nonResolues: nonResolues);
}

// ---------------------------------------------------------------------------
// Le graphe des imports : a qui appartient un geste porte par un widget partage
// ---------------------------------------------------------------------------

/// Pour chaque fichier, les fichiers de `lib/` qui l'IMPORTENT.
Map<String, Set<String>> importeursParFichier(List<File> fichiers) {
  final chemins = fichiers.map((f) => f.path).toSet();
  final out = <String, Set<String>>{};
  final reImport = RegExp(r"""^\s*import\s+['"]([^'"]+)['"]""");
  for (final f in fichiers) {
    for (final l in f.readAsStringSync().split('\n')) {
      final m = reImport.firstMatch(l);
      if (m == null) continue;
      final brut = m.group(1)!;
      String? cible;
      if (brut.startsWith('package:moteur_gr/')) {
        cible = 'lib/${brut.substring('package:moteur_gr/'.length)}';
      } else if (!brut.startsWith('package:') && !brut.startsWith('dart:')) {
        cible = resoudreRelatif(f.path, brut);
      }
      if (cible == null || !chemins.contains(cible)) continue;
      (out[cible] ??= <String>{}).add(f.path);
    }
  }
  return out;
}

/// Les routes AUXQUELLES appartient un geste trouve dans [fichier].
///
/// Si le fichier porte lui-meme une ou plusieurs routes, ce sont celles-la. Sinon
/// on remonte le graphe des imports : un `push` ecrit dans une tuile partagee
/// appartient aux ecrans qui affichent cette tuile.
Set<String> routesPorteusesDuGeste(
  String fichier,
  Map<String, Set<String>> routeVersFichiers,
  Map<String, Set<String>> importeurs,
) {
  Set<String> routesDe(String f) => routeVersFichiers.entries
      .where((e) => e.value.contains(f))
      .map((e) => e.key)
      .toSet();

  final directes = routesDe(fichier);
  if (directes.isNotEmpty) return directes;

  final vus = <String>{fichier};
  final file = <String>[...(importeurs[fichier] ?? const <String>{})];
  final out = <String>{};
  while (file.isNotEmpty) {
    final f = file.removeLast();
    if (!vus.add(f)) continue;
    final r = routesDe(f);
    if (r.isNotEmpty) {
      out.addAll(r);
      // On s'arrete a l'ecran : au-dessus de lui il n'y a plus d'ecran.
      continue;
    }
    file.addAll(importeurs[f] ?? const <String>{});
  }
  return out;
}

// ---------------------------------------------------------------------------
// Les portes d'entree : par ou l'utilisateur ARRIVE, sans avoir rien tape
// ---------------------------------------------------------------------------

/// Les routes ou l'application POSE l'utilisateur d'elle-meme.
///
/// Ce sont les racines du parcours : l'entree du routeur
/// (`initialLocation`) et toutes les destinations que la garde de redirection
/// peut imposer, quel que soit l'etat de l'appli. Elles sont CALCULEES, pas
/// listees : une garde qui gagnerait une destination l'ajouterait ici toute
/// seule.
Set<String> portesDEntree(List<RouteDeclaree> routes) {
  final out = <String>{
    appRouter.routeInformationProvider.value.uri.path,
  };
  final memoOnboarding = hasCompletedOnboarding;
  final memoSentiers = hasDownloadedTrails;
  try {
    for (final etat in EtatAppli.values) {
      etat.appliquer();
      for (final r in routes) {
        final concret = cheminConcret(r.gabarit) ?? r.gabarit;
        final cible = redirectForPath(concret);
        if (cible != null) out.add(gabaritDe(cible));
      }
    }
  } finally {
    hasCompletedOnboarding = memoOnboarding;
    hasDownloadedTrails = memoSentiers;
  }
  return out;
}
