import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';

void main() {
  group('Stage', () {
    test('fromJson roundtrip', () {
      const stage = Stage(
        id: 'stage-1',
        nameFr: 'Calenzana - Ortu di u Piobbu',
        nameEn: 'Calenzana - Ortu di u Piobbu',
        nameDe: 'Calenzana - Ortu di u Piobbu',
        nameIt: 'Calenzana - Ortu di u Piobbu',
        nameEs: 'Calenzana - Ortu di u Piobbu',
        distance: 12.5,
        elevationGain: 1500,
        elevationLoss: 200,
        estimatedDurationSeconds: 25200,
        difficulty: 'hard',
        orderIndex: 1,
        startLat: 42.5082,
        startLng: 8.8556,
        endLat: 42.4875,
        endLng: 8.9213,
        descriptionFr: 'Premiere etape du GR20 Nord',
        descriptionEn: 'First stage of the GR20 North',
      );

      final json = stage.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = Stage.fromJson(decoded);

      expect(restored, equals(stage));
      expect(restored.id, equals('stage-1'));
      expect(restored.nameFr, equals('Calenzana - Ortu di u Piobbu'));
      expect(restored.distance, equals(12.5));
      expect(restored.elevationGain, equals(1500));
      expect(restored.elevationLoss, equals(200));
      expect(restored.estimatedDuration, equals(const Duration(hours: 7)));
      expect(restored.difficulty, equals('hard'));
      expect(restored.orderIndex, equals(1));
      expect(restored.startLat, equals(42.5082));
      expect(restored.descriptionFr, equals('Premiere etape du GR20 Nord'));
      expect(restored.descriptionEn, equals('First stage of the GR20 North'));
    });

    test('difficulty String inconnue ne crash pas', () {
      const stage = Stage(
        id: 'stage-2',
        nameFr: 'Test',
        distance: 5.0,
        elevationGain: 300,
        elevationLoss: 100,
        difficulty: 'ultra_extreme_custom',
        orderIndex: 2,
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.1,
        endLng: 9.1,
      );

      expect(stage.difficulty, equals('ultra_extreme_custom'));

      // Roundtrip JSON avec difficulte inconnue
      final json = stage.toJson();
      final restored = Stage.fromJson(json);
      expect(restored.difficulty, equals('ultra_extreme_custom'));

      // Valeur vide
      final emptyDifficulty = stage.copyWith(difficulty: '');
      expect(emptyDifficulty.difficulty, equals(''));

      // Valeur avec caracteres speciaux
      final specialDifficulty = stage.copyWith(difficulty: 'T2-alpine');
      expect(specialDifficulty.difficulty, equals('T2-alpine'));
    });
  });
}
