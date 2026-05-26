import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';
import 'package:moteur_gr/features/trail/widgets/trail_catalog_card.dart';

/// Tests du widget TrailCatalogCard.
void main() {
  const testEntry = CatalogEntry(
    trailId: 'gr20',
    dataVersion: 3,
    fileSize: 524288,
    status: 'active',
    lastUpdated: '2026-05-26T12:00:00Z',
    localStatus: TrailLocalStatus.notDownloaded,
  );

  const downloadedEntry = CatalogEntry(
    trailId: 'mare_a_mare',
    dataVersion: 2,
    fileSize: 1048576,
    status: 'active',
    lastUpdated: '2026-05-20T08:00:00Z',
    localStatus: TrailLocalStatus.downloaded,
    localVersion: 2,
  );

  const updateEntry = CatalogEntry(
    trailId: 'gr10',
    dataVersion: 5,
    fileSize: 2097152,
    status: 'active',
    lastUpdated: '2026-05-25T10:00:00Z',
    localStatus: TrailLocalStatus.updateAvailable,
    localVersion: 3,
  );

  group('TrailCatalogCard', () {
    testWidgets('affiche le trailId', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailCatalogCard(entry: testEntry),
          ),
        ),
      );
      expect(find.text('gr20'), findsOneWidget);
    });

    testWidgets('affiche la taille formatee', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailCatalogCard(entry: testEntry),
          ),
        ),
      );
      expect(find.text('512 Ko'), findsOneWidget);
    });

    testWidgets('affiche le badge Non telecharge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailCatalogCard(entry: testEntry),
          ),
        ),
      );
      expect(find.text('Non telecharge'), findsOneWidget);
    });

    testWidgets('affiche le bouton Telecharger quand non telecharge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailCatalogCard(entry: testEntry),
          ),
        ),
      );
      expect(find.text('Telecharger'), findsOneWidget);
    });

    testWidgets('affiche le bouton Supprimer quand telecharge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailCatalogCard(entry: downloadedEntry),
          ),
        ),
      );
      expect(find.text('Supprimer'), findsOneWidget);
      expect(find.text('Telecharge'), findsOneWidget);
    });

    testWidgets('affiche le bouton Mettre a jour quand MAJ dispo',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailCatalogCard(entry: updateEntry),
          ),
        ),
      );
      expect(find.text('Mettre a jour'), findsOneWidget);
      expect(find.text('MAJ disponible'), findsOneWidget);
    });

    testWidgets('appelle onDownload quand on tape Telecharger',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailCatalogCard(
              entry: testEntry,
              onDownload: () => called = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Telecharger'));
      expect(called, isTrue);
    });

    testWidgets('appelle onDelete quand on tape Supprimer', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrailCatalogCard(
              entry: downloadedEntry,
              onDelete: () => called = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Supprimer'));
      expect(called, isTrue);
    });
  });

  group('TrailCatalogCard.formatFileSize', () {
    test('formate les octets', () {
      expect(TrailCatalogCard.formatFileSize(500), '500 o');
    });

    test('formate les Ko', () {
      expect(TrailCatalogCard.formatFileSize(1024), '1 Ko');
      expect(TrailCatalogCard.formatFileSize(524288), '512 Ko');
    });

    test('formate les Mo', () {
      expect(TrailCatalogCard.formatFileSize(1048576), '1.0 Mo');
      expect(TrailCatalogCard.formatFileSize(2097152), '2.0 Mo');
    });
  });

  group('TrailCatalogCard.statusColor', () {
    test('retourne gris pour notDownloaded', () {
      final color = TrailCatalogCard.statusColor(TrailLocalStatus.notDownloaded);
      expect(color, isNotNull);
    });

    test('retourne vert pour downloaded', () {
      final color = TrailCatalogCard.statusColor(TrailLocalStatus.downloaded);
      expect(color, isNotNull);
    });
  });
}
