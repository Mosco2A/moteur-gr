import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/map_pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 571 — LOT T : LES MARQUEURS DE LA CARTE NE SE RECOUVRENT PLUS.
///
/// Retour de Chris en testant l'appli, mot pour mot : « 14rando les numeros
/// d'etapes son caches par les refucge, il ne faut pas que les icones se
/// superposent ».
///
/// CE QUE CES TESTS MESURENT, ET POURQUOI ILS SONT ECRITS SUR L'ECRAN REEL :
/// le defaut est GEOMETRIQUE — deux rectangles peints au meme endroit — et il
/// ne se voit qu'a l'ecran. Ils mesurent donc les RECTANGLES RENDUS et non la
/// presence des widgets : un marqueur present mais entierement recouvert passe
/// toutes les verifications d'existence et reste invisible pour le randonneur.
///
/// COORDONNEES REELLES DU SENTIER (assets/data/mare_a_mare_centre) — ce ne sont
/// pas des chiffres inventes pour arranger le test :
///   * depart de l'etape 3 = 41.9392 / 9.1978 ;
///   * « Gite d etape de Cozzano » (shelter) = 41.9392 / 9.1978, soit 0,0 m du
///     depart d'etape — LE MEME POINT, au chiffre pres. Aucun decalage de
///     quelques pixels ne peut regler ce cas : a n'importe quel zoom, meme au
///     plus fort, les deux marqueurs restent au meme pixel ;
///   * « Epicerie de Cozzano » (shop) = 41.9395 / 9.198, a 37,2 m.
/// Une etape se TERMINE a un hebergement et la suivante en REPART : la
/// coincidence est structurelle sur tout sentier de randonnee, pas un accident
/// de donnees corse.
void main() {
  // Trace reelle simplifiee : Cozzano -> Guitera, le troncon de l'etape 3.
  final trackCozzanoGuitera = [
    const TrackPoint(
      lat: 41.9392,
      lng: 9.1978,
      altitude: 727,
      distanceFromStart: 0,
    ),
    const TrackPoint(
      lat: 41.9330,
      lng: 9.1830,
      altitude: 900,
      distanceFromStart: 1500,
    ),
    const TrackPoint(
      lat: 41.9270,
      lng: 9.1700,
      altitude: 1050,
      distanceFromStart: 3000,
    ),
    const TrackPoint(
      lat: 41.9200,
      lng: 9.1550,
      altitude: 850,
      distanceFromStart: 4500,
    ),
    const TrackPoint(
      lat: 41.9147,
      lng: 9.1411,
      altitude: 620,
      distanceFromStart: 6000,
    ),
  ];

  // Etape 3 du Mare a Mare Centre, coordonnees de la source de donnees.
  const stageCozzano = StageModel(
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Cozzano',
    distanceKm: 12.5,
    elevationGainM: 640,
    elevationLossM: 520,
    startLat: 41.9392,
    startLng: 9.1978,
    endLat: 41.9147,
    endLng: 9.1411,
  );

  // Les deux points d'interet de Cozzano, coordonnees de la source de donnees.
  const giteCozzano = PoiModel(
    id: 31,
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Gite d etape de Cozzano',
    type: 'shelter',
    lat: 41.9392,
    lng: 9.1978,
    altitudeM: 727,
  );
  const epicerieCozzano = PoiModel(
    id: 32,
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Epicerie de Cozzano',
    type: 'shop',
    lat: 41.9395,
    lng: 9.198,
    altitudeM: 730,
  );

  /// Monte l'ecran carte avec les etapes et les points d'interet donnes.
  Future<void> pumpMap(
    WidgetTester tester, {
    required List<StageModel> stages,
    required List<PoiModel> pois,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          gpxTrackProvider(testTrailConfig.id).overrideWith(
            (ref) => Future.value(trackCozzanoGuitera),
          ),
          stagesProvider(testTrailConfig.id).overrideWith(
            (ref) => Future.value(stages),
          ),
          mapPoisProvider(testTrailConfig.id).overrideWith(
            (ref) => Future.value(pois),
          ),
          // GPS non accorde en test -> aucune position, aucun flux ouvert.
          gpsPermissionProvider.overrideWith(
            (ref) => Future.value(GpsPermissionStateValues.denied),
          ),
        ],
        child: const MaterialApp(
          home: MapScreen(trailId: 'test-trail'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Les reperes vivent DANS la carte ; la barre d'etape et l'en-tete vivent
  /// au-dessus. On ne mesure donc que ce qui est peint dans [FlutterMap].
  Finder inMap(Finder matching) => find.descendant(
        of: find.byType(FlutterMap),
        matching: matching,
      );

  group('Carte — marqueurs poses au meme endroit (tache 571)', () {
    testWidgets(
      'le numero d etape n est JAMAIS recouvert par l icone du refuge pose '
      'au meme point',
      (tester) async {
        await pumpMap(
          tester,
          stages: const [stageCozzano],
          pois: const [giteCozzano, epicerieCozzano],
        );

        final numero = inMap(find.text('3'));
        final refuge = inMap(find.byIcon(Icons.house));

        expect(
          numero,
          findsOneWidget,
          reason: 'le numero de l etape 3 doit etre peint sur la carte',
        );
        expect(
          refuge,
          findsOneWidget,
          reason: 'le gite de Cozzano doit etre peint sur la carte',
        );

        final rectNumero = tester.getRect(numero);
        final rectRefuge = tester.getRect(refuge);

        expect(
          rectNumero.overlaps(rectRefuge),
          isFalse,
          reason: 'le numero d etape $rectNumero est recouvert par l icone du '
              'refuge $rectRefuge — les deux points sont au meme endroit '
              '(0,0 m) et il faut UN repere qui porte les deux informations, '
              'pas deux marqueurs empiles',
        );
      },
    );

    testWidgets(
      'le tap sur le repere donne acces AUX DEUX informations : l etape ET '
      'les lieux',
      (tester) async {
        await pumpMap(
          tester,
          stages: const [stageCozzano],
          pois: const [giteCozzano, epicerieCozzano],
        );

        await tester.tap(inMap(find.text('3')), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(
          find.text(t.a11y.stageMarker(number: 3)),
          findsOneWidget,
          reason: 'l information d ETAPE doit etre accessible depuis le repere',
        );
        expect(
          find.text(giteCozzano.name),
          findsOneWidget,
          reason: 'l information du GITE doit etre accessible depuis le repere',
        );
        expect(
          find.text(epicerieCozzano.name),
          findsOneWidget,
          reason: 'l epicerie, au meme endroit elle aussi, ne doit pas '
              'disparaitre du repere fusionne',
        );
      },
    );

    testWidgets(
      'deux points d interet voisins ne se recouvrent pas non plus — le '
      'defaut ne concerne pas que le couple etape / refuge',
      (tester) async {
        // AUCUNE etape : le couple mesure est shop <-> shelter, a 37,2 m l un
        // de l autre a Cozzano. Le meme defaut, sans numero d etape en jeu.
        await pumpMap(
          tester,
          stages: const [],
          pois: const [giteCozzano, epicerieCozzano],
        );

        final refuge = inMap(find.byIcon(Icons.house));
        final epicerie = inMap(find.byIcon(Icons.shopping_cart));

        expect(refuge, findsOneWidget);

        if (epicerie.evaluate().isEmpty) {
          // Les deux lieux ont fusionne en un seul repere : rien ne se
          // recouvre, c est le resultat attendu a ce zoom.
          return;
        }

        final rectRefuge = tester.getRect(refuge);
        final rectEpicerie = tester.getRect(epicerie);
        expect(
          rectRefuge.overlaps(rectEpicerie),
          isFalse,
          reason: 'l icone du gite $rectRefuge recouvre celle de l epicerie '
              '$rectEpicerie : deux reperes distincts doivent etre lisibles, '
              'ou etre fusionnes en un seul',
        );
      },
    );
  });
}
