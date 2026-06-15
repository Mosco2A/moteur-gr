// D4A-03 — Garde-fou lexical « PSEUDONYME, JAMAIS ANONYME » (design #86166).
//
// CONTEXTE (C-2, critique Themis #86142) : StepWays est PSEUDONYME, pas
// anonyme. Un classement / fil social attache des contributions a un
// identifiant stable (UID hache) : les 3 criteres CNIL (singularisation,
// correlation, inference) ne sont PAS tenus pour de l'anonymat. Communiquer
// « anonyme » a l'utilisateur serait TROMPEUR (risque CNIL) et juridiquement
// faux (RGPD plein s'applique).
//
// CE TEST ECHOUE si le mot « anonyme / anonymous / anonymis... » apparait
// dans un TEXTE DESTINE A L'UTILISATEUR :
//   (1) une VALEUR de traduction Slang (assets/i18n/*.i18n.json) ;
//   (2) un LITTERAL de chaine dans les sources des features sociales /
//       classement / partage / gamification.
//
// CE QUI EST AUTORISE (et VOLONTAIREMENT non flague) :
//   - le socle TECHNIQUE d'anonymisation/pseudonymisation (UID hache SHA-256,
//     #85383) : identifiants de code (isAnonymous, signInAnonymously,
//     AnonymousIdService), CLES JSON techniques ('anonymous' comme cle), enums ;
//   - les COMMENTAIRES techniques explicatifs (ex // pseudonyme, PAS anonyme).
//
// BUT : empecher toute REGRESSION future ou un dev re-introduirait « anonyme »
// dans un texte vu par l'utilisateur. Test pur (pas de Riverpod / widget).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Motif interdit dans les textes utilisateur (insensible a la casse).
/// Couvre « anonyme », « anonymous », « anonymis(ation/er) », « anonimo »...
final RegExp _forbidden = RegExp(r'anonym|anonim', caseSensitive: false);

/// Locales Slang scannees (toutes les langues livrees).
const List<String> _locales = ['fr', 'en', 'de', 'es', 'it'];

/// Dossiers de features dont les LITTERAUX de chaine sont scannes (surfaces
/// ou un libelle « anonyme » serait montre a l'utilisateur — C-2).
const List<String> _userFacingFeatureDirs = [
  'lib/features/leaderboard',
  'lib/features/social',
  'lib/features/share',
  'lib/features/gamification',
];

void main() {
  group('Lexique pseudonyme — D4A-03 (jamais "anonyme" en texte user)', () {
    test('aucune VALEUR de traduction Slang ne contient "anonyme"', () {
      final offenders = <String>[];

      for (final locale in _locales) {
        final file = File('assets/i18n/$locale.i18n.json');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Fichier de traduction introuvable: ${file.path}',
        );
        final decoded = jsonDecode(file.readAsStringSync());
        _walkJsonValues(decoded, locale, (path, value) {
          if (_forbidden.hasMatch(value)) {
            offenders.add('  [$path] = "$value"');
          }
        });
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Le classement/social est PSEUDONYME, pas anonyme (#86142). '
            'Ces VALEURS de traduction emploient un terme interdit cote '
            'utilisateur (utiliser "pseudonyme" / "sans compte"):\n'
            '${offenders.join('\n')}',
      );
    });

    test('aucun LITTERAL de chaine user-facing ne contient "anonyme"', () {
      final offenders = <String>[];

      for (final dirPath in _userFacingFeatureDirs) {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) continue; // feature optionnelle / absente
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          if (entity.path.endsWith('.g.dart')) continue; // genere
          _scanDartStringLiterals(entity, (line, content) {
            offenders.add('  ${entity.path}:$line -> $content');
          });
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Un libelle utilisateur emploie "anonyme" dans une feature '
            'sociale/classement (PSEUDONYME impose, #86142). Les commentaires '
            'techniques sont autorises, pas les chaines affichees:\n'
            '${offenders.join('\n')}',
      );
    });

    test('le garde-fou detecte bien une occurrence (test du test)', () {
      // Garantit que le scanner n'est pas un no-op : il DOIT matcher.
      expect(_forbidden.hasMatch('Randonneur anonyme'), isTrue);
      expect(_forbidden.hasMatch('Anonymous hiker'), isTrue);
      expect(_forbidden.hasMatch('modalità anonima'), isTrue);
      // ...et ne PAS matcher un texte propre.
      expect(_forbidden.hasMatch('Randonneur sans compte'), isFalse);
      expect(_forbidden.hasMatch('pseudonyme'), isFalse);
    });
  });
}

/// Parcourt recursivement les VALEURS d'un arbre JSON Slang et invoque
/// [onString] pour chaque chaine, avec son chemin pointe (ex fr.auth.profile).
///
/// Seules les VALEURS sont visitees : les CLES (identifiants techniques comme
/// "anonymous") ne sont jamais montrees a l'utilisateur et sont ignorees.
void _walkJsonValues(
  Object? node,
  String path,
  void Function(String path, String value) onString,
) {
  if (node is String) {
    onString(path, node);
  } else if (node is Map) {
    node.forEach((key, value) {
      _walkJsonValues(value, '$path.$key', onString);
    });
  } else if (node is List) {
    for (var i = 0; i < node.length; i++) {
      _walkJsonValues(node[i], '$path[$i]', onString);
    }
  }
}

/// Scanne un fichier Dart a la recherche de LITTERAUX de chaine contenant le
/// motif interdit, en IGNORANT les lignes de commentaire (//, ///, * ).
///
/// Heuristique volontairement simple et conservatrice : on ne flague une ligne
/// que si elle (a) n'est pas un commentaire et (b) contient le motif a
/// l'interieur d'une chaine (guillemets simples ou doubles). Cela autorise les
/// commentaires explicatifs (« pseudonyme, PAS anonyme ») tout en attrapant un
/// libelle re-introduit dans une chaine affichee.
void _scanDartStringLiterals(
  File file,
  void Function(int line, String content) onMatch,
) {
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final trimmed = raw.trimLeft();
    // Lignes de commentaire pures : autorisees (explications techniques).
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;

    // Retire un eventuel commentaire de fin de ligne pour ne pas le scanner.
    final code = _stripTrailingComment(raw);
    if (!_forbidden.hasMatch(code)) continue;

    // Le motif est present hors commentaire : n'est-il que dans une chaine ?
    for (final literal in _stringLiterals(code)) {
      if (_forbidden.hasMatch(literal)) {
        onMatch(i + 1, literal.trim());
        break;
      }
    }
  }
}

/// Retire un commentaire `//` en fin de ligne (en respectant les chaines).
String _stripTrailingComment(String line) {
  var inSingle = false;
  var inDouble = false;
  for (var i = 0; i < line.length - 1; i++) {
    final c = line[i];
    if (c == "'" && !inDouble) inSingle = !inSingle;
    if (c == '"' && !inSingle) inDouble = !inDouble;
    if (!inSingle && !inDouble && c == '/' && line[i + 1] == '/') {
      return line.substring(0, i);
    }
  }
  return line;
}

/// Extrait les contenus de chaines (entre ' ' ou " ") d'une ligne de code.
List<String> _stringLiterals(String code) {
  final result = <String>[];
  // Chaines double-quote OU simple-quote (contenu capture, hors guillemets).
  final pattern = RegExp('"([^"]*)"' r"|'([^']*)'");
  for (final m in pattern.allMatches(code)) {
    result.add(m.group(1) ?? m.group(2) ?? '');
  }
  return result;
}
