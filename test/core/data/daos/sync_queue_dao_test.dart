import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/sync_queue_dao.dart';

/// Tests du DAO SyncQueue sur une base in-memory.
void main() {
  late AppDatabase db;
  late SyncQueueDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = SyncQueueDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  SyncQueueCompanion makeAction({
    required String trailId,
    required String action,
    String status = 'pending',
    String? payload,
    String createdAt = '2026-05-26T12:00:00Z',
    String? completedAt,
    int retryCount = 0,
  }) {
    return SyncQueueCompanion(
      trailId: Value(trailId), action: Value(action),
      status: Value(status), payload: Value(payload),
      createdAt: Value(createdAt), completedAt: Value(completedAt),
      retryCount: Value(retryCount),
    );
  }

  group('SyncQueueDao CRUD', () {
    test('insertOrReplace puis getByTrailId retourne les actions', () async {
      await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_trail_meta'));
      await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_stages'));
      final result = await dao.getByTrailId('sentier-bleu');
      expect(result.length, 2);
      expect(result[0].action, 'insert_trail_meta');
      expect(result[1].action, 'insert_stages');
    });

    test('getPending retourne uniquement les actions pending', () async {
      await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_trail_meta', status: 'pending'));
      await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_stages', status: 'completed'));
      final pending = await dao.getPending();
      expect(pending.length, 1);
      expect(pending[0].action, 'insert_trail_meta');
    });

    test('getByTrailId retourne vide si aucune action', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isEmpty);
    });
  });

  group('SyncQueueDao markCompleted', () {
    test('markCompleted change le statut et set completedAt', () async {
      final id = await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_trail_meta'));
      await dao.markCompleted(id);
      final actions = await dao.getByTrailId('sentier-bleu');
      expect(actions.length, 1);
      expect(actions[0].status, 'completed');
      expect(actions[0].completedAt, isNotNull);
    });

    test('markCompleted retire l action des pending', () async {
      final id = await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_trail_meta'));
      await dao.markCompleted(id);
      final pending = await dao.getPending();
      expect(pending, isEmpty);
    });
  });

  group('SyncQueueDao markFailed', () {
    test('markFailed change le statut et stocke l erreur', () async {
      final id = await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_trail_meta'));
      await dao.markFailed(id, 'Network timeout');
      final actions = await dao.getByTrailId('sentier-bleu');
      expect(actions[0].status, 'failed');
      expect(actions[0].payload, 'Network timeout');
    });
  });

  group('SyncQueueDao incrementRetry', () {
    test('incrementRetry augmente le compteur', () async {
      final id = await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_trail_meta'));
      await dao.incrementRetry(id);
      final actions = await dao.getByTrailId('sentier-bleu');
      expect(actions[0].retryCount, 1);
    });

    test('incrementRetry fonctionne plusieurs fois', () async {
      final id = await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_trail_meta'));
      await dao.incrementRetry(id);
      await dao.incrementRetry(id);
      await dao.incrementRetry(id);
      final actions = await dao.getByTrailId('sentier-bleu');
      expect(actions[0].retryCount, 3);
    });

    test('incrementRetry ignore un id inexistant', () async {
      await dao.incrementRetry(9999);
    });
  });

  group('SyncQueueDao deleteByTrailId', () {
    test('deleteByTrailId supprime toutes les actions du sentier', () async {
      await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_trail_meta'));
      await dao.insertOrReplace(makeAction(trailId: 'sentier-bleu', action: 'insert_stages'));
      await dao.insertOrReplace(makeAction(trailId: 'tmb', action: 'insert_trail_meta'));
      final deleted = await dao.deleteByTrailId('sentier-bleu');
      expect(deleted, 2);
      final remaining = await dao.getByTrailId('tmb');
      expect(remaining.length, 1);
    });
  });
}