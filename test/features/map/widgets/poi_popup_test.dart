import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/features/map/widgets/poi_popup.dart';

/// Tests du widget PoiPopup.
///
/// Vérifie l'affichage du nom, de la description,
/// et des champs optionnels (altitude, horaires).
void main() {
  group('PoiPopup', () {
    /// POI complet avec tous les champs remplis
    const poiComplet = PoiModel(
      id: 1,
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Refuge du Pic Brunel',
      description: 'Refuge gardé, 24 places.',
      type: 'shelter',
      lat: 45.542,
      lng: 2.838,
      altitudeM: 1350,
      openingHours: 'Mai-Octobre',
    );

    /// POI minimal sans altitude ni horaires
    const poiMinimal = PoiModel(
      trailId: 'test-trail',
      stageNumber: 2,
      name: 'Source cachée',
      description: '',
      type: 'water',
      lat: 45.5,
      lng: 2.8,
      altitudeM: 0,
    );

    Widget buildPopup(PoiModel poi) {
      return MaterialApp(
        home: Scaffold(body: PoiPopup(poi: poi)),
      );
    }

    testWidgets('affiche le nom en gras', (tester) async {
      await tester.pumpWidget(buildPopup(poiComplet));
      expect(find.text('Refuge du Pic Brunel'), findsOneWidget);
    });

    testWidgets('affiche la description', (tester) async {
      await tester.pumpWidget(buildPopup(poiComplet));
      expect(find.text('Refuge gardé, 24 places.'), findsOneWidget);
    });

    testWidgets('affiche l\'altitude quand disponible', (tester) async {
      await tester.pumpWidget(buildPopup(poiComplet));
      expect(find.text('1350 m'), findsOneWidget);
      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });

    testWidgets('affiche les horaires quand disponibles', (tester) async {
      await tester.pumpWidget(buildPopup(poiComplet));
      expect(find.text('Mai-Octobre'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('masque l\'altitude quand elle vaut 0', (tester) async {
      await tester.pumpWidget(buildPopup(poiMinimal));
      expect(find.byIcon(Icons.terrain), findsNothing);
    });

    testWidgets('masque les horaires quand null', (tester) async {
      await tester.pumpWidget(buildPopup(poiMinimal));
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    testWidgets('masque la description quand vide', (tester) async {
      await tester.pumpWidget(buildPopup(poiMinimal));
      // Seul le nom doit être présent comme texte significatif
      expect(find.text('Source cachée'), findsOneWidget);
    });

    testWidgets('affiche l\'icône du type de POI', (tester) async {
      await tester.pumpWidget(buildPopup(poiComplet));
      // L'icône shelter (house) est dans l'en-tête du popup
      expect(find.byIcon(Icons.house), findsOneWidget);
    });

    testWidgets('est encapsulé dans une Card', (tester) async {
      await tester.pumpWidget(buildPopup(poiComplet));
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('la largeur maximale est contrainte', (tester) async {
      await tester.pumpWidget(buildPopup(poiComplet));
      // Chercher le ConstrainedBox descendant direct du PoiPopup
      final boxes = tester.widgetList<ConstrainedBox>(
        find.descendant(
          of: find.byType(PoiPopup),
          matching: find.byType(ConstrainedBox),
        ),
      );
      final popupBox = boxes.first;
      expect(popupBox.constraints.maxWidth, 200);
    });
  });
}
