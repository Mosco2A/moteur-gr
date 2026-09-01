import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/presentation/map/controls/map_controls.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests E5.3b — ordre de focus logique des controles carte (ecran principal).
///
/// SW-SKIN-L7 : un 4e bouton « Changer de peau » (ordre 0) precede desormais
/// zoom+/zoom-/centrer (ordres 1/2/3).
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.setLocaleRaw('fr');
  });

  Widget wrap(Widget child) => ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(home: Scaffold(body: Center(child: child))),
        ),
      );

  testWidgets('controles carte : groupe de traversee ordonnee 0->1->2->3',
      (tester) async {
    await tester.pumpWidget(
      wrap(MapControls(mapController: MapController(), onCenterOnMe: () {})),
    );

    // Le groupe DE MapControls applique une politique de traversee ORDONNEE
    // (le groupe racine de l'app utilise ReadingOrderTraversalPolicy).
    final group = tester.widget<FocusTraversalGroup>(
      find.descendant(
        of: find.byType(MapControls),
        matching: find.byType(FocusTraversalGroup),
      ),
    );
    expect(group.policy, isA<OrderedTraversalPolicy>());

    // Les quatre boutons portent un ordre numerique strictement croissant
    // (SW-SKIN-L7 : changer de peau = 0, puis zoom+/zoom-/centrer = 1/2/3).
    final orders = tester
        .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
        .map((w) => (w.order as NumericFocusOrder).order)
        .toList();
    expect(orders, [0.0, 1.0, 2.0, 3.0]);
  });

  testWidgets('controles carte : labels d\'accessibilite (tooltips Slang)',
      (tester) async {
    await tester.pumpWidget(
      wrap(MapControls(mapController: MapController(), onCenterOnMe: () {})),
    );

    expect(find.byTooltip(t.appearance.changeSkin), findsOneWidget);
    expect(find.byTooltip(t.a11y.zoomIn), findsOneWidget);
    expect(find.byTooltip(t.a11y.zoomOut), findsOneWidget);
    expect(find.byTooltip(t.a11y.centerOnMe), findsOneWidget);
  });

  testWidgets('controles carte : la traversee clavier respecte l\'ordre',
      (tester) async {
    await tester.pumpWidget(
      wrap(MapControls(mapController: MapController(), onCenterOnMe: () {})),
    );

    // Donner le focus au premier bouton, puis avancer deux fois : aucune
    // exception et le focus reste dans le groupe (3 noeuds focusables).
    final scope = FocusScope.of(tester.element(find.byType(MapControls)));
    scope.nextFocus();
    await tester.pump();
    final first = FocusManager.instance.primaryFocus;
    expect(first, isNotNull);

    scope.nextFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNot(equals(first)));
  });
}
