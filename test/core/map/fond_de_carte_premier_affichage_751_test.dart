import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/map/fond_de_carte.dart';
import 'package:moteur_gr/core/map/offline_tile_provider.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/map_pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';

/// TACHE 751 — LA CARTE PEINT DES LE PREMIER AFFICHAGE.
///
/// Retour de Christophe du 09/10 a 10:01, mot pour mot : « En fait il faut
/// sortir puis revenir sur la carte pour qu'elle s'affiche ». Il avait d'abord
/// cru a une absence de fond, puis a une lenteur. C'etait NI L'UN NI L'AUTRE :
/// les tuiles arrivaient, mais la PREMIERE construction de l'ecran ne les
/// montrait pas, et sortir de l'ecran puis y revenir suffisait.
///
/// LES DEUX CAUSES MESUREES, ET CE QUE CES GARDES REFUSENT DESORMAIS.
///
/// 1. LA COUCHE ETAIT REMONTEE QUAND LA DECISION ARRIVAIT. Le decideur
///    `choixDuFondProvider`
///    est un `FutureProvider` : son `.value` est `null` au premier `watch`, et
///    il l'est MEME quand le futur est deja termine. La premiere construction
///    batissait donc toujours la couche du reseau, puis `FondDeCarte`
///    remplacait un widget par un widget d'un AUTRE TYPE au meme endroit — la
///    [TileLayer] etait DETRUITE et REMONTEE. Or `flutter_map` 8.3 ne recharge
///    ses tuiles que sur un flux `broadcast` SANS REJEU, et n'applique
///    `initialCameraFit` que dans la branche « la taille a change » : une
///    couche remontee apres le cadrage rate les evenements qui l'auraient fait
///    charger. Revenir sur l'ecran reglait tout parce que le [MapController]
///    est partage par un `NotifierProvider` non `autoDispose` — a la deuxieme
///    visite, la camera etait deja posee sur le sentier.
///    LA GARDE : l'element de la couche principale doit etre LE MEME avant et
///    apres la decision ; seul son FOURNISSEUR change.
///
/// 2. LA PREMIERE FRAME REGARDAIT L'UKRAINE. `MapOptions` n'avait pas
///    d'`initialCenter` : la camera demarrait sur le centre par defaut de
///    `flutter_map` (50.5 / 30.5, Kiev) et c'est pour la que la couche faisait
///    sa premiere demande de tuiles ; `initialCameraFit` ne corrigeait la vue
///    qu'au post-frame suivant.
///    LA GARDE : au premier affichage, la camera est DEJA sur le sentier.
void main() {
  const trailId = 'mare-a-mare-centre';
  late Directory documents;

  setUp(() => documents = Directory.systemTemp.createTempSync('fond751_'));
  tearDown(() {
    if (documents.existsSync()) {
      try {
        documents.deleteSync(recursive: true);
      } catch (_) {
        // Sous Windows un fichier encore tenu refuse de partir ; ce n'est pas
        // l'objet de ces gardes (la fuite a la sienne, tache 731).
      }
    }
  });

  /// Une vraie carte MBTiles, z10 a z15, aux memes metadonnees que celles
  /// posees par `tool/cartes_hors_ligne/rendu.py`.
  String fabriquerUneCarte(String id) {
    Directory('${documents.path}/mbtiles').createSync(recursive: true);
    final chemin = '${documents.path}/mbtiles/$id.mbtiles';
    final base = MbTiles.create(
      mbtilesPath: chemin,
      metadata: const MbTilesMetadata(
        name: 'carte de test',
        format: 'png',
        type: TileLayerType.baseLayer,
        version: 1,
        minZoom: 10,
        maxZoom: 15,
        bounds: MbTilesBounds(left: 8.9, bottom: 41.8, right: 9.6, top: 42.4),
        defaultCenter: LatLng(42.1, 9.3),
        defaultZoom: 13,
      ),
    );
    base.putTile(
      z: 12,
      x: 2170,
      y: 2563,
      bytes: Uint8List.fromList(TileProvider.transparentImage),
    );
    base.dispose();
    return chemin;
  }

  /// La carte NUE, avec la decision pilotee a la main : c'est le seul moyen de
  /// placer l'arrivee de la decision APRES la premiere construction, comme sur
  /// un telephone.
  Future<void> poser(WidgetTester tester, Future<ChoixDuFond> decision) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [choixDuFondProvider.overrideWith((ref, id) => decision)],
        child: const MaterialApp(
          home: SizedBox(
            width: 400,
            height: 400,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(42.15, 9.1),
                initialZoom: 12,
              ),
              children: [FondDeCarte(trailId: trailId)],
            ),
          ),
        ),
      ),
    );
  }

  List<TileLayer> couches(WidgetTester tester) =>
      tester.widgetList<TileLayer>(find.byType(TileLayer)).toList();

  group('la carte peint des le premier affichage (751)', () {
    testWidgets('DES LA PREMIERE CONSTRUCTION, la couche de tuiles est la et '
        'elle est configuree — aucun second passage', (tester) async {
      final chemin = fabriquerUneCarte(trailId);
      // La decision n'arrivera JAMAIS pendant ce test : on mesure donc bien la
      // toute premiere construction, celle que Christophe voyait vide.
      await poser(tester, Completer<ChoixDuFond>().future);

      final lues = couches(tester);
      expect(
        lues,
        hasLength(1),
        reason:
            'la premiere construction doit deja porter UNE couche de tuiles : '
            'sans elle, le randonneur regarde un ecran sans fond',
      );
      final seule = lues.single;
      expect(
        seule.tileProvider,
        isNotNull,
        reason: 'une couche sans fournisseur ne demande aucune tuile',
      );
      expect(
        seule.urlTemplate,
        OfflineTileProvider.defaultTileUrl,
        reason:
            'tant que la decision n est pas rendue, le fond vient du reseau — '
            'et il doit etre pret a servir, pas en attente',
      );
      expect(
        seule.minZoom,
        0,
        reason:
            'en attente de decision la couche doit couvrir TOUS les zooms : '
            'une couche bornee laisserait un fond vide a l ouverture',
      );
      expect(chemin, isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la decision arrive APRES : c est le FOURNISSEUR qui change, '
        'la couche n est PAS remontee', (tester) async {
      final chemin = fabriquerUneCarte(trailId);
      final porte = Completer<ChoixDuFond>();
      await poser(tester, porte.future);

      // L identite de la couche principale AVANT la decision.
      final elementAvant = tester.element(find.byType(TileLayer).last);
      final fournisseurAvant = couches(tester).last.tileProvider;
      expect(
        fournisseurAvant,
        isNot(isA<MbTilesTileProvider>()),
        reason: 'avant la decision, le fond ne peut venir que du reseau',
      );

      // LA DECISION ARRIVE — le fichier est lisible, il doit gagner.
      porte.complete(FondDuFichier(chemin: chemin, zoomMin: 10, zoomMax: 15));
      await tester.pump();
      await tester.pump();

      final elementApres = tester.element(find.byType(TileLayer).last);
      final fournisseurApres = couches(tester).last.tileProvider;

      expect(
        identical(elementAvant, elementApres),
        isTrue,
        reason:
            'LA REGRESSION DE LA TACHE 751 : la couche de tuiles a ete '
            'REMONTEE au lieu d etre reconfiguree. Une couche remontee apres '
            'le cadrage d ouverture rate les evenements de flutter_map (flux '
            'broadcast sans rejeu) et ne peint rien — il faut sortir de l '
            'ecran et y revenir pour la voir, ce qui est exactement le defaut '
            'rapporte par Christophe le 09/10 a 10:01',
      );
      expect(
        fournisseurApres,
        isA<MbTilesTileProvider>(),
        reason:
            'la decision est rendue et le fichier gagne : le fournisseur doit '
            'avoir ete remplace SUR PLACE par celui du fichier',
      );
      expect(
        identical(fournisseurAvant, fournisseurApres),
        isFalse,
        reason:
            'le fournisseur du reseau ne peut pas servir les tuiles du '
            'fichier : il doit avoir ete refabrique quand la decision est '
            'arrivee, et non fige sur l attente',
      );
      expect(
        couches(tester).first.maxZoom,
        9,
        reason:
            'sous le plus petit zoom du fichier, le relais reseau reprend la '
            'main — et seulement la',
      );
      expect(
        couches(tester).last.minZoom,
        10,
        reason: 'la couche du fichier ne sert que les zooms que le fichier a',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('une reconstruction qui ne change PAS la decision garde le '
        'MEME fournisseur (pas une connexion de plus)', (tester) async {
      final chemin = fabriquerUneCarte(trailId);
      final choix = FondDuFichier(chemin: chemin, zoomMin: 10, zoomMax: 15);
      await poser(tester, Future.value(choix));
      await tester.pump();
      final avant = couches(tester).last.tileProvider;
      expect(avant, isA<MbTilesTileProvider>());

      // Une reconstruction avec la MEME decision — chaque changement de zoom
      // en provoque une sur un telephone.
      await poser(tester, Future.value(choix));
      await tester.pump();

      expect(
        identical(couches(tester).last.tileProvider, avant),
        isTrue,
        reason:
            'refabriquer le fournisseur a chaque reconstruction ouvrirait une '
            'connexion SQLite de plus a chaque changement de zoom, sans '
            'jamais fermer les precedentes (tache 731)',
      );
    });
  });

  group('l ecran de carte ouvre DEJA sur le sentier (751)', () {
    // Une trace de la taille d un vrai sentier corse.
    final trace = <TrackPoint>[
      for (var i = 0; i <= 20; i++)
        TrackPoint(
          lat: 41.90 + i * 0.02,
          lng: 9.10 + i * 0.02,
          altitude: 700,
          distanceFromStart: i * 3500,
        ),
    ];

    const etape1 = StageModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Cozzano',
      distanceKm: 12.5,
      elevationGainM: 640,
      elevationLossM: 520,
      startLat: 41.90,
      startLng: 9.10,
      endLat: 41.98,
      endLng: 9.18,
    );

    testWidgets('la camera du PREMIER affichage est sur le sentier, pas sur le '
        'centre par defaut de flutter_map', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(
              testTrailConfig.id,
            ).overrideWith((ref) => Future.value(trace)),
            stagesProvider(
              testTrailConfig.id,
            ).overrideWith((ref) => Future.value(const [etape1])),
            mapPoisProvider(
              testTrailConfig.id,
            ).overrideWith((ref) => Future.value(const [])),
            gpsPermissionProvider.overrideWith(
              (ref) => Future.value(GpsPermissionStateValues.denied),
            ),
          ],
          child: const MaterialApp(home: MapScreen(trailId: 'test-trail')),
        ),
      );
      // UNE SEULE frame apres l arrivee de la trace : c est la premiere image
      // de la carte que voit le randonneur.
      await tester.pump();

      expect(
        find.byType(TileLayer),
        findsWidgets,
        reason: 'la carte doit porter une couche de tuiles des son ouverture',
      );
      final camera = MapCamera.of(tester.element(find.byType(TileLayer).first));

      // Le sentier est en Corse : 41,90-42,30 de latitude, 9,10-9,50 de
      // longitude. Le centre par defaut de flutter_map est Kiev (50,5 / 30,5).
      expect(
        camera.center.latitude,
        inInclusiveRange(41.8, 42.4),
        reason:
            'LA REGRESSION DE LA TACHE 751 : la premiere frame de la carte '
            'regarde ${camera.center} au lieu du sentier. Sans '
            'initialCenter, la camera demarre sur le centre par defaut de '
            'flutter_map (Kiev) et la couche de tuiles fait sa premiere '
            'demande POUR LA — le randonneur ouvre sa carte sur un ailleurs, '
            'ou sur du vide',
      );
      expect(
        camera.center.longitude,
        inInclusiveRange(9.0, 9.6),
        reason:
            'la premiere frame doit etre cadree sur le sentier, pas sur le '
            'centre par defaut de flutter_map',
      );
    });
  });
}
