// LECTURE DES SOURCES POUR LES GARDES DE PLAFOND DU LOT 645 (tache 645-01).
//
// POURQUOI UN FICHIER PARTAGE, ET POURQUOI IL NE DEPEND DE RIEN. Les sept
// gardes de ce lot mesurent toutes la MEME arborescence, et une mesure qui
// differe d'une garde a l'autre ne vaut rien : deux plafonds calcules sur deux
// definitions de « fichier source » ne sont pas comparables. Le decoupage des
// sources vit donc ici, une fois, et les sept gardes l'appellent.
//
// IL N'IMPORTE NI `flutter_test` NI LE CODE DE L'APPLICATION. Les gardes de ce
// lot sont des lectures de fichiers, pas des montages de widgets : rien a
// monter, rien a pomper. C'est ce qui les rend instantanees et ce qui les rend
// executables meme quand `lib/` ne compile pas — exactement le moment ou l'on
// a le plus besoin de savoir ce qu'il contient.
library;

import 'dart:io';

/// Les zones autorisees a la racine de `lib/` (ECR-13).
///
/// `domain` EST ENTRE LE 02/10/2026, PAR DECISION DE CHRISTOPHE (voie A du lot
/// 645-05, verbatim « Option. A » puis « A »). C'est la maison des modeles que
/// PLUSIEURS features lisent : tant qu'elle n'existait pas, un modele partage
/// devait habiter chez l'une d'elles, et les autres l'atteignaient par un
/// croisement interdit. La convention redevient vraie par le rangement, pas en
/// baissant la regle.
const zonesRacineAutorisees = <String>{
  'core',
  'domain',
  'features',
  'shared',
  'i18n',
  'main.dart',
};

/// Les suffixes des fichiers produits par la generation de code.
///
/// Ils sont exclus de toutes les mesures de qualite : personne ne les ecrit a
/// la main, et les compter reviendrait a reprocher au depot le style de ses
/// generateurs.
const suffixesGeneres = <String>[
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.config.dart',
];

/// Vrai si [chemin] est produit par la generation de code.
bool estGenere(String chemin) => suffixesGeneres.any((s) => chemin.endsWith(s));

String _normal(String p) => p.replaceAll(r'\', '/');

/// Les `.dart` sous [racine], en chemins relatifs au depot, TRIES.
///
/// Le tri n'est pas cosmetique : la garde de code mort attribue chaque symbole
/// au PREMIER fichier qui le declare, et un ordre de parcours dependant du
/// systeme de fichiers rendrait ses rapports irreproductibles.
List<String> listerDart(String racine, {bool avecGeneres = false}) {
  final dir = Directory(racine);
  if (!dir.existsSync()) return const <String>[];
  final trouves = <String>[];
  for (final entite in dir.listSync(recursive: true)) {
    if (entite is! File) continue;
    final chemin = _normal(entite.path);
    if (!chemin.endsWith('.dart')) continue;
    if (chemin.contains('/.dart_tool/') || chemin.contains('/build/')) {
      continue;
    }
    if (!avecGeneres && estGenere(chemin)) continue;
    trouves.add(chemin);
  }
  trouves.sort();
  return trouves;
}

/// Les `.dart` source de `lib/`, hors code genere.
List<String> sourcesLib({bool avecGeneres = false}) =>
    listerDart('lib', avecGeneres: avecGeneres);

/// Le contenu de [rel], en UTF-8 tolerant.
String lireSource(String rel) =>
    File(rel).readAsStringSync(); // ignore: avoid_slow_async_io

/// Les lignes de [rel], sans fin de ligne.
List<String> lignesDe(String rel) => File(rel).readAsLinesSync();

/// Vrai si [ligne] est une ligne de COMMENTAIRE et non de code.
///
/// Les gardes qui cherchent des motifs dans le code doivent l'appeler : un
/// defaut EXPLIQUE dans un commentaire n'est pas un defaut livre, et sans ce
/// filtre la documentation de la garde elle-meme la ferait rougir.
bool estLigneDeCommentaire(String ligne) {
  final nue = ligne.trimLeft();
  return nue.startsWith('//') || nue.startsWith('*');
}

/// LES IDENTIFIANTS D'UN SOURCE DART, HORS CHAINES ET HORS COMMENTAIRES.
///
/// POURQUOI LES CHAINES ET LES COMMENTAIRES SORTENT. La garde de code mort
/// demande « ce nom est-il CITE quelque part ? ». Un nom ecrit dans un
/// commentaire ne cite rien : il en parle. Un nom dans une chaine de
/// caracteres ne l'appelle pas non plus. Les laisser entrer permettrait
/// d'eteindre la garde en ECRIVANT LE NOM DU SYMBOLE MORT dans sa propre
/// documentation — c'est le defaut qu'avait deja connu
/// `tout_ecran_a_une_route_573_test.dart` (tache 580, Y2).
///
/// `(?<!:)//` preserve les `//` des URL : `'https://...'` n'est pas un
/// commentaire, et l'amputer ferait disparaitre de vraies citations.
List<String> identifiants(String source) {
  var texte = source.replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '');
  texte = texte.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ');
  texte = texte.replaceAll(RegExp(r'(?<!:)//.*$', multiLine: true), '');
  texte = texte.replaceAll(
    RegExp("'''.*?'''|\"\"\".*?\"\"\"", dotAll: true),
    ' ',
  );
  texte = texte.replaceAll(RegExp(r"'(?:\\.|[^'\\])*'"), ' ');
  texte = texte.replaceAll(RegExp(r'"(?:\\.|[^"\\])*"'), ' ');
  return RegExp(
    r'[A-Za-z_][A-Za-z0-9_]*',
  ).allMatches(texte).map((m) => m.group(0)!).toList();
}

