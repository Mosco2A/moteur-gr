import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/app_router.dart';

/// Tests du routeur GoRouter (E2.9b — bottom nav 5 onglets + ShellRoute).
///
/// Couvre :
///   - structure de premier niveau (1 shell + 10 routes racine) ;
///   - composition du StatefulShellRoute (5 branches, chemins, cles) ;
///   - preservation des liens profonds existants (/trail/:id et sous-routes) ;
///   - navigation entre onglets via la NavigationBar ;
///   - restauration d'etat par onglet (IndexedStack natif).
void main() {
  group('AppRouter — structure', () {
    test('la route initiale est /trails', () {
      expect(appRouter.routeInformationProvider.value.uri.path, '/trails');
    });

    test('le premier niveau contient 1 shell + 10 routes racine', () {
      final routes = appRouter.configuration.routes;
      expect(routes.length, 11);
      expect(routes.first, isA<StatefulShellRoute>());
      expect(routes.whereType<GoRoute>().length, 10);
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
        '/catalog',
        '/goodies',
        '/booking',
        '/emergency',
        '/no-data',
        '/settings',
        '/profile',
      ]);
    });

    test('les routes racine sont nommees correctement', () {
      final routes =
          appRouter.configuration.routes.whereType<GoRoute>().toList();
      expect(routes.map((r) => r.name).toList(), [
        'trails',
        'trail-detail',
        'group',
        'catalog',
        'goodies',
        'booking',
        'emergency',
        'no-data',
        'settings',
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
      final paths = shell()
          .branches
          .map((b) => (b.routes.first as GoRoute).path)
          .toList();
      expect(paths, ['/map', '/stages', '/planning', '/journal', '/more']);
    });

    test('chaque onglet porte le bon nom de route', () {
      final names = shell()
          .branches
          .map((b) => (b.routes.first as GoRoute).name)
          .toList();
      expect(names, ['map', 'stages', 'trek-planning', 'journal', 'more']);
    });

    test('chaque branche a sa propre cle de navigateur (etat isole)', () {
      final keys = shell().branches.map((b) => b.navigatorKey).toList();
      expect(keys.toSet().length, 5, reason: 'cles distinctes par onglet');
    });

    test('l onglet Etapes conserve sa sous-route /stages/:id', () {
      final stagesBranch = shell().branches[1];
      final stagesRoute = stagesBranch.routes.first as GoRoute;
      expect(stagesRoute.path, '/stages');
      expect(stagesRoute.routes.length, 1);
      expect((stagesRoute.routes.first as GoRoute).path, ':id');
      expect((stagesRoute.routes.first as GoRoute).name, 'stage-by-id');
    });
  });

  group('AppRouter — liens profonds preserves', () {
    GoRoute trailRoute() => appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == '/trail/:id');

    test('la route /trail/:id conserve ses 9 sous-routes', () {
      final trail = trailRoute();
      expect(trail.routes.length, 9);
      final subPaths =
          trail.routes.map((r) => (r as GoRoute).path).toList();
      expect(subPaths, [
        'stage/:num',
        'map',
        'planning',
        'checklist',
        'feasibility',
        'tips',
        'journal',
        'diploma',
        'feedback',
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
        'trail-feedback',
      ]);
    });
  });

  group('AppRouter — comportement', () {
    testWidgets('page erreur saffiche pour route inconnue', (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/route-inexistante',
        routes: appRouter.configuration.routes,
        errorBuilder: (context, state) => Scaffold(
          body: Center(child: Text('Erreur: ${state.uri.path}')),
        ),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: testRouter));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsOneWidget);
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
                  NavigationDestination(
                      icon: Icon(Icons.map), label: 'Carte'),
                  NavigationDestination(
                      icon: Icon(Icons.terrain), label: 'Etapes'),
                  NavigationDestination(
                      icon: Icon(Icons.more_horiz), label: 'Plus'),
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

    testWidgets('la NavigationBar affiche les onglets et bascule de contenu',
        (tester) async {
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

    testWidgets('l etat d un onglet est restaure apres bascule',
        (tester) async {
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
