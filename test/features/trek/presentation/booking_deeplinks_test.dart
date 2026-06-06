import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/stage_accommodation.dart';
import 'package:moteur_gr/features/trek/presentation/refuge_detail_screen.dart';

/// Tests E5.12b — Deeplinks reservation V1 (design #83560).
///
/// Verifie que les boutons CTA (Appeler, Email, Site web) sont
/// affiches uniquement si les donnees correspondantes sont presentes
/// dans l'hebergement. Fixtures : sentier FICTIF (Sentier des Volcans),
/// hebergements via override du provider (canal DB generique).
void main() {
  // Hebergement fictif etape 1 : phone + website, PAS d'email.
  const refugeVolcans = StageAccommodation(
    id: 'acc-volcans-1',
    stageId: 'stage-volcans-1',
    stageNumber: 1,
    nameFr: 'Refuge des Volcans',
    type: AccommodationType.refuge,
    lat: 45.51,
    lng: 2.96,
    phone: '04 00 00 00 01',
    website: 'https://example.org/refuge-volcans',
    capacity: 30,
    priceRange: '15-20 EUR',
  );

  Widget buildApp({
    int stageNumber = 1,
    List<StageAccommodation> accommodations = const [],
  }) {
    return ProviderScope(
      overrides: [
        accommodationsByStageProvider.overrideWith(
          (ref, stage) async =>
              accommodations.where((a) => a.stageNumber == stage).toList(),
        ),
      ],
      child: MaterialApp(
        home: RefugeDetailScreen(stageNumber: stageNumber),
      ),
    );
  }

  group('RefugeDetailScreen -- Section Reserver', () {
    testWidgets(
      'boutons visibles si donnees presentes (etape 1 : phone + website)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildApp(
          stageNumber: 1,
          accommodations: const [refugeVolcans],
        ));
        await tester.pumpAndSettle();

        // Section header "Reserver" doit etre visible
        expect(find.text('Reserver'), findsOneWidget);

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
      'boutons masques si aucun hebergement reference sur l\'etape',
      (WidgetTester tester) async {
        // Etape 9 : aucun hebergement en base pour cette etape
        // → pas d'hebergement principal → section "Reserver" absente
        await tester.pumpWidget(buildApp(stageNumber: 9));
        await tester.pumpAndSettle();

        expect(find.text('Reserver'), findsNothing);
        expect(find.text('Appeler'), findsNothing);
        expect(find.text('Email'), findsNothing);
        expect(find.text('Site web'), findsNothing);

        // Message d'information affiche a la place
        expect(
          find.textContaining('Pas d\'hebergement reference'),
          findsOneWidget,
        );
      },
    );
  });
}
