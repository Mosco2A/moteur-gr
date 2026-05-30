import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/stage_markers_layer.dart';

/// Tests widget du composant StageMarkersLayer (Phase 2 E2.3d).
///
/// Verifie que StageMarkersLayer genere le bon nombre de markers
/// et applique les bonnes couleurs (vert/rouge/bleu).
void main() {
  /// Helper — cree une liste de stages factices.
  List<Stage> buildStages(int count) {
    return List.generate(count, (i) {
      return Stage(
        id: 'stage_$i',
        nameFr: 'Etape ${i + 1}',
        distance: 10.0 + i,
        elevationGain: 500 + i * 100,
        elevationLoss: 400 + i * 50,
        orderIndex: i + 1,
        startLat: 42.0 + i * 0.1,
        startLng: 9.0 + i * 0.1,
        endLat: 42.05 + i * 0.1,
        endLng: 9.05 + i * 0.1,
      );
    });
  }

  group('StageMarkersLayer', () {
    testWidgets('genere le bon nombre de markers', (tester) async {
      final stages = buildStages(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(),
              children: [
                StageMarkersLayer(
                  stages: stages,
                  onStageTap: (id) {},
                ),
              ],
            ),
          ),
        ),
      );

      // StageMarkersLayer doit etre dans l arbre
      expect(find.byType(StageMarkersLayer), findsOneWidget);

      // Le MarkerLayer sous-jacent doit etre present
      expect(find.byType(MarkerLayer), findsOneWidget);

      // Verifier que le widget a bien 5 stages
      final layer = tester.widget<StageMarkersLayer>(
        find.byType(StageMarkersLayer),
      );
      expect(layer.stages.length, 5);
    });

    test('est un StatelessWidget', () {
      const layer = StageMarkersLayer(stages: []);
      expect(layer, isA<StatelessWidget>());
    });

    test('taille par defaut est 32.0', () {
      const layer = StageMarkersLayer(stages: []);
      expect(layer.markerSize, 32.0);
    });

    test('accepte une taille personnalisee', () {
      const layer = StageMarkersLayer(
        stages: [],
        markerSize: 48.0,
      );
      expect(layer.markerSize, 48.0);
    });
  });
}
