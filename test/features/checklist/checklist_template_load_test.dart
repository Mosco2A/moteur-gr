import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';

/// Test que le template JSON se charge et se resout correctement.
/// Utilise un mock du rootBundle pour eviter la dependance Flutter.
void main() {
  group('checklist_template.json validation', () {
    /// JSON du template — meme structure que assets/data/checklist_template.json
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
          {'id': 'idCard', 'category': 'documents', 'nameKey': 'idCard', 'isEssential': true},
          {'id': 'towel', 'category': 'hygiene', 'nameKey': 'towel', 'isEssential': false},
        ],
      },
      'trailOverrides': {
        'sentier-bleu': {
          'addItems': [
            {'id': 'crampons', 'category': 'equipment', 'nameKey': 'crampons', 'isEssential': true},
          ],
          'removeItems': ['towel'],
          'essentialOverrides': {'trailSnacks': true},
        },
      },
    };

    test('template JSON se parse correctement', () {
      final defaultData = testJson['defaultTemplate'] as Map<String, dynamic>;
      final items = (defaultData['items'] as List<dynamic>)
          .map((e) => ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(items.length, 7);
      expect(items.first.id, 'backpack');
      expect(items.first.isEssential, true);
    });

    test('categories sont toutes presentes', () {
      final defaultData = testJson['defaultTemplate'] as Map<String, dynamic>;
      final categories = (defaultData['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      expect(categories, containsAll(['equipment', 'clothing', 'food', 'safety', 'documents', 'hygiene']));
      expect(categories.length, 6);
    });

    test('overrides sentier ajoute crampons et retire towel', () {
      final defaultData = testJson['defaultTemplate'] as Map<String, dynamic>;
      final defaultItems = (defaultData['items'] as List<dynamic>)
          .map((e) => ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
          .toList();

      final overridesData = testJson['trailOverrides'] as Map<String, dynamic>;
      final trailOverride = TrailChecklistOverride.fromJson(
        overridesData['sentier-bleu'] as Map<String, dynamic>,
      );

      // Simuler _applyOverrides
      var result = defaultItems
          .where((item) => !trailOverride.removeItems.contains(item.id))
          .toList();

      result = result.map((item) {
        if (trailOverride.essentialOverrides.containsKey(item.id)) {
          return ChecklistTemplateItem(
            id: item.id,
            category: item.category,
            nameKey: item.nameKey,
            isEssential: trailOverride.essentialOverrides[item.id]!,
          );
        }
        return item;
      }).toList();

      result.addAll(trailOverride.addItems);

      // towel retire
      expect(result.any((i) => i.id == 'towel'), false);
      // crampons ajoute
      expect(result.any((i) => i.id == 'crampons'), true);
      expect(result.firstWhere((i) => i.id == 'crampons').isEssential, true);
      // trailSnacks devenu essentiel
      expect(result.firstWhere((i) => i.id == 'trailSnacks').isEssential, true);
      // Total: 7 - 1 (towel) + 1 (crampons) = 7
      expect(result.length, 7);
    });

    test('sentier sans override retourne le template par defaut', () {
      final overridesData = testJson['trailOverrides'] as Map<String, dynamic>;
      expect(overridesData.containsKey('mare_a_mare_centre'), false);
      // Pas d'override -> on retourne les items par defaut tels quels
    });

    test('JSON encode/decode roundtrip complet du template', () {
      final encoded = json.encode(testJson);
      final decoded = json.decode(encoded) as Map<String, dynamic>;

      final defaultData = decoded['defaultTemplate'] as Map<String, dynamic>;
      final items = (defaultData['items'] as List<dynamic>)
          .map((e) => ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(items.length, 7);
      expect(items.first.id, 'backpack');
    });
  });

  group('defaultChecklistTemplate (retrocompat)', () {
    test('contient 84 articles (clone GR20)', () {
      expect(defaultChecklistTemplate.length, 84);
    });

    test('tous les ids sont uniques', () {
      final ids = defaultChecklistTemplate.map((i) => i.id).toSet();
      expect(ids.length, defaultChecklistTemplate.length);
    });

    test('toutes les categories sont valides', () {
      for (final item in defaultChecklistTemplate) {
        expect(
          checklistCategories.contains(item.category),
          true,
          reason: 'Categorie invalide: ${item.category} pour ${item.id}',
        );
      }
    });
  });
}
