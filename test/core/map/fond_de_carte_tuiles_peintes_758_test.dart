import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/map_pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';

/// TACHE 758 — LA PREMIERE IMAGE EST DEJA A LA BONNE ECHELLE.
///
/// CE QUE LA GARDE DU LOT 751 PROUVAIT, ET POURQUOI ELLE NE SUFFISAIT PAS.
/// Elle verifiait que la [TileLayer] existe des la premiere construction,
/// qu'elle a un fournisseur, que son `minZoom` vaut 0, et que la camera est
/// sur le sentier et non sur Kiev. Ces quatre cas etaient VERTS le 09/10 — et
/// Christophe voyait quand meme un fond gris uni pendant pres de cinq minutes.
/// Une couche presente, configuree et bien centree ne dit RIEN de l'ECHELLE a
/// laquelle elle demande ses tuiles.
///
/// LE DEFAUT, MESURE SUR L'EMULATEUR LE 09/10. `MapOptions` recevait
/// `initialCenter` mais PAS `initialZoom`. `flutter_map` ouvrait donc au zoom
/// 13 par DEFAUT, et la couche demandait une pleine fournee de tuiles A CE
/// ZOOM-LA ; le cadrage d'ouverture (`initialCameraFit`) n'etait applique
/// qu'au post-frame suivant, a une AUTRE echelle. Releve de l'instrumentation
/// posee dans le fournisseur de tuiles : 80 tuiles de zoom 13 demandees en 72
/// millisecondes pour une vue jamais affichee, 90 tuiles de zoom 12 — les
/// vraies — mises en file derriere elles sur le meme client HTTP, puis 37
/// SECONDES sans aucune demande nouvelle, le temps que la file se vide.
///
/// CE QUE CETTE GARDE MESURE. Que l'application du cadrage d'ouverture est un
/// NON-EVENEMENT : des la premiere image ou la couche de tuiles existe, la
/// camera est DEJA celle que `initialCameraFit` produirait. Si elle ne l'est
/// pas, c'est qu'une fournee de tuiles part pour une vue qui sera jetee.
///
/// CE QU'ELLE NE PROUVE PAS, ET IL FAUT LE DIRE. Elle ne mesure ni le reseau,
/// ni le nombre de tuiles reellement telechargees, ni les pixels a l'ecran :
/// hors appareil le fournisseur est inerte (`test_inert_tile_provider.dart`)
/// et rend une image transparente sans aucune requete. Le delai vu par le
/// randonneur ne se mesure que sur l'appareil, chronometre en main, et c'est
/// ce que fait la recette du lot 758. Cette garde tient l'autre bout : elle
/// refuse le retour de la CAUSE, une premiere fournee de tuiles demandee a la
/// mauvaise echelle.
void main() {
  // Une trace de la taille d'un vrai sentier corse.
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

  Future<void> ouvrirLaCarte(WidgetTester tester) {
    return tester.pumpWidget(
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
  }

  /// La camera telle qu'elle est VUE PAR LA COUCHE DE TUILES — c'est elle qui
  /// decide des tuiles demandees, pas celle du widget parent.
  MapCamera cameraDeLaCouche(WidgetTester tester) =>
      MapCamera.of(tester.element(find.byType(TileLayer).first));

  /// Le cadrage que la carte VISE, applique a la camera qu'elle a reellement.
  MapCamera cadrageVise(WidgetTester tester, MapCamera camera) {
    final carte = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final fit = carte.options.initialCameraFit;
    expect(
      fit,
      isNotNull,
      reason: 'sans cadrage d ouverture, cette garde n a rien a comparer',
    );
    return fit!.fit(camera);
  }

  void exigerQueLeCadrageSoitDejaFait(WidgetTester tester, String quand) {
    final camera = cameraDeLaCouche(tester);
    final vise = cadrageVise(tester, camera);
    expect(
      camera.zoom,
      closeTo(vise.zoom, 0.01),
      reason:
          'LE DEFAUT DE LA TACHE 758 ($quand) : la couche de tuiles travaille '
          'au zoom ${camera.zoom.toStringAsFixed(2)} alors que le cadrage '
          'd ouverture vise ${vise.zoom.toStringAsFixed(2)}. Toutes les '
          'tuiles demandees a cette echelle-la seront JETEES quand le cadrage '
          's appliquera au post-frame, et les vraies tuiles passeront derriere '
          'elles dans la file du client HTTP. C est ce qui laissait le fond '
          'gris pres de cinq minutes a la premiere entree, mot pour mot de '
          'Christophe le 09/10 a 16:24 : « il faut sortir de navigation et y '
          'revenir pour avoir la carte qui s affiche ». Donner `initialZoom` '
          'en meme temps que `initialCenter` suffit a l eviter.',
    );
    expect(
      camera.center.latitude,
      closeTo(vise.center.latitude, 0.0001),
      reason:
          'la premiere fournee de tuiles doit viser le MEME endroit que le '
          'cadrage d ouverture ($quand)',
    );
    expect(
      camera.center.longitude,
      closeTo(vise.center.longitude, 0.0001),
      reason:
          'la premiere fournee de tuiles doit viser le MEME endroit que le '
          'cadrage d ouverture ($quand)',
    );
  }

  group('la premiere image de la carte est deja cadree (758)', () {
    testWidgets('DES LA PREMIERE IMAGE ou la couche existe, appliquer le '
        'cadrage d ouverture ne changerait RIEN', (tester) async {
      await ouvrirLaCarte(tester);
      // Une seule frame apres l arrivee de la trace : c est la toute premiere
      // image de carte que voit le randonneur, et c est a cet instant que la
      // couche de tuiles fait sa premiere demande.
      await tester.pump();

      expect(
        find.byType(TileLayer),
        findsWidgets,
        reason: 'sans couche de tuiles, il n y a meme pas de fond a demander',
      );
      exigerQueLeCadrageSoitDejaFait(tester, 'premiere image');
      expect(tester.takeException(), isNull);
    });

    testWidgets('et cela reste vrai une fois toutes les donnees arrivees', (
      tester,
    ) async {
      await ouvrirLaCarte(tester);
      await tester.pumpAndSettle();

      exigerQueLeCadrageSoitDejaFait(tester, 'carte posee');
      expect(tester.takeException(), isNull);
    });
  });
}
