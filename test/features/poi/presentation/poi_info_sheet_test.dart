import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/poi/domain/poi_type_config.dart';
import 'package:moteur_gr/features/poi/presentation/poi_info_sheet.dart';

void main() {
  /// Helper pour creer un Poi de test.
  Poi makePoi({
    int id = 1,
    String name = 'Source de Spasimata',
    String description = 'Point eau potable pres du refuge',
    String type = 'water',
    double lat = 42.15234,
    double lng = 9.08765,
    int altitudeM = 1520,
  }) {
    return Poi(
      id: id,
      trailId: 'gr20',
      stageNumber: 3,
      name: name,
      description: description,
      type: type,
      lat: lat,
      lng: lng,
      altitudeM: altitudeM,
    );
  }

  group('PoiInfoSheet', () {
    testWidgets('affiche les infos correctes du POI', (tester) async {
      final poi = makePoi();
      final style = PoiTypeConfig.getStyle(poi.type);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiInfoSheet(poi: poi),
          ),
        ),
      );

      // Nom du POI
      expect(find.text('Source de Spasimata'), findsOneWidget);

      // Label du type (labelKey)
      expect(find.text(style.labelKey), findsOneWidget);

      // Description
      expect(
        find.text('Point eau potable pres du refuge'),
        findsOneWidget,
      );

      // Coordonnees GPS
      expect(find.text('42.15234, 9.08765'), findsOneWidget);

      // Altitude
      expect(find.text('1520 m'), findsOneWidget);

      // Bouton "Voir sur la carte"
      expect(find.text('Voir sur la carte'), findsOneWidget);

      // Icone du type (water -> water_drop)
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('masque la description si elle est vide', (tester) async {
      final poi = makePoi(description: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiInfoSheet(poi: poi),
          ),
        ),
      );

      // Le nom est present
      expect(find.text('Source de Spasimata'), findsOneWidget);

      // Pas de texte de description vide affiche
      expect(find.text(''), findsNothing);
    });

    testWidgets('masque l\'altitude si elle vaut 0', (tester) async {
      final poi = makePoi(altitudeM: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiInfoSheet(poi: poi),
          ),
        ),
      );

      // Pas d'affichage '0 m'
      expect(find.text('0 m'), findsNothing);

      // Icone terrain absente
      expect(find.byIcon(Icons.terrain), findsNothing);
    });

    testWidgets('type inconnu utilise le fallback PoiTypeConfig',
        (tester) async {
      final poi = makePoi(type: 'alien_base');
      final style = PoiTypeConfig.getStyle('alien_base');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiInfoSheet(poi: poi),
          ),
        ),
      );

      // Le fallback labelKey est le type brut
      expect(find.text('alien_base'), findsOneWidget);

      // Icone fallback : location_on
      expect(find.byIcon(style.icon), findsOneWidget);
    });
  });
}
