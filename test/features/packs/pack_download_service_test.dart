import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/packs/data/pack_download_service.dart';
import 'package:moteur_gr/features/packs/data/pack_storage.dart';
import 'package:moteur_gr/features/packs/domain/pack_download_progress.dart';
import 'package:moteur_gr/features/packs/domain/pack_manifest.dart';

/// Stockage en memoire (fake) — simule path_provider sans toucher au disque.
class InMemoryPackStorage implements PackStorage {
  final Map<String, Map<String, Uint8List>> _packs = {};

  @override
  Future<String> save(String packId, String ref, Uint8List bytes) async {
    (_packs[packId] ??= {})[ref] = bytes;
    return 'mem://$packId/$ref';
  }

  @override
  Future<bool> exists(String packId, String ref) async =>
      _packs[packId]?.containsKey(ref) ?? false;

  @override
  Future<Uint8List?> read(String packId, String ref) async =>
      _packs[packId]?[ref];

  @override
  Future<int> packSizeBytes(String packId) async =>
      (_packs[packId]?.values.fold<int>(0, (s, b) => s + b.length)) ?? 0;

  @override
  Future<bool> packExists(String packId) async =>
      (_packs[packId]?.isNotEmpty) ?? false;

  @override
  Future<int> deletePack(String packId) async {
    final freed = await packSizeBytes(packId);
    _packs.remove(packId);
    return freed;
  }
}

/// Source de fichiers (fake) — renvoie un contenu deterministe par ref et peut
/// simuler des echecs transitoires pour valider le retry borne (X6).
class FakePackFileSource implements PackFileSource {
  FakePackFileSource({
    this.failuresByRef = const {},
    this.alwaysFailRefs = const {},
  });

  /// Nombre d'echecs transitoires AVANT succes, par ref.
  final Map<String, int> failuresByRef;

  /// Refs qui echouent systematiquement (pour epuiser le retry).
  final Set<String> alwaysFailRefs;

  final Map<String, int> calls = {};

  /// Contenu deterministe servi pour une ref (utilise aussi pour le checksum).
  static Uint8List contentFor(String ref) =>
      Uint8List.fromList(utf8.encode('CONTENT::$ref'));

  @override
  Future<Uint8List> fetch(String ref) async {
    calls[ref] = (calls[ref] ?? 0) + 1;
    if (alwaysFailRefs.contains(ref)) {
      throw Exception('echec reseau permanent ($ref)');
    }
    final remaining = (failuresByRef[ref] ?? 0) - (calls[ref]! - 1);
    if (remaining > 0) {
      throw Exception('echec reseau transitoire ($ref)');
    }
    return contentFor(ref);
  }
}

/// Calcule le checksum attendu d'un manifeste (meme algo que le service).
String expectedChecksum(PackManifest manifest) {
  final builder = BytesBuilder(copy: false);
  for (final ref in manifest.allRefs) {
    builder.add(utf8.encode('$ref:'));
    builder.add(FakePackFileSource.contentFor(ref));
  }
  return 'sha256:${sha256.convert(builder.takeBytes())}';
}

