@Tags(['reseau'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mbtiles/mbtiles.dart';
import 'package:moteur_gr/core/config/trail_data_source.dart';
import 'package:moteur_gr/core/data/empreinte_de_publication.dart';
import 'package:moteur_gr/core/map/mbtiles_manager.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';

/// LA PREUVE QUE LA CARTE PUBLIEE DESCEND VRAIMENT — PAR LA CHAINE DU LOT 640,
/// DEPUIS LE VRAI ESPACE DE STOCKAGE (tache 648).
///
/// CE QUE CE TEST PROUVE, ET IL NE SIMULE RIEN. Aucun faux client HTTP, aucune
/// fausse liste, aucune fausse empreinte : il lit la liste REELLEMENT publiee,
/// en construit l adresse avec le code de production (`TrailDataSource`), et
/// fait descendre le fichier par `MBTilesManager` — celui que le bouton
/// « Telecharger les cartes du circuit » appelle. S il passe, le geste de
/// Christophe aboutit.
///
/// POURQUOI IL NE TOURNE PAS PAR DEFAUT. Il telecharge des dizaines de
/// megaoctets depuis Internet : une suite de tests qui en depend devient lente
/// et surtout MENTEUSE — elle echouerait sur une coupure de reseau en accusant
/// le code, alors que rien n aurait bouge dans le depot. Il se lance a la
/// demande, et le fait de le sauter se DIT :
///
/// ```bash
/// STEPWAYS_TEST_RESEAU=1 flutter test test/outillage/cartes_publiees_648_test.dart
/// ```
///
/// LA SEULE CHOSE INJECTEE EST LE DOSSIER DE DESTINATION, parce que
/// `path_provider` passe par un canal de plateforme qui n existe pas hors
/// telephone. Tout le reste est le chemin de production.
void main() {
  test(
    'la carte du Mare a Mare Centre descend du vrai espace de stockage, '
    'et son empreinte est celle qui est annoncee',
    () async {
      // LE HARNAIS DE TEST COUPE LE RESEAU, ET C EST UNE BONNE CHOSE — SAUF ICI.
      // `TestWidgetsFlutterBinding` installe un `HttpOverrides` qui rend 400 a
      // toute requete, pour qu aucun test ne depende d Internet par accident.
      // Ce test-ci a pour OBJET d aller chercher le vrai fichier sur le vrai
      // serveur : on rend donc son client reel au processus, et a lui seul.
      final surcharge = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = surcharge);

      const trail = 'mare-a-mare-centre';
      final client = http.Client();
      addTearDown(client.close);

      // 1. LA LISTE PUBLIEE, telle que l application la lit en repli de la base.
      final reponse = await client.get(Uri.parse(TrailDataSource.urlManifeste));
      expect(
        reponse.statusCode,
        200,
        reason:
            'la liste ${TrailDataSource.urlManifeste} doit etre LISIBLE SANS '
            'COMPTE : le catalogue s affiche avant toute connexion. Un 403 '
            'signifie que les regles de Firebase Storage ont ete refermees.',
      );

      final list = TrailManifest.fromJson(
        jsonDecode(reponse.body) as Map<String, dynamic>,
      );
      final entree = list.trails.firstWhere(
        (e) => e.trailId == trail,
        orElse: () => throw StateError('$trail absent de la liste publiee'),
      );

      // 2. LE DESCRIPTEUR DE TUILES : les trois champs vont ensemble ou pas du tout.
      expect(
        entree.aDesTuilesPubliees,
        isTrue,
        reason:
            'la liste doit porter tilesPath, tilesSize ET tilesHash — sans les '
            'trois, `MapDownloader` refuse avec « aucune carte publiee ».',
      );
      expect(
        EmpreinteDePublication.normaliser(entree.tilesHash),
        isNotNull,
        reason: 'une empreinte illisible ne vaut pas « pas de verification ».',
      );

      // 3. LA DESCENTE, PAR LE CODE DE PRODUCTION.
      final dossier = await Directory.systemTemp.createTemp('stepways_648_');
      addTearDown(() => dossier.delete(recursive: true));

      final gestionnaire = MBTilesManager(
        dossierDocuments: () async => dossier,
      );
      var dernierPoint = 0;
      final resultat = await gestionnaire.descendre(
        trailId: trail,
        url: TrailDataSource.trailDataUrl(entree.tilesPath!),
        octetsAttendus: entree.tilesSize!,
        empreinteAttendue: entree.tilesHash!,
        progression: (p) => dernierPoint = p.octetsRecus,
      );

      expect(
        resultat.echec,
        isNull,
        reason:
            'la descente doit aboutir : un echec ici est exactement celui que '
            'le randonneur verrait, avec la meme cause nommee.',
      );
      expect(resultat.reussie, isTrue);
      expect(resultat.octetsSurLeTelephone, entree.tilesSize);
      expect(
        dernierPoint,
        greaterThan(0),
        reason: 'la progression doit avancer',
      );

      // 4. LE FICHIER EST LA, SOUS SON NOM DEFINITIF, ET C EST UNE BASE SQLITE.
      expect(await gestionnaire.hasMbtiles(trail), isTrue);
      final carte = File(await gestionnaire.getMbtilesPath(trail));
      expect(await carte.length(), entree.tilesSize);
      final entete = await carte.openRead(0, 16).first;
      expect(
        String.fromCharCodes(entete.take(15)),
        'SQLite format 3',
        reason:
            'un .mbtiles est une base SQLite — sinon la carte ne s ouvre pas',
      );

      // 5. LA CARTE REND BIEN UNE IMAGE A L ENDROIT DEMANDE — ET C EST LE PIEGE
      //    DU FORMAT. Un `.mbtiles` range ses lignes en TMS (origine EN BAS)
      //    alors que la carte compte en XYZ (origine EN HAUT) :
      //    `flutter_map_mbtiles` calcule `tmsY = (1 << z) - 1 - y` AVANT
      //    d interroger la base. Une carte ecrite dans le mauvais sens s ouvre
      //    parfaitement et n affiche que du vide — le defaut ne se verrait qu en
      //    montagne. On refait donc ici le calcul exact du paquet, sur le
      //    milieu de l emprise, et on exige une IMAGE PNG.
      final base = MbTiles(mbtilesPath: carte.path);
      addTearDown(base.dispose);
      final metadonnees = base.getMetadata();
      expect(metadonnees.format, 'png');
      expect(
        metadonnees.attributionHtml,
        contains('OpenStreetMap'),
        reason:
            'les tuiles sont derivees d OpenStreetMap : le fichier doit porter '
            'son attribution, c est l obligation ODbL',
      );
      final bornes = metadonnees.bounds!;
      const zoom = 14;
      const n = 1 << zoom;
      final lon = (bornes.left + bornes.right) / 2;
      final lat = (bornes.top + bornes.bottom) / 2;
      final x = ((lon + 180.0) / 360.0 * n).floor();
      final radians = lat * math.pi / 180.0;
      final y =
          ((1.0 -
                      math.log(math.tan(radians) + 1.0 / math.cos(radians)) /
                          math.pi) /
                  2.0 *
                  n)
              .floor();
      final tuile = base.getTile(z: zoom, x: x, y: n - 1 - y);
      expect(
        tuile,
        isNotNull,
        reason:
            'aucune tuile a z$zoom x$x y$y : soit l emprise ne couvre pas le '
            'sentier, soit les lignes ont ete ecrites en XYZ au lieu de TMS.',
      );
      expect(
        tuile!.take(8).toList(),
        <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        reason: 'la carte doit rendre un PNG : c est ce que la couche affiche',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: Platform.environment['STEPWAYS_TEST_RESEAU'] == '1'
        ? null
        : 'preuve reseau : relancer avec STEPWAYS_TEST_RESEAU=1',
  );
}
