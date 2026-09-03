import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/app_router.dart';

/// Tests du routeur GoRouter (E2.9b + HUB E07/AM-1 — bottom nav 5 onglets).
///
/// Couvre :
///   - structure de premier niveau (1 shell + routes racine) ;
///   - composition du StatefulShellRoute (5 branches Accueil/Carte/Etapes/
///     Journal/Plus, chemins, cles) ;
///   - Planning trek sorti de la barre -> route hors-shell /planning ;
///   - preservation des liens profonds existants (/trail/:id et sous-routes) ;
///   - navigation entre onglets via la NavigationBar ;
///   - restauration d'etat par onglet (IndexedStack natif).
void main() {
  group('AppRouter — structure', () {
    test('la route initiale est /home (HUB E07, AM-1)', () {
      expect(appRouter.routeInformationProvider.value.uri.path, '/home');
    });

    test('le premier niveau contient 1 shell + 19 routes racine', () {
      // +1 : /health (E57 LOT D/D1, fiche sante hors-shell via Urgence).
      final routes = appRouter.configuration.routes;
      expect(routes.length, 20);
      expect(routes.first, isA<StatefulShellRoute>());
      expect(routes.whereType<GoRoute>().length, 19);
    });

    test('les routes racine (hors shell) sont celles attendues', () {
      final paths = appRouter.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(paths, [
        '/trails',
        '/trail/:id',
        '/group/:id',
        '/follow/:code',
        '/catalog',
        '/trail-selection',
        '/goodies',
        '/booking',
        '/accommodations-nearby',
        '/emergency',
        // E57 (LOT D/D1) : fiche infos sante LOCAL ONLY (via Urgence E29).
        '/health',
        '/signalement',
        '/training',
        // HUB E07 (#NAV02) : Planning trek sorti de la barre -> hors-shell.
        '/planning',
        '/onboarding',
        '/no-data',
        '/settings',
        '/consent',
        '/profile',
      ]);
    });

    test('les routes racine sont nommees correctement', () {
      final routes = appRouter.configuration.routes
          .whereType<GoRoute>()
          .toList();
      expect(routes.map((r) => r.name).toList(), [
        'trails',
        'trail-detail',
        'group',
        'follow',
        'catalog',
        'trail-selection',
        'goodies',
        'booking',
        'accommodations-nearby',
        'emergency',
        'health',
        'signalement',
        'training',
        'trek-planning',
        'onboarding',
        'no-data',
        'settings',
        'consent',
        'profile',
      ]);
    });
  });

  group('AppRouter — bottom nav (StatefulShellRoute)', () {
    StatefulShellRoute shell() =>
        appRouter.configuration.routes.first as StatefulShellRoute;

    test('le shell expose exactement 5 branches (5 onglets)', () {
      expect(shell().branches.length, 5);
    });

    test('chaque onglet porte le bon chemin racine', () {
      final paths = shell().branches
          .map((b) => (b.routes.first as GoRoute).path)
          .toList();
      // HUB E07 (AM-1) : Accueil en position 1, Planning sorti de la barre.
      expect(paths, ['/home', '/map', '/stages', '/journal', '/more']);
    });

    test('chaque onglet porte le bon nom de route', () {
      final names = shell().branches
          .map((b) => (b.routes.first as GoRoute).name)
          .toList();
      expect(names, ['home', 'map', 'stages', 'journal', 'more']);
    });

    test('chaque branche a sa propre cle de navigateur (etat isole)', () {
      final keys = shell().branches.map((b) => b.navigatorKey).toList();
      expect(keys.toSet().length, 5, reason: 'cles distinctes par onglet');
    });

    test('l onglet Etapes conserve sa sous-route /stages/:id', () {
      // Accueil en index 0 -> Etapes passe en index 2 (Accueil/Carte/Etapes).
      final stagesBranch = shell().branches[2];
      final stagesRoute = stagesBranch.routes.first as GoRoute;
      expect(stagesRoute.path, '/stages');
      expect(stagesRoute.routes.length, 1);
      expect((stagesRoute.routes.first as GoRoute).path, ':id');
      expect((stagesRoute.routes.first as GoRoute).name, 'stage-by-id');
    });

    test('l onglet Accueil (position 1) pointe vers le HUB /home', () {
      final homeBranch = shell().branches.first;
      final homeRoute = homeBranch.routes.first as GoRoute;
      expect(homeRoute.path, '/home');
      expect(homeRoute.name, 'home');
    });
  });

  group('AppRouter — liens profonds preserves', () {
    GoRoute trailRoute() => appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == '/trail/:id');

    test('la route /trail/:id conserve ses 12 sous-routes (+ recap LOT3)', () {
      // +1 : 'guides' (E33/E34 LOT D/D2, feature Guides villes cablee).
      // +1 : 'recap' (PARITE GR20 LOT 3 #99433, recap « Mon aventure »).
      final trail = trailRoute();
      expect(trail.routes.length, 12);
      final subPaths = trail.routes.map((r) => (r as GoRoute).path).toList();
      expect(subPaths, [
        'stage/:num',
        'map',
        'planning',
        'checklist',
        'feasibility',
        'tips',
        'journal',
        'diploma',
        'recap',
        'feedback',
        'weather',
        'guides',
      ]);
    });

    test('les sous-routes /trail/:id sont nommees correctement', () {
      final trail = trailRoute();
      final names = trail.routes.map((r) => (r as GoRoute).name).toList();
      expect(names, [
        'stage-detail',
        'trail-map',
        'trail-planning',
        'trail-checklist',
        'trail-feasibility',
        'trail-tips',
        'trail-journal',
        'trail-diploma',
        'trail-recap',
        'trail-feedback',
        'trail-weather',
        'trail-guides',
      ]);
    });

    test('la sous-route guides porte le detail /trail/:id/guides/:guideId', () {
      // E34 (LOT D/D2) : deeplink du detail d'un guide ville.
      final trail = trailRoute();
      final guides = trail.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == 'guides');
      expect(guides.routes.length, 1);
      final detail = guides.routes.first as GoRoute;
      expect(detail.path, ':guideId');
      expect(detail.name, 'trail-guide-detail');
    });
  });

  group('AppRouter — comportement', () {
    testWidgets('page erreur saffiche pour route inconnue', (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/route-inexistante',
        routes: appRouter.configuration.routes,
        errorBuilder: (context, state) =>
            Scaffold(body: Center(child: Text('Erreur: ${state.uri.path}'))),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: testRouter));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsOneWidget);
    });
  });

  // ===========================================================================
  // Cablage nav (#88246) : stub /trails neutralise + currentTrailGuard.
  // On manipule les drapeaux globaux du module (hasCompletedOnboarding /
  // hasDownloadedTrails) et on les restaure systematiquement apres chaque test.
  // ===========================================================================
  group('AppRouter — cablage nav (#88246)', () {
    late bool savedOnboarding;
    late bool savedDownloaded;

    setUp(() {
      savedOnboarding = hasCompletedOnboarding;
      savedDownloaded = hasDownloadedTrails;
      // Conditions nominales : onboarding fait, un sentier dispo.
      hasCompletedOnboarding = true;
      hasDownloadedTrails = true;
    });

    tearDown(() {
      hasCompletedOnboarding = savedOnboarding;
      hasDownloadedTrails = savedDownloaded;
    });

    test('la route /trails est une redirection (plus de builder de stub)', () {
      final trails = appRouter.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == '/trails');
      expect(trails.redirect, isNotNull,
          reason: '/trails doit rediriger, pas afficher TrailListScreen');
    });

    test('onboarding non fait : toute route renvoie vers /onboarding', () {
      hasCompletedOnboarding = false;
      expect(redirectForPath('/catalog'), '/onboarding');
      expect(redirectForPath('/map'), '/onboarding');
      // /onboarding lui-meme n'est jamais redirige (pas de boucle).
      expect(redirectForPath('/onboarding'), isNull);
    });

    test('sans sentier dispo, les routes du shell renvoient au catalogue', () {
      hasDownloadedTrails = false;
      // HUB E07 (AM-1) : /home remplace /planning dans les onglets coeur.
      for (final tab in ['/home', '/map', '/stages', '/journal', '/more']) {
        expect(redirectForPath(tab), '/catalog',
            reason: '$tab (coeur) doit renvoyer au catalogue sans sentier');
      }
      // Une autre route hors-shell retombe sur l'ecran bloquant historique.
      expect(redirectForPath('/trail/test-trail'), '/no-data');
    });

    test('routes toujours accessibles : aucune redirection', () {
      hasDownloadedTrails = false; // meme sans sentier
      for (final p in [
        '/catalog',
        '/trail-selection',
        '/no-data',
        '/settings',
        '/profile',
        '/emergency',
        // E57 (LOT D/D1) : fiche sante = donnee perso, accessible sans sentier.
        '/health',
      ]) {
        expect(redirectForPath(p), isNull, reason: '$p doit rester accessible');
      }
    });

    test('avec sentier dispo + onboarding fait : navigation libre', () {
      // Conditions nominales (cf. setUp) -> shell atteignable directement.
      expect(redirectForPath('/home'), isNull);
      expect(redirectForPath('/map'), isNull);
      expect(redirectForPath('/stages'), isNull);
    });
  });

  // ===========================================================================
  // Contrat de navigation : StatefulShellRoute.indexedStack preserve l'etat de
  // chaque onglet. Teste sur un routeur minimal (ecrans-stub a compteur) pour
  // isoler le comportement de navigation, sans dependances (DB, providers).
  // ===========================================================================
  group('StatefulShellRoute.indexedStack — navigation + restauration', () {
    final mapKey = GlobalKey<NavigatorState>(debugLabel: 't-map');
    final stagesKey = GlobalKey<NavigatorState>(debugLabel: 't-stages');
    final moreKey = GlobalKey<NavigatorState>(debugLabel: 't-more');

    GoRouter buildStubRouter() {
      return GoRouter(
        initialLocation: '/tab-map',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => Scaffold(
              body: navigationShell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (i) => navigationShell.goBranch(
                  i,
                  initialLocation: i == navigationShell.currentIndex,
                ),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.map), label: 'Carte'),
                  NavigationDestination(
                    icon: Icon(Icons.terrain),
                    label: 'Etapes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz),
                    label: 'Plus',
                  ),
                ],
              ),
            ),
            branches: [
              StatefulShellBranch(
                navigatorKey: mapKey,
                routes: [
                  GoRoute(
                    path: '/tab-map',
                    builder: (c, s) => const _CounterStub(label: 'Carte'),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: stagesKey,
                routes: [
                  GoRoute(
                    path: '/tab-stages',
                    builder: (c, s) => const _CounterStub(label: 'Etapes'),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: moreKey,
                routes: [
                  GoRoute(
                    path: '/tab-more',
                    builder: (c, s) => const _CounterStub(label: 'Plus'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    testWidgets('la NavigationBar affiche les onglets et bascule de contenu', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: buildStubRouter()),
      );
      await tester.pumpAndSettle();

      // Onglet initial : Carte.
      expect(find.text('Ecran Carte'), findsOneWidget);

      // Bascule vers l'onglet Etapes.
      await tester.tap(find.text('Etapes'));
      await tester.pumpAndSettle();
      expect(find.text('Ecran Etapes'), findsOneWidget);

      // Bascule vers l'onglet Plus.
      await tester.tap(find.text('Plus'));
      await tester.pumpAndSettle();
      expect(find.text('Ecran Plus'), findsOneWidget);
    });

    testWidgets('l etat d un onglet est restaure apres bascule', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: buildStubRouter()),
      );
      await tester.pumpAndSettle();

      // Incremente le compteur de l'onglet Carte (0 -> 2).
      await tester.tap(find.byKey(const ValueKey('inc-Carte')));
      await tester.tap(find.byKey(const ValueKey('inc-Carte')));
      await tester.pumpAndSettle();
      expect(find.text('Carte: 2'), findsOneWidget);

      // Va sur Etapes puis revient sur Carte.
      await tester.tap(find.text('Etapes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();

      // L'etat (compteur a 2) est preserve : indexedStack garde la branche.
      expect(find.text('Carte: 2'), findsOneWidget);
    });
  });
}

/// Ecran-stub a compteur, pour observer la preservation d'etat par onglet.
class _CounterStub extends StatefulWidget {
  const _CounterStub({required this.label});

  final String label;

  @override
  State<_CounterStub> createState() => _CounterStubState();
}

class _CounterStubState extends State<_CounterStub> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ecran ${widget.label}'),
            Text('${widget.label}: $_count'),
            IconButton(
              key: ValueKey('inc-${widget.label}'),
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _count++),
            ),
          ],
        ),
      ),
    );
  }
}
