import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/poi/domain/poi_type_config.dart';
import 'package:moteur_gr/features/poi/presentation/poi_markers_layer.dart';

/// Tests du widget PoiMarkersLayer.
///
/// Verifie le filtrage par visibleTypes et le fallback icone
/// pour les types de POI inconnus.
void main() {
  /// Helper pour creer un Poi de test.
  Poi makePoi({
    required int id,
    required String type,
    double lat = 42.0,
    double lng = 9.0,
  }) {
    return Poi(
      id: id,
      trailId: 'gr20',
      stageNumber: 1,
      name: 'POI $id',
      description: 'Desc $id',
      type: type,
      lat: lat,
      lng: lng,
      altitudeM: 1000,
    );
  }

  group('PoiMarkersLayer', () {
    test('nombre de markers = nombre de POIs visibles (filtrage par type)', () {
      final pois = [
        makePoi(id: 1, type: 'water'),
        makePoi(id: 2, type: 'refuge'),
        makePoi(id: 3, type: 'water'),
        makePoi(id: 4, type: 'danger'),
        makePoi(id: 5, type: 'shop'),
      ];

      // Seuls water et refuge sont visibles -> 3 POIs attendus
      final visibleTypes = {'water', 'refuge'};

      Poi? tappedPoi;
      final layer = PoiMarkersLayer(
        pois: pois,
        visibleTypes: visibleTypes,
        onPoiTap: (poi) => tappedPoi = poi,
      );

      final element = layer.build(_FakeBuildContext());
      expect(element, isA<MarkerLayer>());

      final markerLayer = element as MarkerLayer;
      expect(markerLayer.markers.length, 3);
    });

    test('POI de type inconnu a icone fallback (location_on gris)', () {
      // Type 'alien_base' n'existe pas dans PoiTypeConfig -> fallback
      final style = PoiTypeConfig.getStyle('alien_base');

      expect(style.icon, Icons.location_on);
      expect(style.color, Colors.grey);
      expect(style.labelKey, 'alien_base');
    });

    test('liste vide genere zero markers', () {
      final layer = PoiMarkersLayer(
        pois: const [],
        visibleTypes: {'water'},
        onPoiTap: (_) {},
      );

      final element = layer.build(_FakeBuildContext());
      final markerLayer = element as MarkerLayer;
      expect(markerLayer.markers.length, 0);
    });

    test('visibleTypes vide genere zero markers meme avec des POIs', () {
      final pois = [
        makePoi(id: 1, type: 'water'),
        makePoi(id: 2, type: 'refuge'),
      ];

      final layer = PoiMarkersLayer(
        pois: pois,
        visibleTypes: const {},
        onPoiTap: (_) {},
      );

      final element = layer.build(_FakeBuildContext());
      final markerLayer = element as MarkerLayer;
      expect(markerLayer.markers.length, 0);
    });

    test('filterVisible retourne uniquement les POIs du type demande', () {
      final pois = [
        makePoi(id: 1, type: 'water'),
        makePoi(id: 2, type: 'shop'),
        makePoi(id: 3, type: 'water'),
      ];

      final filtered = PoiMarkersLayer.filterVisible(pois, {'water'});
      expect(filtered.length, 2);
      expect(filtered.every((p) => p.type == 'water'), isTrue);
    });

    test('markers sont positionnes sur lat/lng du POI', () {
      final pois = [
        makePoi(id: 1, type: 'water', lat: 42.15, lng: 9.22),
      ];

      final layer = PoiMarkersLayer(
        pois: pois,
        visibleTypes: {'water'},
        onPoiTap: (_) {},
      );

      final markerLayer = layer.build(_FakeBuildContext()) as MarkerLayer;
      expect(markerLayer.markers.first.point.latitude, 42.15);
      expect(markerLayer.markers.first.point.longitude, 9.22);
    });
  });
}

/// Minimal BuildContext stub pour appeler build() sans widget tree complet.
/// Suffisant pour PoiMarkersLayer qui ne lit pas le context.
class _FakeBuildContext extends Fake implements BuildContext {}
