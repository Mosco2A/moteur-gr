import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/app_router.dart';

/// Tests E2.4d -- navigation GoRouter /stages -> /stages/:id.
void main() {
  group('Navigation GoRouter etapes', () {
    testWidgets('route /stages et /stages/1 sont definies dans appRouter', (
      tester,
    ) async {
      // Verifier que les routes existent dans la configuration
      final routes = appRouter.configuration.routes;

      // Chercher la route /stages dans les routes de premier niveau
      GoRoute? stagesRoute;
      for (final route in routes) {
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
