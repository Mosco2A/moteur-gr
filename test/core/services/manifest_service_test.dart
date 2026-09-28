import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';

import '../../fixtures/horodatage_de_serveur.dart';

/// LA REVISION N DEVIENT L INSTANT « REFERENCE + N JOURS » (tache 610).
HorodatageServeur v(int n) => aJPlus(n);

/// Fake ConnectivityMonitor pour les tests (toujours online).
class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;

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
              'trailId': 'sentier-volcans',
              'dataVersion': v(3).iso8601,
              'hash': 'abc123',
              'filePath': 'trails/sentier-volcans/data.json',
              'fileSize': 524288,
              'status': 'active',
              'lastUpdated': '2026-05-26T12:00:00Z',
            },
            {
              'trailId': 'sentier-cantal',
              'dataVersion': v(1).iso8601,
              'hash': 'def456',
              'filePath': 'trails/sentier-cantal/data.json',
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
      expect(manifest.trails[0].trailId, 'sentier-volcans');
      expect(manifest.trails[0].dataVersion, v(3));
      expect(manifest.trails[1].trailId, 'sentier-cantal');
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
      expect(updates[0].trailId, 'sentier-volcans');
      expect(updates[1].trailId, 'sentier-cantal');
    });

    test('retourne uniquement les trails a mettre a jour', () async {
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('sentier-volcans'),
        dataVersion: Value(v(3)),
        hash: const Value('abc123'),
        filePath: const Value('trails/sentier-volcans/data.json'),
        fileSize: const Value(524288),
        status: const Value('active'),
        lastUpdated: const Value('2026-05-26T12:00:00Z'),
        localVersion: Value(v(3)),
      ));
      final manifest = service.parseManifest(makeManifestJson());
      final updates = await service.checkForUpdates(manifest);
      expect(updates.length, 1);
      expect(updates[0].trailId, 'sentier-cantal');
    });

    test('retourne vide si tout est a jour', () async {
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('sentier-volcans'),
        dataVersion: Value(v(3)),
        hash: const Value('abc123'),
        filePath: const Value('p'),
        fileSize: const Value(100),
        status: const Value('active'),
        lastUpdated: const Value('2026-01-01T00:00:00Z'),
        localVersion: Value(v(3)),
      ));
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('sentier-cantal'),
        dataVersion: Value(v(1)),
        hash: const Value('def456'),
        filePath: const Value('p'),
        fileSize: const Value(100),
        status: const Value('active'),
        lastUpdated: const Value('2026-01-01T00:00:00Z'),
        localVersion: Value(v(1)),
      ));
      final manifest = service.parseManifest(makeManifestJson());
      final updates = await service.checkForUpdates(manifest);
      expect(updates, isEmpty);
    });

    test('detecte une nouvelle version distante', () async {
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('sentier-volcans'),
        dataVersion: Value(v(2)),
        hash: const Value('old_hash'),
        filePath: const Value('p'),
        fileSize: const Value(100),
        status: const Value('active'),
        lastUpdated: const Value('2026-01-01T00:00:00Z'),
        localVersion: Value(v(2)),
      ));
      final manifest = service.parseManifest(makeManifestJson());
      final updates = await service.checkForUpdates(manifest);
      // needsUpdate compare dataVersion vs localVersion stockes (lib/ fait foi).
      // sentier-volcans est a jour (2 == 2) ; seul sentier-cantal (absent) remonte.
      expect(updates.length, 1);
      expect(updates[0].trailId, 'sentier-cantal');
    });

    test('manifeste vide retourne vide', () async {
      final manifest = service.parseManifest(makeManifestJson(trails: []));
      final updates = await service.checkForUpdates(manifest);
      expect(updates, isEmpty);
    });
  });

  group('saveLocalManifest', () {
    test('sauvegarde une entree en base', () async {
      final entry = TrailManifestEntry(
        trailId: 'sentier-volcans',
        dataVersion: v(3),
        hash: 'abc123',
        filePath: 'trails/sentier-volcans/data.json',
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
      );
      await service.saveLocalManifest(entry);
      final result = await dao.getByTrailId('sentier-volcans');
      expect(result, isNotNull);
      expect(result!.trailId, 'sentier-volcans');
      expect(result.dataVersion, v(3));
      expect(result.hash, 'abc123');
      expect(result.localVersion, isNull);
    });

    test('met a jour une entree existante', () async {
      final v1 = TrailManifestEntry(
        trailId: 'sentier-volcans',
        dataVersion: v(1),
        hash: 'hash_v1',
        filePath: 'trails/sentier-volcans/v1.json',
        fileSize: 100,
        status: 'active',
        lastUpdated: '2026-05-20T00:00:00Z',
      );
      final v2 = TrailManifestEntry(
        trailId: 'sentier-volcans',
        dataVersion: v(2),
        hash: 'hash_v2',
        filePath: 'trails/sentier-volcans/v2.json',
        fileSize: 200,
        status: 'active',
        lastUpdated: '2026-05-26T00:00:00Z',
      );
      await service.saveLocalManifest(v1);
      await service.saveLocalManifest(v2);
      final result = await dao.getByTrailId('sentier-volcans');
      expect(result!.dataVersion, v(2));
      expect(result.hash, 'hash_v2');
      expect(result.fileSize, 200);
    });
  });
}
