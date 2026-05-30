import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/user_position_layer.dart';

/// Tests widget du composant UserPositionLayer (Phase 2 E2.3e).
///
/// Verifie que UserPositionLayer retourne SizedBox.shrink si position null,
/// et affiche CircleLayer + MarkerLayer si position non null.
void main() {
  group('UserPositionLayer', () {
    test('est un StatelessWidget', () {
      const layer = UserPositionLayer(position: null);
      expect(layer, isA<StatelessWidget>());
    });

    testWidgets('retourne SizedBox.shrink si position null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserPositionLayer(position: null),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.byType(CircleLayer), findsNothing);
    });

    testWidgets('affiche MarkerLayer si position non null', (tester) async {
      const pos = LatLng(42.0, 9.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: MapOptions(),
              children: [
                UserPositionLayer(
                  position: pos,
                  accuracy: 50.0,
                ),
              ],
            ),
          ),
        ),
      );

      // Le layer doit etre present
      expect(find.byType(UserPositionLayer), findsOneWidget);

      // MarkerLayer pour le point bleu
      expect(find.byType(MarkerLayer), findsOneWidget);

      // CircleLayer pour le cercle de precision
      expect(find.byType(CircleLayer), findsOneWidget);
    });

    testWidgets('pas de CircleLayer si accuracy null', (tester) async {
      const pos = LatLng(42.0, 9.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: MapOptions(),
              children: [
                UserPositionLayer(
                  position: pos,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.byType(CircleLayer), findsNothing);
    });

    test('valeurs par defaut correctes', () {
      const layer = UserPositionLayer(position: null);
      expect(layer.markerSize, 20.0);
      expect(layer.accuracy, isNull);
      expect(layer.accuracyColor, const Color(0x301976D2));
      expect(layer.accuracyBorderColor, const Color(0x601976D2));
    });
  });
}
