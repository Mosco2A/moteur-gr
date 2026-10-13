// GARDE STRUCTURELLE — DANS `tool/` ET `integration_test/`, NI `flutter` NI
// `dart` NE SE LANCE PAR SON NOM NU (StepWays tache 699).
//
// CE QUE CETTE GARDE EMPECHE DE REVENIR, ET C'EST ARRIVE DEUX FOIS EN DEUX
// JOURS. Le dossier `bin` de Flutter ne contient que `flutter` (un script sh)
// et `flutter.bat` — AUCUN `.exe`. Or `CreateProcess`, l'appel systeme derriere
// `subprocess.run(..., shell=False)` et derriere `Process.run` de Dart, ne
// cherche dans le PATH que le nom EXACT puis le nom + `.exe` : il NE RESOUT NI
// `.bat` NI `.cmd`. C'est `cmd.exe` interactif qui honore `PATHEXT`, pas le
// systeme.
//   * 05/10 18:20 — `gerer_qa('compiler')` du registre Skynet rend FAIL en
//     36 MILLISECONDES sans rien compiler : le build 11 s'arrete avant le
//     bundle (#101301, corrige par le lot infra L8a, #101318) ;
//   * 05/10 21:50 — `python tool/pub_cache_sain.py --pub-get` leve
//     `FileNotFoundError [WinError 2]` avec une trace nue : l'outil ecrit la
//     veille pour serialiser les `pub get` ne peut PAS faire de `pub get` sous
//     Windows (#101332). La garde du lot L8a ne couvrait que les deux fichiers
//     coeur du registre : elle n'a rien vu de celui-ci, dans un autre depot.
// Un defaut qui revient a l'identique dans un autre fichier n'est pas de la
// malchance, c'est une garde qui manque. La voici, et son perimetre est
// NOMME : `tool/` et `integration_test/`, les deux dossiers de ce depot qui
// lancent des processus.
//
// CE QUE LA GARDE EXIGE, EN QUATRE REGLES :
//
//   (A) AUCUNE liste de commande, dans un `.py` du perimetre, ne commence par
//       le nom nu `flutter` ou `dart`. Un nom nu n'a qu'UNE place legitime :
//       argument de la resolution (`resoudre_executable('flutter')`), la ou il
//       DEVIENT un chemin. La regle porte sur la liste, pas sur le site de
//       lancement, et c'est delibere : le defaut du 05/10 construisait la liste
//       dans `main()` et la lancait trois fonctions plus loin, par une
//       variable. Une garde qui n'aurait regarde que `subprocess.run(...)` ne
//       l'aurait pas vu.
//   (B) AUCUN lancement ne passe une CHAINE de commande commencant par
//       `flutter` ou `dart` (la forme `shell=True`), ni un tuple a nom nu.
//   (C) AUCUN fichier qui lance un outil du SDK (donc qui importe la
//       resolution) n'utilise le SHELL. Reparer une resolution de chemin en
//       faisant interpreter la ligne par `cmd.exe` rouvre une injection pour
//       fermer un `WinError 2` : `tool/set_branding.py` le faisait avec
//       `shell=(sys.platform == "win32")`, c'est parti avec le nom nu.
//   (D) AUCUN `.dart` du perimetre ne lance `flutter` ou `dart` par un nom nu
//       (`Process.run`, `Process.runSync`, `Process.start`). Il n'y en a aucun
//       aujourd'hui : la regle est posee avant le premier.
//
// ET LA GARDE SE MESURE ELLE-MEME, parce qu'une garde qui ne voit plus rien
// passe au vert sans rien dire : un cas TEMOIN lui soumet les quatre formes de
// faute et les quatre formes acceptees, et un cas de PERIMETRE verifie qu'elle
// a bien lu les fichiers du depot.
//
// LES SCRIPTS SHELL (`.ps1`, `.sh`) SONT MESURES, PAS REFUSES, ET VOICI
// POURQUOI. `& flutter` en PowerShell et `dart format` en `sh` ne passent pas
// par `CreateProcess` avec un nom nu : PowerShell resout lui-meme la commande
// en honorant `PATHEXT` (donc `flutter.bat`), et un shell POSIX trouve le
// script `flutter` sans suffixe. Le defaut leur est etranger. Mais un
// lanceur de plus doit etre une DECISION, pas un oubli : leur liste est pinnee
// ci-dessous, et la garde rougit si elle change.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les deux dossiers du perimetre.
const perimetre = <String>['tool', 'integration_test'];

