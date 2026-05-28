import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/trace_layer.dart';

/// Tests widget de [TraceLayer].
///
/// Verifie que le composant TraceLayer construit correctement
/// un PolylineLayer avec les points, couleur et epaisseur fournis.
void main() {
  group('TraceLayer', () {
    /// 3 points de test representant un mini-trace.
    final testPoints = [
      const LatLng(42.15, 9.10),
      const LatLng(42.16, 9.11),
      const LatLng(42.17, 9.12),
    ];

    testWidgets('affiche un PolylineLayer avec 3 points', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(),
              children: [
                TraceLayer(points: testPoints),
              ],
            ),
          ),
        ),
      );

      // Le PolylineLayer doit etre present dans l'arbre
      expect(find.byType(PolylineLayer), findsOneWidget);

      // Le TraceLayer lui-meme doit etre present
      expect(find.byType(TraceLayer), findsOneWidget);

      // Verifier que le PolylineLayer contient bien une polyline
      // avec les 3 points fournis
      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      expect(polylineLayer.polylines.length, 1);
      expect(polylineLayer.polylines.first.points.length, 3);
      expect(polylineLayer.polylines.first.points, testPoints);
    });

    testWidgets('utilise la couleur bleue par defaut', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(),
              children: [
                TraceLayer(points: testPoints),
              ],
            ),
          ),
        ),
      );

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      expect(
        polylineLayer.polylines.first.color,
        TraceLayer.defaultColor,
      );
    });

    testWidgets('accepte une couleur personnalisee', (tester) async {
      const customColor = Color(0xFF4CAF50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(),
              children: [
                TraceLayer(
                  points: testPoints,
                  color: customColor,
                ),
              ],
            ),
          ),
        ),
      );

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      expect(polylineLayer.polylines.first.color, customColor);
    });

    testWidgets('utilise l\'epaisseur par defaut de 4.0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(),
              children: [
                TraceLayer(points: testPoints),
              ],
            ),
          ),
        ),
      );

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      expect(
        polylineLayer.polylines.first.strokeWidth,
        TraceLayer.defaultStrokeWidth,
      );
    });
  });
}
