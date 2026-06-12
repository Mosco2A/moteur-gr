import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/report_local_dao.dart';

/// Tests du DAO ReportLocal (signalements offline-first) sur base in-memory.
void main() {
  late AppDatabase db;
  late ReportLocalDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ReportLocalDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  ReportLocalCompanion makeReport({
    String type = 'obstacle',
    double lat = 42.0,
    double lon = 9.0,
    DateTime? createdAt,
    String? payload,
    String syncState = 'pending',
  }) {
    return ReportLocalCompanion(
      type: Value(type),
      latitude: Value(lat),
      longitude: Value(lon),
      createdAt: Value(createdAt ?? DateTime.utc(2026, 6, 12, 10)),
      payload: Value(payload),
      syncState: Value(syncState),
    );
  }

  group('ReportLocalDao — insertion offline', () {
    test('insertReport cree un signalement pending sans reseau', () async {
      final id = await dao.insertReport(makeReport(type: 'eau_a_sec'));
      expect(id, greaterThan(0));
      final pending = await dao.pendingReports();
      expect(pending.length, 1);
      expect(pending.first.type, 'eau_a_sec');
      expect(pending.first.syncState, 'pending');
      expect(pending.first.attempts, 0);
    });

    test('pendingReports tries du plus ancien au plus recent', () async {
      await dao.insertReport(
          makeReport(type: 'danger', createdAt: DateTime.utc(2026, 6, 12, 12)));
      await dao.insertReport(makeReport(
          type: 'obstacle', createdAt: DateTime.utc(2026, 6, 12, 9)));
      final pending = await dao.pendingReports();
      expect(pending.first.type, 'obstacle'); // plus ancien d'abord
      expect(pending.last.type, 'danger');
    });
  });

  group('ReportLocalDao — synchronisation', () {
    test('markSynced retire le signalement des pending', () async {
      final id = await dao.insertReport(makeReport());
      await dao.markSynced(id, remoteId: 'fs-123');
      final pending = await dao.pendingReports();
      expect(pending, isEmpty);
      final all = await dao.allReports();
      expect(all.first.syncState, 'synced');
      expect(all.first.remoteId, 'fs-123');
    });

    test('markFailed incremente attempts et stocke l erreur', () async {
      final id = await dao.insertReport(makeReport());
      await dao.markFailed(id, 'timeout');
      final all = await dao.allReports();
      expect(all.first.syncState, 'failed');
      expect(all.first.attempts, 1);
      expect(all.first.lastError, 'timeout');
    });

    test('markFailed plusieurs fois cumule les tentatives', () async {
      final id = await dao.insertReport(makeReport());
      await dao.markFailed(id, 'e1');
      await dao.requeue(id);
      await dao.markFailed(id, 'e2');
      final all = await dao.allReports();
      expect(all.first.attempts, 2);
      expect(all.first.lastError, 'e2');
    });

    test('requeue remet un failed en pending', () async {
      final id = await dao.insertReport(makeReport());
      await dao.markFailed(id, 'x');
      await dao.requeue(id);
      final pending = await dao.pendingReports();
      expect(pending.length, 1);
    });
  });

  group('ReportLocalDao — file et nettoyage', () {
    test('dequeueBatch borne le nombre de signalements', () async {
      for (var i = 0; i < 5; i++) {
        await dao.insertReport(
            makeReport(createdAt: DateTime.utc(2026, 6, 12, 10, i)));
      }
      final batch = await dao.dequeueBatch(limit: 3);
      expect(batch.length, 3);
    });

    test('countPending compte les pending uniquement', () async {
      final id1 = await dao.insertReport(makeReport());
      await dao.insertReport(makeReport(type: 'danger'));
      await dao.markSynced(id1);
      expect(await dao.countPending(), 1);
    });

    test('deleteSynced supprime les signalements synchronises', () async {
      final id1 = await dao.insertReport(makeReport());
      await dao.insertReport(makeReport(type: 'danger'));
      await dao.markSynced(id1);
      final deleted = await dao.deleteSynced();
      expect(deleted, 1);
      final all = await dao.allReports();
      expect(all.length, 1);
      expect(all.first.type, 'danger');
    });
  });
}
