import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';

/// Tests finitions V8 F3 — DAO du trace GPS de session.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SessionTrackPointsDao (F3)', () {
    test('round-trip : points inseres puis relus dans l ordre', () async {
      final dao = db.sessionTrackPointsDao;
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        lat: 45.10,
        lng: 3.10,
        altitude: 900,
      );
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        lat: 45.11,
        lng: 3.12,
        altitude: 950,
      );

      final points = await dao.getByTrailId('sentier-bleu');
      expect(points.length, 2);
      expect(points.first.lat, 45.10);
      expect(points.last.lng, 3.12);
      expect(points.last.altitude, 950);
    });

    test('isolation par sentier', () async {
      final dao = db.sessionTrackPointsDao;
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        lat: 45.0,
        lng: 3.0,
        altitude: 100,
      );
      await dao.insertPoint(
        trailId: 'sentier-vert',
        lat: 44.0,
        lng: 2.0,
        altitude: 200,
      );

      expect((await dao.getByTrailId('sentier-bleu')).length, 1);
      expect((await dao.getByTrailId('sentier-vert')).length, 1);
    });

    test('clearTrail : nouvelle session remplace le trace precedent',
        () async {
      final dao = db.sessionTrackPointsDao;
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        lat: 45.0,
        lng: 3.0,
        altitude: 100,
      );
      await dao.clearTrail('sentier-bleu');

      expect(await dao.getByTrailId('sentier-bleu'), isEmpty);
    });
  });
}
