import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';

/// Tests du modele TrailManifest (parsing JSON, fromJson/toJson round-trip).
void main() {
  group('TrailManifestEntry', () {
    test('fromJson deserialise correctement', () {
      final json = {
        'trailId': 'gr20',
        'dataVersion': 3,
        'hash': 'abc123def456',
        'filePath': 'trails/gr20/data.json',
        'fileSize': 524288,
        'status': 'active',
        'lastUpdated': '2026-05-26T12:00:00Z',
      };

      final entry = TrailManifestEntry.fromJson(json);
      expect(entry.trailId, 'gr20');
      expect(entry.dataVersion, 3);
      expect(entry.hash, 'abc123def456');
      expect(entry.filePath, 'trails/gr20/data.json');
      expect(entry.fileSize, 524288);
      expect(entry.status, 'active');
      expect(entry.lastUpdated, '2026-05-26T12:00:00Z');
    });

    test('toJson serialise correctement', () {
      const entry = TrailManifestEntry(
        trailId: 'mare_a_mare',
        dataVersion: 1,
        hash: 'sha256hash',
        filePath: 'trails/mare_a_mare/data.json',
        fileSize: 102400,
        status: 'active',
        lastUpdated: '2026-05-20T08:00:00Z',
      );

      final json = entry.toJson();
      expect(json['trailId'], 'mare_a_mare');
      expect(json['dataVersion'], 1);
      expect(json['hash'], 'sha256hash');
      expect(json['fileSize'], 102400);
    });

    test('roundtrip fromJson -> toJson', () {
      final original = {
        'trailId': 'tmb',
        'dataVersion': 5,
        'hash': 'roundtrip_hash_sha256',
        'filePath': 'trails/tmb/data.json',
        'fileSize': 256000,
        'status': 'draft',
        'lastUpdated': '2026-05-25T14:30:00Z',
      };

      final entry = TrailManifestEntry.fromJson(original);
      final restored = entry.toJson();

      expect(restored['trailId'], original['trailId']);
      expect(restored['dataVersion'], original['dataVersion']);
      expect(restored['hash'], original['hash']);
      expect(restored['filePath'], original['filePath']);
      expect(restored['fileSize'], original['fileSize']);
      expect(restored['status'], original['status']);
      expect(restored['lastUpdated'], original['lastUpdated']);
    });

    test('equality fonctionne avec freezed', () {
      const a = TrailManifestEntry(
        trailId: 'gr20', dataVersion: 1, hash: 'h1',
        filePath: 'p', fileSize: 100, status: 'active',
        lastUpdated: '2026-01-01T00:00:00Z',
      );
      const b = TrailManifestEntry(
        trailId: 'gr20', dataVersion: 1, hash: 'h1',
        filePath: 'p', fileSize: 100, status: 'active',
        lastUpdated: '2026-01-01T00:00:00Z',
      );
      expect(a, equals(b));
    });

    test('copyWith modifie un champ', () {
      const entry = TrailManifestEntry(
        trailId: 'gr20', dataVersion: 1, hash: 'h1',
        filePath: 'p', fileSize: 100, status: 'active',
        lastUpdated: '2026-01-01T00:00:00Z',
      );
      final modified = entry.copyWith(dataVersion: 2);
      expect(modified.dataVersion, 2);
      expect(modified.trailId, 'gr20');
    });
  });

  group('TrailManifest', () {
    test('fromJson deserialise le manifeste complet', () {
      final json = {
        'schemaVersion': 1,
        'trails': [
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
      };

      final manifest = TrailManifest.fromJson(json);
      expect(manifest.schemaVersion, 1);
      expect(manifest.trails.length, 2);
      expect(manifest.trails[0].trailId, 'gr20');
      expect(manifest.trails[1].trailId, 'mare_a_mare');
    });

    test('fromJson avec liste vide', () {
      final json = {
        'schemaVersion': 1,
        'trails': <Map<String, dynamic>>[],
      };

      final manifest = TrailManifest.fromJson(json);
      expect(manifest.schemaVersion, 1);
      expect(manifest.trails, isEmpty);
    });

    test('toJson serialise le manifeste complet', () {
      const manifest = TrailManifest(
        schemaVersion: 2,
        trails: [
          TrailManifestEntry(
            trailId: 'gr20',
            dataVersion: 3,
            hash: 'abc',
            filePath: 'p',
            fileSize: 100,
            status: 'active',
            lastUpdated: '2026-01-01T00:00:00Z',
          ),
        ],
      );

      final json = manifest.toJson();
      expect(json['schemaVersion'], 2);
      expect((json['trails'] as List).length, 1);
    });

    test('roundtrip JSON string -> parse -> toJson', () {
      final jsonString = jsonEncode({
        'schemaVersion': 1,
        'trails': [
          {
            'trailId': 'gr20',
            'dataVersion': 4,
            'hash': 'sha256_full',
            'filePath': 'trails/gr20/v4.json',
            'fileSize': 600000,
            'status': 'active',
            'lastUpdated': '2026-05-26T18:00:00Z',
          },
        ],
      });

      final parsed = TrailManifest.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
      final reEncoded = jsonEncode(parsed.toJson());
      final reParsed = TrailManifest.fromJson(
        jsonDecode(reEncoded) as Map<String, dynamic>,
      );

      expect(reParsed.schemaVersion, 1);
      expect(reParsed.trails.first.trailId, 'gr20');
      expect(reParsed.trails.first.dataVersion, 4);
      expect(reParsed.trails.first.hash, 'sha256_full');
    });
  });
}
