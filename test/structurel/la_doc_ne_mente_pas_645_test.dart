import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LA DOCUMENTATION DU DEPOT DIT LA VERITE SUR CE QU ELLE
/// CITE (StepWays tache 645-12, livre de bord du depot).
///
/// POURQUOI CETTE GARDE EXISTE, ET LA PREUVE EST DANS LE DEPOT. Au 04/10/2026,
/// `docs/CONTRIBUTING.md`, `docs/README.md` et `docs/ADR/003-riverpod-over-bloc.md`
/// annoncaient encore Riverpod 2.6 alors que `pubspec.yaml` etait en
/// `flutter_riverpod` ^3.3.2 depuis la migration. La doc perimee avait deja
/// induit en erreur. Un document que rien ne verifie devient faux, et il
/// devient faux EN SILENCE. Le precedent est
/// `codemagic_entete_ne_mente_pas_619_test.dart`, qui fait la meme chose pour
/// l en-tete de `codemagic.yaml` ; cette garde en suit la forme.
///
/// CE QUE LA GARDE EXIGE, EN TROIS POINTS :
///
///   (a) toute version de paquet citee dans `docs/` (un nom de paquet de
///       `pubspec.yaml` suivi d un numero, ou un nom d usage comme
///       « Riverpod 3.3.2 ») EST celle du depot : une contrainte `^X.Y.Z` est
///       celle de `pubspec.yaml`, un numero nu est celui de `pubspec.lock` ou
///       de la contrainte ;
///   (b) chaque ligne de lot de `docs/JOURNAL.md` porte un numero en base
///       `#NNNNNN`, ou la mention exacte « a completer par Skynet » — jamais
///       un trou muet ; et chaque lot du plan 644-03 y a sa ligne ;
///   (c) chaque chiffre de `docs/architecture.md` marque par un commentaire
///       HTML `audit:<cle>` est celui que donne `tool/audit_global.py` sur
///       l arbre courant (sections `arborescence` et `couches`), relance par
///       le test lui-meme.
void main() {
  group('645-12 — la doc ne ment pas', () {
    test('(a) toute version de paquet citee dans docs/ est celle de '
        'pubspec.yaml ou de pubspec.lock', () {
      final contraintes = contraintesDuPubspec(
        File('pubspec.yaml').readAsLinesSync(),
      );
      final resolues = versionsDuLock(File('pubspec.lock').readAsStringSync());
      expect(
        contraintes,
        contains('flutter_riverpod'),
        reason: 'pubspec.yaml non lu : le format du fichier a change',
      );
      expect(
        resolues,
        contains('flutter_riverpod'),
        reason: 'pubspec.lock non lu : le format du fichier a change',
      );

      final citations = <Citation>[];
      for (final fichier in documentsVerifies()) {
        final lignes = fichier.readAsLinesSync();
        for (var i = 0; i < lignes.length; i++) {
          citations.addAll(
            citationsDeLaLigne(
              lignes[i],
              contraintes.keys.toSet(),
              '${normal(fichier.path)}:${i + 1}',
            ),
          );
        }
      }

      // Une garde qui ne trouve rien a verifier passe au vert sur un motif
      // mort. docs/architecture.md cite flutter_riverpod : il doit etre vu.
      expect(
        citations.where((c) => c.paquet == 'flutter_riverpod'),
        isNotEmpty,
        reason:
            'aucune citation de flutter_riverpod trouvee dans docs/ : le '
            'motif de lecture est casse, la garde ne verifie plus rien',
      );

      final fausses = <String>[];
      for (final c in citations) {
        final contrainte = contraintes[c.paquet];
        final resolue = resolues[c.paquet];
        if (!citationVraie(c, contrainte, resolue)) {
          fausses.add(
            '${c.ou} : « ${c.texte} » cite ${c.paquet} '
            '${c.caret ? '^' : ''}${c.version}, or pubspec.yaml dit '
            '${contrainte ?? 'rien'} et pubspec.lock dit ${resolue ?? 'rien'}',
          );
        }
      }
      expect(
        fausses,
        isEmpty,
        reason:
            'la doc cite des versions qui ne sont pas celles du depot :\n'
            '${fausses.join('\n')}',
      );
    });

    test('(b) chaque ligne de lot du journal porte son numero en base, ou '
        '« $aCompleter »', () {
      final journal = File('docs/JOURNAL.md');
      expect(journal.existsSync(), isTrue, reason: 'docs/JOURNAL.md absent');
      final lignes = lignesDeLots(journal.readAsLinesSync());
      expect(
        lignes,
        isNotEmpty,
        reason: 'aucune ligne de lot sous « ## Lots » : le format a change',
      );

      final dateValide = RegExp(r'^\d{2}/\d{2}/\d{4}$');
      final numero = RegExp(r'#\d{6}(?!\d)');
      final fautives = <String>[];
      for (final l in lignes) {
        final cellules = cellulesDe(l);
        if (cellules.length != 4) {
          fautives.add('ligne a ${cellules.length} colonnes au lieu de 4 : $l');
          continue;
        }
        if (!dateValide.hasMatch(cellules[0])) {
          fautives.add('date illisible « ${cellules[0]} » : $l');
        }
        if (cellules[1].isEmpty) fautives.add('lot sans nom : $l');
        final numeros = cellules[3];
        if (!numero.hasMatch(numeros) && !numeros.contains(aCompleter)) {
          fautives.add(
            'lot « ${cellules[1]} » sans numero en base ni '
            '« $aCompleter » : $l',
          );
        }
      }
      expect(
        fautives,
        isEmpty,
        reason:
            'un lot du journal sans numero est un trou muet :\n'
            '${fautives.join('\n')}',
      );
    });

    test('(b) chaque lot du plan 644-03 a sa ligne dans le journal', () {
      final plan = File(
        'docs/assainissement/644-03-decoupage-et-plan.md',
      ).readAsLinesSync();
      final titre = RegExp(r'^### (?:Lot )?(645-[0-9A-Za-z]+) ');
      final lotsDuPlan = <String>{
        for (final l in plan)
          if (titre.firstMatch(l) case final m?) m.group(1)!,
      };
      expect(
        lotsDuPlan,
        contains('645-12'),
        reason: 'fiches du plan non lues : le format des titres a change',
      );

      final journal = lignesDeLots(
        File('docs/JOURNAL.md').readAsLinesSync(),
      ).map((l) => cellulesDe(l)[1]).toSet();
      final absents = lotsDuPlan.difference(journal).toList()..sort();
      expect(
        absents,
        isEmpty,
        reason:
            'ces lots du plan n ont pas de ligne dans docs/JOURNAL.md : '
            '${absents.join(', ')}',
      );
    });

    test('(c) les chiffres marques de docs/architecture.md sont ceux de '
        'tool/audit_global.py sur l arbre courant', () {
      final doc = File('docs/architecture.md').readAsStringSync();
      final marques = chiffresMarques(doc);
      final balises = RegExp(r'<!-- audit:').allMatches(doc).length;
      expect(
        marques.length,
        balises,
        reason:
            'une balise audit: n est pas precedee d un chiffre : elle ne '
            'verifie rien',
      );
      // Un document dont on aurait retire les balises passerait au vert.
      expect(
        marques.length,
        greaterThanOrEqualTo(20),
        reason:
            'moins de 20 chiffres marques dans docs/architecture.md : les '
            'balises ont ete retirees, et plus rien n y est verifie',
      );

      final rapport = lancerAudit();
      final faux = <String>[];
      for (final m in marques) {
        final mesure = resoudre(rapport, m.cle);
        if (mesure == null) {
          faux.add('cle introuvable dans l audit : ${m.cle}');
        } else if (mesure != m.valeur) {
          faux.add('${m.cle} : la doc dit ${m.valeur}, l audit mesure $mesure');
        }
      }
      expect(
        faux,
        isEmpty,
        reason:
            'docs/architecture.md ne dit plus le reel mesure ; relancer '
            'python3 tool/audit_global.py --rapide et corriger :\n'
            '${faux.join('\n')}',
      );
    });
  });
}

