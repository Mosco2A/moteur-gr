import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';

/// Tests du template de checklist materiel — CLONE du contenu GR20
/// « Materiel & Sac » (parite #99433).
void main() {
  group('ChecklistTemplateItem', () {
    test('constructor initialise tous les champs', () {
      const item = ChecklistTemplateItem(
        id: 'test_item',
        category: 'carrying',
        nameKey: 'testKey',
        isEssential: true,
        weightGrams: 500,
        quantity: 2,
        requirement: ChecklistRequirement.required,
      );

      expect(item.id, 'test_item');
      expect(item.category, 'carrying');
      expect(item.nameKey, 'testKey');
      expect(item.isEssential, true);
      expect(item.weightGrams, 500);
      expect(item.quantity, 2);
      expect(item.requirement, ChecklistRequirement.required);
    });

    test('valeurs par defaut : optional, quantite 1, non essentiel', () {
      const item = ChecklistTemplateItem(
        id: 'test',
        category: 'foodWater',
        nameKey: 'test',
      );

      expect(item.isEssential, false);
      expect(item.quantity, 1);
      expect(item.requirement, ChecklistRequirement.optional);
    });
  });

  group('defaultChecklistTemplate (clone GR20)', () {
    test('contient 84 articles (clone du sac GR20)', () {
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

    test('contient des articles obligatoires (required)', () {
      final required = defaultChecklistTemplate.where(
          (i) => i.requirement == ChecklistRequirement.required);
      expect(required.length, greaterThanOrEqualTo(5));
    });

    test('chaque categorie a au moins un article', () {
      for (final category in checklistCategories) {
        final items =
            defaultChecklistTemplate.where((i) => i.category == category);
        expect(items.isNotEmpty, true, reason: 'Categorie vide: $category');
      }
    });

    test('les obligatoires incluent la veste impermeable (parite GR20)', () {
      final rainJacket =
          defaultChecklistTemplate.firstWhere((i) => i.id == 'rainJacket');
      expect(rainJacket.requirement, ChecklistRequirement.required);
      expect(rainJacket.isEssential, true);
    });

    test('les obligatoires incluent le sifflet, la couverture de survie et '
        'la lampe frontale (parite GR20)', () {
      for (final id in ['whistle', 'emergencyBlanket', 'headlamp']) {
        final item = defaultChecklistTemplate.firstWhere((i) => i.id == id);
        expect(item.requirement, ChecklistRequirement.required,
            reason: '$id doit etre obligatoire');
      }
    });

    test('les quantites par defaut clonent GR20 (ex: t-shirt x2, gaz x2)', () {
      expect(
          defaultChecklistTemplate
              .firstWhere((i) => i.id == 'techTshirt')
              .quantity,
          2);
      expect(
          defaultChecklistTemplate
              .firstWhere((i) => i.id == 'gasCanister')
              .quantity,
          2);
      expect(
          defaultChecklistTemplate
              .firstWhere((i) => i.id == 'dogPoopBags')
              .quantity,
          10);
    });

    test('les articles portes ont un poids 0 (chaussures, batons) — GR20', () {
      expect(
          defaultChecklistTemplate
              .firstWhere((i) => i.id == 'hikingBoots')
              .weightGrams,
          0);
      expect(
          defaultChecklistTemplate
              .firstWhere((i) => i.id == 'hikingPoles')
              .weightGrams,
          0);
    });
  });

  group('checklistCategories (clone GR20)', () {
    test('contient les 12 categories de GR20', () {
      expect(checklistCategories.length, 12);
    });

    test('contient carrying sleeping clothing cooking foodWater hygiene '
        'firstAid electronics women men misc dog', () {
      for (final c in [
        'carrying',
        'sleeping',
        'clothing',
        'cooking',
        'foodWater',
        'hygiene',
        'firstAid',
        'electronics',
        'women',
        'men',
        'misc',
        'dog',
      ]) {
        expect(checklistCategories, contains(c));
      }
    });

    test('ordre GR20 : Femme, Homme, Divers, Chien en fin', () {
      final n = checklistCategories.length;
      expect(checklistCategories.sublist(n - 4),
          ['women', 'men', 'misc', 'dog']);
    });

    test('pas de doublons', () {
      final unique = checklistCategories.toSet();
      expect(unique.length, checklistCategories.length);
    });

    test('chaque categorie a une icone', () {
      for (final c in checklistCategories) {
        expect(checklistCategoryIconCodepoints.containsKey(c), true,
            reason: 'Icone manquante pour $c');
      }
    });
  });
}
