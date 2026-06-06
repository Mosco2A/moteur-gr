import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/app_router.dart';

/// Tests E2.4d -- navigation GoRouter /stages -> /stages/:id.
void main() {
  group('Navigation GoRouter etapes', () {
    testWidgets('route /stages et /stages/1 sont definies dans appRouter', (
      tester,
    ) async {
      // Verifier que les routes existent dans la configuration.
      // Depuis E2.9b, /stages est un onglet : il vit dans une branche du
      // StatefulShellRoute, pas au premier niveau. On parcourt donc aussi
      // les branches du shell pour le retrouver.
      final routes = appRouter.configuration.routes;

      // Aplatit les routes : premier niveau + routes des branches du shell.
      final flat = <RouteBase>[];
      for (final route in routes) {
        if (route is StatefulShellRoute) {
          for (final branch in route.branches) {
            flat.addAll(branch.routes);
          }
        } else {
          flat.add(route);
        }
      }

      // Chercher la route /stages parmi les routes aplaties.
      GoRoute? stagesRoute;
      for (final route in flat) {
        if (route is GoRoute && route.path == '/stages') {
          stagesRoute = route;
          break;
        }
      }

      expect(stagesRoute, isNotNull, reason: 'Route /stages doit exister');
      expect(stagesRoute!.name, 'stages');

      // Verifier la sous-route :id
      GoRoute? stageByIdRoute;
      for (final sub in stagesRoute.routes) {
        if (sub is GoRoute && sub.path == ':id') {
          stageByIdRoute = sub;
          break;
        }
      }

      expect(
        stageByIdRoute,
        isNotNull,
        reason: 'Sous-route :id doit exister sous /stages',
      );
      expect(stageByIdRoute!.name, 'stage-by-id');
    });
  });
}