/// La mention exacte d un numero en base que Skynet n a pas encore fourni.
const aCompleter = 'a completer par Skynet';

/// Les dossiers de `docs/` exclus de (a), et pourquoi.
///
/// `docs/assainissement/` porte les documents DATES de l audit 644 et de son
/// plan (30/09 au 04/10/2026). Ils citent volontairement l etat passe — y
/// compris la phrase « annoncaient Riverpod 2.6 » qui est l origine de cette
/// garde. Les reecrire au present falsifierait la trace de l audit.
const dossiersExclus = <String>['docs/assainissement/'];

/// Les noms d usage qui designent un paquet dans la prose.
const nomsDUsage = <String, String>{
  'Riverpod': 'flutter_riverpod',
  'GoRouter': 'go_router',
  'Drift': 'drift',
  'Freezed': 'freezed',
  'Slang': 'slang',
  'Melos': 'melos',
};

String normal(String p) => p.replaceAll(r'\', '/');

/// Les `.md` de `docs/`, hors [dossiersExclus], tries.
List<File> documentsVerifies() {
  final fichiers = <File>[];
  for (final e in Directory('docs').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.md')) continue;
    final chemin = normal(e.path);
    if (dossiersExclus.any(chemin.startsWith)) continue;
    fichiers.add(e);
  }
  fichiers.sort((a, b) => a.path.compareTo(b.path));
  return fichiers;
}

/// Les paquets VERSIONNES de `pubspec.yaml` et leur contrainte.
///
/// Un paquet tire du SDK, d un chemin ou de git n a pas de version dans
/// `pubspec.yaml` : il n est pas verifiable, donc pas retenu.
Map<String, String> contraintesDuPubspec(List<String> lignes) {
  final sections = {'dependencies:', 'dev_dependencies:'};
  final cle = RegExp(
    r'''^  ([a-z0-9_]+):\s*["']?([^"'\s#][^"'#]*?)["']?\s*$''',
  );
  final res = <String, String>{};
  var dedans = false;
  for (final l in lignes) {
    if (l.startsWith('#')) continue;
    if (RegExp(r'^\S').hasMatch(l)) {
      dedans = sections.contains(l.trim());
      continue;
    }
    if (!dedans) continue;
    final m = cle.firstMatch(l);
    if (m != null && RegExp(r'\d').hasMatch(m.group(2)!)) {
      res[m.group(1)!] = m.group(2)!.trim();
    }
  }
  return res;
}

/// Les versions resolues de `pubspec.lock`.
Map<String, String> versionsDuLock(String texte) {
  final res = <String, String>{};
  final bloc = RegExp(
    r'^  ([a-z0-9_]+):\n(?:    .*\n)*?    version: "([^"]+)"',
    multiLine: true,
  );
  for (final m in bloc.allMatches(texte)) {
    res[m.group(1)!] = m.group(2)!;
  }
  return res;
}

/// Une version citee : ou, quel paquet, quel numero, avec ou sans `^`.
class Citation {
  Citation(this.ou, this.paquet, this.version, this.caret, this.texte);

  final String ou;
  final String paquet;
  final String version;
  final bool caret;
  final String texte;
}

final _version = RegExp(r'(\^?)v?(\d+(?:\.\d+)+)(?![\d.]*\d)');

/// Les versions citees par [ligne] pour un paquet de [paquets] ou un nom
/// d usage de [nomsDUsage].
///
/// Deux formes : un nom suivi de sa version (`flutter_riverpod ^3.3.2`,
/// « Riverpod 3.3.2 », `` `go_router` ^13.0.0 ``), et une ligne de tableau dont
/// la premiere cellule est un nom de paquet — chaque version de la ligne est
/// alors la sienne.
List<Citation> citationsDeLaLigne(
  String ligne,
  Set<String> paquets,
  String ou,
) {
  final res = <Citation>[];
  final noms = <String, String>{for (final p in paquets) p: p, ...nomsDUsage};
  for (final entree in noms.entries) {
    final motif = RegExp(
      '(?<![A-Za-z0-9_])${RegExp.escape(entree.key)}(?![A-Za-z0-9_])'
      r'[`*\s:(]*(\^?)v?(\d+(?:\.\d+)+)(?![\d.]*\d)',
    );
    for (final m in motif.allMatches(ligne)) {
      res.add(
        Citation(ou, entree.value, m.group(2)!, m.group(1) == '^', m.group(0)!),
      );
    }
  }
  if (ligne.trimLeft().startsWith('|')) {
    final cellules = cellulesDe(ligne);
    if (cellules.isNotEmpty) {
      final nom = cellules.first.replaceAll('`', '').trim();
      final paquet = paquets.contains(nom) ? nom : nomsDUsage[nom];
      if (paquet != null) {
        for (final cellule in cellules.skip(1)) {
          for (final m in _version.allMatches(cellule)) {
            res.add(
              Citation(ou, paquet, m.group(2)!, m.group(1) == '^', ligne),
            );
          }
        }
      }
    }
  }
  return res;
}

/// Vrai si [c] dit la version du depot.
///
/// `^X.Y.Z` est une contrainte : elle doit etre MOT POUR MOT celle de
/// `pubspec.yaml`. Un numero nu est une version : il doit etre le debut de la
/// version resolue dans `pubspec.lock`, ou de celle de la contrainte
/// (« 3.3 » vaut pour 3.3.2, « 2.6 » ne vaut pas pour 3.3.2).
bool citationVraie(Citation c, String? contrainte, String? resolue) {
  if (contrainte == null) return false;
  if (c.caret) return contrainte == '^${c.version}';
  bool debutDe(String? v) {
    if (v == null) return false;
    final cite = c.version.split('.');
    final reel = v.replaceFirst('^', '').split(RegExp(r'[.+-]'));
    if (cite.length > reel.length) return false;
    for (var i = 0; i < cite.length; i++) {
      if (cite[i] != reel[i]) return false;
    }
    return true;
  }

  return debutDe(resolue) || debutDe(contrainte);
}

/// Les cellules d une ligne de tableau Markdown, sans les bords.
List<String> cellulesDe(String ligne) {
  var l = ligne.trim();
  if (l.startsWith('|')) l = l.substring(1);
  if (l.endsWith('|')) l = l.substring(0, l.length - 1);
  return l.split('|').map((c) => c.trim()).toList();
}

/// Les lignes du tableau de la section « ## Lots » du journal, hors en-tete.
List<String> lignesDeLots(List<String> lignes) {
  final res = <String>[];
  var dedans = false;
  for (final l in lignes) {
    if (l.startsWith('## ')) {
      dedans = l.trim() == '## Lots';
      continue;
    }
    if (!dedans || !l.trimLeft().startsWith('|')) continue;
    final cellules = cellulesDe(l);
    if (cellules.first == 'Date') continue;
    if (cellules.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))) continue;
    res.add(l);
  }
  return res;
}

