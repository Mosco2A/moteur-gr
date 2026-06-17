import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/pyrenees_trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/trail/presentation/trail_catalog_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests du cablage navigation depuis le catalogue (design #88246).
///
/// Le catalogue (P2-P3, donnees fictives) liste les sentiers embarques
/// ([availableTrailsProvider]) et chaque carte offre un bouton "Entrer" qui :
///   1. ecrit la selection ([selectedTrailIdProvider]) -> bascule la config
///      active ([trailConfigProvider]) ;
///   2. ouvre le shell sur /map.
/// C'est l'entree du coeur de l'app, auparavant orpheline.
void main() {
  /// Routeur minimal : /catalog (ecran teste) + /map (stub) pour observer la
  /// navigation declenchee par le bouton "Entrer", sans dependances reelles.
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/catalog',
      routes: [
        GoRoute(
          path: '/catalog',
          builder: (context, state) => const TrailCatalogScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) =>
              const Scaffold(body: Text('STUB MAP SCREEN')),
        ),
      ],
    );
  }

  testWidgets('liste les sentiers embarques du catalogue', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: buildRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trail-catalog-list')), findsOneWidget);
    for (final trail in TrailCatalog.all) {
      expect(find.byKey(ValueKey('catalog-trail-${trail.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('catalog-enter-${trail.id}')), findsOneWidget);
    }
  });

  testWidgets(
      'taper Entrer ecrit la selection et ouvre le shell sur /map',
      (tester) async {
    // Container partage : selection initiale sur le sentier de test, on lira
    // l'etat apres l'action UI.
    final container = ProviderContainer(overrides: [
      selectedTrailIdProvider.overrideWith((ref) => testTrailConfig.id),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: buildRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Etat initial : sentier de test actif, on est bien sur le catalogue.
    expect(container.read(trailConfigProvider).id, testTrailConfig.id);
    expect(find.byKey(const ValueKey('trail-catalog-list')), findsOneWidget);

    // Entrer dans le sentier Pyrenees (autre que l'actif).
    await tester.tap(
      find.byKey(ValueKey('catalog-enter-${pyreneesTrailConfig.id}')),
    );
    await tester.pumpAndSettle();

    // 1) La selection ET la config active ont bascule (propagation moteur).
    expect(container.read(selectedTrailIdProvider), pyreneesTrailConfig.id);
    expect(container.read(trailConfigProvider).id, pyreneesTrailConfig.id);

    // 2) On a navigue vers le shell (stub /map affiche, catalogue parti).
    expect(find.text('STUB MAP SCREEN'), findsOneWidget);
    expect(find.byKey(const ValueKey('trail-catalog-list')), findsNothing);
  });
}
