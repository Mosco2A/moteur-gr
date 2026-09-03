import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trek_sessions_dao.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';

/// PARITE GR20, LOT 2 (2.C, #99433) — persistance REELLE de la session.
///
/// Prouve que la memoire du finisher (`completedStages` /
/// `parcoursFullyWalked`) est ecrite en local Drift et SURVIT a un
/// « redemarrage » (relecture par un DAO frais sur la meme base). Au LOT 1,
/// `onSessionPersist` etait vide : ces champs etaient perdus.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  TrekSession session({
    String id = 'sess-1',
    String status = 'active',
    List<String> completed = const [],
    bool fullyWalked = false,
    DateTime? finishedAt,
  }) {
    return TrekSession(
      id: id,
      trailId: 'mare-a-mare-centre',
      startedAt: DateTime.utc(2026, 6, 15, 8),
      finishedAt: finishedAt,
      status: status,
      completedStages: completed,
      parcoursFullyWalked: fullyWalked,
    );
  }

  group('TrekSessionsDao (2.C persistance)', () {
    test('round-trip : session persistee relue a l identique', () async {
      final dao = db.trekSessionsDao;
      final s = session(
        completed: const ['s1', 's2', 's3'],
        fullyWalked: true,
        status: 'completed',
        finishedAt: DateTime.utc(2026, 6, 17, 17),
      );

      await dao.upsertSession(s);
      final restored = await dao.getById('sess-1');

      expect(restored, isNotNull);
      expect(restored!.id, 'sess-1');
      expect(restored.trailId, 'mare-a-mare-centre');
      expect(restored.status, 'completed');
      expect(restored.completedStages, ['s1', 's2', 's3']);
      expect(restored.parcoursFullyWalked, isTrue);
      // Drift relit les DateTime en heure LOCALE : on compare l'INSTANT (meme
      // moment absolu), pas le fuseau.
      expect(
        restored.finishedAt!.isAtSameMomentAs(DateTime.utc(2026, 6, 17, 17)),
        isTrue,
      );
      expect(
        restored.startedAt.isAtSameMomentAs(DateTime.utc(2026, 6, 15, 8)),
        isTrue,
      );
    });

    test('SURVIE au redemarrage : DAO frais relit la session persistee',
        () async {
      // Ecriture avec un premier DAO.
      await db.trekSessionsDao.upsertSession(
        session(completed: const ['s1', 's2'], status: 'active'),
      );

      // « Redemarrage » simule : nouvelle instance de DAO sur la MEME base
      // (les donnees vivent en base, pas dans l'etat en memoire du manager).
      final freshDao = TrekSessionsDao(db);
      final restored = await freshDao.getById('sess-1');

      expect(restored, isNotNull);
      expect(restored!.completedStages, ['s1', 's2'],
          reason: 'Les etapes marchees survivent au redemarrage.');
    });

    test('upsert idempotent : meme id -> derniere ecriture gagnante', () async {
      final dao = db.trekSessionsDao;
      await dao.upsertSession(session(completed: const ['s1']));
      // Une etape de plus marchee + finisher ferme -> reecriture.
      await dao.upsertSession(
        session(completed: const ['s1', 's2', 's3'], fullyWalked: true),
      );

      final restored = await dao.getById('sess-1');
      expect(restored!.completedStages, ['s1', 's2', 's3']);
      expect(restored.parcoursFullyWalked, isTrue);
      // Toujours une seule ligne pour cet id.
      final actives = await dao.findActiveSessions();
      expect(actives.where((x) => x.id == 'sess-1').length, 1);
    });

    test('findActiveSessions ne renvoie que les sessions actives', () async {
      final dao = db.trekSessionsDao;
      await dao.upsertSession(session(id: 'a', status: 'active'));
      await dao.upsertSession(session(id: 'b', status: 'completed'));
      await dao.upsertSession(session(id: 'c', status: 'active'));

      final actives = await dao.findActiveSessions();
      expect(actives.map((s) => s.id).toSet(), {'a', 'c'});
    });

    test('updateStatus / deleteSession', () async {
      final dao = db.trekSessionsDao;
      await dao.upsertSession(session(id: 'a', status: 'active'));

      await dao.updateStatus('a', 'abandoned');
      expect((await dao.getById('a'))!.status, 'abandoned');

      await dao.deleteSession('a');
      expect(await dao.getById('a'), isNull);
    });

    test('completedStages JSON corrompu -> liste vide (pas de faux finisher)',
        () async {
      // Insertion directe d'une valeur JSON invalide dans la colonne.
      await db.customStatement(
        "INSERT INTO trek_sessions "
        "(id, trail_id, started_at, status, completed_stages_json, "
        "parcours_fully_walked) VALUES "
        "('bad', 'x', 0, 'active', 'not-json', 0)",
      );

      final restored = await db.trekSessionsDao.getById('bad');
      expect(restored, isNotNull);
      expect(restored!.completedStages, isEmpty,
          reason: 'Une valeur non-JSON retombe sur une liste vide.');
    });
  });
}
