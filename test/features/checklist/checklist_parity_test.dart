import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/features/checklist/providers/checklist_provider.dart';

/// Tests de PARITE GR20 « Materiel & Sac » — blocs clones cote StepWays :
/// articles personnalises, quantite (regles B-06a/B143), liste de courses,
/// niveaux d'exigence, poids total quantite comprise, validation du sac.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      trailConfigProvider.overrideWithValue(testTrailConfig),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> ready() =>
      Future<void>.delayed(const Duration(milliseconds: 200));

  group('Categories & articles (clone GR20)', () {
    test('les 12 categories GR20 sont toutes peuplees', () async {
      container.read(checklistProvider);
      await ready();
      final state = container.read(checklistProvider);
      for (final cat in checklistCategories) {
        expect(state.items.any((i) => i.template.category == cat), true,
            reason: 'categorie $cat vide');
      }
      expect(state.items.length, 84);
    });

    test('categories GR20 specifiques presentes (Femme/Homme/Chien/Cuisine)',
        () async {
      container.read(checklistProvider);
      await ready();
      final cats = container
          .read(checklistProvider)
          .items
          .map((i) => i.template.category)
          .toSet();
      expect(cats.containsAll(['women', 'men', 'dog', 'cooking', 'electronics']),
          true);
    });
  });

  group('Quantite (parite GR20 B-06a / B143)', () {
    test('B143 : + sur un article non coche le coche a quantite 1', () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      // dryBags a une quantite par defaut de 3 mais est decoche.
      await notifier.setItemQuantity('dryBags', 4); // item non coche + '+'
      final item = container
          .read(checklistProvider)
          .items
          .firstWhere((i) => i.template.id == 'dryBags');
      expect(item.isChecked, true);
      expect(item.quantity, 1);
    });

    test('B-06a : quantite descendue sous 1 decoche et remet a 1', () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      await notifier.toggle('gasCanister'); // coche (qty defaut 2)
      await notifier.setItemQuantity('gasCanister', 3);
      await notifier.setItemQuantity('gasCanister', 0); // sous 1
      final item = container
          .read(checklistProvider)
          .items
          .firstWhere((i) => i.template.id == 'gasCanister');
      expect(item.isChecked, false);
      expect(item.quantity, 1);
    });

    test('le poids total prend la quantite en compte', () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      await notifier.toggle('gasCanister'); // 230 g
      await notifier.setItemQuantity('gasCanister', 3);
      // 230 * 3 = 690
      expect(container.read(checklistProvider).checkedWeightGrams, 690);
    });
  });

  group('Articles personnalises (parite GR20)', () {
    test('ajout d un article custom : coche, persiste, compte dans le total',
        () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      await notifier.addCustomItem('misc', 'Gourde perso', 250);

      final state = container.read(checklistProvider);
      final custom = state.items.firstWhere((i) => i.isCustom);
      expect(custom.customName, 'Gourde perso');
      expect(custom.isChecked, true);
      expect(custom.weightGrams, 250);
      expect(state.checkedWeightGrams, 250);

      // Persistance DB.
      final rows = await ChecklistDao(db).getByTrailId(testTrailConfig.id);
      expect(rows.any((r) => r.isCustom && r.customName == 'Gourde perso'),
          true);
    });

    test('suppression d un article custom le retire (et pas les autres)',
        () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      await notifier.addCustomItem('misc', 'A supprimer', 100);
      final custom = container
          .read(checklistProvider)
          .items
          .firstWhere((i) => i.isCustom);
      final before = container.read(checklistProvider).items.length;

      await notifier.deleteCustomItem(custom.template.id);
      final after = container.read(checklistProvider).items;
      expect(after.length, before - 1);
      expect(after.any((i) => i.template.id == custom.template.id), false);
    });

    test('renommer un article du template est sans effet (nom verrouille)',
        () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      await notifier.setCustomName('backpack', 'Nouveau nom');
      final item = container
          .read(checklistProvider)
          .items
          .firstWhere((i) => i.template.id == 'backpack');
      expect(item.customName, isNull);
    });
  });

  group('Liste de courses (parite GR20)', () {
    test('ajout/retrait a la liste de courses persiste et compte', () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      expect(container.read(checklistProvider).shoppingListCount, 0);

      await notifier.toggleShoppingList('tickRemover');
      expect(container.read(checklistProvider).shoppingListCount, 1);
      expect(
          container
              .read(checklistProvider)
              .items
              .firstWhere((i) => i.template.id == 'tickRemover')
              .inShoppingList,
          true);

      // Persistance DB.
      final rows = await ChecklistDao(db).getByTrailId(testTrailConfig.id);
      expect(
          rows.firstWhere((r) => r.itemId == 'tickRemover').inShoppingList,
          true);

      await notifier.toggleShoppingList('tickRemover');
      expect(container.read(checklistProvider).shoppingListCount, 0);
    });
  });

  group('Exigence & validation du sac (parite GR20)', () {
    test('requiredCount > 0 et allRequiredChecked bascule quand tout coche',
        () async {
      container.read(checklistProvider);
      await ready();
      final state0 = container.read(checklistProvider);
      expect(state0.requiredCount, greaterThan(0));
      expect(state0.allRequiredChecked, false);

      final notifier = container.read(checklistProvider.notifier);
      for (final item in state0.items.where((i) =>
          i.template.requirement == ChecklistRequirement.required)) {
        await notifier.toggle(item.template.id);
      }
      expect(container.read(checklistProvider).allRequiredChecked, true);
    });

    test('validateBag / cancelValidation basculent le flag', () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      expect(container.read(checklistProvider).bagValidated, false);
      notifier.validateBag();
      expect(container.read(checklistProvider).bagValidated, true);
      notifier.cancelValidation();
      expect(container.read(checklistProvider).bagValidated, false);
    });

    test('forceUncheck decoche un article obligatoire', () async {
      container.read(checklistProvider);
      await ready();
      final notifier = container.read(checklistProvider.notifier);
      await notifier.toggle('whistle');
      expect(
          container
              .read(checklistProvider)
              .items
              .firstWhere((i) => i.template.id == 'whistle')
              .isChecked,
          true);
      await notifier.forceUncheck('whistle');
      expect(
          container
              .read(checklistProvider)
              .items
              .firstWhere((i) => i.template.id == 'whistle')
              .isChecked,
          false);
    });
  });
}
