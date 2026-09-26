import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/ui/error_view.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

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

      // LIBELLE TRADUIT (tache 579, LOT X) : il etait ecrit en dur, en
      // francais et sans accent, dans un widget utilise par TOUTE
      // l'application. Il passe par Slang, donc par les cinq langues.
      expect(find.text(t.common.retry), findsOneWidget);
      await tester.tap(find.text(t.common.retry));
      expect(retryCount, equals(1));

      // L'ESSAI SE VOIT (tache 579). Le bouton annonce « Nouvel essai… » et
      // devient inactif : sans ce changement, un nouvel essai qui echoue a
      // l'identique ne produisait RIEN a l'ecran.
      await tester.pump();
      expect(find.text(t.common.retrying), findsOneWidget);

      // Puis, toujours en erreur, il le DIT.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
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

      expect(find.text(t.common.retry), findsNothing);
    });
  });
}
