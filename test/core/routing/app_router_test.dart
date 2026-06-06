import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/app_router.dart';

/// Tests du routeur GoRouter (routes, navigation).
void main() {
  group('AppRouter', () {
    test('la route initiale est /trails', () {
      expect(appRouter.routeInformationProvider.value.uri.path, '/trails');
    });

    test('le router contient 13 routes de premier niveau', () {
      // Structure complete du moteur (post E5.x) :
      // [0] /trails  [1] /trail/:id  [2] /stages  [3] /map  [4] /planning
      // [5] /group/:id  [6] /catalog  [7] /goodies  [8] /booking
      // [9] /emergency  [10] /no-data  [11] /settings  [12] /profile
      expect(appRouter.configuration.routes.length, 13);
    });

    test('les chemins de premier niveau sont ceux attendus', () {
      final paths = appRouter.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(paths, [
        '/trails',
        '/trail/:id',
        '/stages',
        '/map',
        '/planning',
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

    test('la route /trail/:id a 9 sous-routes', () {
      final trailRoute = appRouter.configuration.routes[1] as GoRoute;
      expect(trailRoute.path, '/trail/:id');
      expect(trailRoute.routes.length, 9);

      final stageRoute = trailRoute.routes[0] as GoRoute;
      expect(stageRoute.path, 'stage/:num');

      final mapRoute = trailRoute.routes[1] as GoRoute;
      expect(mapRoute.path, 'map');

      final planningRoute = trailRoute.routes[2] as GoRoute;
      expect(planningRoute.path, 'planning');

      final checklistRoute = trailRoute.routes[3] as GoRoute;
      expect(checklistRoute.path, 'checklist');

      final feasibilityRoute = trailRoute.routes[4] as GoRoute;
      expect(feasibilityRoute.path, 'feasibility');

      final tipsRoute = trailRoute.routes[5] as GoRoute;
      expect(tipsRoute.path, 'tips');

      final journalRoute = trailRoute.routes[6] as GoRoute;
      expect(journalRoute.path, 'journal');

      final diplomaRoute = trailRoute.routes[7] as GoRoute;
      expect(diplomaRoute.path, 'diploma');

      final feedbackRoute = trailRoute.routes[8] as GoRoute;
      expect(feedbackRoute.path, 'feedback');
    });

    test('les routes sont nommees correctement', () {
      final routes = appRouter.configuration.routes;
      expect((routes[0] as GoRoute).name, 'trails');
      expect((routes[1] as GoRoute).name, 'trail-detail');
      expect((routes[2] as GoRoute).name, 'stages');
      expect((routes[3] as GoRoute).name, 'map');
      expect((routes[4] as GoRoute).name, 'trek-planning');
      expect((routes[5] as GoRoute).name, 'group');
      expect((routes[6] as GoRoute).name, 'catalog');
      expect((routes[7] as GoRoute).name, 'goodies');
      expect((routes[8] as GoRoute).name, 'booking');
      expect((routes[9] as GoRoute).name, 'emergency');
      expect((routes[10] as GoRoute).name, 'no-data');
      expect((routes[11] as GoRoute).name, 'settings');
      expect((routes[12] as GoRoute).name, 'profile');

      final trailRoute = routes[1] as GoRoute;
      expect((trailRoute.routes[0] as GoRoute).name, 'stage-detail');
      expect((trailRoute.routes[1] as GoRoute).name, 'trail-map');
      expect((trailRoute.routes[2] as GoRoute).name, 'trail-planning');
      expect((trailRoute.routes[3] as GoRoute).name, 'trail-checklist');
      expect((trailRoute.routes[4] as GoRoute).name, 'trail-feasibility');
      expect((trailRoute.routes[5] as GoRoute).name, 'trail-tips');
      expect((trailRoute.routes[6] as GoRoute).name, 'trail-journal');
      expect((trailRoute.routes[7] as GoRoute).name, 'trail-diploma');
      expect((trailRoute.routes[8] as GoRoute).name, 'trail-feedback');
    });

    testWidgets('navigation vers /trails affiche TrailListScreen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sentiers'), findsOneWidget);
    });

    testWidgets('page erreur saffiche pour route inconnue',
        (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/route-inexistante',
        routes: appRouter.configuration.routes,
        errorBuilder: (context, state) => Scaffold(
          body: Center(child: Text('Erreur: ${state.uri.path}')),
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: testRouter),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsOneWidget);
    });
  });
}