/// Un chiffre de la doc et la cle de l audit qui doit le redonner.
class ChiffreMarque {
  ChiffreMarque(this.valeur, this.cle);

  final int valeur;
  final String cle;
}

/// Les chiffres suivis d un commentaire HTML `audit:<cle>`.
///
/// Le separateur de milliers est l espace fine insecable (U+202F), et lui
/// seul : deux nombres voisins separes d une espace ordinaire ne peuvent pas
/// etre lus comme un seul.
List<ChiffreMarque> chiffresMarques(String doc) {
  final motif = RegExp(r'(\d{1,3}(?: \d{3})+|\d+)\**\s*<!-- audit:(.+?) -->');
  return [
    for (final m in motif.allMatches(doc))
      ChiffreMarque(
        int.parse(m.group(1)!.replaceAll(' ', '')),
        m.group(2)!.trim(),
      ),
  ];
}

/// Relance `tool/audit_global.py` (arborescence et couches) et lit son JSON.
///
/// L interpreteur s appelle `python3` sous Linux et macOS, `python` ou
/// `py -3` sous Windows : le premier qui produit le JSON est retenu. Aucun ne
/// marche = ECHEC, pas un test ignore : une doc inverifiable n est pas une
/// doc verifiee.
Map<String, dynamic> lancerAudit() {
  final dossier = Directory.systemTemp.createTempSync('audit_645_12_');
  final sortie = File('${dossier.path}/audit.json');
  final essais = <List<String>>[
    ['python3'],
    ['python'],
    ['py', '-3'],
  ];
  final echecs = <String>[];
  try {
    for (final essai in essais) {
      try {
        final r = Process.runSync(
          essai.first,
          [
            ...essai.skip(1),
            'tool/audit_global.py',
            '--section',
            'arborescence',
            '--section',
            'couches',
            '--json-out',
            sortie.path,
          ],
          environment: {'PYTHONIOENCODING': 'utf-8'},
        );
        if (r.exitCode == 0 && sortie.existsSync()) {
          return jsonDecode(sortie.readAsStringSync()) as Map<String, dynamic>;
        }
        echecs.add('${essai.join(' ')} : code ${r.exitCode} ${r.stderr}');
      } on ProcessException catch (e) {
        echecs.add('${essai.join(' ')} : ${e.message}');
      }
    }
  } finally {
    dossier.deleteSync(recursive: true);
  }
  fail(
    'tool/audit_global.py n a pas pu etre lance, donc docs/architecture.md '
    'ne peut pas etre verifie :\n${echecs.join('\n')}',
  );
}

