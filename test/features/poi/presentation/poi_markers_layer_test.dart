import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/features/poi/domain/poi_type_config.dart';
import 'package:moteur_gr/features/poi/presentation/poi_markers_layer.dart';

/// Tests E2.5b — PoiMarkersLayer markers filtres par type String + fallback.
void main() {
  /// Helper — cree un PoiModel factice avec le type donne.
  PoiModel buildPoi({
    required String name,
    required String type,
    double lat = 42.0,
    double lng = 9.0,
  }) {
    return PoiModel(
      trailId: 'trail_1',
      stageNumber: 1,
      name: name,
      description: '',
      type: type,
      lat: lat,
      lng: lng,
    );
  }

  group('PoiMarkersLayer', () {
    testWidgets('nombre de markers = nombre de POIs visibles', (tester) async {
      final pois = [
        buildPoi(name: 'Source A', type: 'water', lat: 42.0, lng: 9.0),
        buildPoi(name: 'Refuge B', type: 'refuge', lat: 42.1, lng: 9.1),
        buildPoi(name: 'Danger C', type: 'danger', lat: 42.2, lng: 9.2),
        buildPoi(name: 'Shop D', type: 'shop', lat: 42.3, lng: 9.3),
      ];

      // Seuls water et refuge sont visibles
      final visibleTypes = <String>{'water', 'refuge'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(),
              children: [
                PoiMarkersLayer(
                  pois: pois,
                  visibleTypes: visibleTypes,
                  onPoiTap: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Le widget PoiMarkersLayer est dans l arbre
      expect(find.byType(PoiMarkersLayer), findsOneWidget);

      // MarkerLayer sous-jacent present
      expect(find.byType(MarkerLayer), findsOneWidget);

      // Le widget a bien filtre : 2 visibles sur 4 total
      final layer = tester.widget<PoiMarkersLayer>(
        find.byType(PoiMarkersLayer),
      );
      expect(layer.pois.length, 4);
      expect(layer.visibleTypes.length, 2);

      // Verifier que seuls 2 markers (water + refuge) sont generes
      final markerLayer = tester.widget<MarkerLayer>(
        find.byType(MarkerLayer),
      );
      expect(markerLayer.markers.length, 2);
    });

    testWidgets('POI de type inconnu a icone fallback', (tester) async {
      final pois = [
        buildPoi(name: 'Parking X', type: 'parking_lot', lat: 42.5, lng: 9.5),
        buildPoi(name: 'Source A', type: 'water', lat: 42.0, lng: 9.0),
      ];

      // parking_lot visible, water non visible
      final visibleTypes = <String>{'parking_lot'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(),
              children: [
                PoiMarkersLayer(
                  pois: pois,
                  visibleTypes: visibleTypes,
                ),
              ],
            ),
          ),
        ),
      );

      // Le MarkerLayer doit contenir 1 marker (parking_lot seul visible)
      final markerLayer = tester.widget<MarkerLayer>(
        find.byType(MarkerLayer),
      );
      expect(markerLayer.markers.length, 1);

      // Verifier que PoiTypeConfig retourne le fallback pour un type inconnu
      final fallbackStyle = PoiTypeConfig.getStyle('parking_lot');
      expect(fallbackStyle.icon, Icons.location_on);
      expect(fallbackStyle.color, const Color(0xFF616161));
      expect(fallbackStyle.labelKey, 'parking_lot');

      // Verifier que le marker utilise le bon point
      expect(markerLayer.markers.first.point.latitude, 42.5);
      expect(markerLayer.markers.first.point.longitude, 9.5);
    });
  });
}
