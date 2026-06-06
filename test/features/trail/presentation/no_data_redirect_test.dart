import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/trail/presentation/no_data_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Test de redirection de l ecran NoDataScreen (E4.10).
///
/// Verifie que l ecran bloquant redirige automatiquement vers
/// /trails quand des sentiers deviennent disponibles
/// (hasLocalTrailsProvider passe a true).
void main() {
  group('NoDataScreen redirection', () {
    testWidgets('reste bloque tant qu aucun sentier n est disponible',
        (tester) async {
      String? navigatedTo;

      final router = GoRouter(
        initialLocation: '/no-data',
        routes: [
          GoRoute(
            path: '/no-data',
            builder: (context, state) => const NoDataScreen(),
          ),
          GoRoute(
            path: '/trails',
            builder: (context, state) {
              navigatedTo = '/trails';
              return const Scaffold(body: Text('Trails'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.pumpAndSettle();

      // Ecran bloquant affiche, aucune redirection
      expect(find.text(t.noData.title), findsOneWidget);
      expect(navigatedTo, isNull);
    });

    testWidgets('redirige vers /trails quand hasLocalTrails passe a true',
        (tester) async {
      String? navigatedTo;

      final router = GoRouter(
        initialLocation: '/no-data',
        routes: [
          GoRoute(
            path: '/no-data',
            builder: (context, state) => const NoDataScreen(),
          ),
          GoRoute(
            path: '/catalog',
            builder: (context, state) =>
                const Scaffold(body: Text('Catalogue')),
          ),
          GoRoute(
            path: '/trails',
            builder: (context, state) {
              navigatedTo = '/trails';
              return const Scaffold(body: Text('Trails'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.pumpAndSettle();

      // Ecran bloquant affiche
      expect(find.text(t.noData.title), findsOneWidget);

      // Acceder au container pour simuler le changement de state
      final element = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(element);

      // Simuler qu un sentier est telecharge
      container.read(hasLocalTrailsProvider.notifier).state = true;
      await tester.pumpAndSettle();

      // Devrait avoir redirige vers /trails
      expect(navigatedTo, '/trails');
    });
  });
}