final _filtre = RegExp(r'\[(!?)~([^\]]+)\]');

/// La valeur que [rapport] donne pour [cle], ou `null` si la cle n existe pas.
///
/// La cle est un chemin pointe dans le JSON (`couches.nombre_croisements`).
/// Un segment numerique indexe une liste. Un segment qui finit par `*`
/// additionne les entrees dont la cle commence ainsi
/// (`arborescence.detail_lib.lib/core/*.fichiers`). Au bout du chemin, une
/// liste vaut sa longueur ; `[~motif]` puis `[!~motif]` ne gardent que les
/// entrees qui correspondent, ou non, a l expression reguliere.
int? resoudre(Map<String, dynamic> rapport, String cle) {
  final crochet = cle.indexOf('[');
  final chemin = crochet < 0 ? cle : cle.substring(0, crochet);
  final filtres = crochet < 0
      ? const <RegExpMatch>[]
      : _filtre.allMatches(cle.substring(crochet)).toList();

  int? marcher(Object? noeud, List<String> segments) {
    if (segments.isEmpty) {
      if (noeud is int) return noeud;
      if (noeud is List) {
        var elements = noeud.whereType<String>().toList();
        for (final f in filtres) {
          final rx = RegExp(f.group(2)!);
          final garder = f.group(1) != '!';
          elements = elements.where((e) => rx.hasMatch(e) == garder).toList();
        }
        return filtres.isEmpty ? noeud.length : elements.length;
      }
      return null;
    }
    final s = segments.first;
    final reste = segments.sublist(1);
    if (s.endsWith('*') && noeud is Map) {
      final prefixe = s.substring(0, s.length - 1);
      var somme = 0;
      var vu = false;
      for (final e in noeud.entries) {
        if (!(e.key as String).startsWith(prefixe)) continue;
        final v = marcher(e.value, reste);
        if (v == null) return null;
        somme += v;
        vu = true;
      }
      return vu ? somme : null;
    }
    if (noeud is List) {
      final i = int.tryParse(s);
      if (i == null || i < 0 || i >= noeud.length) return null;
      return marcher(noeud[i], reste);
    }
    if (noeud is Map && noeud.containsKey(s)) return marcher(noeud[s], reste);
    return null;
  }

  return marcher(rapport, chemin.split('.'));
}
