import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/share/domain/share_card_generator.dart';

/// Tests du générateur de cartes de partage.
void main() {
  group('ShareCardData', () {
    test('constructeur avec tous les champs', () {
      final data = ShareCardData(
        trailName: 'GR20',
        stageName: 'Calenzana — Ortu di u Piobbu',
        stageNumber: 1,
        distanceKm: 12.5,
        elevationGain: 1560,
        date: DateTime(2026, 7, 15),
      );

      expect(data.trailName, 'GR20');
      expect(data.stageNumber, 1);
      expect(data.distanceKm, 12.5);
      expect(data.elevationGain, 1560);
      expect(data.customMessage, isNull);
    });

    test('constructeur avec message personnalisé', () {
      final data = ShareCardData(
        trailName: 'GR20',
        stageName: 'Étape test',
        stageNumber: 3,
        distanceKm: 8.0,
        elevationGain: 900,
        date: DateTime(2026, 7, 15),
        customMessage: 'Quel panorama !',
      );

      expect(data.customMessage, 'Quel panorama !');
    });
  });

  group('ShareCardGenerator', () {
    test('cardSize vaut 1080', () {
      expect(ShareCardGenerator.cardSize, 1080);
    });
  });
}