/// Les outils du SDK dont le nom nu est refuse.
const outilsSdk = <String>['flutter', 'dart'];

/// Le module de resolution, unique dans `tool/`.
const moduleResolution = 'resolution_executable';

/// LES LANCEURS DE SCRIPTS SHELL CONNUS, ET TOLERES — voir l'en-tete.
///
/// La cle est le chemin, la valeur le nombre de lancements par nom nu. Un
/// changement de ce compte est une DECISION a prendre, pas un detail : si le
/// script devient un `.py`, ou si le lanceur change, la ligne doit bouger ici.
const lanceursShellConnus = <String, int>{
  'tool/gate_format.ps1': 1, // & dart format, PowerShell honore PATHEXT
  'tool/gate_format.sh': 1, // xargs ... dart format, sh trouve le script nu
  'tool/run_persona.ps1': 2, // & flutter build apk, & flutter test
};

void main() {
  group('699 — aucun nom nu pour flutter ou dart', () {
    test('(A et B) aucun fichier Python du perimetre ne porte de nom nu de '
        'flutter ou dart en tete de commande', () {
      final fautes = <String>[];
      for (final f in fichiersDu(perimetre, '.py')) {
        fautes.addAll(fautesPython(f.readAsStringSync(), chemin(f)));
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'un nom nu de flutter ou dart ne se lance pas sous Windows '
            '(CreateProcess ne resout ni .bat ni .cmd) : passez par '
            'resoudre_executable de tool/$moduleResolution.py.\n'
            '${fautes.join('\n')}',
      );
    });

    test('(C) aucun fichier qui lance un outil du SDK ne passe par le '
        'shell', () {
      final fautes = <String>[];
      for (final f in fichiersDu(perimetre, '.py')) {
        final source = f.readAsStringSync();
        if (!source.contains(moduleResolution)) continue;
        fautes.addAll(fautesDeShell(source, chemin(f)));
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'le shell n est pas un correctif de resolution : on resout un '
            'chemin et on garde une liste d arguments.\n${fautes.join('\n')}',
      );
    });

    test('(D) aucun fichier Dart du perimetre ne lance flutter ou dart par un '
        'nom nu', () {
      final fautes = <String>[];
      for (final f in fichiersDu(perimetre, '.dart')) {
        fautes.addAll(fautesDart(f.readAsStringSync(), chemin(f)));
      }
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    });

    test('LE PERIMETRE EST VRAIMENT LU : les fichiers du depot sont la', () {
      final python = fichiersDu(perimetre, '.py').map(chemin).toList();
      final dart = fichiersDu(perimetre, '.dart').map(chemin).toList();
      // Les trois fichiers qui lancent un outil du SDK aujourd hui. S ils
      // disparaissent de la lecture, la garde ne verifie plus le defaut.
      for (final attendu in const [
        'tool/pub_cache_sain.py',
        'tool/audit_global.py',
        'tool/set_branding.py',
      ]) {
        expect(
          python,
          contains(attendu),
          reason: '$attendu n est plus lu : le parcours du perimetre est casse',
        );
      }
      expect(
        python.length,
        greaterThanOrEqualTo(15),
        reason:
            'moins de 15 fichiers Python lus dans ${perimetre.join(' et ')} : '
            'le parcours est casse, la garde ne verifie presque rien',
      );
      expect(
        dart.length,
        greaterThanOrEqualTo(15),
        reason: 'moins de 15 fichiers Dart lus : le parcours est casse',
      );
      // ET LA RESOLUTION EXISTE, EN UN SEUL EXEMPLAIRE.
      expect(
        File('tool/$moduleResolution.py').existsSync(),
        isTrue,
        reason:
            'tool/$moduleResolution.py absent : il n y a plus de resolution a '
            'laquelle renvoyer les appelants',
      );
      final avecResolution = python
          .where(
            (p) =>
                p != 'tool/$moduleResolution.py' &&
                File(p).readAsStringSync().contains(moduleResolution),
          )
          .toList();
      expect(
        avecResolution,
        containsAll(const ['tool/pub_cache_sain.py', 'tool/audit_global.py']),
        reason:
            'les outils qui lancent flutter ou dart doivent passer par la '
            'resolution commune, et non par la leur',
      );
    });

    test('LA GARDE VOIT VRAIMENT LES QUATRE FORMES DE FAUTE, et accepte les '
        'formes resolues', () {
      // Le cas temoin de L8a, repris : sans lui, une garde dont le motif est
      // casse passe au vert sur un depot sain et mentirait le jour du defaut.
      const fautifPython = '''
import subprocess
from resolution_executable import resoudre_executable
def a():
    cmd = ['flutter', 'pub', 'get']
    return subprocess.run(list(cmd), shell=False)
def b():
    return subprocess.run(["dart", "run", "x"], shell=False)
def c():
    return subprocess.run("flutter pub get", shell=True)
def d():
    return subprocess.run(('dart', 'format'), shell=False)
''';
      final vues = fautesPython(fautifPython, 'temoin.py');
      expect(
        vues.length,
        4,
        reason:
            'la garde doit voir les quatre formes (liste, liste a doubles '
            'guillemets, chaine shell, tuple) et elle en voit '
            '${vues.length} :\n${vues.join('\n')}',
      );
      expect(
        fautesDeShell(fautifPython, 'temoin.py'),
        isNotEmpty,
        reason: 'shell=True non vu : la regle (C) ne verifie rien',
      );

      const sainPython = '''
import subprocess
from resolution_executable import resoudre_executable
def a():
    chemin, raison = resoudre_executable('flutter')
    return subprocess.run([chemin, 'pub', 'get'], shell=False)
def b():
    dart, _ = resoudre_executable("dart")
    return subprocess.run([dart, "format", "lib"], shell=False)
def c():
    # Un commentaire qui dit ['flutter', 'pub', 'get'] n est pas un lancement.
    return 0
def d():
    """Et une docstring qui montre subprocess.run(['dart', 'run']) non plus."""
    return subprocess.run(["adb", "-s", "x", "shell"], shell=False)
''';
      expect(
        fautesPython(sainPython, 'temoin.py'),
        isEmpty,
        reason:
            'la garde refuse une forme CORRECTE : elle ferait du bruit et on '
            'finirait par la desarmer.\n'
            '${fautesPython(sainPython, 'temoin.py').join('\n')}',
      );
      expect(fautesDeShell(sainPython, 'temoin.py'), isEmpty);

      const fautifDart = '''
void main() {
  Process.runSync('flutter', const ['pub', 'get']);
  Process.start("dart", const ['format']);
}
''';
      expect(
        fautesDart(fautifDart, 'temoin.dart').length,
        2,
        reason: 'la regle (D) ne voit pas les deux lancements Dart',
      );
      expect(
        fautesDart(
          "void main() { Process.runSync(chemin, const ['pub', 'get']); }",
          'temoin.dart',
        ),
        isEmpty,
      );
    });

    test('LES LANCEURS DE SCRIPTS SHELL SONT CEUX QU ON CONNAIT', () {
      final mesures = <String, int>{};
      for (final ext in const ['.ps1', '.sh', '.bat', '.cmd']) {
        for (final f in fichiersDu(perimetre, ext)) {
          final n = lancementsShell(f.readAsStringSync());
          if (n > 0) mesures[chemin(f)] = n;
        }
      }
      expect(
        mesures,
        lanceursShellConnus,
        reason:
            'la liste des lanceurs par nom nu dans les scripts shell a '
            'change. Ils sont toleres parce que PowerShell et sh resolvent '
            'eux-memes la commande (PATHEXT, script sans suffixe) — un '
            'lanceur de plus doit etre une decision prise, pas un oubli : '
            'mesure $mesures, attendu $lanceursShellConnus',
      );
    });
  });
}

