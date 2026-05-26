import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/features/checklist/providers/checklist_provider.dart';

/// Tests du provider de checklist materiel.
///
/// On teste directement le ChecklistNotifier avec une DB in-memory,
/// sans passer par le ProviderContainer pour eviter les race conditions.
void main() {
  group('ChecklistNotifier', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    /// Helper : cree un notifier et attend le chargement initial.
    Future<ChecklistNotifier> createNotifier(String trailId) async {
      final notifier = ChecklistNotifier(db, trailId);
      // Attendre que le chargement async soit termine
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return notifier;
    }

    test('charge le template par defaut au premier acces', () async {
      final notifier = await createNotifier('test_trail');

      expect(notifier.state.totalCount, defaultChecklistTemplate.length);
      expect(notifier.state.checkedCount, 0);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.items.length, 25);

      notifier.dispose();
    });

    test('toggle coche un item', () async {
      final notifier = await createNotifier('test_trail');

      await notifier.toggle('backpack');

      expect(notifier.state.checkedCount, 1);
      final backpack = notifier.state.items
          .firstWhere((i) => i.template.id == 'backpack');
      expect(backpack.isChecked, true);

      notifier.dispose();
    });

    test('toggle decoche un item deja coche', () async {
      final notifier = await createNotifier('test_trail');

      await notifier.toggle('backpack');
      await notifier.toggle('backpack');

      expect(notifier.state.checkedCount, 0);
      final backpack = notifier.state.items
          .firstWhere((i) => i.template.id == 'backpack');
      expect(backpack.isChecked, false);

      notifier.dispose();
    });

    test('toggle plusieurs items', () async {
      final notifier = await createNotifier('test_trail');

      await notifier.toggle('backpack');
      await notifier.toggle('sleepingBag');
      await notifier.toggle('headlamp');

      expect(notifier.state.checkedCount, 3);

      notifier.dispose();
    });

    test('progress calcule correctement', () async {
      final notifier = await createNotifier('test_trail');

      expect(notifier.state.progress, 0.0);

      await notifier.toggle('backpack');

      expect(
        notifier.state.progress,
        closeTo(1.0 / defaultChecklistTemplate.length, 0.01),
      );

      notifier.dispose();
    });

    test('isComplete est false au debut', () async {
      final notifier = await createNotifier('test_trail');

      expect(notifier.state.isComplete, false);

      notifier.dispose();
    });

    test('resetAll decoche tous les items', () async {
      final notifier = await createNotifier('test_trail');

      await notifier.toggle('backpack');
      await notifier.toggle('sleepingBag');
      expect(notifier.state.checkedCount, 2);

      await notifier.resetAll();
      // Attendre le rechargement
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(notifier.state.checkedCount, 0);

      notifier.dispose();
    });

    test('les items persistent entre deux notifiers', () async {
      final notifier1 = await createNotifier('test_trail');
      await notifier1.toggle('backpack');
      notifier1.dispose();

      // Creer un deuxieme notifier avec la meme DB
      final notifier2 = await createNotifier('test_trail');
      final backpack = notifier2.state.items
          .firstWhere((i) => i.template.id == 'backpack');
      expect(backpack.isChecked, true);

      notifier2.dispose();
    });

    test('sentiers differents ont des checklists independantes', () async {
      final notifier1 = await createNotifier('gr20');
      await notifier1.toggle('backpack');
      notifier1.dispose();

      final notifier2 = await createNotifier('tmb');
      final backpack = notifier2.state.items
          .firstWhere((i) => i.template.id == 'backpack');
      expect(backpack.isChecked, false);

      notifier2.dispose();
    });

    test('initialise depuis le template et cree les items en DB', () async {
      final notifier = await createNotifier('test_trail');
      notifier.dispose();

      // Verifier directement en DB
      final dao = ChecklistDao(db);
      final items = await dao.getByTrailId('test_trail');
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
      );
      expect(itemState.template.id, 'test');
      expect(itemState.template.isEssential, true);
      expect(itemState.isChecked, true);
    });
  });
}
