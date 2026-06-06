import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';

/// Tests du CatalogNotifier et des modeles du catalogue.
void main() {
  group('CatalogEntry', () {
    test('constructeur initialise tous les champs', () {
      const entry = CatalogEntry(
        trailId: 'sentier-volcans',
        dataVersion: 3,
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
        localStatus: TrailLocalStatusValues.notDownloaded,
      );
      expect(entry.trailId, 'sentier-volcans');
      expect(entry.dataVersion, 3);
      expect(entry.fileSize, 524288);
      expect(entry.localStatus, TrailLocalStatusValues.notDownloaded);
      expect(entry.localVersion, isNull);
    });

    test('localVersion est renseigne pour un sentier telecharge', () {
      const entry = CatalogEntry(
        trailId: 'sentier-volcans',
        dataVersion: 3,
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
        localStatus: TrailLocalStatusValues.downloaded,
        localVersion: 3,
      );
      expect(entry.localVersion, 3);
      expect(entry.localStatus, TrailLocalStatusValues.downloaded);
    });
  });

  group('CatalogState', () {
    test('copyWith preserve les valeurs non modifiees', () {
      const state = CatalogState(entries: [], isOffline: false);
      final updated = state.copyWith(isOffline: true);
      expect(updated.isOffline, true);
      expect(updated.entries, isEmpty);
    });

    test('copyWith remplace entries', () {
      const state = CatalogState(entries: [], isOffline: false);
      const newEntry = CatalogEntry(
        trailId: 'test',
        dataVersion: 1,
        fileSize: 100,
        status: 'active',
        lastUpdated: '2026-01-01T00:00:00Z',
        localStatus: TrailLocalStatusValues.notDownloaded,
      );
      final updated = state.copyWith(entries: [newEntry]);
      expect(updated.entries.length, 1);
      expect(updated.entries[0].trailId, 'test');
    });
  });

  group('TrailLocalStatus', () {
    test('combine distant/local correctement — jamais telecharge', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = TrailManifestsDao(db);

      // Inserer un manifeste distant sans version locale
      await dao.insertOrReplace(const TrailManifestsCompanion(
        trailId: Value('sentier-volcans'),
        dataVersion: Value(3),
        hash: Value('abc123'),
        filePath: Value('trails/sentier-volcans/data.json'),
        fileSize: Value(524288),
        status: Value('active'),
        lastUpdated: Value('2026-05-26T12:00:00Z'),
      ));

      final entry = await dao.getByTrailId('sentier-volcans');
      expect(entry, isNotNull);
      expect(entry!.localVersion, isNull);

      // Le statut devrait etre notDownloaded
      final needsUpdate = await dao.needsUpdate('sentier-volcans');
      expect(needsUpdate, true);

      await db.close();
    });

    test('combine distant/local correctement — a jour', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = TrailManifestsDao(db);

      await dao.insertOrReplace(const TrailManifestsCompanion(
        trailId: Value('sentier-volcans'),
        dataVersion: Value(3),
        hash: Value('abc123'),
        filePath: Value('trails/sentier-volcans/data.json'),
        fileSize: Value(524288),
        status: Value('active'),
        lastUpdated: Value('2026-05-26T12:00:00Z'),
        localVersion: Value(3),
      ));

      final needsUpdate = await dao.needsUpdate('sentier-volcans');
      expect(needsUpdate, false);

      await db.close();
    });

    test('combine distant/local correctement — MAJ disponible', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = TrailManifestsDao(db);

      await dao.insertOrReplace(const TrailManifestsCompanion(
        trailId: Value('sentier-volcans'),
        dataVersion: Value(5),
        hash: Value('new_hash'),
        filePath: Value('trails/sentier-volcans/data.json'),
        fileSize: Value(600000),
        status: Value('active'),
        lastUpdated: Value('2026-05-26T12:00:00Z'),
        localVersion: Value(3),
      ));

      final needsUpdate = await dao.needsUpdate('sentier-volcans');
      expect(needsUpdate, true);

      await db.close();
    });
  });

  group('downloadProgressProvider', () {
    test('etat initial est null', () async {
      final container = ProviderContainer();
      final progress =
          await container.read(downloadProgressProvider('test').future);
      expect(progress, isNull);
      container.dispose();
    });
  });
}
