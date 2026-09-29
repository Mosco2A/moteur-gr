import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/map/widgets/poi_marker.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';

/// Tests du widget PoiMarker.
///
/// Vérifie que chaque PoiType produit une icône
/// et une couleur spécifiques.
void main() {
  group('PoiMarker', () {
    group('iconFor', () {
      test('shelter retourne StepwaysIcons.hebergement', () {
        expect(PoiMarker.iconFor('shelter'), StepwaysIcons.hebergement);
      });

      test('water retourne StepwaysIcons.pluie', () {
        expect(PoiMarker.iconFor('water'), StepwaysIcons.pluie);
      });

      test('viewpoint retourne StepwaysIcons.oeil', () {
        expect(PoiMarker.iconFor('viewpoint'), StepwaysIcons.oeil);
      });

      test('campsite retourne StepwaysIcons.hebergement', () {
        expect(PoiMarker.iconFor('campsite'), StepwaysIcons.hebergement);
      });

      test('restaurant retourne StepwaysIcons.restauration', () {
        expect(PoiMarker.iconFor('restaurant'), StepwaysIcons.restauration);
      });

      test('emergency retourne StepwaysIcons.secours', () {
        expect(PoiMarker.iconFor('emergency'), StepwaysIcons.secours);
      });

      test('danger retourne StepwaysIcons.danger', () {
        expect(PoiMarker.iconFor('danger'), StepwaysIcons.danger);
      });

      test('shop retourne StepwaysIcons.panier', () {
        expect(PoiMarker.iconFor('shop'), StepwaysIcons.panier);
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
        expect(find.byWidgetPredicate((w) => w is StepIcon && w.asset == StepwaysIcons.hebergement), findsOneWidget);
      });

      testWidgets('affiche l\'icône correcte pour water', (tester) async {
        await tester.pumpWidget(buildMarker('water'));
        expect(find.byWidgetPredicate((w) => w is StepIcon && w.asset == StepwaysIcons.pluie), findsOneWidget);
      });

      testWidgets('affiche l\'icône correcte pour danger', (tester) async {
        await tester.pumpWidget(buildMarker('danger'));
        expect(find.byWidgetPredicate((w) => w is StepIcon && w.asset == StepwaysIcons.danger), findsOneWidget);
      });

      testWidgets('l\'icône est blanche', (tester) async {
        await tester.pumpWidget(buildMarker('viewpoint'));
        final icon = tester.widget<StepIcon>(find.byType(StepIcon));
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
