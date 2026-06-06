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
        makeItem(trailId: 'sentier-bleu', itemId: 'backpack'),
        makeItem(trailId: 'sentier-bleu', itemId: 'sleepingBag'),
        makeItem(trailId: 'sentier-bleu', itemId: 'headlamp'),
      ];
      await dao.insertAll(items);

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result.length, 3);
    });

    test('getByTrailId retourne vide si aucun sentier', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isEmpty);
    });

    test('getByTrailId filtre par sentier', () async {
      await dao.insertAll([
        makeItem(trailId: 'sentier-bleu', itemId: 'backpack'),
        makeItem(trailId: 'tmb', itemId: 'backpack'),
        makeItem(trailId: 'sentier-bleu', itemId: 'headlamp'),
      ]);

      final sentierBleu = await dao.getByTrailId('sentier-bleu');
      final tmb = await dao.getByTrailId('tmb');
      expect(sentierBleu.length, 2);
      expect(tmb.length, 1);
    });

    test('getByCategory filtre par categorie', () async {
      await dao.insertAll([
        makeItem(
            trailId: 'sentier-bleu', itemId: 'backpack', category: 'equipment'),
        makeItem(
            trailId: 'sentier-bleu', itemId: 'boots', category: 'clothing'),
        makeItem(
            trailId: 'sentier-bleu', itemId: 'headlamp', category: 'equipment'),
      ]);

      final equipment = await dao.getByCategory('sentier-bleu', 'equipment');
      final clothing = await dao.getByCategory('sentier-bleu', 'clothing');
      expect(equipment.length, 2);
      expect(clothing.length, 1);
    });

    test('toggleItem coche un item', () async {
      await dao.insertAll([
        makeItem(trailId: 'sentier-bleu', itemId: 'backpack'),
      ]);

      await dao.toggleItem('sentier-bleu', 'backpack', true);
      final items = await dao.getByTrailId('sentier-bleu');
      expect(items.first.isChecked, true);
    });

    test('toggleItem decoche un item', () async {
      await dao.insertAll([
        makeItem(trailId: 'sentier-bleu', itemId: 'backpack', isChecked: true),
      ]);

      await dao.toggleItem('sentier-bleu', 'backpack', false);
      final items = await dao.getByTrailId('sentier-bleu');
      expect(items.first.isChecked, false);
    });

    test('upsertItem insere un nouvel item', () async {
      await dao.upsertItem(
        makeItem(trailId: 'sentier-bleu', itemId: 'newItem'),
      );

      final items = await dao.getByTrailId('sentier-bleu');
      expect(items.length, 1);
      expect(items.first.itemId, 'newItem');
    });

    test('upsertItem met a jour un item existant', () async {
      await dao.insertAll([
        makeItem(trailId: 'sentier-bleu', itemId: 'backpack'),
      ]);

      await dao.upsertItem(const ChecklistItemsCompanion(
        trailId: Value('sentier-bleu'),
        itemId: Value('backpack'),
        category: Value('equipment'),
        isChecked: Value(true),
      ));

      final items = await dao.getByTrailId('sentier-bleu');
      expect(items.length, 1);
      expect(items.first.isChecked, true);
    });

    test('deleteByTrailId supprime les items du bon sentier', () async {
      await dao.insertAll([
        makeItem(trailId: 'sentier-bleu', itemId: 'backpack'),
        makeItem(trailId: 'sentier-bleu', itemId: 'headlamp'),
        makeItem(trailId: 'tmb', itemId: 'backpack'),
      ]);

      final deleted = await dao.deleteByTrailId('sentier-bleu');
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
        makeItem(trailId: 'sentier-bleu', itemId: 'a', isChecked: true),
        makeItem(trailId: 'sentier-bleu', itemId: 'b', isChecked: true),
        makeItem(trailId: 'sentier-bleu', itemId: 'c', isChecked: false),
      ]);

      final count = await dao.countChecked('sentier-bleu');
      expect(count, 2);
    });

    test('countTotal retourne le bon nombre', () async {
      await dao.insertAll([
        makeItem(trailId: 'sentier-bleu', itemId: 'a'),
        makeItem(trailId: 'sentier-bleu', itemId: 'b'),
        makeItem(trailId: 'sentier-bleu', itemId: 'c'),
      ]);

      final count = await dao.countTotal('sentier-bleu');
      expect(count, 3);
    });

    test('countChecked retourne 0 si aucun item', () async {
      final count = await dao.countChecked('inexistant');
      expect(count, 0);
    });
  });
}
