import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/trail/presentation/trail_catalog_screen.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
import 'package:moteur_gr/features/treks/presentation/my_treks_screen.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Q2 (tache 568, LOT Q) — LE RETOUR ARRIERE DU CATALOGUE TOMBAIT SUR UN
/// SENTIER QU ON N AVAIT PAS CHOISI.
///
/// CE QUE CHRIS A VU, verbatim (26/09 09:48) : « ... un retour arriere arrive a
/// mare a mare ». A la PREMIERE ouverture de l'application.
///
/// LA CAUSE, mesuree : on entre au catalogue par `context.go('/catalog')`, qui
/// REMPLACE la pile au lieu d'empiler. Depuis le catalogue il n'y a donc aucun
/// historique : `context.canPop()` est faux, et le retour de l'`AppHeader`
/// retombe sur l'accueil CONTEXTUEL ([homeLocationProvider]) — c'est-a-dire le
/// COCKPIT du sentier courant des qu'une rando existe. On atterrit sur le
/// cockpit d'un sentier qu'on n'a ni choisi ni telecharge.
///
/// CE QUE CES TESTS VERROUILLENT :
///  1. la porte d'entree « Decouvrir » de l'accueil maison EMPILE le catalogue
///     (`push`), donc le retour DEPILE vers « Mes treks » — y compris le geste
///     systeme Android, qui suit la meme pile ;
///  2. et meme quand la pile est VIDE (arrivee depuis l'onboarding), le retour
///     du catalogue va a « Mes treks » et JAMAIS au cockpit : le catalogue force
///     son accueil de repli, il ne le laisse plus deriver d'une rando active.
///
/// Les deux tests ont ete ecrits ROUGES.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Un trek possede, pour que « Mes treks » ait quelque chose a afficher.
  const treks = <TrekSummary>[
    TrekSummary(config: testTrailConfig, state: TrekLifecycleState.owned),
  ];

  /// Enveloppe : ProviderScope + Slang + un routeur a trois routes reelles
  /// (maison / cockpit-temoin / catalogue).
  Widget wrap({
    required String initialLocation,
    List<Override> overrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/my-treks', builder: (_, __) => const MyTreksScreen()),
        // Cockpit TEMOIN : s'il apparait, c'est que le retour a derive vers le
        // sentier courant — exactement le defaut de Chris.
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('COCKPIT_TEMOIN')),
        ),
        GoRoute(path: '/catalog', builder: (_, __) => const TrailCatalogScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
      ],
    );
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        myTreksProvider.overrideWith((ref) async => treks),
        ...overrides,
      ],
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  group('Q2 — le retour du catalogue ramene a « Mes treks »', () {
    testWidgets(
      'depuis l accueil maison, « Decouvrir » EMPILE le catalogue : le retour '
      'depile vers « Mes treks », il ne derive pas vers le cockpit',
      (tester) async {
        tester.view.physicalSize = const Size(420, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          wrap(
            initialLocation: '/my-treks',
            // Une rando EST active : sans le correctif, l'accueil contextuel
            // renvoie vers le cockpit.
            overrides: [
              activeTrekIdProvider.overrideWith((ref) async => testTrailConfig.id),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MyTreksScreen), findsOneWidget);

        // La carte « Decouvrir » du bandeau de l'accueil maison.
        await tester.tap(find.text(t.myTreks.discoverTitle).first);
        await tester.pumpAndSettle();
        expect(find.byType(TrailCatalogScreen), findsOneWidget);

        // La pile doit avoir ete EMPILEE : le retour depile.
        await tester.tap(find.byTooltip(t.nav.back));
        await tester.pumpAndSettle();

        expect(
          find.byType(MyTreksScreen),
          findsOneWidget,
          reason: 'le retour du catalogue ramene a « Mes treks »',
        );
        expect(
          find.text('COCKPIT_TEMOIN'),
          findsNothing,
          reason: 'jamais le cockpit d un sentier qu on n a pas choisi',
        );
      },
    );

    testWidgets(
      'pile VIDE (arrivee depuis l onboarding) : le retour va a « Mes treks » '
      'meme si une rando active ferait deriver l accueil vers le cockpit',
      (tester) async {
        tester.view.physicalSize = const Size(420, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          wrap(
            initialLocation: '/catalog',
            overrides: [
              activeTrekIdProvider.overrideWith((ref) async => testTrailConfig.id),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TrailCatalogScreen), findsOneWidget);

        await tester.tap(find.byTooltip(t.nav.back));
        await tester.pumpAndSettle();

        expect(
          find.byType(MyTreksScreen),
          findsOneWidget,
          reason: 'sans historique, le repli du catalogue est « Mes treks » — '
              'jamais le cockpit du sentier courant (defaut Chris 26/09)',
        );
        expect(find.text('COCKPIT_TEMOIN'), findsNothing);
      },
    );

    testWidgets(
      'le bouton Accueil du catalogue mene lui aussi a « Mes treks »',
      (tester) async {
        tester.view.physicalSize = const Size(420, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          wrap(
            initialLocation: '/catalog',
            overrides: [
              activeTrekIdProvider.overrideWith((ref) async => testTrailConfig.id),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip(t.nav.home));
        await tester.pumpAndSettle();

        expect(find.byType(MyTreksScreen), findsOneWidget);
        expect(find.text('COCKPIT_TEMOIN'), findsNothing);
      },
    );
  });
}
