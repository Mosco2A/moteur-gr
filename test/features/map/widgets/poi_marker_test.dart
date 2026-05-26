import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/features/map/widgets/poi_marker.dart';

/// Tests du widget PoiMarker.
///
/// Vérifie que chaque PoiType produit une icône
/// et une couleur spécifiques.
void main() {
  group('PoiMarker', () {
    group('iconFor', () {
      test('shelter retourne Icons.house', () {
        expect(PoiMarker.iconFor(PoiType.shelter), Icons.house);
      });

      test('water retourne Icons.water_drop', () {
        expect(PoiMarker.iconFor(PoiType.water), Icons.water_drop);
      });

      test('viewpoint retourne Icons.visibility', () {
        expect(PoiMarker.iconFor(PoiType.viewpoint), Icons.visibility);
      });

      test('campsite retourne Icons.holiday_village', () {
        expect(PoiMarker.iconFor(PoiType.campsite), Icons.holiday_village);
      });

      test('restaurant retourne Icons.restaurant', () {
        expect(PoiMarker.iconFor(PoiType.restaurant), Icons.restaurant);
      });

      test('emergency retourne Icons.local_hospital', () {
        expect(PoiMarker.iconFor(PoiType.emergency), Icons.local_hospital);
      });

      test('danger retourne Icons.warning', () {
        expect(PoiMarker.iconFor(PoiType.danger), Icons.warning);
      });

      test('shop retourne Icons.shopping_bag', () {
        expect(PoiMarker.iconFor(PoiType.shop), Icons.shopping_bag);
      });
    });

    group('colorFor', () {
      test('chaque type a une couleur unique', () {
        final colors = PoiType.values.map(PoiMarker.colorFor).toSet();
        expect(colors.length, PoiType.values.length);
      });

      test('shelter est brun', () {
        expect(PoiMarker.colorFor(PoiType.shelter), const Color(0xFF5D4037));
      });

      test('water est bleu', () {
        expect(PoiMarker.colorFor(PoiType.water), const Color(0xFF1565C0));
      });

      test('viewpoint est vert', () {
        expect(
          PoiMarker.colorFor(PoiType.viewpoint),
          const Color(0xFF2E7D32),
        );
      });

      test('danger est orange', () {
        expect(PoiMarker.colorFor(PoiType.danger), const Color(0xFFEF6C00));
      });

      test('emergency est rouge', () {
        expect(
          PoiMarker.colorFor(PoiType.emergency),
          const Color(0xFFC62828),
        );
      });
    });

    group('widget', () {
      Widget buildMarker(PoiType type) {
        return MaterialApp(
          home: Scaffold(body: PoiMarker(type: type)),
        );
      }

      testWidgets('affiche l\'icône correcte pour shelter', (tester) async {
        await tester.pumpWidget(buildMarker(PoiType.shelter));
        expect(find.byIcon(Icons.house), findsOneWidget);
      });

      testWidgets('affiche l\'icône correcte pour water', (tester) async {
        await tester.pumpWidget(buildMarker(PoiType.water));
        expect(find.byIcon(Icons.water_drop), findsOneWidget);
      });

      testWidgets('affiche l\'icône correcte pour danger', (tester) async {
        await tester.pumpWidget(buildMarker(PoiType.danger));
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('l\'icône est blanche', (tester) async {
        await tester.pumpWidget(buildMarker(PoiType.viewpoint));
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, Colors.white);
      });

      testWidgets('le conteneur est rond avec bordure blanche',
          (tester) async {
        await tester.pumpWidget(buildMarker(PoiType.campsite));
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
        expect(decoration.border, isNotNull);
      });

      testWidgets('respecte la taille par défaut de 36', (tester) async {
        await tester.pumpWidget(buildMarker(PoiType.shop));
        final container = tester.widget<Container>(find.byType(Container));
        expect(container.constraints?.maxWidth, 36);
      });
    });
  });
}
