import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/booking/domain/models/hebergement_peripherique.dart';

/// Tests du modèle HebergementPeripherique (F6D-02).
///
/// Vérifie la sérialisation Freezed/JSON et le calcul du détour aller simple.
void main() {
  const sample = HebergementPeripherique(
    id: 'hp-1',
    nom: 'Gîte du Vallon',
    type: HebergementType.gite,
    latitude: 42.12,
    longitude: 9.05,
    distanceAllerRetourKm: 2.4,
    deeplinkUrl: 'https://example.org/gite',
  );

  group('HebergementPeripherique', () {
    test('distanceAllerKm est la moitié du A/R', () {
      expect(sample.distanceAllerKm, closeTo(1.2, 1e-9));
    });

    test('sérialise et désérialise sans perte (roundtrip JSON)', () {
      final json = sample.toJson();
      final back = HebergementPeripherique.fromJson(json);
      expect(back, sample);
    });

    test('le type est correctement mappé en JSON', () {
      expect(sample.toJson()['type'], 'gite');
      final refuge = sample.copyWith(type: HebergementType.refuge);
      expect(refuge.toJson()['type'], 'refuge');
    });

    test('copyWith modifie un champ et conserve les autres', () {
      final modifie = sample.copyWith(distanceAllerRetourKm: 6.0);
      expect(modifie.distanceAllerRetourKm, 6.0);
      expect(modifie.distanceAllerKm, 3.0);
      expect(modifie.nom, sample.nom);
    });
  });
}
