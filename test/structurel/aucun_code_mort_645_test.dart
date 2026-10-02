// GARDE DE PLAFOND — LE CODE MORT NE S'ACCUMULE PLUS (tache 645-01).
//
// CE QUE CETTE GARDE MESURE. Les declarations de haut niveau PUBLIQUES de
// `lib/` — classe, enum, mixin, extension, typedef, fonction de premier
// niveau — que PERSONNE ne cite, nulle part, en dehors du fichier qui les
// declare. Les citations sont cherchees dans les quatre zones Dart du depot :
// `lib/`, `test/`, `integration_test/` et `tool/`.
//
// POURQUOI C'EST UNE DETTE ET PAS UN DETAIL. Un symbole sans appelant coute a
// chaque lecture : il faut le lire pour decider qu'il ne sert pas, et il faut
// le maintenir quand une signature change autour de lui. Il fausse aussi
// toutes les autres mesures — un doublon dont une moitie est morte n'est pas
// un doublon, c'est un reste. C'est precisement pour cela que le lot 645-02
// (retrait du code mort) passe AVANT le lot 645-04 (doublons) dans le plan.
//
// ---------------------------------------------------------------------------
// LA LIMITE EST ASSUMEE, ET ELLE EST ECRITE : CE SONT DES CANDIDATS
// ---------------------------------------------------------------------------
//
// Une citation par CHAINE DE CARACTERES ou par REFLEXION n'est pas vue. Un
// symbole atteint seulement par son nom en chaine sera donc compte mort a
// tort. La liste produite est une liste de CANDIDATS, a confirmer un par un
// avant toute suppression — jamais un ordre de suppression en masse.
//
// Cela ne retire rien a la garde : son travail n'est pas de dire QUI est mort,
// c'est d'empecher que leur NOMBRE augmente. Un faux positif stable ne fait
// pas bouger le compte ; un symbole neuf et sans appelant, si.
//
// POURQUOI LES CITATIONS SONT CHERCHEES HORS COMMENTAIRES ET HORS CHAINES.
// Sinon la garde s'eteindrait en ECRIVANT LE NOM du symbole mort dans sa
// propre documentation — le defaut exact qu'avait connu
// `tout_ecran_a_une_route_573_test.dart` (tache 580, Y2), ou une phrase de
// doc suffisait a declarer joignable un ecran que personne ne pouvait ouvrir.
// Un commentaire qui NOMME un symbole ne l'appelle pas : il en parle.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Mesure du 02/10/2026, tete 147ca32d : 152 declarations publiques de `lib/`
/// sans aucun appelant hors de leur propre fichier.
const plafondCodeMort = 152;

/// Les declarations de TYPE de haut niveau.
final _motifDeclaration = RegExp(
  r'^(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+)*'
  r'(?:class|enum|mixin|extension|typedef)\s+([A-Z_][A-Za-z0-9_]*)',
  multiLine: true,
);

/// Les fonctions de PREMIER niveau : un type de retour en debut de ligne, puis
/// un nom, puis une parenthese. L'ancrage en debut de ligne est ce qui
/// distingue une fonction de premier niveau d'une methode, toujours indentee.
final _motifFonction = RegExp(
  r'^(?:Future<[^>]*>|Stream<[^>]*>|void|bool|int|double|String|'
  r'List<[^>]*>|Map<[^>]*>|[A-Z][A-Za-z0-9_<>,\s?]*)\s+'
  r'([a-z_][A-Za-z0-9_]*)\s*\(',
  multiLine: true,
);

/// Les mots-cles que [_motifFonction] attrape sans qu'ils soient des noms de
/// fonction, et `main`/`build`, appeles par le framework et jamais par nous.
const _nonDeclarations = <String>{
  'main',
  'build',
  'if',
  'for',
  'while',
  'switch',
  'return',
  'catch',
};

