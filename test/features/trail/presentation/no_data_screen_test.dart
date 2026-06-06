import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/trail/presentation/no_data_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests widget de l'ecran NoDataScreen.
///
/// Verifie le rendu (icone, textes, bouton) et la navigation
/// vers /catalog au tap sur le bouton. Les textes sont verifies
/// via les cles Slang (t.noData.*) — migration i18n E4.10.
void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  group('NoDataScreen', () {
    testWidgets('affiche le titre et le message', (tester) async {
      await tester.pumpWidget(wrap(const NoDataScreen()));

      await tester.pumpAndSettle();

      // Titre principal
      expect(find.text(t.noData.title), findsOneWidget);
      // Message explicatif
      expect(find.text(t.noData.subtitle), findsOneWidget);
    });

    testWidgets('affiche l icone de telechargement', (tester) async {
      await tester.pumpWidget(wrap(const NoDataScreen()));

      await tester.pumpAndSettle();

      // Icone downloading_rounded presente
      expect(
        find.byIcon(Icons.downloading_rounded),
        findsOneWidget,
      );
    });

    testWidgets('affiche le bouton vers le catalogue', (tester) async {
      await tester.pumpWidget(wrap(const NoDataScreen()));

      await tester.pumpAndSettle();

      expect(find.text(t.noData.browseCta), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('bouton navigue vers /catalog', (tester) async {
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
            builder: (context, state) {
              navigatedTo = '/catalog';
              return const Scaffold(body: Text('Catalogue'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.pumpAndSettle();

      // Tap sur le bouton
      await tester.tap(find.text(t.noData.browseCta));
      await tester.pumpAndSettle();

      expect(navigatedTo, '/catalog');
    });
  });
}
