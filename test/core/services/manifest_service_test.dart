import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';

/// Fake ConnectivityMonitor pour les tests (toujours online).
class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatus.online;

  void setStatus(ConnectivityStatus status) => _status = status;

  @override
  Future<ConnectivityStatus> checkStatus() async => _status;
}

/// Tests du ManifestService (parseManifest, checkForUpdates).
void main() {
  late AppDatabase db;
  late TrailManifestsDao dao;
  late FakeConnectivityMonitor connectivity;
  late ManifestService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailManifestsDao(db);
    connectivity = FakeConnectivityMonitor();
    service = ManifestService(
      dao: dao,
      connectivityMonitor: connectivity,
    );
  });

  tearDown(() async {
    await db.close();
  });

  String makeManifestJson({
    int schemaVersion = 1,
    List<Map<String, dynamic>>? trails,
  }) {
    return jsonEncode({
      'schemaVersion': schemaVersion,
      'trails': trails ??
          [
            {
              'trailId': 'gr20',
              'dataVersion': 3,
              'hash': 'abc123',
              'filePath': 'trails/gr20/data.json',
              'fileSize': 524288,
              'status': 'active',
              'lastUpdated': '2026-05-26T12:00:00Z',
            },
            {
              'trailId': 'mare_a_mare',
              'dataVersion': 1,
              'hash': 'def456',
              'filePath': 'trails/mare_a_mare/data.json',
              'fileSize': 102400,
              'status': 'active',
              'lastUpdated': '2026-05-20T08:00:00Z',
            },
          ],
    });
  }

  group('parseManifest', () {
    test('parse un JSON valide correctement', () {
      final manifest = service.parseManifest(makeManifestJson());
      expect(manifest.schemaVersion, 1);
      expect(manifest.trails.length, 2);
      expect(manifest.trails[0].trailId, 'gr20');
      expect(manifest.trails[0].dataVersion, 3);
      expect(manifest.trails[1].trailId, 'mare_a_mare');
    });

    test('parse un manifeste avec liste vide', () {
      final manifest = service.parseManifest(makeManifestJson(trails: []));
      expect(manifest.schemaVersion, 1);
      expect(manifest.trails, isEmpty);
    });

    test('parse un manifeste avec schemaVersion different', () {
      final manifest = service.parseManifest(makeManifestJson(schemaVersion: 42));
      expect(manifest.schemaVersion, 42);
    });

    test('leve une exception sur JSON invalide', () {
      expect(
        () => service.parseManifest('not valid json'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('checkForUpdates', () {
    test('retourne tous les trails si base vide', () async {
      final manifest = service.parseManifest(makeManifestJson());
      final updates = await service.checkForUpdates(manifest);
      expect(updates.length, 2);
      expect(updates[0].trailId, 'gr20');
      expect(updates[1].trailId, 'mare_a_mare');
    });

    test('retourne uniquement les trails a mettre a jour', () async {
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('gr20'),
        dataVersion: const Value(3),
        hash: const Value('abc123'),
        filePath: const Value('trails/gr20/data.json'),
        fileSize: const Value(524288),
        status: const Value('active'),
        lastUpdated: const Value('2026-05-26T12:00:00Z'),
        localVersion: const Value(3),
      ));
      final manifest = service.parseManifest(makeManifestJson());
      final updates = await service.checkForUpdates(manifest);
      expect(updates.length, 1);
      expect(updates[0].trailId, 'mare_a_mare');
    });

    test('retourne vide si tout est a jour', () async {
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('gr20'),
        dataVersion: const Value(3),
        hash: const Value('abc123'),
        filePath: const Value('p'),
        fileSize: const Value(100),
        status: const Value('active'),
        lastUpdated: const Value('2026-01-01T00:00:00Z'),
        localVersion: const Value(3),
      ));
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('mare_a_mare'),
        dataVersion: const Value(1),
        hash: const Value('def456'),
        filePath: const Value('p'),
        fileSize: const Value(100),
        status: const Value('active'),
        lastUpdated: const Value('2026-01-01T00:00:00Z'),
        localVersion: const Value(1),
      ));
      final manifest = service.parseManifest(makeManifestJson());
      final updates = await service.checkForUpdates(manifest);
      expect(updates, isEmpty);
    });

    test('detecte une nouvelle version distante', () async {
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('gr20'),
        dataVersion: const Value(2),
        hash: const Value('old_hash'),
        filePath: const Value('p'),
        fileSize: const Value(100),
        status: const Value('active'),
        lastUpdated: const Value('2026-01-01T00:00:00Z'),
        localVersion: const Value(2),
      ));
      final manifest = service.parseManifest(makeManifestJson());
      final updates = await service.checkForUpdates(manifest);
      expect(updates.length, 2);
    });

    test('manifeste vide retourne vide', () async {
      final manifest = service.parseManifest(makeManifestJson(trails: []));
      final updates = await service.checkForUpdates(manifest);
      expect(updates, isEmpty);
    });
  });

  group('saveLocalManifest', () {
    test('sauvegarde une entree en base', () async {
      const entry = TrailManifestEntry(
        trailId: 'gr20',
        dataVersion: 3,
        hash: 'abc123',
        filePath: 'trails/gr20/data.json',
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
      );
      await service.saveLocalManifest(entry);
      final result = await dao.getByTrailId('gr20');
      expect(result, isNotNull);
      expect(result!.trailId, 'gr20');
      expect(result.dataVersion, 3);
      expect(result.hash, 'abc123');
      expect(result.localVersion, isNull);
    });

    test('met a jour une entree existante', () async {
      const v1 = TrailManifestEntry(
        trailId: 'gr20',
        dataVersion: 1,
        hash: 'hash_v1',
        filePath: 'trails/gr20/v1.json',
        fileSize: 100,
        status: 'active',
        lastUpdated: '2026-05-20T00:00:00Z',
      );
      const v2 = TrailManifestEntry(
        trailId: 'gr20',
        dataVersion: 2,
        hash: 'hash_v2',
        filePath: 'trails/gr20/v2.json',
        fileSize: 200,
        status: 'active',
        lastUpdated: '2026-05-26T00:00:00Z',
      );
      await service.saveLocalManifest(v1);
      await service.saveLocalManifest(v2);
      final result = await dao.getByTrailId('gr20');
      expect(result!.dataVersion, 2);
      expect(result.hash, 'hash_v2');
      expect(result.fileSize, 200);
    });
  });
}
