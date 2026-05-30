import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/ui/error_view.dart';

void main() {
  group('ErrorView', () {
    testWidgets('affiche le message d erreur', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(message: 'Une erreur est survenue'),
          ),
        ),
      );

      expect(find.text('Une erreur est survenue'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('affiche le bouton retry quand onRetry est fourni',
        (tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Erreur reseau',
              onRetry: () => retryCount++,
            ),
          ),
        ),
      );

      expect(find.text('Reessayer'), findsOneWidget);
      await tester.tap(find.text('Reessayer'));
      expect(retryCount, equals(1));
    });

    testWidgets('cache le bouton retry quand onRetry est null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(message: 'Erreur'),
          ),
        ),
      );

      expect(find.text('Reessayer'), findsNothing);
    });
  });
}
