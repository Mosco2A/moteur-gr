// D4C-03 — Tests widget de l'ecran EXPOSE DES MOTIFS (DSA art 17, design
// #86166).
//
// Couvre :
//   - affichage de la decision + du motif communique a l'auteur (art 17) ;
//   - bouton d'acces aux plaintes (art 20) present et navigant ;
//   - cas « aucune restriction » : message neutre, pas de carte de motifs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/moderation_service.dart';
import 'package:moteur_gr/features/moderation/presentation/complaint_screen.dart';
import 'package:moteur_gr/features/moderation/presentation/statement_of_reasons_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Translations tr = AppLocale.fr.buildSync();

  Widget host(StatementOfReasonsView? statement) => ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            home: StatementOfReasonsScreen(statement: statement),
          ),
        ),
      );

  final restricted = StatementOfReasonsView(
    contentType: ModeratedContentType.waypoint,
    contentRef: 'wp-1',
    decision: ModerationDecision.remove,
    motif: 'Contenu signale comme dangereux et retire.',
    createdAt: DateTime.utc(2026, 6, 15),
  );

  group('StatementOfReasonsScreen — DSA art 17', () {
    testWidgets('affiche la decision et le motif communique a l auteur',
        (tester) async {
      await tester.pumpWidget(host(restricted));
      await tester.pumpAndSettle();

      expect(find.text(tr.moderation.decisions.remove), findsOneWidget);
      expect(
        find.text('Contenu signale comme dangereux et retire.'),
        findsOneWidget,
      );
    });

    testWidgets('bouton plaintes (art 20) present et navigue', (tester) async {
      await tester.pumpWidget(host(restricted));
      await tester.pumpAndSettle();

      final complaintBtn =
          find.byKey(const ValueKey('statement-complaint-action'));
      expect(complaintBtn, findsOneWidget);

      await tester.tap(complaintBtn);
      await tester.pumpAndSettle();

      // L'ecran de plaintes (art 20) s'ouvre.
      expect(find.byType(ComplaintScreen), findsOneWidget);
      expect(find.text(tr.moderation.complaintTitle), findsOneWidget);
    });

    testWidgets('aucune restriction : message neutre, pas de carte motifs',
        (tester) async {
      await tester.pumpWidget(host(null));
      await tester.pumpAndSettle();

      expect(find.text(tr.moderation.noStatement), findsOneWidget);
      expect(
        find.byKey(const ValueKey('statement-complaint-action')),
        findsNothing,
      );
    });
  });
}
