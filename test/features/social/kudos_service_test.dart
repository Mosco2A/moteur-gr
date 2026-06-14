import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/kudos_feed_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/social/data/kudos_service.dart';

/// Sink fake : enregistre les docId pousses, succes ou echec configurable.
class _FakeKudoSink implements KudoRemoteSink {
  _FakeKudoSink({this.fail = false});

  bool fail;
  final List<String> pushedDocIds = [];

  @override
  Future<KudoPushResult> push({
    required String docId,
    required String fromUidHash,
    required String targetActivityId,
  }) async {
    pushedDocIds.add(docId);
    if (fail) return const KudoPushResult.failure('reseau KO');
    return const KudoPushResult.success();
  }
}

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

  group('KudosService — offline-first', () {
    test('giveKudo cree un kudo pending sans reseau', () async {
      final service = KudosService(database: db, remoteSink: _FakeKudoSink());
      final id = await service.giveKudo(
        fromUidHash: 'hash-aaa',
        targetActivityId: 'act-1',
      );
      expect(id, isNotNull);
      final pending = await dao.pendingKudos();
      expect(pending.length, 1);
      expect(pending.first.syncState, 'pending');
    });

    test('trySync pousse puis marque synced', () async {
      final sink = _FakeKudoSink();
      final service = KudosService(database: db, remoteSink: sink);
      await service.giveKudo(fromUidHash: 'hash-aaa', targetActivityId: 'act-1');
      final n = await service.trySync();
      expect(n, 1);
      expect(await dao.pendingKudos(), isEmpty);
      expect(sink.pushedDocIds.length, 1);
    });

    test('deferSync (zone blanche) ne tente RIEN', () async {
      final sink = _FakeKudoSink();
      final service = KudosService(database: db, remoteSink: sink);
      await service.giveKudo(fromUidHash: 'hash-aaa', targetActivityId: 'act-1');
      final n = await service.trySync(shouldDeferSync: true);
      expect(n, 0);
      expect(sink.pushedDocIds, isEmpty);
      expect((await dao.pendingKudos()).length, 1);
    });
  });

  group('KudosService — idempotence', () {
    test('cle distante stable = hash(from+target)', () {
      final a = KudosService.remoteDocId('hash-aaa', 'act-1');
      final b = KudosService.remoteDocId('hash-aaa', 'act-1');
      final c = KudosService.remoteDocId('hash-bbb', 'act-1');
      expect(a, b); // deterministe
      expect(a, isNot(c)); // depend de l auteur
      expect(a.length, 64); // sha-256 hex
    });

    test('un 2e giveKudo identique est ignore (pas de doublon local)',
        () async {
      final service = KudosService(database: db, remoteSink: _FakeKudoSink());
      final id1 = await service.giveKudo(
          fromUidHash: 'hash-aaa', targetActivityId: 'act-1');
      final id2 = await service.giveKudo(
          fromUidHash: 'hash-aaa', targetActivityId: 'act-1');
      expect(id1, isNotNull);
      expect(id2, isNull); // ignore
      expect((await dao.pendingKudos()).length, 1);
    });

    test('re-sync ne pousse pas un doublon (meme docId)', () async {
      final sink = _FakeKudoSink();
      final service = KudosService(database: db, remoteSink: sink);
      await service.giveKudo(fromUidHash: 'hash-aaa', targetActivityId: 'act-1');
      await service.trySync();
      // 2e sync : plus rien de pending -> aucun nouveau push.
      await service.trySync();
      expect(sink.pushedDocIds.length, 1);
    });
  });

  group('KudosService — retry borne (X6)', () {
    test('echecs repetes plafonnent a maxAttempts, pas de boucle infinie',
        () async {
      final sink = _FakeKudoSink(fail: true);
      final service = KudosService(database: db, remoteSink: sink);
      await service.giveKudo(fromUidHash: 'hash-aaa', targetActivityId: 'act-1');

      // Boucle de sync repetee : doit s arreter au plafond.
      for (var i = 0; i < 10; i++) {
        await service.trySync();
      }
      // Au plus maxAttempts pushes, jamais plus (borne X6).
      expect(sink.pushedDocIds.length, lessThanOrEqualTo(KudosService.maxAttempts));
    });
  });

  group('KudosService — compteur', () {
    test('kudosCount lit le cache local', () async {
      final service = KudosService(database: db, remoteSink: _FakeKudoSink());
      await service.giveKudo(fromUidHash: 'hash-aaa', targetActivityId: 'act-1');
      expect(await service.kudosCount('act-1'), 1);
      expect(await service.kudosCount('autre'), 0);
    });
  });
}