void main() {
  PackManifest baseManifest({String? checksum}) => PackManifest(
        packId: 'mam_complet',
        mbtilesRefs: const ['m1.mbtiles', 'm2.mbtiles'],
        gpxRefs: const ['t.gpx'],
        poiRefs: const ['poi.json'],
        townGuideRefs: const ['guides.json'],
        waypointsSnapshotRef: 'wp.json',
        tailleMo: 340,
        checksum: checksum,
      );

  group('PackDownloadService — telechargement + progression', () {
    test('telecharge tous les fichiers et termine completed', () async {
      final storage = InMemoryPackStorage();
      final service = PackDownloadService(
        fileSource: FakePackFileSource(),
        storage: storage,
      );
      final manifest = baseManifest();

      final events =
          await service.downloadPack(manifest).toList();

      // Dernier evenement = completed, total atteint.
      expect(events.last.status, PackDownloadStatus.completed);
      expect(events.last.filesDone, manifest.allRefs.length);
      expect(events.last.filesTotal, manifest.allRefs.length);
      expect(events.last.fraction, 1.0);

      // Pipeline passe par pending -> downloading -> verifying -> completed.
      final statuses = events.map((e) => e.status).toSet();
      expect(statuses, contains(PackDownloadStatus.pending));
      expect(statuses, contains(PackDownloadStatus.downloading));
      expect(statuses, contains(PackDownloadStatus.verifying));

      // Tous les fichiers sont stockes (lisibles offline).
      expect(await service.isDownloaded('mam_complet'), isTrue);
      for (final ref in manifest.allRefs) {
        expect(await storage.exists('mam_complet', ref), isTrue);
      }
    });

    test('progression monotone croissante en nombre de fichiers', () async {
      final service = PackDownloadService(
        fileSource: FakePackFileSource(),
        storage: InMemoryPackStorage(),
      );
      final manifest = baseManifest();

      final events = await service.downloadPack(manifest).toList();
      final dones =
          events.map((e) => e.filesDone).toList();
      for (var i = 1; i < dones.length; i++) {
        expect(dones[i], greaterThanOrEqualTo(dones[i - 1]));
      }
    });

    test('reprise : un fichier deja present n est pas retelecharge', () async {
      final storage = InMemoryPackStorage();
      final manifest = baseManifest();
      // Pre-remplir un fichier comme s il avait deja ete telecharge.
      await storage.save('mam_complet', 'm1.mbtiles',
          FakePackFileSource.contentFor('m1.mbtiles'));
      final source = FakePackFileSource();
      final service =
          PackDownloadService(fileSource: source, storage: storage);

      await service.downloadPack(manifest).toList();

      // m1 deja present -> jamais fetch ; les autres -> 1 fetch chacun.
      expect(source.calls['m1.mbtiles'], isNull);
      expect(source.calls['t.gpx'], 1);
    });
  });

  group('PackDownloadService — integrite (OK / KO)', () {
    test('checksum correct -> completed', () async {
      final storage = InMemoryPackStorage();
      final manifest = baseManifest();
      final withChecksum =
          manifest.copyWith(checksum: expectedChecksum(manifest));
      final service = PackDownloadService(
        fileSource: FakePackFileSource(),
        storage: storage,
      );

      final events = await service.downloadPack(withChecksum).toList();
      expect(events.last.status, PackDownloadStatus.completed);
    });

    test('checksum errone -> error + purge du pack', () async {
      final storage = InMemoryPackStorage();
      final manifest = baseManifest(checksum: 'sha256:MAUVAIS');
      final service = PackDownloadService(
        fileSource: FakePackFileSource(),
        storage: storage,
      );

      final events = await service.downloadPack(manifest).toList();
      expect(events.last.status, PackDownloadStatus.error);
      expect(events.last.error, isNotNull);
      // Pack corrompu purge (espace libere, rien lisible offline).
      expect(await service.isDownloaded('mam_complet'), isFalse);
    });
  });

  group('PackDownloadService — retry borne (X6) + echec propre', () {
    test('echec transitoire (<5) -> succes apres retry', () async {
      final source = FakePackFileSource(failuresByRef: {'t.gpx': 2});
      final service = PackDownloadService(
        fileSource: source,
        storage: InMemoryPackStorage(),
      );

      final events = await service.downloadPack(baseManifest()).toList();
      expect(events.last.status, PackDownloadStatus.completed);
      // 2 echecs + 1 succes = 3 appels.
      expect(source.calls['t.gpx'], 3);
    });

    test('echec permanent -> error apres maxAttempts, sans boucle', () async {
      final source = FakePackFileSource(alwaysFailRefs: {'t.gpx'});
      final service = PackDownloadService(
        fileSource: source,
        storage: InMemoryPackStorage(),
      );

      final events = await service.downloadPack(baseManifest()).toList();
      expect(events.last.status, PackDownloadStatus.error);
      // Borne stricte : exactement maxAttempts tentatives, pas plus.
      expect(source.calls['t.gpx'], PackDownloadService.maxAttempts);
      expect(await service.isDownloaded('mam_complet'), isFalse);
    });
  });

  group('PackDownloadService — suppression (gestion espace)', () {
    test('deletePack libere l espace et rend le pack absent', () async {
      final storage = InMemoryPackStorage();
      final service =
          PackDownloadService(fileSource: FakePackFileSource(), storage: storage);
      final manifest = baseManifest();

      await service.downloadPack(manifest).toList();
      final sizeBefore = await service.downloadedSizeBytes('mam_complet');
      expect(sizeBefore, greaterThan(0));

      final freed = await service.deletePack('mam_complet');
      expect(freed, sizeBefore);
      expect(await service.isDownloaded('mam_complet'), isFalse);
      expect(await service.downloadedSizeBytes('mam_complet'), 0);
    });

    test('deletePack idempotent sur pack absent', () async {
      final service = PackDownloadService(
        fileSource: FakePackFileSource(),
        storage: InMemoryPackStorage(),
      );
      expect(await service.deletePack('inexistant'), 0);
    });
  });
}