String normal(String p) => p.replaceAll(r'\', '/');

String chemin(File f) => normal(f.path);

/// Les fichiers d extension [ext] sous [dossiers], tries, hors `build/`.
List<File> fichiersDu(List<String> dossiers, String ext) {
  final res = <File>[];
  for (final d in dossiers) {
    final racine = Directory(d);
    if (!racine.existsSync()) continue;
    for (final e in racine.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith(ext)) continue;
      final p = normal(e.path);
      if (p.contains('/build/') || p.contains('/.dart_tool/')) continue;
      res.add(e);
    }
  }
  res.sort((a, b) => a.path.compareTo(b.path));
  return res;
}

/// Le source Python SANS ses commentaires ni ses chaines triples.
///
/// LES CHAINES D UNE SEULE LIGNE SONT GARDEES, et c'est le point : une liste de
/// commande EST faite de chaines d une ligne. Les commentaires et les
/// docstrings, eux, sont de la prose — l'en-tete de `tool/pub_cache_sain.py`
/// RACONTE le defaut, il ne le commet pas.
String pythonSansProse(String src) {
  final out = StringBuffer();
  var i = 0;
  String? delim;
  while (i < src.length) {
    if (delim == null) {
      if (src[i] == '#') {
        while (i < src.length && src[i] != '\n') {
          i++;
        }
        continue;
      }
      if (src.startsWith("'''", i) || src.startsWith('"""', i)) {
        delim = src.substring(i, i + 3);
        i += 3;
        continue;
      }
      if (src[i] == "'" || src[i] == '"') {
        delim = src[i];
        out.write(src[i]);
        i++;
        continue;
      }
      out.write(src[i]);
      i++;
      continue;
    }
    if (src[i] == r'\' && i + 1 < src.length) {
      if (delim.length == 1) out.write(src.substring(i, i + 2));
      i += 2;
      continue;
    }
    if (src.startsWith(delim, i)) {
      if (delim.length == 1) out.write(delim);
      i += delim.length;
      delim = null;
      continue;
    }
    if (delim.length == 1) out.write(src[i]);
    i++;
  }
  return out.toString();
}

