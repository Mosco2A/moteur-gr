import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/core/data/daos/segments_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/tracking/domain/segment_matching_service.dart';

/// Tests du SegmentMatchingService (F7A-02) — detection cote client.
void main() {
  // Polyline d'un segment ~ ligne droite courte (lat croissante), pas ~11m.
  final polyline = <LatLng>[
    const LatLng(42.0000, 9.0000),
    const LatLng(42.0001, 9.0000),
    const LatLng(42.0002, 9.0000),
    const LatLng(42.0003, 9.0000),
  ];

  group('isOnSegment — fonction pure', () {
    test('point sur la polyline detecte sous tolerance', () {
      // Point quasi sur la ligne (~5m a l ouest a cette latitude).
      const p = LatLng(42.00015, 9.00006);
      expect(SegmentMatchingService.isOnSegment(p, polyline, 25), isTrue);
    });

    test('point eloigne hors tolerance non detecte', () {
      // ~100m+ a l est.
      const p = LatLng(42.00015, 9.0020);
      expect(SegmentMatchingService.isOnSegment(p, polyline, 25), isFalse);
    });

    test('polyline vide -> false', () {
      expect(
        SegmentMatchingService.isOnSegment(
          const LatLng(42.0, 9.0),
          const <LatLng>[],
          25,
        ),
        isFalse,
      );
    });

    test('polyline a un point -> distance directe', () {
      const single = [LatLng(42.0, 9.0)];
      expect(
        SegmentMatchingService.isOnSegment(const LatLng(42.0, 9.0), single, 25),
        isTrue,
      );
      expect(
        SegmentMatchingService.isOnSegment(
            const LatLng(42.01, 9.0), single, 25),
        isFalse,
      );
    });
  });

  group('detectPassage — entree/sortie', () {
    List<TimedPoint> track(List<LatLng> pts, {int stepSeconds = 60}) {
      final start = DateTime.utc(2026, 6, 14, 10);
      return [
        for (var i = 0; i < pts.length; i++)
          TimedPoint(
            position: pts[i],
            time: start.add(Duration(seconds: i * stepSeconds)),
          ),
      ];
    }

    test('entree et sortie detectees, duree locale correcte', () {
      final userTrack = track([
        const LatLng(41.9990, 9.0000), // avant le segment
        const LatLng(42.0000, 9.0000), // entree (= debut polyline)
        const LatLng(42.0002, 9.0000), // milieu
        const LatLng(42.0003, 9.0000), // sortie (= fin polyline)
        const LatLng(42.0010, 9.0000), // apres
      ]);
      final detection = SegmentMatchingService.detectPassage(
        userTrack: userTrack,
        segmentPolyline: polyline,
      );
      expect(detection, isNotNull);
      expect(detection!.entryIndex, 1);
      expect(detection.exitIndex, 3);
      // 2 pas de 60s entre l index 1 et 3.
      expect(detection.durationSeconds, 120);
      expect(detection.startedAt, DateTime.utc(2026, 6, 14, 10, 1));
    });

    test('jamais entre sur le segment -> null', () {
      final userTrack = track([
        const LatLng(43.0, 9.5),
        const LatLng(43.1, 9.6),
      ]);
      expect(
        SegmentMatchingService.detectPassage(
          userTrack: userTrack,
          segmentPolyline: polyline,
        ),
        isNull,
      );
    });

    test('entre mais pas de sortie posterieure -> null', () {
      // L entree est detectee (debut polyline) mais aucun point ulterieur
      // n est proche de la FIN du segment (42.0003) : tous restent >25m.
      final userTrack = track([
        const LatLng(42.0000, 9.0000), // entree (= debut)
        const LatLng(42.00005, 9.0000), // ~5.5m du debut, ~28m de la fin
      ]);
      expect(
        SegmentMatchingService.detectPassage(
          userTrack: userTrack,
          segmentPolyline: polyline,
        ),
        isNull,
      );
    });
  });

  group('detectAndStore — persistance effort pending', () {
    late AppDatabase db;
    late SegmentMatchingService service;
    late SegmentsDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = SegmentsDao(db);
      service = SegmentMatchingService(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('stocke un effort pending avec UID hache', () async {
      final start = DateTime.utc(2026, 6, 14, 10);
      final userTrack = [
        TimedPoint(position: const LatLng(42.0000, 9.0000), time: start),
        TimedPoint(
            position: const LatLng(42.0003, 9.0000),
            time: start.add(const Duration(seconds: 90))),
      ];
      final id = await service.detectAndStore(
        segmentId: 'seg-1',
        userUidHash: 'hash-deadbeef',
        userTrack: userTrack,
        segmentPolyline: polyline,
      );
      expect(id, isNotNull);
      final pending = await dao.pendingEfforts();
      expect(pending.length, 1);
      expect(pending.first.segmentId, 'seg-1');
      expect(pending.first.userUidHash, 'hash-deadbeef');
      expect(pending.first.durationSeconds, 90);
      expect(pending.first.syncState, 'pending');
    });

    test('aucun passage -> aucun effort stocke', () async {
      final start = DateTime.utc(2026, 6, 14, 10);
      final userTrack = [
        TimedPoint(position: const LatLng(43.0, 9.5), time: start),
        TimedPoint(
            position: const LatLng(43.1, 9.6),
            time: start.add(const Duration(seconds: 60))),
      ];
      final id = await service.detectAndStore(
        segmentId: 'seg-1',
        userUidHash: 'hash-x',
        userTrack: userTrack,
        segmentPolyline: polyline,
      );
      expect(id, isNull);
      expect(await dao.pendingEfforts(), isEmpty);
    });
  });
}
