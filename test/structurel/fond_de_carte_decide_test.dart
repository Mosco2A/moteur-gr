// GARDE STRUCTURELLE — AUCUNE COUCHE DE TUILES NE CONTOURNE LA DECISION DU
// FOND (lot carte-hors-ligne-branchee, 07/10/2026).
//
// LE DEFAUT QU'ELLE EMPECHE DE REVENIR. Le randonneur telechargeait la carte
// de son sentier (`documents/mbtiles/{trailId}.mbtiles`) et AUCUN ecran ne la
// lisait : la decision « fichier ou reseau » existait dans
// `lib/core/map/offline_tile_provider.dart`, avec zero appelant, pendant que
// les quatre `TileLayer` de l'application recopiaient en dur l'URL d'OSM. En
// mode avion, l'ecran de navigation montrait un FOND BLANC. Aucun test ne
// rougissait, parce qu'aucun ne demandait d'ou venait le fond.
//
// CE QU'ELLE EXIGE.
//  (a) Une `TileLayer` ne se CONSTRUIT que dans `lib/core/map/fond_de_carte.dart`,
//      qui passe par la decision. Liste fermee, egalite STRICTE : une couche
//      de plus ailleurs rougit, une exemption qui disparait aussi (pour que la
//      liste ne garde pas une porte ouverte sans raison).
//  (b) L'URL d'OSM et `NetworkTileProvider(` n'apparaissent que dans le
//      decideur — sinon une couche « maison » pourrait contourner (a) avec un
//      autre widget de flutter_map.
//  (c) Les trois ecrans du randonneur posent bien `FondDeCarte`.
//
// L'UNIQUE EXEMPTION, TRANCHEE ET ECRITE : la vue de suivi web
// (`follow_web_screen.dart`). Elle est ouverte par les PROCHES, depuis un
// lien, dans un navigateur : ils n'ont telecharge aucune carte, ils ne sont
// pas sur le sentier, et un navigateur ne sait pas ouvrir un `.mbtiles`
// (`MbTiles` leve `UnimplementedError` sur le web, faute de SQLite). Lire le
// fichier n'y aurait aucun sens : son fond est le reseau, par nature.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Le seul fichier de `lib/` autorise a construire une `TileLayer`.
const _leFondDeCarte = 'lib/core/map/fond_de_carte.dart';

/// Le decideur : seul a connaitre l'URL d'OSM et le fournisseur reseau.
const _leDecideur = 'lib/core/map/offline_tile_provider.dart';

/// Les exemptions, CHACUNE AVEC SON MOTIF (voir l'en-tete).
const _exemptions = <String, String>{
  'lib/features/group/presentation/follow_web_screen.dart':
      'suivi web des proches : aucun fichier telecharge, pas de SQLite '
      'dans un navigateur',
};

/// Les ecrans du randonneur, qui DOIVENT lire le fichier telecharge.
const _ecransDuRandonneur = <String>[
  'lib/features/trek/presentation/map/map_content.dart',
  'lib/features/journal/presentation/journal_screen.dart',
  'lib/features/after/presentation/gpx_import_screen.dart',
];

/// Le CODE d'un source : commentaires retires, chaines conservees.
String _sansCommentaires(String source) => source
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ')
    .split('\n')
    .where((l) => !estLigneDeCommentaire(l))
    .map((l) => l.replaceFirst(RegExp(r'(?<!:)//.*$'), ''))
    .join('\n');

final _constructionDeCouche = RegExp(r'\bTileLayer\s*\(');
final _fournisseurReseau = RegExp(r'\bNetworkTileProvider\s*\(');
const _urlOsm = 'tile.openstreetmap.org';

/// Les fichiers de `lib/` dont le CODE contient [motif].
Set<String> _fichiersOu(Pattern motif) => {
  for (final f in sourcesLib())
    if (_sansCommentaires(lireSource(f)).contains(motif)) f,
};

void main() {
  group('carte hors ligne — aucun fond ne contourne la decision', () {
    test('(a) une TileLayer ne se construit QUE dans FondDeCarte, plus '
        'les exemptions motivees', () {
      expect(
        _fichiersOu(_constructionDeCouche),
        {_leFondDeCarte, ..._exemptions.keys},
        reason:
            'UNE COUCHE DE TUILES CONTOURNE LA DECISION DU FOND. C est '
            'exactement le defaut qui a laisse le randonneur avec un fond '
            'BLANC en mode avion, alors que sa carte etait telechargee. Posez '
            '`FondDeCarte(trailId: ...)` au lieu d une `TileLayer` ; si la '
            'couche ne doit vraiment pas lire le fichier, ajoutez-la aux '
            'exemptions AVEC SON MOTIF. Si une exemption a disparu, retirez-la '
            'de la liste.',
      );
    });

    test('(b) l URL d OSM et le fournisseur reseau ne vivent que dans le '
        'decideur', () {
      expect(_fichiersOu(_fournisseurReseau), {_leDecideur});
      expect(_fichiersOu(_urlOsm), {_leDecideur, ..._exemptions.keys});
    });

    test('(c) les trois ecrans du randonneur posent FondDeCarte', () {
      for (final ecran in _ecransDuRandonneur) {
        expect(
          _sansCommentaires(lireSource(ecran)),
          contains('FondDeCarte'),
          reason:
              '$ecran affiche une carte que le randonneur regarde hors '
              'ligne : elle doit lire le fichier telecharge',
        );
      }
    });

    test('la garde lit vraiment le code — sinon elle passerait au vert en '
        'ne mesurant rien', () {
      expect(sourcesLib(), isNotEmpty);
      expect(
        _sansCommentaires('// TileLayer(\nfinal x = 1;'),
        isNot(matches(_constructionDeCouche)),
        reason: 'un commentaire n est pas une couche',
      );
      expect(
        _sansCommentaires("  TileLayer(urlTemplate: 'https://a/b'),"),
        allOf(matches(_constructionDeCouche), contains('https://a/b')),
        reason: 'une construction de couche et son URL doivent etre vues',
      );
      expect(
        _sansCommentaires(
          'ImageProvider getImage(TileCoordinates c, TileLayer o) => x;',
        ),
        isNot(matches(_constructionDeCouche)),
        reason: 'un TYPE de parametre n est pas une construction',
      );
      // `lib/docs/` porte des `TileLayer(` EN COMMENTAIRE : ils ne comptent
      // pas, sinon (a) serait rouge pour de la documentation.
      expect(
        lireSource('lib/docs/flutter_map_v8_changes.dart'),
        contains('TileLayer('),
      );
    });
  });
}
