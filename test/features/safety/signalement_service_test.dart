import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/report_local_dao.dart';
import 'package:moteur_gr/features/safety/data/signalement_service.dart';

/// Sink distant simulé : succès par défaut, échec si [fail] est vrai.
class _FakeSink implements ReportRemoteSink {
  _FakeSink({this.fail = false});
  bool fail;
  int pushCount = 0;

  @override
  Future<RemotePushResult> push(ReportLocalData report) async {
    pushCount++;
    if (fail) return const RemotePushResult.failure('réseau KO');
    return RemotePushResult.success('fs-${report.id}');
  }
}

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

  group('SignalementService.createLocal (offline-first)', () {
    test('crée un signalement pending SANS réseau', () async {
      final service =
          SignalementService(database: db, remoteSink: _FakeSink());
      final id = await service.createLocal(
        type: SignalementType.obstacle,
        latitude: 42.0,
        longitude: 9.0,
      );
      expect(id, greaterThan(0));
      expect(await service.pendingCount(), 1);
      final reports = await service.localReports();
      expect(reports.single.synced, isFalse);
      expect(reports.single.type, 'obstacle');
    });

    test('type inconnu rejeté', () async {
      final service =
          SignalementService(database: db, remoteSink: _FakeSink());
      expect(
        () => service.createLocal(
          type: 'invalide',
          latitude: 0,
          longitude: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('SignalementService.trySync (sync différée)', () {
    test('au retour réseau, pousse les pending et marque synced', () async {
      final sink = _FakeSink();
      final service = SignalementService(database: db, remoteSink: sink);
      await service.createLocal(
          type: SignalementType.danger, latitude: 1, longitude: 2);
      await service.createLocal(
          type: SignalementType.eauASec, latitude: 3, longitude: 4);

      final synced = await service.trySync();

      expect(synced, 2);
      expect(sink.pushCount, 2);
      expect(await service.pendingCount(), 0);
      final reports = await service.localReports();
      expect(reports.every((r) => r.synced), isTrue);
    });

    test('zone blanche (deferSync) : aucune tentative de sync', () async {
      final sink = _FakeSink();
      final service = SignalementService(database: db, remoteSink: sink);
      await service.createLocal(
          type: SignalementType.obstacle, latitude: 1, longitude: 2);

      final synced = await service.trySync(shouldDeferSync: true);

      expect(synced, 0);
      expect(sink.pushCount, 0);
      expect(await service.pendingCount(), 1); // reste en attente
    });

    test('échec réseau : signalement reste pending (retry ultérieur)', () async {
      final sink = _FakeSink(fail: true);
      final service = SignalementService(database: db, remoteSink: sink);
      await service.createLocal(
          type: SignalementType.danger, latitude: 1, longitude: 2);

      final synced = await service.trySync();

      expect(synced, 0);
      expect(await service.pendingCount(), 1); // requeue pour re-tenter
    });

    test('retry BORNÉ : abandon après maxAttempts (pas de boucle infinie)',
        () async {
      final sink = _FakeSink(fail: true);
      final service = SignalementService(database: db, remoteSink: sink);
      final id = await service.createLocal(
          type: SignalementType.danger, latitude: 1, longitude: 2);

      // Tente plus de fois que le plafond.
      for (var i = 0; i < SignalementService.maxAttempts + 3; i++) {
        await service.trySync();
      }

      // Le plafond limite le nombre de push réels.
      expect(sink.pushCount, SignalementService.maxAttempts);
      // Le signalement n'est plus dans la file (plafond atteint), en échec.
      expect(await service.pendingCount(), 0);
      final all = await dao.allReports();
      final row = all.firstWhere((r) => r.id == id);
      expect(row.attempts, SignalementService.maxAttempts);
      expect(row.syncState, 'failed');
    });
  });
}
