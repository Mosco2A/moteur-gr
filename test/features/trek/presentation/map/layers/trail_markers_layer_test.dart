import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/features/map/widgets/poi_marker.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/stage_markers_layer.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/trail_markers_layer.dart';

/// TACHE 571 — LA COUCHE UNIQUE DES REPERES DU SENTIER.
///
/// Les tests d'ecran ([map_screen_marker_overlap_test]) prouvent que le numero
/// d'etape n'est plus recouvert et que le tap rend les deux informations. Ceux
/// d'ici verrouillent la COMPOSITION du repere, a des zooms CHOISIS :
///  * un repere seul est dessine comme avant — aucune regression sur le cas
///    courant, qui est le plus frequent ;
///  * un repere fusionne porte le numero d'etape ET la nature du lieu, et
///    annonce les lieux supplementaires ;
///  * au plus fin, les lieux reellement distincts reprennent chacun leur
///    repere.
///
/// Coordonnees reelles du Mare a Mare Centre (assets/data/mare_a_mare_centre).
void main() {
  const cozzano = LatLng(41.9392, 9.1978);

  const etape3 = Stage(
    id: '3',
    nameFr: 'Cozzano',
    distance: 12.5,
    elevationGain: 640,
    elevationLoss: 520,
    orderIndex: 3,
    startLat: 41.9392,
    startLng: 9.1978,
    endLat: 41.9147,
    endLng: 9.1411,
  );

  const gite = PoiModel(
    id: 31,
    trailId: 'mare-a-mare',
    stageNumber: 3,
    name: 'Gite d etape de Cozzano',
    type: 'shelter',
    lat: 41.9392,
    lng: 9.1978,
    altitudeM: 727,
  );

  const epicerie = PoiModel(
    id: 32,
    trailId: 'mare-a-mare',
    stageNumber: 3,
    name: 'Epicerie de Cozzano',
    type: 'shop',
    lat: 41.9395,
    lng: 9.198,
    altitudeM: 730,
  );

  Future<void> pumpLayer(
    WidgetTester tester, {
    required List<Stage> stages,
    required List<PoiModel> pois,
    required double zoom,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: MapOptions(initialCenter: cozzano, initialZoom: zoom),
            children: [
              TrailMarkersLayer(stages: stages, pois: pois, zoom: zoom),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> markersOf(WidgetTester tester) =>
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;

  group('TrailMarkersLayer', () {
    testWidgets(
      'une etape seule garde EXACTEMENT le repere d avant : un disque '
      'numerote, sans pastille',
      (tester) async {
        await pumpLayer(
          tester,
          stages: const [etape3],
          pois: const [],
          zoom: 14,
        );

        expect(markersOf(tester).length, 1);
        expect(find.byType(StageNumberCircle), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.byType(PoiMarker), findsNothing);
      },
    );

    testWidgets(
      'un point d interet seul garde EXACTEMENT son icone d avant',
      (tester) async {
        await pumpLayer(
          tester,
          stages: const [],
          pois: const [gite],
          zoom: 14,
        );

        expect(markersOf(tester).length, 1);
        expect(find.byType(PoiMarker), findsOneWidget);
        expect(find.byIcon(Icons.house), findsOneWidget);
        expect(find.byType(StageNumberCircle), findsNothing);
      },
    );

    testWidgets(
      'etape et gite au meme point : UN SEUL repere, qui porte le numero ET '
      'l icone du lieu',
      (tester) async {
        await pumpLayer(
          tester,
          stages: const [etape3],
          pois: const [gite],
          zoom: 14,
        );

        expect(
          markersOf(tester).length,
          1,
          reason: 'deux marqueurs au meme point doivent n en faire qu un',
        );
        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.house), findsOneWidget);

        // Et le numero reste lisible : sa surface ne croise pas la pastille.
        expect(
          tester.getRect(find.text('3')).overlaps(
                tester.getRect(find.byIcon(Icons.house)),
              ),
          isFalse,
        );
      },
    );

    testWidgets(
      'trois reperes reunis : le repere annonce le lieu principal et COMPTE '
      'les autres',
      (tester) async {
        await pumpLayer(
          tester,
          stages: const [etape3],
          pois: const [gite, epicerie],
          zoom: 14,
        );

        expect(markersOf(tester).length, 1);
        expect(find.text('3'), findsOneWidget);
        // Le couchage passe devant le commerce : c est l ordre des decisions
        // d un randonneur, et la pastille porte donc le gite.
        expect(find.byIcon(Icons.house), findsOneWidget);
        expect(find.byIcon(Icons.shopping_cart), findsNothing);
        // Un lieu de plus est reuni ici, et le repere le dit.
        expect(find.text('+1'), findsOneWidget);
      },
    );

    testWidgets(
      'au plus fin, les lieux reellement distincts reprennent chacun leur '
      'repere — on ne fusionne pas ce qui se distingue',
      (tester) async {
        await pumpLayer(
          tester,
          stages: const [],
          pois: const [gite, epicerie],
          zoom: 20,
        );

        expect(markersOf(tester).length, 2);
        expect(find.byIcon(Icons.house), findsOneWidget);
        expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
        expect(
          tester.getRect(find.byIcon(Icons.house)).overlaps(
                tester.getRect(find.byIcon(Icons.shopping_cart)),
              ),
          isFalse,
        );
      },
    );

    testWidgets('sans etape ni point d interet, la couche ne rend rien',
        (tester) async {
      await pumpLayer(tester, stages: const [], pois: const [], zoom: 14);
      expect(find.byType(MarkerLayer), findsNothing);
    });
  });
}