/// LE NOM DU PAQUETTAGE, LU DANS `pubspec.yaml` ET JAMAIS DEVINE.
///
/// Il sert a resoudre les imports `package:<nom>/...` vers un chemin de
/// `lib/`. Le coder en dur serait une bombe a retardement : le jour d'un
/// renommage, la garde des couches cesserait de resoudre quoi que ce soit et
/// passerait au VERT en ne mesurant plus rien.
String nomDuPaquet() {
  for (final ligne in lignesDe('pubspec.yaml')) {
    final m = RegExp(r'^name:\s*([A-Za-z_][A-Za-z0-9_]*)').firstMatch(ligne);
    if (m != null) return m.group(1)!;
  }
  throw StateError('nom du paquet introuvable dans pubspec.yaml');
}

/// LA CIBLE D'UN IMPORT, RAMENEE A UN CHEMIN DU DEPOT — OU `null`.
///
/// `null` pour `dart:` et pour les paquets tiers : ils ne designent aucun
/// fichier du depot, et les compter dans une mesure de couches n'aurait pas
/// de sens.
///
/// POURQUOI LA RESOLUTION EST FAITE POUR DE VRAI. Un import relatif ne dit pas
/// ce qu'il atteint : depuis `lib/features/trek/presentation/map/`, le chemin
/// `../../domain/models/stage.dart` designe `lib/features/trek/domain/...`,
/// c'est-a-dire LA MEME feature. Comparer les segments du texte de l'import au
/// lieu de sa cible resolue fait prendre `domain` et `providers` pour des noms
/// de features voisines — voir l'en-tete de
/// `couches_respectees_645_test.dart`, qui mesure ce que cela coute.
String? cibleDeLImport(String fichier, String import, String paquet) {
  if (import.startsWith('dart:')) return null;
  if (import.startsWith('package:$paquet/')) {
    return 'lib/${import.substring('package:$paquet/'.length)}';
  }
  if (import.startsWith('package:')) return null;
  final segments = <String>[];
  final base = fichier.split('/')..removeLast();
  for (final s in [...base, ...import.split('/')]) {
    if (s == '.' || s.isEmpty) continue;
    if (s == '..') {
      if (segments.isNotEmpty) segments.removeLast();
      continue;
    }
    segments.add(s);
  }
  return segments.join('/');
}

/// Les cibles des directives `import` de [source].
Iterable<String> importsDe(String source) => RegExp(
  '''import\\s+['"]([^'"]+)['"]''',
).allMatches(source).map((m) => m.group(1)!);
