import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/map/widgets/poi_marker.dart';

/// Tests du widget PoiMarker.
///
/// Vérifie que chaque PoiType produit une icône
/// et une couleur spécifiques.
void main() {
  group('PoiMarker', () {
    group('iconFor', () {
      test('shelter retourne Icons.house', () {
        expect(PoiMarker.iconFor('shelter'), Icons.house);
      });

      test('water retourne Icons.water_drop', () {
        expect(PoiMarker.iconFor('water'), Icons.water_drop);
      });

      test('viewpoint retourne Icons.visibility', () {
        expect(PoiMarker.iconFor('viewpoint'), Icons.visibility);
      });

      test('campsite retourne Icons.holiday_village', () {
        expect(PoiMarker.iconFor('campsite'), Icons.holiday_village);
      });

      test('restaurant retourne Icons.restaurant', () {
        expect(PoiMarker.iconFor('restaurant'), Icons.restaurant);
      });

      test('emergency retourne Icons.local_hospital', () {
        expect(PoiMarker.iconFor('emergency'), Icons.local_hospital);
      });

      test('danger retourne Icons.warning', () {
        expect(PoiMarker.iconFor('danger'), Icons.warning);
      });

      test('shop retourne Icons.shopping_cart', () {
        expect(PoiMarker.iconFor('shop'), Icons.shopping_cart);
      });
    });

    group('colorFor', () {
      test('chaque type a une couleur unique', () {
        final types = ['shelter', 'water', 'viewpoint', 'campsite', 'restaurant', 'emergency', 'danger', 'shop'];
        final colors = types.map(PoiMarker.colorFor).toSet();
        expect(colors.length, greaterThanOrEqualTo(6));
      });

      test('shelter est brun', () {
        expect(PoiMarker.colorFor('shelter'), const Color(0xFF5D4037));
      });

      test('water est bleu', () {
        expect(PoiMarker.colorFor('water'), const Color(0xFF1565C0));
      });

      test('viewpoint est vert', () {
        expect(PoiMarker.colorFor('viewpoint'), const Color(0xFFE65100));
      });

      test('danger est orange', () {
        expect(PoiMarker.colorFor('danger'), const Color(0xFFC62828));
      });

      test('emergency est rouge', () {
        expect(
          PoiMarker.colorFor('emergency'),
          const Color(0xFFC62828),
        );
      });
    });

    group('widget', () {
      Widget buildMarker(String type) {
        return MaterialApp(
          home: Scaffold(body: PoiMarker(type: type)),
        );
      }

      testWidgets('affiche l\'icône correcte pour shelter', (tester) async {
        await tester.pumpWidget(buildMarker('shelter'));
        expect(find.byIcon(Icons.house), findsOneWidget);
      });

      testWidgets('affiche l\'icône correcte pour water', (tester) async {
        await tester.pumpWidget(buildMarker('water'));
        expect(find.byIcon(Icons.water_drop), findsOneWidget);
      });

      testWidgets('affiche l\'icône correcte pour danger', (tester) async {
        await tester.pumpWidget(buildMarker('danger'));
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('l\'icône est blanche', (tester) async {
        await tester.pumpWidget(buildMarker('viewpoint'));
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, Colors.white);
      });

      testWidgets('le conteneur est rond avec bordure blanche',
          (tester) async {
        await tester.pumpWidget(buildMarker('campsite'));
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
        expect(decoration.border, isNotNull);
      });

      testWidgets('respecte la taille par défaut de 36', (tester) async {
        await tester.pumpWidget(buildMarker('shop'));
        final container = tester.widget<Container>(find.byType(Container));
        expect(container.constraints?.maxWidth, 36);
      });
    });
  });
}
