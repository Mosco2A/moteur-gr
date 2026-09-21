import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gpx/gpx.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/after/data/gpx_export_service.dart';

/// CORRECTIF L5-4 — EXPORT GPX REEL.
///
/// StepWays ne savait que LIRE du GPX ; aucun ecrivain n'existait et
/// l'export etait un TODO. Ces tests verrouillent le contenu produit, et
/// surtout le DECOUPAGE PAR JOUR — sans lui, l'outil de cartographie
/// tracerait une ligne droite a travers la vallee entre le dernier point du
/// soir et le premier du lendemain.
void main() {
  SessionTrackPoint point({
    required DateTime at,
    required double lat,
    int? dayIndex,
    double altitude = 900,
  }) {
    return SessionTrackPoint(
      id: 0,
      trailId: 'sentier-bleu',
      dayIndex: dayIndex,
      lat: lat,
      lng: 9.0,
      altitude: altitude,
      recordedAt: at,
    );
  }

  group('L5-4 — contenu GPX', () {
    test('un segment PAR JOUR de marche', () {
      final base = DateTime.utc(2026, 6, 10, 8);
      final xml = GpxExportService.buildGpx(
        trackName: 'Fra li Monti',
        generatedAt: base,
        points: [
          point(at: base, lat: 42.00, dayIndex: 1),
          point(at: base.add(const Duration(hours: 2)), lat: 42.01, dayIndex: 1),
          point(at: base.add(const Duration(days: 1)), lat: 43.00, dayIndex: 2),
          point(at: base.add(const Duration(days: 1, hours: 2)), lat: 43.01, dayIndex: 2),
        ],
      );

      final parsed = GpxReader().fromString(xml);
      expect(parsed.trks.length, 1);
      // LE point du correctif : deux jours = deux segments, pas un seul.
      expect(parsed.trks.single.trksegs.length, 2);
      expect(parsed.trks.single.trksegs.first.trkpts.length, 2);
      expect(parsed.trks.single.trksegs.last.trkpts.first.lat, 43.00);
    });

    test('jours dans l ordre de marche, meme inseres en desordre', () {
      final base = DateTime.utc(2026, 6, 10, 8);
      final xml = GpxExportService.buildGpx(
        trackName: 'Fra li Monti',
        generatedAt: base,
        points: [
          point(at: base.add(const Duration(days: 2)), lat: 44.0, dayIndex: 3),
          point(at: base, lat: 42.0, dayIndex: 1),
          point(at: base.add(const Duration(days: 1)), lat: 43.0, dayIndex: 2),
        ],
      );

      final segs = GpxReader().fromString(xml).trks.single.trksegs;
      expect(segs.map((s) => s.trkpts.single.lat).toList(), [42.0, 43.0, 44.0]);
    });

    test('points sans jour connu : un segment a part, en tete', () {
      final base = DateTime.utc(2026, 6, 10, 8);
      final xml = GpxExportService.buildGpx(
        trackName: 'Fra li Monti',
        generatedAt: base,
        points: [
          point(at: base, lat: 42.0, dayIndex: 1),
          // Trace anterieure a la migration v26 : dayIndex nul.
          point(at: base.subtract(const Duration(days: 30)), lat: 41.0),
        ],
      );

      final segs = GpxReader().fromString(xml).trks.single.trksegs;
      expect(segs.length, 2);
      expect(segs.first.trkpts.single.lat, 41.0);
    });

    test('altitude et horodatage sont portes par chaque point', () {
      final at = DateTime.utc(2026, 6, 10, 8, 30);
      final xml = GpxExportService.buildGpx(
        trackName: 'Fra li Monti',
        generatedAt: at,
        points: [
          point(at: at, lat: 42.0, dayIndex: 1, altitude: 1550),
          point(at: at.add(const Duration(hours: 1)), lat: 42.01, dayIndex: 1),
        ],
      );

      final first = GpxReader().fromString(xml).trks.single.trksegs.single.trkpts.first;
      expect(first.ele, 1550);
      expect(first.time?.toUtc(), at);
      expect(GpxReader().fromString(xml).metadata?.name, 'Fra li Monti');
    });
  });

  group('L5-4 — ecriture du fichier', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('gpx_export_test_');
    });

    tearDown(() {
      if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
    });

    test('le fichier existe et se relit comme un GPX valide', () async {
      final at = DateTime.utc(2026, 6, 10, 8);
      final content = GpxExportService.buildGpx(
        trackName: 'Fra li Monti',
        generatedAt: at,
        points: [
          point(at: at, lat: 42.0, dayIndex: 1),
          point(at: at.add(const Duration(hours: 1)), lat: 42.01, dayIndex: 1),
        ],
      );

      final file = await GpxExportService.saveGpx(
        content: content,
        trailId: 'mare-a-mare-centre',
        at: DateTime(2026, 6, 16, 12, 0, 0),
        directory: sandbox,
      );

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.gpx'), isTrue);
      final reread = GpxReader().fromString(file.readAsStringSync());
      expect(reread.trks.single.trksegs.single.trkpts.length, 2);
    });

    test('nom de fichier horodate et nettoye', () {
      final name = GpxExportService.gpxFileName(
        'Mare a Mare/Centre',
        at: DateTime(2026, 6, 16, 12, 0, 5),
      );
      expect(name, 'trace-mare-a-mare-centre-20260616-120005.gpx');
    });
  });
}
