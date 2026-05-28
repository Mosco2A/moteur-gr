import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/stage_markers_layer.dart';

/// Tests du widget StageMarkersLayer.
///
/// Verifie que le layer genere le bon nombre de markers FlutterMap v8
/// et que les couleurs (depart vert, arrivee rouge, intermediaires bleu)
/// sont correctement attribuees.
void main() {
  /// Helper pour creer une Stage de test sans nom de lieu specifique.
  Stage makeStage(String id, int orderIndex) {
    return Stage(
      id: id,
      nameFr: 'Etape $id',
      nameEn: 'Stage $id',
      distance: 10.0,
      elevationGain: 500,
      elevationLoss: 400,
      estimatedDurationMinutes: 300,
      orderIndex: orderIndex,
      startLat: 42.0 + orderIndex * 0.1,
      startLng: 9.0 + orderIndex * 0.1,
      endLat: 42.0 + orderIndex * 0.1 + 0.05,
      endLng: 9.0 + orderIndex * 0.1 + 0.05,
    );
  }

  group('StageMarkersLayer', () {
    test('genere le bon nombre de markers', () {
      final stages = [
        makeStage('s1', 0),
        makeStage('s2', 1),
        makeStage('s3', 2),
        makeStage('s4', 3),
        makeStage('s5', 4),
      ];

      String? tappedId;
      final layer = StageMarkersLayer(
        stages: stages,
        onStageTap: (id) => tappedId = id,
      );

      // Build retourne un MarkerLayer — extraire la liste de markers
      final element = layer.build(
        // Minimal BuildContext via StatelessElement
        _FakeBuildContext(),
      );

      expect(element, isA<MarkerLayer>());
      final markerLayer = element as MarkerLayer;
      expect(markerLayer.markers.length, stages.length);
    });

    test('liste vide genere zero markers', () {
      final layer = StageMarkersLayer(
        stages: const [],
        onStageTap: (_) {},
      );

      final element = layer.build(_FakeBuildContext());
      final markerLayer = element as MarkerLayer;
      expect(markerLayer.markers.length, 0);
    });

    test('une seule etape genere un marker', () {
      final layer = StageMarkersLayer(
        stages: [makeStage('solo', 0)],
        onStageTap: (_) {},
      );

      final element = layer.build(_FakeBuildContext());
      final markerLayer = element as MarkerLayer;
      expect(markerLayer.markers.length, 1);
    });

    test('markers sont positionnes sur startLat/startLng de chaque etape', () {
      final stages = [makeStage('a', 0), makeStage('b', 1)];
      final layer = StageMarkersLayer(
        stages: stages,
        onStageTap: (_) {},
      );

      final markerLayer = layer.build(_FakeBuildContext()) as MarkerLayer;
      for (int i = 0; i < stages.length; i++) {
        expect(markerLayer.markers[i].point.latitude, stages[i].startLat);
        expect(markerLayer.markers[i].point.longitude, stages[i].startLng);
      }
    });

    group('colorForIndex', () {
      test('index 0 est vert (depart)', () {
        expect(
          StageMarkersLayer.colorForIndex(0, 5),
          const Color(0xFF2E7D32),
        );
      });

      test('dernier index est rouge (arrivee)', () {
        expect(
          StageMarkersLayer.colorForIndex(4, 5),
          const Color(0xFFC62828),
        );
      });

      test('index intermediaire est bleu', () {
        expect(
          StageMarkersLayer.colorForIndex(2, 5),
          const Color(0xFF1565C0),
        );
      });

      test('total 1 : index 0 est vert (depart = arrivee)', () {
        // Un seul element : index 0 est le depart -> vert
        expect(
          StageMarkersLayer.colorForIndex(0, 1),
          const Color(0xFF2E7D32),
        );
      });

      test('total 2 : index 0 vert, index 1 rouge', () {
        expect(
          StageMarkersLayer.colorForIndex(0, 2),
          const Color(0xFF2E7D32),
        );
        expect(
          StageMarkersLayer.colorForIndex(1, 2),
          const Color(0xFFC62828),
        );
      });

      test('total 0 retourne bleu par defaut', () {
        expect(
          StageMarkersLayer.colorForIndex(0, 0),
          const Color(0xFF1565C0),
        );
      });
    });
  });
}

/// Minimal BuildContext stub pour appeler build() sans widget tree complet.
/// Suffisant pour StageMarkersLayer qui ne lit pas le context.
class _FakeBuildContext extends Fake implements BuildContext {}
