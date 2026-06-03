import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/features/trek/presentation/refuge_detail_screen.dart';

/// Tests E5.12b — Deeplinks reservation V1 (design #83560).
///
/// Verifie que les boutons CTA (Appeler, Email, Site web) sont
/// affiches uniquement si les donnees correspondantes sont presentes
/// dans le refuge.
void main() {
  group('RefugeDetailScreen -- Section Reserver', () {
    // Note: Les refuges PNRC de l etape 1 (Ortu di u Piobbu) ont
    // phone + website mais pas email. Les boutons doivent refléter ca.

    Widget buildApp({int stageNumber = 1}) {
      return ProviderScope(
        child: MaterialApp(
          home: RefugeDetailScreen(stageNumber: stageNumber),
        ),
      );
    }

    testWidgets(
      'boutons visibles si donnees presentes (etape 1 : phone + website)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildApp(stageNumber: 1));
        await tester.pumpAndSettle();

        // Etape 1 = Ortu di u Piobbu : phone='04 95 65 28 09',
        // website='https://pnr-resa.corsica', email=null

        // Section header "Reserver" doit etre visible
        expect(find.text('Réserver'), findsOneWidget);

        // Bouton Appeler visible (phone present)
        expect(find.text('Appeler'), findsOneWidget);
        expect(find.byIcon(Icons.phone), findsWidgets);

        // Bouton Site web visible (website present)
        expect(find.text('Site web'), findsOneWidget);
        expect(find.byIcon(Icons.language), findsWidgets);

        // Bouton Email absent (email null)
        expect(find.text('Email'), findsNothing);
      },
    );

    testWidgets(
      'boutons masques si donnees absentes (etape 9 : pas de refuge PNRC)',
      (WidgetTester tester) async {
        // Etape 9 = Vizzavona, pas de refuge PNRC principal
        // → _buildBookingSection n est pas appele (mainRefuge == null)
        // → section "Reserver" absente
        await tester.pumpWidget(buildApp(stageNumber: 9));
        await tester.pumpAndSettle();

        // Pas de section "Reserver" car pas de refuge PNRC
        // Le widget affiche "Pas de refuge PNRC" a la place
        expect(find.text('Réserver'), findsNothing);
        expect(find.text('Appeler'), findsNothing);
        expect(find.text('Email'), findsNothing);
        // Note: "Site web" en tant que bouton CTA ne devrait pas apparaitre
        // (le site web apparait dans les infos pratiques, pas comme CTA)
      },
    );
  });
}
