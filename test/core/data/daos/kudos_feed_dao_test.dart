import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/kudos_feed_dao.dart';

/// Tests du DAO kudos + fil d'activite offline-first (F7B-01) en memoire.
void main() {
  late AppDatabase db;
  late KudosFeedDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = KudosFeedDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  KudosLocalCompanion makeKudo({
    String target = 'act-1',
    String from = 'hash-aaa',
    DateTime? createdAt,
    String syncState = 'pending',
  }) {
    return KudosLocalCompanion(
      targetActivityId: Value(target),
      fromUidHash: Value(from),
      createdAt: Value(createdAt ?? DateTime.utc(2026, 6, 14, 10)),
      syncState: Value(syncState),
    );
  }

  ActivityFeedCacheCompanion makeActivity({
    String id = 'act-1',
    String type = 'segment_effort',
    String author = 'hash-bbb',
    DateTime? createdAt,
    String moderationState = 'visible',
  }) {
    return ActivityFeedCacheCompanion.insert(
      id: id,
      type: type,
      authorUidHash: author,
      createdAt: createdAt ?? DateTime.utc(2026, 6, 14, 9),
      moderationState: Value(moderationState),
    );
  }

  group('KudosFeedDao — kudos offline-first', () {
    test('addKudoLocal cree un kudo pending sans reseau', () async {
      final id = await dao.addKudoLocal(makeKudo());
      expect(id, greaterThan(0));
      final pending = await dao.pendingKudos();
      expect(pending.length, 1);
      expect(pending.first.targetActivityId, 'act-1');
      expect(pending.first.fromUidHash, 'hash-aaa');
      expect(pending.first.syncState, 'pending');
    });

    test('markKudoSynced retire le kudo de la file pending', () async {
      final id = await dao.addKudoLocal(makeKudo());
      await dao.markKudoSynced(id);
      expect(await dao.pendingKudos(), isEmpty);
    });

    test('hasKudoLocal detecte un doublon local (garde idempotence)', () async {
      await dao.addKudoLocal(makeKudo(from: 'hash-x', target: 'act-9'));
      expect(await dao.hasKudoLocal('hash-x', 'act-9'), isTrue);
      expect(await dao.hasKudoLocal('hash-x', 'autre'), isFalse);
    });

    test('markKudoFailed + requeue refait passer pending', () async {
      final id = await dao.addKudoLocal(makeKudo());
      await dao.markKudoFailed(id, 'timeout');
      var pending = await dao.pendingKudos();
      expect(pending, isEmpty);
      await dao.requeueKudo(id);
      pending = await dao.pendingKudos();
      expect(pending.length, 1);
    });
  });

  group('KudosFeedDao — fil d activite cache', () {
    test('upsertActivities puis visibleActivities lit le cache', () async {
      await dao.upsertActivities([makeActivity(id: 'act-1')]);
      final visible = await dao.visibleActivities();
      expect(visible.length, 1);
      expect(visible.first.id, 'act-1');
    });

    test('visibleActivities masque les activites removed (DSA)', () async {
      await dao.upsertActivities([
        makeActivity(id: 'act-1', moderationState: 'visible'),
        makeActivity(id: 'act-2', moderationState: 'removed'),
        makeActivity(id: 'act-3', moderationState: 'flagged'),
      ]);
      final visible = await dao.visibleActivities();
      final ids = visible.map((a) => a.id).toSet();
      expect(ids.contains('act-1'), isTrue);
      expect(ids.contains('act-3'), isTrue); // flagged reste visible
      expect(ids.contains('act-2'), isFalse); // removed masque
    });

    test('setModerationState reflete une decision serveur en cache', () async {
      await dao.upsertActivities([makeActivity(id: 'act-1')]);
      await dao.setModerationState('act-1', 'removed');
      expect(await dao.visibleActivities(), isEmpty);
    });

    test('upsert idempotent (meme id -> update)', () async {
      await dao.upsertActivities([makeActivity(id: 'act-1', type: 'badge')]);
      await dao.upsertActivities([makeActivity(id: 'act-1', type: 'defi')]);
      final visible = await dao.visibleActivities();
      expect(visible.length, 1);
      expect(visible.first.type, 'defi');
    });
  });
}
