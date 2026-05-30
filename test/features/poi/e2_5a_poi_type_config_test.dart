import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/poi/domain/poi_type_config.dart';

/// Tests E2.5a — PoiTypeConfig getStyle type connu et inconnu.
void main() {
  group('PoiTypeConfig', () {
    test('getStyle type connu retourne le bon style', () {
      final waterStyle = PoiTypeConfig.getStyle('water');
      expect(waterStyle.icon, Icons.water_drop);
      expect(waterStyle.color, const Color(0xFF1565C0));
      expect(waterStyle.labelKey, 'Eau');

      final refugeStyle = PoiTypeConfig.getStyle('refuge');
      expect(refugeStyle.icon, Icons.house);
      expect(refugeStyle.color, const Color(0xFF5D4037));

      final dangerStyle = PoiTypeConfig.getStyle('danger');
      expect(dangerStyle.icon, Icons.warning);
      expect(dangerStyle.color, const Color(0xFFC62828));
    });

    test('getStyle type inconnu retourne fallback', () {
      final unknown = PoiTypeConfig.getStyle('parking_lot');
      expect(unknown.icon, Icons.location_on);
      expect(unknown.color, const Color(0xFF616161));
      // labelKey = le type brut pour les inconnus
      expect(unknown.labelKey, 'parking_lot');
    });

    test('getStyle type vide retourne fallback', () {
      final empty = PoiTypeConfig.getStyle('');
      expect(empty.icon, Icons.location_on);
      expect(empty.color, const Color(0xFF616161));
    });

    test('knownTypes contient les types attendus', () {
      final known = PoiTypeConfig.knownTypes;
      expect(known, contains('water'));
      expect(known, contains('refuge'));
      expect(known, contains('shelter'));
      expect(known, contains('shop'));
      expect(known, contains('accommodation'));
      expect(known, contains('danger'));
      expect(known, contains('viewpoint'));
      expect(known, contains('info'));
    });
  });
}
