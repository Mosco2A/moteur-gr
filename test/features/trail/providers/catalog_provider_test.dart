import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';

import '../../../fixtures/horodatage_de_serveur.dart';
/// LA REVISION N DEVIENT L INSTANT REFERENCE + N JOURS (tache 610).
HorodatageServeur v(int n) => aJPlus(n);


/// Tests du CatalogNotifier et des modeles du catalogue.
void main() {
  group('CatalogEntry', () {
    test('constructeur initialise tous les champs', () {
      final entry = CatalogEntry(
        trailId: 'sentier-volcans',
        dataVersion: v(3),
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
        localStatus: TrailLocalStatusValues.notDownloaded,
      );
      expect(entry.trailId, 'sentier-volcans');
      expect(entry.dataVersion, v(3));
      expect(entry.fileSize, 524288);
      expect(entry.localStatus, TrailLocalStatusValues.notDownloaded);
      expect(entry.localVersion, isNull);
    });

    test('localVersion est renseigne pour un sentier telecharge', () {
      final entry = CatalogEntry(
        trailId: 'sentier-volcans',
        dataVersion: v(3),
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
        localStatus: TrailLocalStatusValues.downloaded,
        localVersion: v(3),
      );
      expect(entry.localVersion, v(3));
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
      final newEntry = CatalogEntry(
        trailId: 'test',
        dataVersion: v(1),
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
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('sentier-volcans'),
        dataVersion: Value(v(3)),
        hash: const Value('abc123'),
        filePath: const Value('trails/sentier-volcans/data.json'),
        fileSize: const Value(524288),
        status: const Value('active'),
        lastUpdated: const Value('2026-05-26T12:00:00Z'),
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

      final needsUpdate = await dao.needsUpdate('sentier-volcans');
      expect(needsUpdate, false);

      await db.close();
    });

    test('combine distant/local correctement — MAJ disponible', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = TrailManifestsDao(db);

      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('sentier-volcans'),
        dataVersion: Value(v(5)),
        hash: const Value('new_hash'),
        filePath: const Value('trails/sentier-volcans/data.json'),
        fileSize: const Value(600000),
        status: const Value('active'),
        lastUpdated: const Value('2026-05-26T12:00:00Z'),
        localVersion: Value(v(3)),
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
