import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';

/// Tests du DAO Checklist sur une base in-memory.
void main() {
  late AppDatabase db;
  late ChecklistDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ChecklistDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : cree un companion d item checklist de test
  ChecklistItemsCompanion makeItem({
    required String trailId,
    required String itemId,
    String category = 'equipment',
    bool isChecked = false,
  }) {
    return ChecklistItemsCompanion(
      trailId: Value(trailId),
      itemId: Value(itemId),
      category: Value(category),
      isChecked: Value(isChecked),
    );
  }

  group('ChecklistDao', () {
    test('insertAll insere les items correctement', () async {
      final items = [
        makeItem(trailId: 'gr20', itemId: 'backpack'),
        makeItem(trailId: 'gr20', itemId: 'sleepingBag'),
        makeItem(trailId: 'gr20', itemId: 'headlamp'),
      ];
      await dao.insertAll(items);

      final result = await dao.getByTrailId('gr20');
      expect(result.length, 3);
    });

    test('getByTrailId retourne vide si aucun sentier', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isEmpty);
    });

    test('getByTrailId filtre par sentier', () async {
      await dao.insertAll([
        makeItem(trailId: 'gr20', itemId: 'backpack'),
        makeItem(trailId: 'tmb', itemId: 'backpack'),
        makeItem(trailId: 'gr20', itemId: 'headlamp'),
      ]);

      final gr20 = await dao.getByTrailId('gr20');
      final tmb = await dao.getByTrailId('tmb');
      expect(gr20.length, 2);
      expect(tmb.length, 1);
    });

    test('getByCategory filtre par categorie', () async {
      await dao.insertAll([
        makeItem(
            trailId: 'gr20', itemId: 'backpack', category: 'equipment'),
        makeItem(
            trailId: 'gr20', itemId: 'boots', category: 'clothing'),
        makeItem(
            trailId: 'gr20', itemId: 'headlamp', category: 'equipment'),
      ]);

      final equipment = await dao.getByCategory('gr20', 'equipment');
      final clothing = await dao.getByCategory('gr20', 'clothing');
      expect(equipment.length, 2);
      expect(clothing.length, 1);
    });

    test('toggleItem coche un item', () async {
      await dao.insertAll([
        makeItem(trailId: 'gr20', itemId: 'backpack'),
      ]);

      await dao.toggleItem('gr20', 'backpack', true);
      final items = await dao.getByTrailId('gr20');
      expect(items.first.isChecked, true);
    });

    test('toggleItem decoche un item', () async {
      await dao.insertAll([
        makeItem(trailId: 'gr20', itemId: 'backpack', isChecked: true),
      ]);

      await dao.toggleItem('gr20', 'backpack', false);
      final items = await dao.getByTrailId('gr20');
      expect(items.first.isChecked, false);
    });

    test('upsertItem insere un nouvel item', () async {
      await dao.upsertItem(
        makeItem(trailId: 'gr20', itemId: 'newItem'),
      );

      final items = await dao.getByTrailId('gr20');
      expect(items.length, 1);
      expect(items.first.itemId, 'newItem');
    });

    test('upsertItem met a jour un item existant', () async {
      await dao.insertAll([
        makeItem(trailId: 'gr20', itemId: 'backpack'),
      ]);

      await dao.upsertItem(const ChecklistItemsCompanion(
        trailId: Value('gr20'),
        itemId: Value('backpack'),
        category: Value('equipment'),
        isChecked: Value(true),
      ));

      final items = await dao.getByTrailId('gr20');
      expect(items.length, 1);
      expect(items.first.isChecked, true);
    });

    test('deleteByTrailId supprime les items du bon sentier', () async {
      await dao.insertAll([
        makeItem(trailId: 'gr20', itemId: 'backpack'),
        makeItem(trailId: 'gr20', itemId: 'headlamp'),
        makeItem(trailId: 'tmb', itemId: 'backpack'),
      ]);

      final deleted = await dao.deleteByTrailId('gr20');
      expect(deleted, 2);

      final remaining = await dao.getByTrailId('tmb');
      expect(remaining.length, 1);
    });

    test('deleteByTrailId retourne 0 si rien a supprimer', () async {
      final deleted = await dao.deleteByTrailId('inexistant');
      expect(deleted, 0);
    });

    test('countChecked retourne le bon nombre', () async {
      await dao.insertAll([
        makeItem(trailId: 'gr20', itemId: 'a', isChecked: true),
        makeItem(trailId: 'gr20', itemId: 'b', isChecked: true),
        makeItem(trailId: 'gr20', itemId: 'c', isChecked: false),
      ]);

      final count = await dao.countChecked('gr20');
      expect(count, 2);
    });

    test('countTotal retourne le bon nombre', () async {
      await dao.insertAll([
        makeItem(trailId: 'gr20', itemId: 'a'),
        makeItem(trailId: 'gr20', itemId: 'b'),
        makeItem(trailId: 'gr20', itemId: 'c'),
      ]);

      final count = await dao.countTotal('gr20');
      expect(count, 3);
    });

    test('countChecked retourne 0 si aucun item', () async {
      final count = await dao.countChecked('inexistant');
      expect(count, 0);
    });
  });
}
