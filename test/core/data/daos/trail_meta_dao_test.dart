import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';

/// Tests du DAO TrailMeta sur une base in-memory.
void main() {
  late AppDatabase db;
  late TrailMetaDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailMetaDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : cree un companion TrailMeta de test
  TrailMetaCompanion makeMeta({
    required String id,
    required String code,
    int dataVersion = 1,
    String? lastSync,
    String status = 'active',
  }) {
    return TrailMetaCompanion(
      id: Value(id),
      code: Value(code),
      dataVersion: Value(dataVersion),
      lastSync: Value(lastSync),
      status: Value(status),
    );
  }

  group('TrailMetaDao', () {
    test('insertOrReplace puis getById retourne le bon sentier', () async {
      await dao.insertOrReplace(makeMeta(id: 'tr1', code: 'sentier-bleu'));

      final result = await dao.getById('tr1');
      expect(result, isNotNull);
      expect(result!.code, 'sentier-bleu');
      expect(result.dataVersion, 1);
      expect(result.status, 'active');
    });

    test('getAll retourne tous les sentiers', () async {
      await dao.insertOrReplace(makeMeta(id: 'tr1', code: 'sentier-bleu'));
      await dao.insertOrReplace(makeMeta(id: 'tr2', code: 'mare_a_mare'));

      final result = await dao.getAll();
      expect(result.length, 2);
    });

    test('getById retourne null si inexistant', () async {
      final result = await dao.getById('inexistant');
      expect(result, isNull);
    });

    test('insertOrReplace met a jour un sentier existant', () async {
      await dao.insertOrReplace(makeMeta(id: 'tr1', code: 'sentier-bleu', dataVersion: 1));
      await dao.insertOrReplace(makeMeta(id: 'tr1', code: 'sentier-bleu', dataVersion: 2));

      final result = await dao.getById('tr1');
      expect(result!.dataVersion, 2);
    });

    test('deleteById supprime le bon sentier', () async {
      await dao.insertOrReplace(makeMeta(id: 'tr1', code: 'sentier-bleu'));
      await dao.insertOrReplace(makeMeta(id: 'tr2', code: 'mare'));

      final deleted = await dao.deleteById('tr1');
      expect(deleted, 1);

      final remaining = await dao.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'tr2');
    });

    test('deleteAll supprime tous les sentiers', () async {
      await dao.insertOrReplace(makeMeta(id: 'tr1', code: 'sentier-bleu'));
      await dao.insertOrReplace(makeMeta(id: 'tr2', code: 'mare'));

      final deleted = await dao.deleteAll();
      expect(deleted, 2);

      final remaining = await dao.getAll();
      expect(remaining, isEmpty);
    });

    test('lastSync nullable fonctionne', () async {
      await dao.insertOrReplace(
        makeMeta(id: 'tr1', code: 'sentier-bleu', lastSync: '2026-05-26T12:00:00Z'),
      );

      final result = await dao.getById('tr1');
      expect(result!.lastSync, '2026-05-26T12:00:00Z');
    });
  });
}
