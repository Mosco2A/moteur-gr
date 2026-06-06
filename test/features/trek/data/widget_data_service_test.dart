// E5.19a -- Tests widget data service progression trek (R1.9).
//
// VRAIS tests : SharedPreferences mocke via setMockInitialValues,
// service reellement instancie, round-trip ecrit -> lit verifie.
// Fixtures : sentier FICTIF "Sentier des Volcans" (test_trail_config).
//
// 2 tests spec V8 :
// - Ecrit les bonnes donnees dans SharedPreferences
// - MAJ apres flush (donnees rafraichies)

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/features/trek/data/widget_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetDataService -- R1.9', () {
    test('ecrit les bonnes donnees -- round-trip ecrit puis lu', () async {
      // Mock SharedPreferences vide
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = WidgetDataService(prefs: prefs);

      await service.updateWidgetData(
        trailName: 'Sentier des Volcans',
        stageName: 'Etape 3 - Crete des Puys',
        stageProgress: 0.45,
        distanceRemaining: 5200.0,
        etaMinutes: 120,
        altitude: 1465.0,
        stageIndex: 3,
        totalStages: 5,
        themeColorValue: 0xFF8B4513,
      );

      // Lecture DIRECTE des prefs : les valeurs ecrites sont la
      expect(prefs.getString(WidgetDataService.keyTrailName),
          equals('Sentier des Volcans'));
      expect(prefs.getString(WidgetDataService.keyStageName),
          equals('Etape 3 - Crete des Puys'));
      expect(prefs.getDouble(WidgetDataService.keyStageProgress),
          equals(0.45));
      expect(prefs.getDouble(WidgetDataService.keyDistanceRemaining),
          equals(5200.0));
      expect(prefs.getInt(WidgetDataService.keyEtaMinutes), equals(120));
      expect(prefs.getDouble(WidgetDataService.keyAltitude), equals(1465.0));
      expect(prefs.getInt(WidgetDataService.keyStageIndex), equals(3));
      expect(prefs.getInt(WidgetDataService.keyTotalStages), equals(5));
      expect(prefs.getInt(WidgetDataService.keyThemeColor),
          equals(0xFF8B4513));
      expect(prefs.getString(WidgetDataService.keyLastUpdate), isNotEmpty);

      // Round-trip via l'API du service
      final data = service.getWidgetData();
      expect(data['trailName'], equals('Sentier des Volcans'));
      expect(data['stageName'], equals('Etape 3 - Crete des Puys'));
      expect(data['stageProgress'], equals(0.45));
      expect(data['totalStages'], equals(5));

      // La progression est clampee dans [0, 1]
      await service.updateWidgetData(
        trailName: 'Sentier des Volcans',
        stageName: 'Etape 3 - Crete des Puys',
        stageProgress: 1.8,
        distanceRemaining: 0,
        etaMinutes: 0,
        altitude: 1465.0,
        stageIndex: 3,
        totalStages: 5,
      );
      expect(prefs.getDouble(WidgetDataService.keyStageProgress),
          equals(1.0));
    });

    test('MAJ apres flush -- donnees rafraichies a chaque ecriture',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = WidgetDataService(prefs: prefs);

      // Premier flush du TrekRecorder (10 positions)
      await service.updateWidgetData(
        trailName: 'Sentier des Volcans',
        stageName: 'Etape 2 - Col du Lac Vert',
        stageProgress: 0.20,
        distanceRemaining: 9100.0,
        etaMinutes: 210,
        altitude: 1180.0,
        stageIndex: 2,
        totalStages: 5,
      );
      final firstUpdate =
          prefs.getString(WidgetDataService.keyLastUpdate);
      expect(service.getWidgetData()['stageProgress'], equals(0.20));

      // Deuxieme flush : la position a avance
      await service.updateWidgetData(
        trailName: 'Sentier des Volcans',
        stageName: 'Etape 2 - Col du Lac Vert',
        stageProgress: 0.55,
        distanceRemaining: 5400.0,
        etaMinutes: 130,
        altitude: 1320.0,
        stageIndex: 2,
        totalStages: 5,
      );

      // Les donnees lues refletent la DERNIERE ecriture
      final data = service.getWidgetData();
      expect(data['stageProgress'], equals(0.55));
      expect(data['distanceRemaining'], equals(5400.0));
      expect(data['etaMinutes'], equals(130));
      expect(data['altitude'], equals(1320.0));
      expect(prefs.getString(WidgetDataService.keyLastUpdate),
          isNotNull);
      expect(firstUpdate, isNotNull);

      // clearWidgetData efface tout (fin de trek)
      await service.clearWidgetData();
      expect(prefs.getString(WidgetDataService.keyTrailName), isNull);
      expect(prefs.getDouble(WidgetDataService.keyStageProgress), isNull);
      expect(service.getWidgetData()['trailName'], equals(''));
    });
  });
}
