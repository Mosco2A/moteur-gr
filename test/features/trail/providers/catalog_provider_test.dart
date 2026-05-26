import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';

/// Tests du CatalogNotifier et des modeles du catalogue.
void main() {
  group('CatalogEntry', () {
    test('constructeur initialise tous les champs', () {
      const entry = CatalogEntry(
        trailId: 'gr20',
        dataVersion: 3,
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
        localStatus: TrailLocalStatus.notDownloaded,
      );
      expect(entry.trailId, 'gr20');
      expect(entry.dataVersion, 3);
      expect(entry.fileSize, 524288);
      expect(entry.localStatus, TrailLocalStatus.notDownloaded);
      expect(entry.localVersion, isNull);
    });

    test('localVersion est renseigne pour un sentier telecharge', () {
      const entry = CatalogEntry(
        trailId: 'gr20',
        dataVersion: 3,
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
        localStatus: TrailLocalStatus.downloaded,
        localVersion: 3,
      );
      expect(entry.localVersion, 3);
      expect(entry.localStatus, TrailLocalStatus.downloaded);
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
        localStatus: TrailLocalStatus.notDownloaded,
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
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('gr20'),
        dataVersion: const Value(3),
        hash: const Value('abc123'),
        filePath: const Value('trails/gr20/data.json'),
        fileSize: const Value(524288),
        status: const Value('active'),
        lastUpdated: const Value('2026-05-26T12:00:00Z'),
      ));

      final entry = await dao.getByTrailId('gr20');
      expect(entry, isNotNull);
      expect(entry!.localVersion, isNull);

      // Le statut devrait etre notDownloaded
      final needsUpdate = await dao.needsUpdate('gr20');
      expect(needsUpdate, true);

      await db.close();
    });

    test('combine distant/local correctement — a jour', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = TrailManifestsDao(db);

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

      final needsUpdate = await dao.needsUpdate('gr20');
      expect(needsUpdate, false);

      await db.close();
    });

    test('combine distant/local correctement — MAJ disponible', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = TrailManifestsDao(db);

      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('gr20'),
        dataVersion: const Value(5),
        hash: const Value('new_hash'),
        filePath: const Value('trails/gr20/data.json'),
        fileSize: const Value(600000),
        status: const Value('active'),
        lastUpdated: const Value('2026-05-26T12:00:00Z'),
        localVersion: const Value(3),
      ));

      final needsUpdate = await dao.needsUpdate('gr20');
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
