import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';

import '../../fixtures/horodatage_de_serveur.dart';

/// LA REVISION N DEVIENT L INSTANT « REFERENCE + N JOURS » (tache 610).
///
/// Les assertions ne sont pas affaiblies : `v(1) < v(2)` dit exactement ce que
/// `1 < 2` disait. Sur le fil, l instant s ecrit en ISO 8601 UTC (`v(n).iso8601`),
/// ce qu un horodatage natif de base de donnees donne en JSON.
HorodatageServeur v(int n) => aJPlus(n);

/// Tests du modele TrailManifest (parsing JSON, fromJson/toJson round-trip).
void main() {
  group('TrailManifestEntry', () {
    test('fromJson deserialise correctement', () {
      final json = {
        'trailId': 'sentier-bleu',
        'dataVersion': v(3).iso8601,
        'hash': 'abc123def456',
        'filePath': 'trails/sentier-bleu/data.json',
        'fileSize': 524288,
        'status': 'active',
        'lastUpdated': '2026-05-26T12:00:00Z',
      };

      final entry = TrailManifestEntry.fromJson(json);
      expect(entry.trailId, 'sentier-bleu');
      expect(entry.dataVersion, v(3));
      expect(entry.hash, 'abc123def456');
      expect(entry.filePath, 'trails/sentier-bleu/data.json');
      expect(entry.fileSize, 524288);
      expect(entry.status, 'active');
      expect(entry.lastUpdated, '2026-05-26T12:00:00Z');
    });

    test('toJson serialise correctement', () {
      final entry = TrailManifestEntry(
        trailId: 'mare_a_mare',
        dataVersion: v(1),
        hash: 'sha256hash',
        filePath: 'trails/mare_a_mare/data.json',
        fileSize: 102400,
        status: 'active',
        lastUpdated: '2026-05-20T08:00:00Z',
      );

      final json = entry.toJson();
      expect(json['trailId'], 'mare_a_mare');
      expect(json['dataVersion'], v(1).iso8601);
      expect(json['hash'], 'sha256hash');
      expect(json['fileSize'], 102400);
    });

    test('roundtrip fromJson -> toJson', () {
      final original = {
        'trailId': 'tmb',
        'dataVersion': v(5).iso8601,
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
      final a = TrailManifestEntry(
        trailId: 'sentier-bleu',
        dataVersion: v(1),
        hash: 'h1',
        filePath: 'p',
        fileSize: 100,
        status: 'active',
        lastUpdated: '2026-01-01T00:00:00Z',
      );
      final b = TrailManifestEntry(
        trailId: 'sentier-bleu',
        dataVersion: v(1),
        hash: 'h1',
        filePath: 'p',
        fileSize: 100,
        status: 'active',
        lastUpdated: '2026-01-01T00:00:00Z',
      );
      expect(a, equals(b));
    });

    test('copyWith modifie un champ', () {
      final entry = TrailManifestEntry(
        trailId: 'sentier-bleu',
        dataVersion: v(1),
        hash: 'h1',
        filePath: 'p',
        fileSize: 100,
        status: 'active',
        lastUpdated: '2026-01-01T00:00:00Z',
      );
      final modified = entry.copyWith(dataVersion: v(2));
      expect(modified.dataVersion, v(2));
      expect(modified.trailId, 'sentier-bleu');
    });
  });

  group('TrailManifest', () {
    test('fromJson deserialise le manifeste complet', () {
      final json = {
        'schemaVersion': 1,
        'trails': [
          {
            'trailId': 'sentier-bleu',
            'dataVersion': v(3).iso8601,
            'hash': 'abc123',
            'filePath': 'trails/sentier-bleu/data.json',
            'fileSize': 524288,
            'status': 'active',
            'lastUpdated': '2026-05-26T12:00:00Z',
          },
          {
            'trailId': 'mare_a_mare',
            'dataVersion': v(1).iso8601,
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
      expect(manifest.trails[0].trailId, 'sentier-bleu');
      expect(manifest.trails[1].trailId, 'mare_a_mare');
    });

    test('fromJson avec liste vide', () {
      final json = {'schemaVersion': 1, 'trails': <Map<String, dynamic>>[]};

      final manifest = TrailManifest.fromJson(json);
      expect(manifest.schemaVersion, 1);
      expect(manifest.trails, isEmpty);
    });

    test('toJson serialise le manifeste complet', () {
      final manifest = TrailManifest(
        schemaVersion: 2,
        trails: [
          TrailManifestEntry(
            trailId: 'sentier-bleu',
            dataVersion: v(3),
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
            'trailId': 'sentier-bleu',
            'dataVersion': v(4).iso8601,
            'hash': 'sha256_full',
            'filePath': 'trails/sentier-bleu/v4.json',
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
      expect(reParsed.trails.first.trailId, 'sentier-bleu');
      expect(reParsed.trails.first.dataVersion, v(4));
      expect(reParsed.trails.first.hash, 'sha256_full');
    });
  });
}
