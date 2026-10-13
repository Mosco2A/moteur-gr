import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:moteur_gr/core/map/fond_de_carte.dart';
import 'package:moteur_gr/core/map/mbtiles_manager.dart';
import 'package:moteur_gr/core/map/offline_tile_provider.dart';
import 'package:moteur_gr/core/map/test_inert_tile_provider.dart';

/// LA CARTE HORS LIGNE TIENT SA PROMESSE (lot carte-hors-ligne-branchee).
///
/// Le randonneur telechargeait la carte de son sentier et l'ecran carte ne
/// lisait JAMAIS le fichier : en mode avion, fond blanc. Ces tests prouvent la
/// regle sur des fichiers FABRIQUES, au vrai emplacement
/// (`documents/mbtiles/{trailId}.mbtiles`) :
///  - fichier present et lisible -> le fichier est choisi, meme en ligne ;
///  - fichier absent, abime, vide ou injoignable -> le reseau, sans exception.
void main() {
  const trailId = 'mare-a-mare-centre';
  late Directory documents;
  late MBTilesManager maps;
  late OfflineTileProvider decideur;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('fond_de_carte_');
    maps = MBTilesManager(dossierDocuments: () async => documents);
    decideur = OfflineTileProvider(mbtilesManager: maps);
  });

  tearDown(() {
    if (documents.existsSync()) documents.deleteSync(recursive: true);
  });

  /// Le chemin ou le telechargement pose la carte du sentier.
  String cheminDeLaCarte() {
    Directory('${documents.path}/mbtiles').createSync(recursive: true);
    return '${documents.path}/mbtiles/$trailId.mbtiles';
  }

  /// Une vraie carte MBTiles, z10 a z15, avec une tuile — les memes
  /// metadonnees que celles posees par `tool/cartes_hors_ligne/rendu.py`.
  String fabriquerUneCarte() {
    final chemin = cheminDeLaCarte();
    final base = MbTiles.create(
      mbtilesPath: chemin,
      metadata: const MbTilesMetadata(
        name: 'carte de test',
        description: 'mare a mare centre, fabriquee pour le test',
        format: 'png',
        type: TileLayerType.baseLayer,
        version: 1,
        minZoom: 10,
        maxZoom: 15,
        bounds: MbTilesBounds(left: 8.9, bottom: 41.9, right: 9.4, top: 42.4),
        defaultCenter: LatLng(42.15, 9.15),
        defaultZoom: 13,
        attributionHtml: '© OpenStreetMap contributors (ODbL)',
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

  group('la decision du fond', () {
    test('fichier present et lisible : le FICHIER est choisi, avec ses '
        'zooms', () async {
      final chemin = fabriquerUneCarte();

      final choix = await decideur.choisir(trailId);

      expect(
        choix,
        FondDuFichier(chemin: chemin, zoomMin: 10, zoomMax: 15),
        reason:
            'la carte telechargee doit gagner : c est elle qui sert en mode '
            'avion, et elle economise batterie et forfait quand le reseau '
            'est la',
      );
      final fournisseur = OfflineTileProvider.fournisseurPour(choix);
      expect(fournisseur, isA<MbTilesTileProvider>());
      fournisseur.dispose();
    });

    test('la decision ne consulte PAS le reseau : le fichier gagne meme '
        'en ligne', () async {
      // Aucune entree de connectivite n'existe dans la decision : elle ne
      // depend que du fichier. C'est voulu — un fichier present doit servir
      // aussi quand le telephone capte, pour ne pas payer deux fois la carte.
      fabriquerUneCarte();
      expect(await decideur.choisir(trailId), isA<FondDuFichier>());
    });

    test('fichier absent : le RESEAU', () async {
      final choix = await decideur.choisir(trailId);

      expect(choix, const FondDuReseau(RaisonDuReseau.pasDeFichier));
      expect(
        OfflineTileProvider.fournisseurPour(choix),
        isNot(isA<MbTilesTileProvider>()),
      );
    });

    test('descente en cours (.partiel) : le RESEAU — une base tronquee '
        'n est pas une carte', () async {
      File(
        '${cheminDeLaCarte()}${MBTilesManager.suffixePartiel}',
      ).writeAsBytesSync(List<int>.filled(4096, 7));

      expect(
        await decideur.choisir(trailId),
        const FondDuReseau(RaisonDuReseau.pasDeFichier),
      );
    });

    test('fichier CORROMPU : le reseau, sans exception qui remonte', () async {
      File(
        cheminDeLaCarte(),
      ).writeAsBytesSync(List<int>.generate(8192, (i) => (i * 37) % 251));

      expect(
        await decideur.choisir(trailId),
        const FondDuReseau(RaisonDuReseau.fichierIllisible),
      );
    });

    test('vraie carte TRONQUEE (en-tete SQLite intact, pages perdues) : le '
        'reseau', () async {
      final chemin = fabriquerUneCarte();
      final octets = File(chemin).readAsBytesSync();
      File(chemin).writeAsBytesSync(octets.sublist(0, 1024));

      expect(
        await decideur.choisir(trailId),
        const FondDuReseau(RaisonDuReseau.fichierIllisible),
      );
    });

    test('fichier VIDE (base SQLite sans table) : le reseau', () async {
      File(cheminDeLaCarte()).writeAsBytesSync(const <int>[]);

      expect(
        await decideur.choisir(trailId),
        const FondDuReseau(RaisonDuReseau.fichierIllisible),
      );
    });

    test('une carte REFUSEE peut etre EFFACEE aussitot : l examen ne garde '
        'aucune connexion ouverte', () async {
      // CE QU IL GARANTIT, ET QUE « aucune exception » NE GARANTIT PAS.
      // Un `.mbtiles` abime se refuse APRES que sa base a ete ouverte : si
      // l examen ne referme pas ce qu il a ouvert, la connexion et son
      // descripteur de fichier fuient. Sur un telephone, c est une fuite A
      // CHAQUE OUVERTURE D ECRAN DE CARTE, invisible jusqu a l epuisement.
      // Sous Windows, effacer un fichier encore tenu est REFUSE (errno 32) :
      // l effacement est donc la preuve de la fermeture, et les trois formes
      // d abimement sont couvertes parce que chacune leve a un endroit
      // different de l ouverture.
      final abimes = <String, String Function()>{
        'octets qui ne sont pas une base': () {
          final chemin = cheminDeLaCarte();
          File(
            chemin,
          ).writeAsBytesSync(List<int>.generate(8192, (i) => (i * 37) % 251));
          return chemin;
        },
        'base SQLite vide, sans aucune table': () {
          final chemin = cheminDeLaCarte();
          File(chemin).writeAsBytesSync(const <int>[]);
          return chemin;
        },
        'vraie carte TRONQUEE, en-tete SQLite intact': () {
          final chemin = fabriquerUneCarte();
          final octets = File(chemin).readAsBytesSync();
          File(chemin).writeAsBytesSync(octets.sublist(0, 1024));
          return chemin;
        },
      };

      for (final forme in abimes.keys) {
        final chemin = abimes[forme]!();

        expect(
          await decideur.choisir(trailId),
          const FondDuReseau(RaisonDuReseau.fichierIllisible),
          reason: '$forme : la decision attendue reste le reseau',
        );

        File(chemin).deleteSync();
        expect(
          File(chemin).existsSync(),
          isFalse,
          reason:
              '$forme : une carte refusee doit pouvoir etre effacee tout de '
              'suite, donc plus personne ne doit la tenir ouverte',
        );
      }
    });

    test(
      'dossier des documents injoignable : le reseau, sans exception',
      () async {
        final injoignable = OfflineTileProvider(
          mbtilesManager: MBTilesManager(
            dossierDocuments: () async =>
                throw const FileSystemException('documents injoignables'),
          ),
        );

        expect(
          await injoignable.choisir(trailId),
          const FondDuReseau(RaisonDuReseau.dossierInaccessible),
        );
      },
    );

    test('fichier efface entre la decision et l affichage : le reseau', () {
      final fournisseur = OfflineTileProvider.fournisseurPour(
        FondDuFichier(chemin: '${documents.path}/disparu.mbtiles'),
      );
      expect(fournisseur, isNot(isA<MbTilesTileProvider>()));
    });

    test('le provider Riverpod rend la meme decision', () async {
      final chemin = fabriquerUneCarte();
      final conteneur = ProviderContainer(
        overrides: [mbtilesManagerProvider.overrideWithValue(maps)],
      );
      addTearDown(conteneur.dispose);

      expect(
        await conteneur.read(choixDuFondProvider(trailId).future),
        FondDuFichier(chemin: chemin, zoomMin: 10, zoomMax: 15),
      );
    });
  });

  group('la couche affichee', () {
    Future<void> poserLaCarte(
      WidgetTester tester,
      ChoixDuFond choix, {
      double zoom = 12,
    }) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            choixDuFondProvider.overrideWith((ref, id) async => choix),
          ],
          child: MaterialApp(
            home: SizedBox(
              width: 300,
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(42.15, 9.1),
                  initialZoom: zoom,
                ),
                children: const [FondDeCarte(trailId: trailId)],
              ),
            ),
          ),
        ),
      );
    }

    List<TileLayer> couches(WidgetTester tester) =>
        tester.widgetList<TileLayer>(find.byType(TileLayer)).toList();

    testWidgets('fichier choisi : la couche lit le FICHIER dans ses zooms, '
        'le reseau ne relaie que sous le zoom le plus bas', (tester) async {
      final chemin = fabriquerUneCarte();

      await poserLaCarte(
        tester,
        FondDuFichier(chemin: chemin, zoomMin: 10, zoomMax: 15),
      );
      await tester.pump();

      final lues = couches(tester);
      expect(lues, hasLength(2));
      final relais = lues.first;
      final fichier = lues.last;
      expect(fichier.tileProvider, isA<MbTilesTileProvider>());
      expect(fichier.minZoom, 10);
      expect(
        fichier.maxNativeZoom,
        15,
        reason:
            'au-dela du zoom 15, les tuiles du fichier sont agrandies '
            'au lieu de laisser un fond vide',
      );
      expect(relais.tileProvider, isNot(isA<MbTilesTileProvider>()));
      expect(
        relais.maxZoom,
        9,
        reason: 'le reseau ne doit RIEN demander dans les zooms du fichier',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('reseau choisi : une seule couche, aucune lecture de '
        'fichier', (tester) async {
      await poserLaCarte(
        tester,
        const FondDuReseau(RaisonDuReseau.pasDeFichier),
      );
      await tester.pump();

      final lues = couches(tester);
      expect(lues, hasLength(1));
      expect(
        lues.single.tileProvider,
        isA<InertTileProvider>(),
        reason: 'sous test, le relais reseau reste inerte : aucun appel OSM',
      );
    });

    testWidgets('decision en attente : le reseau, pas un ecran vide ni une '
        'erreur', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mbtilesManagerProvider.overrideWithValue(maps)],
          child: const MaterialApp(
            home: FlutterMap(
              options: MapOptions(initialCenter: LatLng(42.15, 9.1)),
              children: [FondDeCarte(trailId: trailId)],
            ),
          ),
        ),
      );

      expect(couches(tester), hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('une reconstruction de la carte NE rouvre PAS le fichier', (
      tester,
    ) async {
      final chemin = fabriquerUneCarte();
      final choix = FondDuFichier(chemin: chemin, zoomMin: 10, zoomMax: 15);

      await poserLaCarte(tester, choix);
      await tester.pump();
      final avant = couches(tester).last.tileProvider;

      await poserLaCarte(tester, choix, zoom: 13);
      await tester.pump();

      expect(
        identical(couches(tester).last.tileProvider, avant),
        isTrue,
        reason:
            'chaque changement de zoom reconstruit la carte : un fournisseur '
            'recree ouvrirait une connexion SQLite de plus a chaque fois',
      );
    });
  });
}
