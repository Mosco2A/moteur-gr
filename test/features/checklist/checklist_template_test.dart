import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';

/// Tests du template de checklist materiel.
void main() {
  group('ChecklistTemplateItem', () {
    test('constructor initialise tous les champs', () {
      const item = ChecklistTemplateItem(
        id: 'test_item',
        category: 'equipment',
        nameKey: 'testKey',
        isEssential: true,
      );

      expect(item.id, 'test_item');
      expect(item.category, 'equipment');
      expect(item.nameKey, 'testKey');
      expect(item.isEssential, true);
    });

    test('isEssential est false par defaut', () {
      const item = ChecklistTemplateItem(
        id: 'test',
        category: 'food',
        nameKey: 'test',
      );

      expect(item.isEssential, false);
    });
  });

  group('defaultChecklistTemplate', () {
    test('contient 25 items', () {
      expect(defaultChecklistTemplate.length, 25);
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

    test('contient des items essentiels', () {
      final essentials =
          defaultChecklistTemplate.where((i) => i.isEssential);
      expect(essentials.length, greaterThan(5));
    });

    test('chaque categorie a au moins un item', () {
      for (final category in checklistCategories) {
        final items = defaultChecklistTemplate
            .where((i) => i.category == category);
        expect(
          items.isNotEmpty,
          true,
          reason: 'Categorie vide: $category',
        );
      }
    });

    test('les items essentiels incluent le sac a dos', () {
      final backpack = defaultChecklistTemplate
          .firstWhere((i) => i.id == 'backpack');
      expect(backpack.isEssential, true);
    });

    test('les items essentiels incluent la trousse de secours', () {
      final firstAid = defaultChecklistTemplate
          .firstWhere((i) => i.id == 'firstAidKit');
      expect(firstAid.isEssential, true);
    });

    test('les items essentiels incluent la piece identite', () {
      final idCard = defaultChecklistTemplate
          .firstWhere((i) => i.id == 'idCard');
      expect(idCard.isEssential, true);
    });
  });

  group('checklistCategories', () {
    test('contient 6 categories', () {
      expect(checklistCategories.length, 6);
    });

    test('contient equipment clothing food safety documents hygiene',
        () {
      expect(checklistCategories, contains('equipment'));
      expect(checklistCategories, contains('clothing'));
      expect(checklistCategories, contains('food'));
      expect(checklistCategories, contains('safety'));
      expect(checklistCategories, contains('documents'));
      expect(checklistCategories, contains('hygiene'));
    });

    test('pas de doublons', () {
      final unique = checklistCategories.toSet();
      expect(unique.length, checklistCategories.length);
    });
  });
}