void main() {
  late Map<String, String> declarations;
  late List<String> morts;

  setUpAll(() {
    final fichiersLib = sourcesLib();
    expect(
      fichiersLib,
      isNotEmpty,
      reason:
          'aucun source dans lib/ : la garde mesurerait le vide et '
          'passerait au vert',
    );

    // Les declarations publiques, attribuees au PREMIER fichier qui les porte.
    declarations = <String, String>{};
    for (final f in fichiersLib) {
      final texte = lireSource(f);
      for (final m in _motifDeclaration.allMatches(texte)) {
        final nom = m.group(1)!;
        if (nom.startsWith('_')) continue;
        declarations.putIfAbsent(nom, () => f);
      }
      for (final m in _motifFonction.allMatches(texte)) {
        final nom = m.group(1)!;
        if (nom.startsWith('_')) continue;
        if (_nonDeclarations.contains(nom)) continue;
        declarations.putIfAbsent(nom, () => f);
      }
    }

    // L'index des citations sur TOUT le code Dart du depot, code genere
    // compris : un symbole cite par un `.g.dart` est bel et bien utilise.
    final citations = <String, Set<String>>{};
    final aBalayer = <String>[
      ...listerDart('lib', avecGeneres: true),
      ...listerDart('test', avecGeneres: true),
      ...listerDart('integration_test', avecGeneres: true),
      ...listerDart('tool', avecGeneres: true),
    ];
    for (final f in aBalayer) {
      for (final mot in identifiants(lireSource(f)).toSet()) {
        if (!declarations.containsKey(mot)) continue;
        (citations[mot] ??= <String>{}).add(f);
      }
    }

    morts = <String>[];
    final noms = declarations.keys.toList()..sort();
    for (final nom in noms) {
      final ailleurs = (citations[nom] ?? const <String>{}).toSet()
        ..remove(declarations[nom]);
      if (ailleurs.isEmpty) morts.add('$nom  (${declarations[nom]})');
    }
  });

  group('645-01 — le code mort ne s accumule plus', () {
    test('pas plus de symboles publics sans appelant qu au 02/10', () {
      expect(
        morts.length,
        lessThanOrEqualTo(plafondCodeMort),
        reason:
            'LE CODE MORT AUGMENTE : ${morts.length} declarations publiques '
            'de lib/ ne sont citees nulle part hors de leur propre fichier, '
            'contre $plafondCodeMort au 02/10/2026. Un symbole sans appelant '
            'se paie a chaque lecture et fausse toutes les autres mesures.\n'
            'CE SONT DES CANDIDATS : la citation par chaine de caracteres ou '
            'par reflexion n est pas vue. Confirmez un par un avant de '
            'supprimer. Si un symbole neuf est LEGITIMEMENT sans appelant — '
            'une API publiee, un point d entree de plateforme — donnez-lui un '
            'test qui l appelle : c est la citation qui manquait.\n'
            '  ${morts.join('\n  ')}',
      );
    });

    test('la lecture des declarations fonctionne — sans quoi le plafond '
        'ci-dessus ne mesure rien', () {
      // UNE GARDE QUI NE RELEVE PLUS RIEN PASSE AU VERT EN SILENCE. Si les
      // deux motifs cessaient d attraper les declarations, `morts` tomberait a
      // zero et cette garde declarerait le depot sain. On verifie donc qu elle
      // voit bien un depot peuple, et que les motifs attrapent les cinq formes
      // de declaration.
      expect(
        declarations.length,
        greaterThan(500),
        reason:
            'le depot porte plus de 500 declarations publiques dans lib/ : '
            'un chiffre plus bas signale que les motifs ne lisent plus rien',
      );
      for (final cas in <List<String>>[
        ['class Truc {}', 'Truc'],
        ['abstract class Machin {}', 'Machin'],
        ['sealed class Bidule {}', 'Bidule'],
        ['enum Couleur { rouge }', 'Couleur'],
        ['mixin Bavard {}', 'Bavard'],
        ['extension SurChaine on String {}', 'SurChaine'],
        ['typedef Rappel = void Function();', 'Rappel'],
      ]) {
        final m = _motifDeclaration.firstMatch(cas[0]);
        expect(
          m?.group(1),
          cas[1],
          reason: 'le motif de declaration ne lit plus « ${cas[0]} »',
        );
      }
      expect(
        _motifFonction
            .firstMatch('Future<void> chargerTout() async {}')
            ?.group(1),
        'chargerTout',
        reason: 'le motif de fonction ne lit plus une fonction de 1er niveau',
      );
      expect(
        identifiants("// SymboleEnCommentaire\nvar x = 'SymboleEnChaine';"),
        isNot(contains('SymboleEnCommentaire')),
        reason:
            'UN COMMENTAIRE N EST PAS UN APPELANT : s il comptait, la '
            'garde s eteindrait en ecrivant le nom du symbole mort dans sa '
            'propre documentation',
      );
      expect(
        identifiants("var x = 'SymboleEnChaine';"),
        isNot(contains('SymboleEnChaine')),
        reason: 'une chaine de caracteres n appelle rien',
      );
    });
  });
}
