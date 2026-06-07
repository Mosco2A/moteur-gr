import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';
import 'package:moteur_gr/features/trail/widgets/trail_catalog_card.dart';

/// Tests E5.3b — pas d'overflow a textScale 2x sur le catalogue (ecran principal).
void main() {
  // Entree la plus "large" (badge MAJ disponible + bouton Mettre a jour).
  const updateEntry = CatalogEntry(
    trailId: 'sentier-des-grands-causses-du-massif-central',
    dataVersion: 5,
    fileSize: 2097152,
    status: 'active',
    lastUpdated: '2026-05-25T10:00:00Z',
    localStatus: TrailLocalStatusValues.updateAvailable,
    localVersion: 3,
  );

  Widget wrapAtScale(Widget child, double scale, {double width = 400}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('TrailCatalogCard ne deborde pas a textScale 2x', (tester) async {
    await tester.pumpWidget(
      wrapAtScale(const TrailCatalogCard(entry: updateEntry), 2.0),
    );
    await tester.pump();

    // Un RenderFlex overflow leverait une exception capturee ici.
    expect(tester.takeException(), isNull);
    // Le contenu reste rendu (titre present).
    expect(find.textContaining('sentier-des-grands-causses'), findsOneWidget);
  });

  testWidgets('TrailCatalogCard ne deborde pas a textScale 2x sur ecran etroit',
      (tester) async {
    await tester.pumpWidget(
      wrapAtScale(const TrailCatalogCard(entry: updateEntry), 2.0, width: 320),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
