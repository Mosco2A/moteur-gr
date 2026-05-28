import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/presentation/map/controls/map_controls.dart';

/// Tests widget de [MapControls].
///
/// Verifie que le composant affiche bien 3 FloatingActionButton
/// avec les icones attendues (zoom in, zoom out, centrer sur moi).
void main() {
  group('MapControls', () {
    late MapController mapController;
    var centerOnMeCalled = false;

    setUp(() {
      mapController = MapController();
      centerOnMeCalled = false;
    });

    Widget buildWidget() {
      return MaterialApp(
        home: Scaffold(
          body: MapControls(
            mapController: mapController,
            onCenterOnMe: () => centerOnMeCalled = true,
          ),
        ),
      );
    }

    testWidgets('affiche 3 FloatingActionButton', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(
        find.byType(FloatingActionButton),
        findsNWidgets(3),
      );
    });

    testWidgets('affiche les icones zoom in, zoom out et centrer',
        (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('le bouton centrer sur moi appelle le callback',
        (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump();

      expect(centerOnMeCalled, isTrue);
    });
  });
}
