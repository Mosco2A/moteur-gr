// GARDE DE PLAFOND — ECR-20 : DEUX FICHIERS NE PORTENT PAS LE MEME NOM
// (tache 645-01).
//
// CE QUE CETTE GARDE MESURE. Les noms de base de fichier `.dart` presents deux
// fois ou plus dans `lib/`, hors code genere.
//
// POURQUOI UN NOM EN DOUBLE COUTE AUTANT. Il ne s'agit pas d'esthetique. Deux
// `stage.dart` veulent dire deux definitions de ce qu'est une etape, et donc
// une question a laquelle le depot repond deux fois, parfois differemment.
// Trois consequences mesurables :
//
//   - LES IMPORTS DEVIENNENT AMBIGUS A LA LECTURE. `import '../domain/stage.dart'`
//     ne dit plus laquelle des deux on prend ; il faut resoudre le chemin a la
//     main pour le savoir.
//   - LES CORRECTIONS NE SE PROPAGENT PAS. Un defaut corrige dans l'une des
//     deux moities survit dans l'autre, et c'est l'autre qui part en
//     production la fois suivante.
//   - LA NAVIGATION DANS L'EDITEUR MENT. « Ouvrir `track_point.dart` » pose une
//     question au lieu d'ouvrir un fichier.
//
// LES QUATRE CONNUS AU 02/10/2026, et c'est le plafond : `gpx_parser.dart`,
// `stage.dart`, `track_point.dart`, `tracking_overlay.dart`.
//
// RESORBER N'EST PAS RENOMMER. Fusionner deux types en deplacant du code est
// interdit par SPEC-06 : c'est le travail du lot 645-04, et il attend un
// arbitrage. Cette garde ne demande donc pas de reparer — seulement de ne pas
// AJOUTER un cinquieme doublon en attendant.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Mesure du 02/10/2026, tete 147ca32d : 4 noms de fichier en double dans
/// `lib/` (`gpx_parser.dart`, `stage.dart`, `track_point.dart`,
/// `tracking_overlay.dart`).
const plafondNomsEnDouble = 4;

void main() {
  late Map<String, List<String>> enDouble;

  setUpAll(() {
    final fichiers = sourcesLib();
    expect(
      fichiers,
      isNotEmpty,
      reason: 'aucun source dans lib/ : la garde mesurerait le vide',
    );

    final parNom = <String, List<String>>{};
    for (final f in fichiers) {
      (parNom[f.split('/').last] ??= <String>[]).add(f);
    }
    enDouble = Map.fromEntries(
      parNom.entries.where((e) => e.value.length > 1).toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
  });

  group('645-01 / ECR-20 — pas un nom de fichier de plus en double', () {
    test('pas plus de noms de fichier en double qu au 02/10', () {
      final detail = enDouble.entries
          .map((e) => '${e.key} :\n    ${e.value.join('\n    ')}')
          .join('\n  ');
      expect(
        enDouble.length,
        lessThanOrEqualTo(plafondNomsEnDouble),
        reason:
            'UN NOM DE FICHIER DE PLUS EST EN DOUBLE : ${enDouble.length} '
            'noms portes par deux fichiers ou davantage dans lib/, contre '
            '$plafondNomsEnDouble au 02/10/2026. Deux fichiers de meme nom, '
            'ce sont deux reponses a la meme question : les imports deviennent '
            'ambigus a la lecture, et un defaut corrige dans l un survit dans '
            'l autre.\n'
            'NE FUSIONNEZ PAS EN DEPLACANT — SPEC-06 l interdit, et c est le '
            'travail du lot 645-04. Pour un fichier NEUF, la reponse est '
            'simple : donnez-lui un nom qui dit ce qu il est.\n  $detail',
      );
    });

    test('les quatre doublons connus sont toujours ceux-la — sinon le plafond '
        'couvre autre chose que ce qu il annonce', () {
      // UN PLAFOND CHIFFRE NE DIT PAS *QUI* IL COUVRE. Sans ce test, resorber
      // `stage.dart` puis introduire `machin.dart` en double laisserait le
      // compte a 4 : la garde resterait verte alors que la dette a change de
      // nature, et le plafond cesserait de designer ce que son en-tete
      // annonce. On verifie donc l IDENTITE, pas seulement le nombre.
      expect(
        enDouble.keys.toList(),
        <String>[
          'gpx_parser.dart',
          'stage.dart',
          'track_point.dart',
          'tracking_overlay.dart',
        ],
        reason:
            'LA LISTE DES DOUBLONS A CHANGE. Si vous en avez RESORBE un, '
            'baissez `plafondNomsEnDouble` et retirez-le de cette liste : '
            'c est une bonne nouvelle qui doit se graver, sinon la place '
            'liberee se remplira en silence. Si un NOUVEAU est apparu, c est '
            'le defaut que le test precedent nomme.',
      );
    });
  });
}
