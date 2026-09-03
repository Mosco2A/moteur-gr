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

/// Tests du provider de checklist materiel.
///
/// On teste le ChecklistNotifier via ProviderContainer avec une DB in-memory.
void main() {
  group('ChecklistNotifier', () {
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

    test('charge le template par defaut au premier acces', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final state = container.read(checklistProvider);
      expect(state.totalCount, defaultChecklistTemplate.length);
      expect(state.checkedCount, 0);
      expect(state.isLoading, false);
      // Parite GR20 : le sac clone contient 84 articles par defaut.
      expect(state.items.length, 84);
    });

    test('toggle coche un item', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await container.read(checklistProvider.notifier).toggle('backpack');

      final state = container.read(checklistProvider);
      expect(state.checkedCount, 1);
      final backpack = state.items
          .firstWhere((i) => i.template.id == 'backpack');
      expect(backpack.isChecked, true);
    });

    test('toggle decoche un item deja coche', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(checklistProvider.notifier);
      await notifier.toggle('backpack');
      await notifier.toggle('backpack');

      final state = container.read(checklistProvider);
      expect(state.checkedCount, 0);
      final backpack = state.items
          .firstWhere((i) => i.template.id == 'backpack');
      expect(backpack.isChecked, false);
    });

    test('toggle plusieurs items', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(checklistProvider.notifier);
      await notifier.toggle('backpack');
      await notifier.toggle('sleepingBag');
      await notifier.toggle('headlamp');

      expect(container.read(checklistProvider).checkedCount, 3);
    });

    test('progress calcule correctement', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(container.read(checklistProvider).progress, 0.0);

      await container.read(checklistProvider.notifier).toggle('backpack');

      expect(
        container.read(checklistProvider).progress,
        closeTo(1.0 / defaultChecklistTemplate.length, 0.01),
      );
    });

    test('isComplete est false au debut', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(container.read(checklistProvider).isComplete, false);
    });

    test('resetAll decoche tous les items', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(checklistProvider.notifier);
      await notifier.toggle('backpack');
      await notifier.toggle('sleepingBag');
      expect(container.read(checklistProvider).checkedCount, 2);

      await notifier.resetAll();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(container.read(checklistProvider).checkedCount, 0);
    });

    test('initialise depuis le template et cree les items en DB', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final dao = ChecklistDao(db);
      final items = await dao.getByTrailId(testTrailConfig.id);
      expect(items.length, defaultChecklistTemplate.length);
    });
  });

  group('ChecklistState', () {
    test('empty a isLoading true', () {
      expect(ChecklistState.empty.isLoading, true);
      expect(ChecklistState.empty.items, isEmpty);
      expect(ChecklistState.empty.checkedCount, 0);
      expect(ChecklistState.empty.totalCount, 0);
    });

    test('progress est 0 si totalCount est 0', () {
      const state = ChecklistState(
        items: [],
        checkedCount: 0,
        totalCount: 0,
      );
      expect(state.progress, 0.0);
    });

    test('isComplete est false si totalCount est 0', () {
      const state = ChecklistState(
        items: [],
        checkedCount: 0,
        totalCount: 0,
      );
      expect(state.isComplete, false);
    });

    test('isComplete est true quand tout est coche', () {
      const state = ChecklistState(
        items: [],
        checkedCount: 5,
        totalCount: 5,
      );
      expect(state.isComplete, true);
    });

    test('progress calcule le bon ratio', () {
      const state = ChecklistState(
        items: [],
        checkedCount: 3,
        totalCount: 10,
      );
      expect(state.progress, closeTo(0.3, 0.01));
    });
  });

  group('ChecklistItemState', () {
    test('stocke le template et l etat coche', () {
      const template = ChecklistTemplateItem(
        id: 'test',
        category: 'equipment',
        nameKey: 'test',
        isEssential: true,
      );
      const itemState = ChecklistItemState(
        template: template,
        isChecked: true,
        weightGrams: 250,
      );
      expect(itemState.template.id, 'test');
      expect(itemState.template.isEssential, true);
      expect(itemState.isChecked, true);
      expect(itemState.weightGrams, 250);
    });
  });
}