/// Le source Dart sans ses commentaires de ligne ni de bloc.
String dartSansCommentaires(String src) => src
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ')
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '')
    .replaceAll(RegExp(r'(?<![:/])//.*$', multiLine: true), '');

final _nomsSdk = outilsSdk.join('|');

/// (A) Une liste de commande qui commence par un nom nu.
final _listeNomNu = RegExp('''\\[\\s*(['"])($_nomsSdk)\\1''');

/// (B) Un lancement dont la commande est une chaine, ou un tuple a nom nu.
final _lancementNomNu = RegExp(
  '''(?:subprocess\\.(?:run|Popen|call|check_call|check_output)|os\\.exec[a-z]*|os\\.spawn[a-z]*)'''
  '''\\s*\\(\\s*(?:\\(\\s*)?(['"])($_nomsSdk)\\b''',
);

/// Les fautes (A) et (B) du source Python [brut].
///
/// La prose est retiree ICI, et pas par l'appelant : une garde dont le
/// nettoyage est optionnel finit par etre appelee sans.
List<String> fautesPython(String brut, String ou) {
  final source = pythonSansProse(brut);
  final res = <String>[];
  for (final m in _listeNomNu.allMatches(source)) {
    res.add(
      '$ou:${ligneDe(source, m.start)} : liste de commande qui commence '
      'par le nom nu « ${m.group(2)} »',
    );
  }
  for (final m in _lancementNomNu.allMatches(source)) {
    res.add(
      '$ou:${ligneDe(source, m.start)} : lancement du nom nu '
      '« ${m.group(2)} » par une chaine ou un tuple',
    );
  }
  return res;
}

final _shellVrai = RegExp(r'shell\s*=\s*(?!False\b)([^,)\n]+)');

/// Les fautes (C) du source Python [brut] : un `shell=` qui n'est pas `False`.
List<String> fautesDeShell(String brut, String ou) {
  final source = pythonSansProse(brut);
  return [
    for (final m in _shellVrai.allMatches(source))
      '$ou:${ligneDe(source, m.start)} : shell=${m.group(1)!.trim()} dans un '
          'fichier qui lance un outil du SDK',
  ];
}

final _processDart = RegExp(
  '''Process\\.(?:run|runSync|start)\\s*\\(\\s*(['"])($_nomsSdk)\\1''',
);

/// Les fautes (D) du source Dart [brut].
List<String> fautesDart(String brut, String ou) {
  final source = dartSansCommentaires(brut);
  return [
    for (final m in _processDart.allMatches(source))
      '$ou:${ligneDe(source, m.start)} : Process lance le nom nu '
          '« ${m.group(2)} »',
  ];
}

/// Les lancements par nom nu d'un script shell : `& flutter ...` (PowerShell)
/// et une commande en tete de ligne ou derriere `xargs` (sh).
final _lancementsShell = RegExp(
  '''(?:&\\s+|^\\s*|\\|\\s*|;\\s*|\\bxargs\\b[^|;\\n]*?\\s)($_nomsSdk)\\s+'''
  '''(?:format|analyze|test|build|pub|run|doctor|create|gen-l10n)\\b''',
  multiLine: true,
);

int lancementsShell(String source) {
  final sansCommentaires = source
      .replaceAll(RegExp(r'^\s*#.*$', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*<#.*?#>', dotAll: true), '');
  return _lancementsShell.allMatches(sansCommentaires).length;
}

/// Le numero de ligne de l'octet [position] dans [source].
int ligneDe(String source, int position) =>
    source.substring(0, position).split('\n').length;
