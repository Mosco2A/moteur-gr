import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/features/map/widgets/poi_filter_bar.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';

/// Tests du widget PoiFilterBar.
///
/// Vérifie que les chips s'activent/désactivent
/// et que seuls les types présents dans les données sont affichés.
void main() {
  /// POIs de test avec 3 types distincts
  final testPois = [
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Source',
      type: PoiType.water,
      lat: 45.5,
      lng: 2.8,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Refuge',
      type: PoiType.shelter,
      lat: 45.52,
      lng: 2.82,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 2,
      name: 'Vue',
      type: PoiType.viewpoint,
      lat: 45.54,
      lng: 2.84,
    ),
  ];

  Widget buildFilterBar({List<PoiModel>? pois}) {
    return ProviderScope(
      overrides: [
        poisProvider('test-trail').overrideWith(
          (ref) => Future.value(pois ?? testPois),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: PoiFilterBar(trailId: 'test-trail'),
        ),
      ),
    );
  }

  group('PoiFilterBar', () {
    testWidgets('affiche un chip par type présent', (tester) async {
      await tester.pumpWidget(buildFilterBar());
      await tester.pumpAndSettle();

      // 3 types dans les données de test
      expect(find.byType(FilterChip), findsNWidgets(3));
    });

    testWidgets('affiche les libellés corrects', (tester) async {
      await tester.pumpWidget(buildFilterBar());
      await tester.pumpAndSettle();

      expect(find.text('Eau'), findsOneWidget);
      expect(find.text('Refuge'), findsOneWidget);
      expect(find.text('Vue'), findsOneWidget);
    });

    testWidgets('les chips sont tous activés par défaut', (tester) async {
      await tester.pumpWidget(buildFilterBar());
      await tester.pumpAndSettle();

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      for (final chip in chips) {
        expect(chip.selected, isTrue);
      }
    });

    testWidgets('tap sur un chip le désactive', (tester) async {
      await tester.pumpWidget(buildFilterBar());
      await tester.pumpAndSettle();

      // Taper sur le chip "Eau" pour le désactiver
      await tester.tap(find.text('Eau'));
      await tester.pumpAndSettle();

      // Vérifier que le chip "Eau" est maintenant désactivé
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final waterChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Eau',
      );
      expect(waterChip.selected, isFalse);
    });

    testWidgets('double tap réactive le chip', (tester) async {
      await tester.pumpWidget(buildFilterBar());
      await tester.pumpAndSettle();

      // Désactiver
      await tester.tap(find.text('Eau'));
      await tester.pumpAndSettle();

      // Réactiver
      await tester.tap(find.text('Eau'));
      await tester.pumpAndSettle();

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final waterChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Eau',
      );
      expect(waterChip.selected, isTrue);
    });

    testWidgets('n\'affiche rien quand la liste de POIs est vide',
        (tester) async {
      await tester.pumpWidget(buildFilterBar(pois: []));
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('labelFor retourne le bon libellé pour chaque type', (_) async {
      expect(PoiFilterBar.labelFor(PoiType.shelter), 'Refuge');
      expect(PoiFilterBar.labelFor(PoiType.water), 'Eau');
      expect(PoiFilterBar.labelFor(PoiType.viewpoint), 'Vue');
      expect(PoiFilterBar.labelFor(PoiType.campsite), 'Bivouac');
      expect(PoiFilterBar.labelFor(PoiType.restaurant), 'Restaurant');
      expect(PoiFilterBar.labelFor(PoiType.emergency), 'Urgence');
      expect(PoiFilterBar.labelFor(PoiType.danger), 'Danger');
      expect(PoiFilterBar.labelFor(PoiType.shop), 'Commerce');
    });
  });
}
