// GARDE — TACHE 860 : LES SEIZE ETIQUETTES DE NIVEAU STOCKEES SONT RETIREES,
// ET ELLES NE REVIENNENT PAS.
//
// CE QUI A ETE RETIRE, ET POURQUOI CE N'ETAIT PAS VISIBLE. `stages.json`
// portait une etiquette de niveau par etape — une `easy`, cinq `hard`, dix
// `moderate` sur le GR20 — posee une fois pour toutes. CES ETIQUETTES
// N'ETAIENT PAS FAUSSES, et c'est exactement pour cela que personne ne les
// avait vues : les cinq `hard` du GR20 sont bien ses etapes de rang 1, 2, 3, 4
// et 6 sur seize.
//
// LEUR DEFAUT EST STRUCTUREL. Une etiquette est FIXE PAR ETAPE, donc elle est
// MUETTE SUR LA JOURNEE — et c'est la journee qui concerne le client, puisque
// c'est elle qu'il marche. Un marcheur qui groupe deux etapes `moderate` fait
// une journee plus dure que celui qui marche une `hard` seule, et l'etiquette
// ne sait pas le dire. La note sur vingt, elle, suit le decoupage reel.
//
// CE QUE CETTE GARDE SURVEILLE, EN QUATRE POINTS : la donnee, les cles de
// traduction, le code qui les lisait, et les mots a l'ecran.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// VRAI quand cette ligne est un commentaire : une garde qui lit les
/// commentaires s'eteint en PARLANT du symbole qu'elle surveille.
bool estUnCommentaire(String ligne) {
  final nue = ligne.trimLeft();
  return nue.startsWith('//') || nue.startsWith('*');
}

/// Le CODE d'un fichier : ses lignes, commentaires retires.
String codeDe(File fichier) => fichier
    .readAsLinesSync()
    .where((ligne) => !estUnCommentaire(ligne))
    .join(' ');

/// Les fichiers Dart de `lib/`, sans le code genere ni les traductions.
List<File> sourcesDeLib() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where(
      (f) =>
          !f.path.endsWith('.g.dart') &&
          !f.path.endsWith('.freezed.dart') &&
          !f.path.contains('i18n'),
    )
    .toList(growable: false);

/// Les `stages.json` des sentiers du catalogue.
List<File> stagesDesSentiers() => <File>[
  for (final dossier in <String>[
    'gr20',
    'gr20-nord',
    'gr20-sud',
    'mare_a_mare_centre',
  ])
    if (File('assets/data/$dossier/stages.json').existsSync())
      File('assets/data/$dossier/stages.json'),
];

void main() {
  group('860 — la donnee ne porte plus aucune etiquette de niveau', () {
    test('AUCUN stages.json NE PORTE DE CHAMP difficulty', () {
      final fichiers = stagesDesSentiers();
      expect(
        fichiers,
        hasLength(4),
        reason: 'les quatre sentiers du catalogue doivent etre verifies',
      );
      for (final fichier in fichiers) {
        final contenu = json.decode(fichier.readAsStringSync());
        final etapes = contenu is List
            ? contenu
            : (contenu as Map<String, dynamic>)['stages'] as List<dynamic>;
        expect(
          etapes,
          isNotEmpty,
          reason: '${fichier.path} : le fichier doit encore porter ses etapes',
        );
        for (final etape in etapes) {
          expect(
            (etape as Map<String, dynamic>).containsKey('difficulty'),
            isFalse,
            reason:
                '${fichier.path} porte encore une etiquette de niveau : elle '
                'est fixe par etape, donc muette sur la journee',
          );
        }
      }
    });

    test('LES ETAPES GARDENT TOUT LE RESTE : on a retire une etiquette, pas '
        'une mesure', () {
      for (final fichier in stagesDesSentiers()) {
        final contenu = json.decode(fichier.readAsStringSync());
        final etapes = contenu is List
            ? contenu
            : (contenu as Map<String, dynamic>)['stages'] as List<dynamic>;
        for (final etape in etapes) {
          final e = etape as Map<String, dynamic>;
          for (final mesure in <String>[
            'distanceKm',
            'elevationGainM',
            'elevationLossM',
          ]) {
            expect(
              e.containsKey(mesure),
              isTrue,
              reason: '${fichier.path} : la mesure $mesure a disparu',
            );
          }
        }
      }
    });
  });

  group('860 — ni cle de traduction, ni lecteur, ni mot a l ecran', () {
    test('LES CINQ LANGUES N ONT PLUS DE CLE stage.difficulty', () {
      for (final langue in <String>['fr', 'en', 'de', 'es', 'it']) {
        final fichier = File('assets/i18n/$langue.i18n.json');
        expect(fichier.existsSync(), isTrue, reason: langue);
        final contenu =
            json.decode(fichier.readAsStringSync()) as Map<String, dynamic>;
        final stage = contenu['stage'] as Map<String, dynamic>?;
        expect(stage, isNotNull, reason: '$langue : le bloc stage a disparu');
        expect(
          stage!.containsKey('difficulty'),
          isFalse,
          reason: '$langue porte encore les mots de niveau',
        );
        expect(stage.containsKey('difficultyLabel'), isFalse, reason: langue);
      }
    });

    test('AUCUN FICHIER DE lib/ NE LIT PLUS UNE ETIQUETTE DE NIVEAU', () {
      final interdits = <String>[
        'stage.difficulty',
        'difficultyRank',
        'maxDifficulty',
        'difficultyLabel',
        '_difficultyColor',
      ];
      final fautes = <String>[];
      for (final fichier in sourcesDeLib()) {
        final texte = codeDe(fichier);
        for (final interdit in interdits) {
          if (texte.contains(interdit)) {
            fautes.add('${fichier.path} : $interdit');
          }
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'une etiquette de niveau est revenue dans le code :\n'
            '${fautes.join('\n')}',
      );
    });

    test('LES QUATRE MOTS DE NIVEAU NE SONT PLUS PRODUITS PAR AUCUNE CHAINE '
        'DE lib/', () {
      // On cherche les mots dans les CHAINES affichables, pas dans les noms de
      // couleurs du theme (`vertFacile`, `orangeDifficile`...), qui ne sont
      // pas du texte : une couleur n'affirme rien.
      final motifs = <RegExp>[
        RegExp(r"'(Facile|Moyen|Modere|Difficile|Tres difficile|Extreme)'"),
        RegExp(r'"(Facile|Moyen|Modere|Difficile|Tres difficile|Extreme)"'),
      ];
      final fautes = <String>[];
      for (final fichier in sourcesDeLib()) {
        final texte = codeDe(fichier);
        for (final motif in motifs) {
          final trouve = motif.firstMatch(texte);
          if (trouve != null) {
            fautes.add('${fichier.path} : ${trouve.group(0)}');
          }
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'Christophe tranchera les niveaux apres (19/10) : aucun mot ne '
            'doit etre affiche d ici la :\n${fautes.join('\n')}',
      );
    });
  });
}
