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

    test('le router contient 3 routes de premier niveau', () {
      // /trails, /trail/:id, /settings
      expect(appRouter.configuration.routes.length, 3);
    });

    test('la route /trail/:id a une sous-route stage', () {
      final trailRoute = appRouter.configuration.routes[1] as GoRoute;
      expect(trailRoute.path, '/trail/:id');
      expect(trailRoute.routes.length, 1);

      final stageRoute = trailRoute.routes[0] as GoRoute;
      expect(stageRoute.path, 'stage/:num');
    });

    test('les routes sont nommees correctement', () {
      final routes = appRouter.configuration.routes;
      expect((routes[0] as GoRoute).name, 'trails');
      expect((routes[1] as GoRoute).name, 'trail-detail');
      expect((routes[2] as GoRoute).name, 'settings');

      final stageRoute = (routes[1] as GoRoute).routes[0] as GoRoute;
      expect(stageRoute.name, 'stage-detail');
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
