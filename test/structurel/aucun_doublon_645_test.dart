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
// LES QUATRE CONNUS AU 02/10/2026 : `gpx_parser.dart`, `stage.dart`,
// `track_point.dart`, `tracking_overlay.dart`.
//
// RESORBE LE 02/10/2026 PAR LE LOT 645-04, et c'est pourquoi le plafond est
// tombe a 3 : `tracking_overlay.dart`. Les deux widgets portaient le meme nom
// de classe `TrackingOverlay` et le meme nom de fichier, mais celui de
// `lib/features/tracking/presentation/` n'avait AUCUN appelant — ni dans
// `lib/`, ni dans un test, ni nulle part dans le depot. Il est parti ; celui de
// `lib/features/trek/presentation/map/overlay/`, que deux fichiers de test
// exercent, reste.
//
//
// LE DOUBLON QUE LE COMPTE DE NOMS NE VOIT PAS — ECR-20 bis (tache 645-04,
// concept C-5). `lib/core/ui/loading_view.dart` (`LoadingView`) et
// `lib/shared/widgets/loading_overlay.dart` (`LoadingOverlay`) etaient le MEME
// widget — une roue de progression centree, un message optionnel dessous — sous
// deux noms differents. Deux noms differents : la mesure ci-dessus, qui compare
// des noms de fichier, ne pouvait pas le voir. Seule la revue du 21/09 l'a vu,
// et il a survecu onze jours a ce signalement.
//
// D'OU LA SECONDE MESURE, PAR LA FORME ET NON PAR LE NOM : les fichiers de
// `lib/` dont tout le travail est d'afficher une attente. Le lot 645-02 a
// retire `LoadingOverlay`, qui n'avait aucun appelant (commit 16aa97e6) ; il
// n'en reste donc qu'UN, et c'est le plafond. La contre-epreuve a ete jouee :
// en remettant `loading_overlay.dart` en place, cette mesure remonte a 2.
//
// RESORBER N'EST PAS RENOMMER. Fusionner deux types en deplacant du code est
// interdit par SPEC-06. Les TROIS qui restent ont ete instruits par le lot
// 645-04 et en sont SORTIS, chacun pour une raison mesuree : ils attendent un
// arbitrage de Christophe, inscrit en ARB-645-04-a (`stage`), ARB-645-04-b
// (`track_point`) et ARB-645-04-c (`gpx_parser`) dans
// `docs/assainissement/644-03-decoupage-et-plan.md`. Resume, parce qu'un
// plafond doit se lire sans ouvrir un autre fichier : `stage` est DEUX TYPES
// differents relies par un convertisseur explicite, pas un doublon ;
// `track_point` a VRAIMENT diverge, et un seul type ne peut pas satisfaire les
// deux series de tests sans renommer un parametre dans un test existant ;
// `gpx_parser` est une facade `rootBundle` devant un parseur en Dart PUR dont
// `dart run tool/publier_sentier.dart` depend — les reunir casse l'outil de
// publication, c'est mesure. Cette garde ne demande donc pas de reparer —
// seulement de ne pas AJOUTER un quatrieme doublon en attendant.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Mesure du 02/10/2026, tete 0310fa9b, APRES le lot 645-04 : 3 noms de
/// fichier en double dans `lib/` (`gpx_parser.dart`, `stage.dart`,
/// `track_point.dart`). `tracking_overlay.dart` a ete resorbe.
const plafondNomsEnDouble = 3;

/// Mesure du 02/10/2026, tete 0310fa9b : UN seul fichier de `lib/` n'a pour
/// tout role que d'afficher une attente (`core/ui/loading_view.dart`).
/// `shared/widgets/loading_overlay.dart`, son jumeau fonctionnel a nom
/// different, est parti avec le lot 645-02.
const plafondVoilesDeChargement = 1;

/// UN FICHIER DONT TOUT LE TRAVAIL EST D'AFFICHER UNE ATTENTE.
///
/// La forme, pas le nom : le source cite `CircularProgressIndicator`, tient en
/// 60 lignes de code ou moins hors commentaires, et ne porte ni `Scaffold`, ni
/// `AppBar`, ni `ListView` — un ecran qui affiche une roue pendant son
/// chargement en porte au moins un des trois, et n'est donc pas un voile.
bool _estUnVoileDeChargement(String source) {
  if (!source.contains('CircularProgressIndicator')) return false;
  if (source.contains('Scaffold') ||
      source.contains('AppBar') ||
      source.contains('ListView')) {
    return false;
  }
  final code = source
      .split('\n')
      .where((l) => l.trim().isNotEmpty && !estLigneDeCommentaire(l))
      .length;
  return code <= 60;
}

/// Les classes PUBLIQUES declarees par [source].
final _motifClassePublique = RegExp(
  r'^(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+)*'
  r'class\s+([A-Z][A-Za-z0-9_]*)',
  multiLine: true,
);

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

    test('les doublons connus sont toujours ceux-la — sinon le plafond '
        'couvre autre chose que ce qu il annonce', () {
      // UN PLAFOND CHIFFRE NE DIT PAS *QUI* IL COUVRE. Sans ce test, resorber
      // `stage.dart` puis introduire `machin.dart` en double laisserait le
      // compte a 4 : la garde resterait verte alors que la dette a change de
      // nature, et le plafond cesserait de designer ce que son en-tete
      // annonce. On verifie donc l IDENTITE, pas seulement le nombre.
      expect(
        enDouble.keys.toList(),
        <String>['gpx_parser.dart', 'stage.dart', 'track_point.dart'],
        reason:
            'LA LISTE DES DOUBLONS A CHANGE. Si vous en avez RESORBE un, '
            'baissez `plafondNomsEnDouble` et retirez-le de cette liste : '
            'c est une bonne nouvelle qui doit se graver, sinon la place '
            'liberee se remplira en silence. Si un NOUVEAU est apparu, c est '
            'le defaut que le test precedent nomme.',
      );
    });
  });

  group('645-04 / ECR-20 bis — un seul voile de chargement', () {
    test('pas plus de widgets d attente qu au 02/10 — la mesure par la forme, '
        'pas par le nom', () {
      final voiles = <String>[];
      for (final f in sourcesLib()) {
        final source = lireSource(f);
        if (!_estUnVoileDeChargement(source)) continue;
        for (final m in _motifClassePublique.allMatches(source)) {
          voiles.add('${m.group(1)}  ($f)');
        }
      }
      voiles.sort();

      expect(
        voiles.length,
        lessThanOrEqualTo(plafondVoilesDeChargement),
        reason:
            'UN DEUXIEME VOILE DE CHARGEMENT EST APPARU : ${voiles.length} '
            'widgets de `lib/` n ont pour tout role que d afficher une '
            'attente, contre $plafondVoilesDeChargement au 02/10/2026. '
            'C EST LE DEFAUT C-5 QUI REVIENT : `LoadingView` et '
            '`LoadingOverlay` ont coexiste onze jours parce que leurs NOMS '
            'differaient et qu aucune commande ne regardait leur FORME. Deux '
            'voiles, ce sont deux reponses a « a quoi ressemble une attente » '
            ': celui qu on corrige n est jamais celui que l ecran affiche.\n'
            'Si vous avez besoin d une attente, appelez `LoadingView` ; si '
            'elle ne suffit pas, etendez-la plutot que de poser une '
            'deuxieme.\n  ${voiles.join('\n  ')}',
      );
    });
  });
}
