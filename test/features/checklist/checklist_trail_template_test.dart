import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';

/// Test E3.2c -- le template de checklist change quand le sentier change.
void main() {
  group('E3.2c template dynamique selon sentier', () {
    final testJson = {
      'version': 1,
      'defaultTemplate': {
        'categories': ['equipment', 'clothing', 'food', 'safety', 'documents', 'hygiene'],
        'items': [
          {'id': 'backpack', 'category': 'equipment', 'nameKey': 'backpack', 'isEssential': true},
          {'id': 'sleepingBag', 'category': 'equipment', 'nameKey': 'sleepingBag', 'isEssential': true},
          {'id': 'hikingBoots', 'category': 'clothing', 'nameKey': 'hikingBoots', 'isEssential': true},
          {'id': 'trailSnacks', 'category': 'food', 'nameKey': 'trailSnacks', 'isEssential': false},
          {'id': 'firstAidKit', 'category': 'safety', 'nameKey': 'firstAidKit', 'isEssential': true},
          {'id': 'towel', 'category': 'hygiene', 'nameKey': 'towel', 'isEssential': false},
        ],
      },
      'trailOverrides': {
        'trail_alpha': {
          'addItems': [
            {'id': 'crampons', 'category': 'equipment', 'nameKey': 'crampons', 'isEssential': true},
          ],
          'removeItems': ['towel'],
          'essentialOverrides': {'trailSnacks': true},
        },
        'trail_beta': {
          'addItems': [
            {'id': 'swimsuit', 'category': 'clothing', 'nameKey': 'swimsuit', 'isEssential': false},
          ],
          'removeItems': <String>[],
          'essentialOverrides': <String, bool>{},
        },
      },
    };

    const trailAlpha = TrailConfig(
      id: 'trail_alpha', name: 'Trail Alpha', displayName: 'Alpha Trek',
      tagline: 'Sentier technique en altitude', totalStages: 10,
      totalDistanceKm: 150.0, totalElevationGain: 9000, region: 'Alpes',
      country: 'France', primaryColorValue: 0xFF2196F3,
      secondaryColorValue: 0xFF1976D2, gpxAssetPath: 'assets/gpx/trail_alpha.gpx',
    );

    const trailBeta = TrailConfig(
      id: 'trail_beta', name: 'Trail Beta', displayName: 'Beta Littoral',
      tagline: 'Sentier cotier facile', totalStages: 5,
      totalDistanceKm: 80.0, totalElevationGain: 1200, region: 'Bretagne',
      country: 'France', primaryColorValue: 0xFF4CAF50,
      secondaryColorValue: 0xFF388E3C, gpxAssetPath: 'assets/gpx/trail_beta.gpx',
    );

    /// Resout le template pour un sentier (simule ChecklistTemplateLoader).
    List<ChecklistTemplateItem> resolveForTrail(String trailId) {
      final defaultData = testJson['defaultTemplate'] as Map<String, dynamic>;
      final defaultItems = (defaultData['items'] as List<dynamic>)
          .map((e) => ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final overrides = testJson['trailOverrides'] as Map<String, dynamic>?;
      if (overrides == null || !overrides.containsKey(trailId)) return defaultItems;
      final trailOverride = TrailChecklistOverride.fromJson(overrides[trailId] as Map<String, dynamic>);
      var result = defaultItems.where((item) => !trailOverride.removeItems.contains(item.id)).toList();
      result = result.map((item) {
        if (trailOverride.essentialOverrides.containsKey(item.id)) {
          return ChecklistTemplateItem(id: item.id, category: item.category, nameKey: item.nameKey,
            isEssential: trailOverride.essentialOverrides[item.id]!);
        }
        return item;
      }).toList();
      result.addAll(trailOverride.addItems);
      return result;
    }

    test('template change quand sentier change', () {
      final itemsAlpha = resolveForTrail(trailAlpha.id);
      final itemsBeta = resolveForTrail(trailBeta.id);
      final idsAlpha = itemsAlpha.map((i) => i.id).toSet();
      final idsBeta = itemsBeta.map((i) => i.id).toSet();
      expect(idsAlpha.contains('crampons'), true);
      expect(idsBeta.contains('crampons'), false);
      expect(idsBeta.contains('swimsuit'), true);
      expect(idsAlpha.contains('swimsuit'), false);
      expect(idsAlpha.contains('towel'), false);
      expect(idsBeta.contains('towel'), true);
      final snacksA = itemsAlpha.firstWhere((i) => i.id == 'trailSnacks');
      final snacksB = itemsBeta.firstWhere((i) => i.id == 'trailSnacks');
      expect(snacksA.isEssential, true);
      expect(snacksB.isEssential, false);
      expect(itemsAlpha.length, 6);
      expect(itemsBeta.length, 7);
    });

    test('sentier sans override retourne template par defaut', () {
      const trailGamma = TrailConfig(
        id: 'trail_gamma', name: 'Trail Gamma', displayName: 'Gamma Campagne',
        tagline: 'Balade tranquille', totalStages: 3, totalDistanceKm: 40.0,
        totalElevationGain: 500, region: 'Normandie', country: 'France',
        primaryColorValue: 0xFFFF9800, secondaryColorValue: 0xFFF57C00,
        gpxAssetPath: 'assets/gpx/trail_gamma.gpx',
      );
      final itemsGamma = resolveForTrail(trailGamma.id);
      final defaultData = testJson['defaultTemplate'] as Map<String, dynamic>;
      final defaultCount = (defaultData['items'] as List<dynamic>).length;
      expect(itemsGamma.length, defaultCount);
      expect(itemsGamma.any((i) => i.id == 'towel'), true);
    });

    test('items communs restent identiques entre sentiers', () {
      final itemsAlpha = resolveForTrail(trailAlpha.id);
      final itemsBeta = resolveForTrail(trailBeta.id);
      final bpA = itemsAlpha.firstWhere((i) => i.id == 'backpack');
      final bpB = itemsBeta.firstWhere((i) => i.id == 'backpack');
      expect(bpA.isEssential, bpB.isEssential);
      expect(bpA.category, bpB.category);
      final faA = itemsAlpha.firstWhere((i) => i.id == 'firstAidKit');
      final faB = itemsBeta.firstWhere((i) => i.id == 'firstAidKit');
      expect(faA.isEssential, faB.isEssential);
    });
  });
}
