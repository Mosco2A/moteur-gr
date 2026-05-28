import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/poi/domain/poi_type_config.dart';

void main() {
  group('PoiTypeConfig.getStyle', () {
    test('retourne le style dedie pour un type connu', () {
      final style = PoiTypeConfig.getStyle('water');

      expect(style.icon, equals(Icons.water_drop));
      expect(style.color, equals(Colors.blue));
      expect(style.labelKey, equals('poi_type_water'));
    });

    test('retourne le style dedie pour chaque type connu', () {
      final knownTypes = {
        'water': (Icons.water_drop, Colors.blue),
        'refuge': (Icons.house, Colors.brown),
        'shop': (Icons.shopping_cart, Colors.green),
        'accommodation': (Icons.hotel, Colors.purple),
        'danger': (Icons.warning, Colors.red),
        'viewpoint': (Icons.visibility, Colors.orange),
        'info': (Icons.info, Colors.grey),
      };

      for (final entry in knownTypes.entries) {
        final style = PoiTypeConfig.getStyle(entry.key);
        expect(style.icon, equals(entry.value.$1),
            reason: 'icon mismatch for type ${entry.key}');
        expect(style.color, equals(entry.value.$2),
            reason: 'color mismatch for type ${entry.key}');
        expect(style.labelKey, equals('poi_type_${entry.key}'),
            reason: 'labelKey mismatch for type ${entry.key}');
      }
    });

    test('retourne fallback generique pour un type inconnu', () {
      final style = PoiTypeConfig.getStyle('alien_base');

      expect(style.icon, equals(Icons.location_on));
      expect(style.color, equals(Colors.grey));
      expect(style.labelKey, equals('alien_base'));
    });
  });
}
