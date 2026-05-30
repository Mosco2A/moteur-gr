import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/trace_layer.dart';

/// Tests widget du composant TraceLayer (Phase 2 E2.3b).
///
/// Verifie que TraceLayer est un StatelessWidget qui produit
/// un PolylineLayer avec les bons parametres (points, couleur, epaisseur).
void main() {
  group('TraceLayer', () {
    testWidgets('affiche un PolylineLayer avec 3 points', (tester) async {
      final points = [
        const LatLng(42.0, 9.0),
        const LatLng(42.1, 9.1),
        const LatLng(42.2, 9.2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(),
              children: [
                TraceLayer(points: points),
              ],
            ),
          ),
        ),
      );

      // TraceLayer doit etre dans l arbre
      expect(find.byType(TraceLayer), findsOneWidget);

      // Le PolylineLayer sous-jacent doit etre present
      expect(find.byType(PolylineLayer), findsOneWidget);

      // Verifier le widget TraceLayer recupere
      final traceLayer = tester.widget<TraceLayer>(find.byType(TraceLayer));
      expect(traceLayer.points.length, 3);
      expect(traceLayer.color, Colors.blue);
      expect(traceLayer.strokeWidth, 4.0);
    });

    test('est un StatelessWidget', () {
      const layer = TraceLayer(points: []);
      expect(layer, isA<StatelessWidget>());
    });

    test('accepte une couleur personnalisee', () {
      const layer = TraceLayer(
        points: [],
        color: Colors.green,
        strokeWidth: 6.0,
      );
      expect(layer.color, Colors.green);
      expect(layer.strokeWidth, 6.0);
    });

    test('couleur par defaut est bleu', () {
      const layer = TraceLayer(points: []);
      expect(layer.color, Colors.blue);
    });

    test('epaisseur par defaut est 4.0', () {
      const layer = TraceLayer(points: []);
      expect(layer.strokeWidth, 4.0);
    });
  });
}
