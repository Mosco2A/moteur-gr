import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/ui/loading_view.dart';

void main() {
  group('LoadingView', () {
    testWidgets('affiche un indicateur de progression', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingView(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('affiche le message optionnel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingView(message: 'Chargement en cours...'),
          ),
        ),
      );

      expect(find.text('Chargement en cours...'), findsOneWidget);
    });

    testWidgets('cache le message quand il est null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingView(),
          ),
        ),
      );

      // Seul le CircularProgressIndicator, pas de Text
      expect(find.byType(Text), findsNothing);
    });
  });
}
