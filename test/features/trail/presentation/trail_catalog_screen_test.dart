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

import '../../../structurel/regie_pub_absente.dart';

/// Tests du cablage navigation depuis le catalogue (design #88246 ; FIX CYCLE 2
/// issue 1).
///
/// Le catalogue (P2-P3, donnees fictives) liste les sentiers embarques
/// ([availableTrailsProvider]) et chaque carte offre un bouton "Entrer" qui :
///   1. ecrit la selection ([selectedTrailIdProvider]) -> bascule la config
///      active ([trailConfigProvider]) ;
///   2. ouvre le COCKPIT DE PREPARATION (`/home`) — PAS la carte de navigation
///      live (`/map`). NOMINAL GR20 : selectionner un sentier ouvre son cockpit
///      (Preparer/Randonner/Apres) ; la carte reste reservee au demarrage du
///      trek. Aligne sur le geste de « Mes treks » (selection + `go('/home')`).
/// C'est l'entree du coeur de l'app, auparavant orpheline.
void main() {
  // AUCUNE REGIE PUBLICITAIRE dans ce test (tache 595). L ecran monte ici
  // porte desormais un emplacement de banniere : sans cette declaration, le
  // test toucherait le SDK Google Mobile Ads, dont les canaux muets font
  // pendre l amorce du consentement six secondes de temps reel (echec
  // « Pending timers », sans rapport avec ce qui est verifie ici). La
  // banniere a son propre test : test/comportement/pub_v1_595_test.dart.
  setUp(brancherAucuneRegiePub);

  /// Routeur minimal : /catalog (ecran teste) + /home (stub cockpit) pour
  /// observer la navigation declenchee par le bouton "Entrer", sans dependances
  /// reelles.
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/catalog',
      routes: [
        GoRoute(
          path: '/catalog',
          builder: (context, state) => const TrailCatalogScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('STUB HOME COCKPIT')),
        ),
      ],
    );
  }

  /// LE CATALOGUE EST PLUS LONG DEPUIS LA TACHE 601 : il porte une entree de
  /// plus (le sentier de demonstration GRATUIT). La liste depasse la hauteur du
  /// viewport de test par defaut, et un ListView ne CONSTRUIT pas ce qui est
  /// hors champ — les dernieres cartes semblaient alors absentes. On donne donc
  /// au test une fenetre assez haute pour porter tout le catalogue : la question
  /// posee ici est « le catalogue liste-t-il TOUS les sentiers », pas « combien
  /// en tient-il sur un ecran de telephone ».
  void fenetreHaute(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('liste les sentiers embarques du catalogue', (tester) async {
    fenetreHaute(tester);
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
      'taper Entrer ecrit la selection et ouvre le cockpit /home',
      (tester) async {
    fenetreHaute(tester);
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

    // 2) On a navigue vers le COCKPIT (stub /home affiche, catalogue parti) —
    // PAS la carte live (issue 1).
    expect(find.text('STUB HOME COCKPIT'), findsOneWidget);
    expect(find.byKey(const ValueKey('trail-catalog-list')), findsNothing);
  });

  // =========================================================================
  // TACHE 601 — DEUX ENTREES AU CATALOGUE, ET LA GRATUITE SE LIT
  // =========================================================================
  //
  // Decision de Chris, 27/09 12:24, verbatim : « il faut un sentier demo, pas un
  // sentier bride demo. Les donnees peuvent etre celle de mare a mare. Mais il y
  // a mare a mare ET mare a mare demo des le catalogue ».
  //
  // Ce que ce groupe verifie est exactement ce qu'il voit a l'ecran : les deux
  // entrees, et de quoi les distinguer SANS ouvrir ni l'une ni l'autre.
  group('601 — le sentier payant et le sentier demo, tous deux au catalogue',
      () {
    testWidgets('les deux entrees Mare a Mare sont affichees', (tester) async {
      fenetreHaute(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp.router(routerConfig: buildRouter()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('catalog-trail-mare-a-mare-centre')),
        findsOneWidget,
        reason: 'le sentier PAYANT reste au catalogue',
      );
      expect(
        find.byKey(const ValueKey('catalog-trail-mare-a-mare-centre-demo')),
        findsOneWidget,
        reason: 'et le sentier DEMO gratuit y est aussi : deux entrees, pas '
            'une entree bridee',
      );
    });

    testWidgets('le sentier demo porte la pastille GRATUIT, le payant non',
        (tester) async {
      fenetreHaute(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp.router(routerConfig: buildRouter()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('catalog-free-badge-mare-a-mare-centre-demo')),
        findsOneWidget,
        reason: 'un sentier gratuit le DIT, sinon le randonneur doit deviner',
      );
      expect(
        find.byKey(const ValueKey('catalog-free-badge-mare-a-mare-centre')),
        findsNothing,
        reason: 'le sentier payant n est pas gratuit',
      );
      expect(find.text(t.catalog.freeBadge), findsOneWidget);
    });

    testWidgets('le sentier demo porte SON nom, dans la langue affichee',
        (tester) async {
      fenetreHaute(tester);
      LocaleSettings.setLocaleRaw('fr');
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp.router(routerConfig: buildRouter()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final demo = TrailCatalog.byId('mare-a-mare-centre-demo')!;
      final paye = TrailCatalog.byId('mare-a-mare-centre')!;

      // Le nom du sentier gratuit est COMPOSE : le nom propre du terrain, plus
      // la mention de gratuite traduite. Les cinq langues portent la cle
      // `catalog.freeTrailName` (parite verrouillee par test/i18n).
      expect(
        find.text(t.catalog.freeTrailName(nom: demo.displayName)),
        findsOneWidget,
        reason: 'Chris a demande que le sentier demo ait son propre nom dans '
            'les cinq langues',
      );
      expect(find.text(paye.displayName), findsOneWidget,
          reason: 'le sentier payant garde son nom propre, non traduit');
      // Et il annonce ce qu'il contient : les deux premieres etapes.
      expect(
        find.text(t.catalog.freeTrailTagline(etapes: demo.totalStages)),
        findsOneWidget,
      );
    });
  });
}
