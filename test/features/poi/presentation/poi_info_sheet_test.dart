import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/features/poi/domain/poi_type_config.dart';
import 'package:moteur_gr/features/poi/presentation/poi_info_sheet.dart';

/// Tests widget du composant PoiInfoSheet (Phase 2 E2.5c).
///
/// Verifie que PoiInfoSheet affiche correctement les informations
/// d un POI: nom, type i18n, description, coordonnees, altitude,
/// horaires et bouton navigation.
void main() {
  /// Helper -- cree un PoiModel factice pour les tests.
  PoiModel buildPoi({
    String name = 'Fontaine du Col',
    String description = 'Source fraiche en altitude',
    String type = 'water',
    double lat = 42.12345,
    double lng = 9.67890,
    int altitudeM = 1450,
    String? openingHours,
  }) {
    return PoiModel(
      id: 1,
      trailId: 'trail_test',
      stageNumber: 3,
      name: name,
      description: description,
      type: type,
      lat: lat,
      lng: lng,
      altitudeM: altitudeM,
      openingHours: openingHours,
    );
  }

  group('PoiInfoSheet', () {
    testWidgets('affiche les infos correctes du POI', (tester) async {
      final poi = buildPoi(
        name: 'Refuge de Paliri',
        description: 'Refuge gardien de montagne',
        type: 'refuge',
        lat: 42.34567,
        lng: 9.12345,
        altitudeM: 1055,
        openingHours: '8h-20h',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => PoiInfoSheet(poi: poi),
                  );
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );

      // Ouvrir le bottom sheet
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Nom du POI affiche
      expect(find.text('Refuge de Paliri'), findsOneWidget);

      // Description affichee
      expect(find.text('Refuge gardien de montagne'), findsOneWidget);

      // Coordonnees GPS affichees (format 5 decimales)
      expect(find.text('42.34567, 9.12345'), findsOneWidget);

      // Altitude affichee
      expect(find.text('1055 m'), findsOneWidget);

      // Horaires affiches
      expect(find.text('8h-20h'), findsOneWidget);

      // Icone du type refuge (house) presente
      final style = PoiTypeConfig.getStyle('refuge');
      expect(find.byIcon(style.icon), findsOneWidget);
    });

    test('est un StatelessWidget', () {
      final poi = buildPoi();
      final sheet = PoiInfoSheet(poi: poi);
      expect(sheet, isA<StatelessWidget>());
    });

    test('methode show statique existe', () {
      // Verifier que la methode statique show est accessible
      expect(PoiInfoSheet.show, isA<Function>());
    });

    testWidgets('masque altitude si zero', (tester) async {
      final poi = buildPoi(altitudeM: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => PoiInfoSheet(poi: poi),
                  );
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Altitude 0 ne doit pas etre affichee
      expect(find.text('0 m'), findsNothing);
    });

    testWidgets('masque horaires si null', (tester) async {
      final poi = buildPoi(openingHours: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => PoiInfoSheet(poi: poi),
                  );
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Pas d horaires affiches
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    testWidgets('masque description si vide', (tester) async {
      final poi = buildPoi(description: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => PoiInfoSheet(poi: poi),
                  );
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Nom present
      expect(find.text('Fontaine du Col'), findsOneWidget);

      // Pas de description vide affichee
      expect(find.text(''), findsNothing);
    });
  });
}
