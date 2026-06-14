import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/segments_dao.dart';

/// Tests du DAO Segments + efforts offline-first (F7A-01) sur base in-memory.
void main() {
  late AppDatabase db;
  late SegmentsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = SegmentsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  SegmentsCompanion makeSegment({
    String id = 'seg-1',
    String trailId = 'mare-a-mare',
    String nom = 'Montee du col',
    double distanceM = 1200,
    double deniveleM = 300,
  }) {
    return SegmentsCompanion.insert(
      id: id,
      trailId: trailId,
      nom: nom,
      polylineGpxRef: '[{"lat":42.0,"lng":9.0}]',
      distanceM: distanceM,
      deniveleM: deniveleM,
    );
  }

  SegmentEffortLocalCompanion makeEffort({
    String segmentId = 'seg-1',
    String uidHash = 'hash-aaa',
    int durationSeconds = 600,
    DateTime? startedAt,
    String syncState = 'pending',
  }) {
    return SegmentEffortLocalCompanion(
      segmentId: Value(segmentId),
      userUidHash: Value(uidHash),
      durationSeconds: Value(durationSeconds),
      startedAt: Value(startedAt ?? DateTime.utc(2026, 6, 14, 10)),
      syncState: Value(syncState),
    );
  }

  group('SegmentsDao — cache segments', () {
    test('upsertSegments insere puis met a jour (idempotent)', () async {
      await dao.upsertSegments([makeSegment(nom: 'V1')]);
      var seg = await dao.segmentById('seg-1');
      expect(seg, isNotNull);
      expect(seg!.nom, 'V1');

      // Re-upsert meme id -> update, pas de doublon.
      await dao.upsertSegments([makeSegment(nom: 'V2')]);
      final all = await dao.segmentsForTrail('mare-a-mare');
      expect(all.length, 1);
      expect(all.first.nom, 'V2');
    });

    test('segmentsForTrail filtre par sentier', () async {
      await dao.upsertSegments([
        makeSegment(id: 'seg-1', trailId: 'mare-a-mare'),
        makeSegment(id: 'seg-2', trailId: 'gr20'),
      ]);
      final mam = await dao.segmentsForTrail('mare-a-mare');
      expect(mam.length, 1);
      expect(mam.first.id, 'seg-1');
    });
  });

  group('SegmentsDao — efforts offline-first', () {
    test('insertEffort cree un effort pending sans reseau', () async {
      final id = await dao.insertEffort(makeEffort());
      expect(id, greaterThan(0));
      final pending = await dao.pendingEfforts();
      expect(pending.length, 1);
      expect(pending.first.segmentId, 'seg-1');
      expect(pending.first.syncState, 'pending');
      // UID hache, jamais de PII en clair.
      expect(pending.first.userUidHash, 'hash-aaa');
    });

    test('markEffortSynced retire l effort de la file pending', () async {
      final id = await dao.insertEffort(makeEffort());
      await dao.markEffortSynced(id, remoteId: 'remote-xyz');
      final pending = await dao.pendingEfforts();
      expect(pending, isEmpty);
      final forSeg = await dao.effortsForSegment('seg-1');
      expect(forSeg.length, 1);
      expect(forSeg.first.syncState, 'synced');
      expect(forSeg.first.remoteId, 'remote-xyz');
    });

    test('markEffortFailed incremente attempts puis requeue repasse pending',
        () async {
      final id = await dao.insertEffort(makeEffort());
      await dao.markEffortFailed(id, 'timeout');
      var all = await dao.effortsForSegment('seg-1');
      expect(all.first.syncState, 'failed');
      expect(all.first.attempts, 1);
      expect(all.first.lastError, 'timeout');

      await dao.requeueEffort(id);
      final pending = await dao.pendingEfforts();
      expect(pending.length, 1);
    });

    test('dequeueBatch borne le lot et countPendingEfforts compte', () async {
      for (var i = 0; i < 5; i++) {
        await dao.insertEffort(
          makeEffort(startedAt: DateTime.utc(2026, 6, 14, 10, i)),
        );
      }
      final batch = await dao.dequeueBatch(limit: 3);
      expect(batch.length, 3);
      expect(await dao.countPendingEfforts(), 5);
    });
  });
}
