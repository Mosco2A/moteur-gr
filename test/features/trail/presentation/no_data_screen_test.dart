import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/trail/presentation/no_data_screen.dart';

/// Tests widget de l'ecran NoDataScreen.
///
/// Verifie le rendu (icone, textes, bouton) et la navigation
/// vers /catalog au tap sur le bouton.
void main() {
  group('NoDataScreen', () {
    testWidgets('affiche le titre et le message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const NoDataScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Titre principal
      expect(find.text('Aucun sentier telecharge'), findsOneWidget);
      // Message explicatif
      expect(
        find.text('Telechargez un sentier pour commencer'),
        findsOneWidget,
      );
    });

    testWidgets('affiche l icone de telechargement', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NoDataScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Icone downloading_rounded presente
      expect(
        find.byIcon(Icons.downloading_rounded),
        findsOneWidget,
      );
    });

    testWidgets('affiche le bouton Parcourir les sentiers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NoDataScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Parcourir les sentiers'), findsOneWidget);
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
        MaterialApp.router(routerConfig: router),
      );

      await tester.pumpAndSettle();

      // Tap sur le bouton
      await tester.tap(find.text('Parcourir les sentiers'));
      await tester.pumpAndSettle();

      expect(navigatedTo, '/catalog');
    });
  });
}
