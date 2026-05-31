import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/checklist/domain/models/checklist_item.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';

/// Tests de serialisation du modele ChecklistItemModel (Freezed)
/// et du template configurable par sentier.
void main() {
  group('ChecklistItemModel serialization roundtrip', () {
    test('toJson -> fromJson preserve tous les champs', () {
      const item = ChecklistItemModel(
        id: 42,
        templateId: 'backpack',
        name: 'backpack',
        category: 'equipment',
        isChecked: true,
        customNote: 'Sac 40L ultralight',
      );

      final jsonMap = item.toJson();
      final restored = ChecklistItemModel.fromJson(jsonMap);

      expect(restored.id, 42);
      expect(restored.templateId, 'backpack');
      expect(restored.name, 'backpack');
      expect(restored.category, 'equipment');
      expect(restored.isChecked, true);
      expect(restored.customNote, 'Sac 40L ultralight');
    });

    test('toJson -> JSON string -> fromJson roundtrip complet', () {
      const item = ChecklistItemModel(
        templateId: 'firstAidKit',
        name: 'firstAidKit',
        category: 'safety',
      );

      final jsonString = json.encode(item.toJson());
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final restored = ChecklistItemModel.fromJson(decoded);

      expect(restored.templateId, 'firstAidKit');
      expect(restored.category, 'safety');
      expect(restored.isChecked, false);
      expect(restored.customNote, isNull);
      expect(restored.id, 0);
    });

    test('valeurs par defaut correctes (id=0, isChecked=false, customNote=null)', () {
      const item = ChecklistItemModel(
        templateId: 'hat',
        name: 'hat',
        category: 'clothing',
      );

      expect(item.id, 0);
      expect(item.isChecked, false);
      expect(item.customNote, isNull);

      final jsonMap = item.toJson();
      final restored = ChecklistItemModel.fromJson(jsonMap);
      expect(restored.id, 0);
      expect(restored.isChecked, false);
      expect(restored.customNote, isNull);
    });
  });

  group('ChecklistTemplateItem JSON', () {
    test('fromJson construit correctement', () {
      final json = {
        'id': 'crampons',
        'category': 'equipment',
        'nameKey': 'crampons',
        'isEssential': true,
      };

      final item = ChecklistTemplateItem.fromJson(json);
      expect(item.id, 'crampons');
      expect(item.category, 'equipment');
      expect(item.nameKey, 'crampons');
      expect(item.isEssential, true);
    });

    test('toJson -> fromJson roundtrip', () {
      const item = ChecklistTemplateItem(
        id: 'helmet',
        category: 'safety',
        nameKey: 'helmet',
        isEssential: true,
      );

      final jsonMap = item.toJson();
      final restored = ChecklistTemplateItem.fromJson(jsonMap);

      expect(restored.id, item.id);
      expect(restored.category, item.category);
      expect(restored.nameKey, item.nameKey);
      expect(restored.isEssential, item.isEssential);
    });

    test('isEssential par defaut a false dans fromJson', () {
      final json = {
        'id': 'towel',
        'category': 'hygiene',
        'nameKey': 'towel',
      };

      final item = ChecklistTemplateItem.fromJson(json);
      expect(item.isEssential, false);
    });
  });

  group('TrailChecklistOverride', () {
    test('fromJson charge correctement les overrides', () {
      final json = {
        'addItems': [
          {'id': 'crampons', 'category': 'equipment', 'nameKey': 'crampons', 'isEssential': true},
        ],
        'removeItems': ['swimsuit'],
        'essentialOverrides': {
          'hikingPoles': true,
        },
      };

      final override = TrailChecklistOverride.fromJson(json);
      expect(override.addItems.length, 1);
      expect(override.addItems.first.id, 'crampons');
      expect(override.removeItems, ['swimsuit']);
      expect(override.essentialOverrides['hikingPoles'], true);
    });

    test('fromJson gere les champs manquants', () {
      final override = TrailChecklistOverride.fromJson({});
      expect(override.addItems, isEmpty);
      expect(override.removeItems, isEmpty);
      expect(override.essentialOverrides, isEmpty);
    });
  });
}
