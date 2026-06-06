import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';

/// Tests du DAO TrailManifests sur une base in-memory.
void main() {
  late AppDatabase db;
  late TrailManifestsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailManifestsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : cree un companion TrailManifests de test
  TrailManifestsCompanion makeManifest({
    required String trailId,
    int dataVersion = 1,
    String hash = 'test_hash_sha256',
    String filePath = 'trails/test/data.json',
    int fileSize = 1024,
    String status = 'active',
    String lastUpdated = '2026-05-26T12:00:00Z',
    int? localVersion,
  }) {
    return TrailManifestsCompanion(
      trailId: Value(trailId),
      dataVersion: Value(dataVersion),
      hash: Value(hash),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      status: Value(status),
      lastUpdated: Value(lastUpdated),
      localVersion: Value(localVersion),
    );
  }

  group('TrailManifestsDao CRUD', () {
    test('insertOrReplace puis getByTrailId retourne le bon manifest', () async {
      await dao.insertOrReplace(makeManifest(trailId: 'sentier-bleu'));

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result, isNotNull);
      expect(result!.trailId, 'sentier-bleu');
      expect(result.dataVersion, 1);
      expect(result.hash, 'test_hash_sha256');
      expect(result.status, 'active');
    });

    test('getAll retourne tous les manifests', () async {
      await dao.insertOrReplace(makeManifest(trailId: 'sentier-bleu'));
      await dao.insertOrReplace(makeManifest(trailId: 'mare_a_mare'));
      await dao.insertOrReplace(makeManifest(trailId: 'tmb'));

      final result = await dao.getAll();
      expect(result.length, 3);
    });

    test('getByTrailId retourne null si inexistant', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isNull);
    });

    test('insertOrReplace met a jour un manifest existant', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 1,
        hash: 'old_hash',
      ));
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 2,
        hash: 'new_hash',
      ));

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result!.dataVersion, 2);
      expect(result.hash, 'new_hash');
    });

    test('deleteByTrailId supprime le bon manifest', () async {
      await dao.insertOrReplace(makeManifest(trailId: 'sentier-bleu'));
      await dao.insertOrReplace(makeManifest(trailId: 'mare'));

      final deleted = await dao.deleteByTrailId('sentier-bleu');
      expect(deleted, 1);

      final remaining = await dao.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.trailId, 'mare');
    });

    test('deleteByTrailId retourne 0 si inexistant', () async {
      final deleted = await dao.deleteByTrailId('fantome');
      expect(deleted, 0);
    });

    test('localVersion nullable fonctionne', () async {
      await dao.insertOrReplace(makeManifest(trailId: 'sentier-bleu'));

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result!.localVersion, isNull);
    });

    test('localVersion se met a jour correctement', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 3,
        localVersion: 2,
      ));

      final result = await dao.getByTrailId('sentier-bleu');
      expect(result!.localVersion, 2);
      expect(result.dataVersion, 3);
    });
  });

  group('TrailManifestsDao needsUpdate', () {
    test('retourne true si le sentier n existe pas en local', () async {
      final needs = await dao.needsUpdate('inexistant');
      expect(needs, isTrue);
    });

    test('retourne true si localVersion est null', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 3,
        localVersion: null,
      ));

      final needs = await dao.needsUpdate('sentier-bleu');
      expect(needs, isTrue);
    });

    test('retourne true si dataVersion > localVersion', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 5,
        localVersion: 3,
      ));

      final needs = await dao.needsUpdate('sentier-bleu');
      expect(needs, isTrue);
    });

    test('retourne false si dataVersion == localVersion', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 3,
        localVersion: 3,
      ));

      final needs = await dao.needsUpdate('sentier-bleu');
      expect(needs, isFalse);
    });

    test('retourne false si dataVersion < localVersion', () async {
      await dao.insertOrReplace(makeManifest(
        trailId: 'sentier-bleu',
        dataVersion: 2,
        localVersion: 3,
      ));

      final needs = await dao.needsUpdate('sentier-bleu');
      expect(needs, isFalse);
    });
  });
}
