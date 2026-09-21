import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/features/auth/data/local_auth_service.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// NON-REGRESSION MINEUR-1 (campagne personas N2) — le pseudo le plus long que
/// la saisie autorise debordait l'ecran Profil de 126 px.
///
/// La saisie plafonne le pseudo a 30 caracteres (`maxLength: 30`) : l'ecran
/// doit donc savoir afficher 30 caracteres sans bande de debordement. On joue
/// le pire cas possible — 30 caracteres larges et sans espace, donc aucune
/// occasion de passer a la ligne « naturellement ».
void main() {
  /// Largeur logique de l'appareil de reference de la campagne.
  const largeurEcran = 390.0;

  /// Pire cas de pseudo : longueur maximale autorisee, caracteres les plus
  /// larges de la fonte, aucun espace.
  const pseudoLePlusLong = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ';

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

  Future<void> afficherPseudo(WidgetTester tester, String pseudo) async {
    tester.view.physicalSize = const Size(largeurEcran, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await settle(tester);
    // Le flux d'auth n'emet que sur CHANGEMENT : on provoque une emission une
    // fois l'ecran abonne, sinon il reste en chargement.
    await service.updateDisplayName(pseudo);
    await settle(tester);
  }

  group('MINEUR-1 — le pseudo le plus long tient dans l ecran Profil', () {
    testWidgets('30 caracteres ne declenchent aucun debordement de rendu',
        (tester) async {
      await afficherPseudo(tester, pseudoLePlusLong);

      expect(find.text(pseudoLePlusLong), findsOneWidget,
          reason: 'le pseudo enregistre doit rester affiche en entier');
      expect(tester.takeException(), isNull,
          reason: 'aucun debordement de rendu (RenderFlex overflow) ne doit '
              'etre signale par l ecran Profil');
    });

    testWidgets('le pseudo affiche reste dans la largeur de l ecran',
        (tester) async {
      await afficherPseudo(tester, pseudoLePlusLong);

      final largeurPseudo = tester.getSize(find.text(pseudoLePlusLong)).width;
      expect(largeurPseudo, lessThanOrEqualTo(largeurEcran),
          reason: 'le pseudo ne doit pas depasser la largeur de l appareil');
    });

    testWidgets('un pseudo court reste centre et intact', (tester) async {
      await afficherPseudo(tester, 'Lea');

      expect(find.text('Lea'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Contre-preuve : la correction ne doit pas etirer un pseudo court sur
      // toute la largeur (la rangee reste dimensionnee sur son contenu).
      expect(tester.getSize(find.text('Lea')).width,
          lessThan(largeurEcran / 2));
    });
  });
}
