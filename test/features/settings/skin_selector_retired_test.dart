import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/skin_provider.dart';
import 'package:moteur_gr/core/theme/skin_theme.dart';
import 'package:moteur_gr/features/settings/presentation/settings_screen.dart';
import 'package:moteur_gr/features/trek/presentation/map/controls/map_controls.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 570, S4 — LE SELECTEUR DE PEAUX EST RETIRE, LE MOTEUR DE PEAUX RESTE.
///
/// LA MESURE QUI A MOTIVE LA DECISION. Sur les trois proprietes qui distinguent
/// les peaux, une seule est lue : `headerStyle` par un unique widget
/// (`app_gradient_header.dart`). `cardStyle` n'est lue par PERSONNE,
/// `photoScrimOpacity` par personne non plus — et les commentaires de
/// `skin_theme.dart` l'avouaient, en renvoyant a des lots jamais faits (« Lu
/// par L5 », « Lu par L3/L5 », « Dimensionne en L9 »). Grand Air n'a meme pas
/// ses photos. On offrait donc un choix entre trois peaux dont deux n'existent
/// pas. Decision de Chris du 26/09, un mot : « retire ».
///
/// CE QUI PART : le SELECTEUR (les deux portes — Reglages et carte) et ses
/// libelles.
/// CE QUI RESTE, ET C'EST VOULU : le code des peaux ([AppSkin], [SkinTheme],
/// [skinProvider], la resolution dans le theme). Le jour ou les trois peaux
/// existent vraiment, on remet le choix — on ne le reecrit pas.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.setLocaleRaw('fr');
  });

  // =========================================================================
  // LES DEUX PORTES DU SELECTEUR SONT FERMEES
  // =========================================================================
  group('S4 — plus aucune porte vers le selecteur de peaux', () {
    testWidgets('la carte n offre plus « changer de peau » (3 FAB, pas 4)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true),
              home: Scaffold(
                body: MapControls(
                  mapController: MapController(),
                  onCenterOnMe: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zoom +, zoom -, centrer : trois gestes de carte, et c'est tout.
      expect(find.byType(FloatingActionButton), findsNWidgets(3),
          reason: 'le 4e FAB ouvrait le selecteur de peaux, il est retire');
      expect(find.byIcon(Icons.brush_outlined), findsNothing,
          reason: 'l icone pinceau etait l entree du selecteur');
    });

    testWidgets('les Reglages n ont plus de section Apparence', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      tester.view.physicalSize = const Size(900, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/settings',
                routes: [
                  GoRoute(
                      path: '/settings',
                      builder: (_, __) => const SettingsScreen()),
                  GoRoute(path: '/consent', builder: (_, __) => const SizedBox()),
                  GoRoute(
                      path: '/recovery-code',
                      builder: (_, __) => const SizedBox()),
                  GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // L'ecran est bien celui des Reglages (repere sur une section gardee).
      expect(find.text(t.settings.theme), findsWidgets);
      // Mais plus rien n'y propose de choisir une peau.
      expect(
        find.byIcon(Icons.brush_outlined),
        findsNothing,
        reason: 'la section Apparence portait cette icone, elle est retiree',
      );
      for (final nom in <String>['Sentier Vivant', 'Topographique', 'Grand Air']) {
        expect(find.textContaining(nom, skipOffstage: false), findsNothing,
            reason: 'le selecteur propose encore la peau « $nom »');
      }
    });
  });

  // =========================================================================
  // LE MOTEUR DE PEAUX SURVIT — pour pouvoir remettre le choix un jour
  // =========================================================================
  group('S4 — le code des peaux est garde, pas supprime', () {
    test('les trois peaux et leurs themes se resolvent toujours', () {
      expect(AppSkin.values.length, 3);
      for (final skin in AppSkin.values) {
        final theme = SkinTheme.fromSkin(skin);
        expect(theme.headerStyle, isNotNull,
            reason: 'la peau $skin doit garder son style d en-tete');
      }
    });

    test('le provider de peau existe et sert une peau par defaut', () {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(AppSkin.values, contains(container.read(skinProvider)));
    });
  });
}
