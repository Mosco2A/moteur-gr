import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/models/day_plan.dart';

/// Tests du modèle DayPlan — sérialisation et calculs.
void main() {
  const testStage = StageModel(
    trailId: 'test',
    stageNumber: 1,
    name: 'Étape 1',
    distanceKm: 12.0,
    elevationGainM: 800,
    elevationLossM: 600,
    startLat: 42.0,
    startLng: 9.0,
    endLat: 42.1,
    endLng: 9.1,
  );

  group('DayPlan', () {
    test('stageCount retourne le bon nombre', () {
      const day = DayPlan(
        dayNumber: 1,
        stages: [testStage, testStage],
        totalDistanceKm: 24.0,
        totalElevationGainM: 1600,
        estimatedDurationHours: 7.0,
        isRestDay: false,
      );
      expect(day.stageCount, 2);
    });

    test('jour de repos a 0 étapes', () {
      const day = DayPlan(
        dayNumber: 3,
        stages: [],
        totalDistanceKm: 0,
        totalElevationGainM: 0,
        estimatedDurationHours: 0,
        isRestDay: true,
      );
      expect(day.stageCount, 0);
      expect(day.isRestDay, true);
      expect(day.totalDistanceKm, 0);
    });

    test('toJson produit un JSON valide', () {
      const day = DayPlan(
        dayNumber: 2,
        stages: [testStage],
        totalDistanceKm: 12.0,
        totalElevationGainM: 800,
        estimatedDurationHours: 5.0,
        isRestDay: false,
      );

      final json = day.toJson();

      expect(json['dayNumber'], 2);
      expect(json['totalDistanceKm'], 12.0);
      expect(json['totalElevationGainM'], 800);
      expect(json['estimatedDurationHours'], 5.0);
      expect(json['isRestDay'], false);
      expect(json['stages'], isA<List>());
      expect((json['stages'] as List).length, 1);
    });

    test('fromJson reconstruit le modèle correctement', () {
      const original = DayPlan(
        dayNumber: 1,
        stages: [testStage],
        totalDistanceKm: 12.0,
        totalElevationGainM: 800,
        estimatedDurationHours: 5.0,
        isRestDay: false,
      );

      // Aller-retour complet via JSON string pour forcer
      // la désérialisation réelle des Maps
      final jsonStr = jsonEncode(original.toJson());
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = DayPlan.fromJson(decoded);

      expect(restored.dayNumber, original.dayNumber);
      expect(restored.totalDistanceKm, original.totalDistanceKm);
      expect(restored.totalElevationGainM,
          original.totalElevationGainM);
      expect(restored.estimatedDurationHours,
          original.estimatedDurationHours);
      expect(restored.isRestDay, original.isRestDay);
      expect(restored.stages.length, original.stages.length);
    });

    test('fromJson/toJson aller-retour jour de repos', () {
      const rest = DayPlan(
        dayNumber: 4,
        stages: [],
        totalDistanceKm: 0,
        totalElevationGainM: 0,
        estimatedDurationHours: 0,
        isRestDay: true,
      );

      final jsonStr = jsonEncode(rest.toJson());
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = DayPlan.fromJson(decoded);

      expect(restored.isRestDay, true);
      expect(restored.stages, isEmpty);
      expect(restored.dayNumber, 4);
    });
  });
}
