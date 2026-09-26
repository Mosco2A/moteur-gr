import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/presentation/map/controls/map_controls.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget du composant MapControls (Phase 2 E2.3c).
///
/// Verifie que MapControls est un StatelessWidget qui affiche
/// 3 FloatingActionButton (zoom in, zoom out, center on me).
/// TACHE 570 (S4) : le 4e bouton ouvrait le selecteur de peaux, retire.
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

    testWidgets('affiche 3 FloatingActionButton', (tester) async {
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

      // 3 FAB dans l arbre (le bouton de peau est retire, tache 570)
      expect(find.byType(FloatingActionButton), findsNWidgets(3));

      // Icones attendues. Le pinceau (selecteur de peaux) est retire : on
      // exige son ABSENCE, pour qu'il ne revienne pas par inadvertance.
      expect(find.byIcon(Icons.brush_outlined), findsNothing);
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
