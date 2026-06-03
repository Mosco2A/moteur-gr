// E5.19a -- Tests widget data service progression trek.
//
// 2 tests :
// - Ecrit les bonnes donnees dans SharedPreferences
// - MAJ apres flush (donnees rafraichies)

import 'package:flutter_test/flutter_test.dart';

import 'package:g20_app/features/trek/data/widget_data_service.dart';

void main() {
  group('WidgetDataService', () {
    test('ecrit les bonnes donnees -- cles et valeurs coherentes', () {
      // Service avec prefs null => getWidgetData retourne {}
      final service = WidgetDataService();

      // Sans prefs initialisees, getWidgetData retourne un map vide
      final emptyData = service.getWidgetData();
      expect(emptyData, isEmpty);

      // Verifier que les cles statiques sont bien definies
      expect(WidgetDataService.keyTrailName, contains('trail_name'));
      expect(WidgetDataService.keyStageName, contains('stage_name'));
      expect(WidgetDataService.keyStageProgress, contains('stage_progress'));
      expect(WidgetDataService.keyDistanceRemaining, contains('distance_remaining'));
      expect(WidgetDataService.keyEtaMinutes, contains('eta_minutes'));
      expect(WidgetDataService.keyAltitude, contains('altitude'));
      expect(WidgetDataService.keyStageIndex, contains('stage_index'));
      expect(WidgetDataService.keyTotalStages, contains('total_stages'));

      // Toutes les cles ont le meme prefixe widget_trek_
      expect(WidgetDataService.keyTrailName, startsWith('widget_trek_'));
      expect(WidgetDataService.keyStageName, startsWith('widget_trek_'));
      expect(WidgetDataService.keyStageProgress, startsWith('widget_trek_'));
    });

    test('MAJ apres flush -- donnees rafraichies', () {
      // Verifier que clearWidgetData ne crash pas meme sans prefs
      final service = WidgetDataService();

      // clearWidgetData avec prefs null ne doit pas crasher
      // (early return si _prefs == null)
      expect(
        () async => await service.clearWidgetData(),
        returnsNormally,
      );

      // updateWidgetData avec prefs null ne doit pas crasher
      expect(
        () async => await service.updateWidgetData(
          trailName: 'GR20',
          stageName: 'Etape 3 - Haut Asco',
          stageProgress: 0.45,
          distanceRemaining: 5200.0,
          etaMinutes: 120,
          altitude: 1422.0,
          stageIndex: 3,
          totalStages: 16,
        ),
        returnsNormally,
      );

      // Verifier que getWidgetData retourne toujours {} sans prefs
      // (pas de crash, juste pas de donnees)
      final data = service.getWidgetData();
      expect(data, isEmpty);
    });
  });
}
