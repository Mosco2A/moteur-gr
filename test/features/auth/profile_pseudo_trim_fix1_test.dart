import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/features/auth/data/local_auth_service.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';

/// NON-REGRESSION FIX-1 — finding m2 : le pseudo n'etait jamais `trim`.
///
/// Un pseudo de 3 espaces etait accepte tel quel. Desormais : bouton
/// Enregistrer DESACTIVE tant que le pseudo est vide une fois les espaces
/// retires (etat visible), et pseudo trimme a l'enregistrement.
void main() {
  late LocalAuthService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = LocalAuthService();
    await service.signInAnonymously();
  });

  tearDown(() {
    service.dispose();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(service)],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home/profile',
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: SizedBox()),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, __) => const ProfileScreen(),
                  ),
                ],
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  /// `pumpAndSettle` est inutilisable ici : l'ecran profil heberge des
  /// indicateurs de chargement (infos paquet / etat cloud) qui animent en
  /// permanence. On pompe donc un nombre BORNE de frames.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openPseudoEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await settle(tester);
    // Le flux d'auth n'emet que sur CHANGEMENT : on provoque une emission une
    // fois l'ecran abonne, sinon il reste en chargement.
    await service.updateDisplayName('Randonneuse');
    await settle(tester);

    final display = find.text('Randonneuse');
    expect(display, findsWidgets,
        reason: 'le pseudo courant doit etre affiche avant edition');
    await tester.ensureVisible(display.first);
    await settle(tester);
    await tester.tap(display.first);
    await settle(tester);
  }

  AppButton saveButton(WidgetTester tester) => tester
      .widget<AppButton>(find.byKey(const ValueKey('profile-pseudo-save')));

  group('m2 — pseudo : trim et refus visible du pseudo vide', () {
    testWidgets('un pseudo de 3 espaces laisse le bouton DESACTIVE',
        (tester) async {
      await openPseudoEditor(tester);

      await tester.enterText(
          find.byKey(const ValueKey('profile-pseudo-field')), '   ');
      await settle(tester);

      expect(saveButton(tester).onPressed, isNull,
          reason: 'un pseudo vide apres trim ne peut pas etre enregistre');
      expect(service.currentUser!.displayName, 'Randonneuse');
    });

    testWidgets('les espaces autour du pseudo sont retires a l enregistrement',
        (tester) async {
      await openPseudoEditor(tester);

      await tester.enterText(
          find.byKey(const ValueKey('profile-pseudo-field')), '  Lea  ');
      await settle(tester);

      expect(saveButton(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('profile-pseudo-save')));
      await settle(tester);

      expect(service.currentUser!.displayName, 'Lea');
    });
  });
}
