import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/presentation/map/controls/map_controls.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget du composant MapControls (Phase 2 E2.3c).
///
/// Verifie que MapControls est un StatelessWidget qui affiche
/// 4 FloatingActionButton (changer de peau, zoom in, zoom out, center on me).
/// SW-SKIN-L7 : ajout de l'acces « Changer de peau » (4e bouton).
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.setLocaleRaw('fr');
  });

  group('MapControls', () {
    late MapController mapController;

    setUp(() {
      mapController = MapController();
    });

    testWidgets('affiche 4 FloatingActionButton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true),
              home: Scaffold(
                body: MapControls(
                  mapController: mapController,
                  onCenterOnMe: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // 4 FAB dans l arbre (SW-SKIN-L7 : + changer de peau)
      expect(find.byType(FloatingActionButton), findsNWidgets(4));

      // Icones attendues
      expect(find.byIcon(Icons.brush_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    test('est un StatelessWidget', () {
      final widget = MapControls(
        mapController: mapController,
        onCenterOnMe: () {},
      );
      expect(widget, isA<StatelessWidget>());
    });

    test('expose mapController et onCenterOnMe', () {
      callback() {}
      final widget = MapControls(
        mapController: mapController,
        onCenterOnMe: callback,
      );
      expect(widget.mapController, same(mapController));
      expect(widget.onCenterOnMe, same(callback));
    });
  });
}
