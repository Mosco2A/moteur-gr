import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
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

    test('clearTrail : effacement VOULU du sentier', () async {
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

  // SOCLE L3-1 — granularite session / jour / etape et non-effacement.
  group('SessionTrackPointsDao — granularite L3-1', () {
    test('dayIndexFor : jour 1 le jour du depart, en jours calendaires', () {
      final start = DateTime(2026, 6, 10, 17, 30);
      expect(
        SessionTrackPointsDao.dayIndexFor(start, DateTime(2026, 6, 10, 23, 59)),
        1,
      );
      // 9 h le lendemain : moins de 24 h ecoulees, mais bien le jour 2.
      expect(
        SessionTrackPointsDao.dayIndexFor(start, DateTime(2026, 6, 11, 9)),
        2,
      );
      expect(
        SessionTrackPointsDao.dayIndexFor(start, DateTime(2026, 6, 14, 8)),
        5,
      );
      // Point antidate : jamais de jour 0 ni negatif.
      expect(
        SessionTrackPointsDao.dayIndexFor(start, DateTime(2026, 6, 9, 8)),
        1,
      );
    });

    test('deux randonnees successives cohabitent (non-effacement)', () async {
      final dao = db.sessionTrackPointsDao;
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        sessionId: 'session-2025',
        dayIndex: 1,
        lat: 45.0,
        lng: 3.0,
        altitude: 100,
      );
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        sessionId: 'session-2026',
        dayIndex: 1,
        lat: 45.5,
        lng: 3.5,
        altitude: 200,
      );

      expect((await dao.getByTrailId('sentier-bleu')).length, 2);
      expect((await dao.getBySessionId('session-2025')).length, 1);
      expect((await dao.getBySessionId('session-2026')).single.lat, 45.5);
    });

    test('le jour 3 reste lisible apres avoir marche le jour 5', () async {
      final dao = db.sessionTrackPointsDao;
      for (final day in [3, 3, 4, 5]) {
        await dao.insertPoint(
          trailId: 'sentier-bleu',
          sessionId: 'session-a',
          dayIndex: day,
          lat: 45.0 + day,
          lng: 3.0,
          altitude: 100,
        );
      }

      final day3 = await dao.getByDayIndex('sentier-bleu', 3);
      expect(day3.length, 2);
      expect(day3.first.lat, 48.0);
      expect(await dao.getRecordedDayIndexes('sentier-bleu'), [3, 4, 5]);
    });

    test('filtrage par etape', () async {
      final dao = db.sessionTrackPointsDao;
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        stageId: 'etape-2',
        lat: 45.0,
        lng: 3.0,
        altitude: 100,
      );
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        stageId: 'etape-3',
        lat: 46.0,
        lng: 3.0,
        altitude: 100,
      );

      expect(
        (await dao.getByStageId('sentier-bleu', 'etape-2')).single.lat,
        45.0,
      );
    });

    test('filtrage par journee calendaire (minuit a minuit)', () async {
      final dao = db.sessionTrackPointsDao;
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        lat: 45.0,
        lng: 3.0,
        altitude: 100,
        recordedAt: DateTime(2026, 6, 10, 23, 59),
      );
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        lat: 46.0,
        lng: 3.0,
        altitude: 100,
        recordedAt: DateTime(2026, 6, 11, 0, 1),
      );

      final d10 = await dao.getByCalendarDay('sentier-bleu', DateTime(2026, 6, 10));
      expect(d10.single.lat, 45.0);
      final d11 = await dao.getByCalendarDay('sentier-bleu', DateTime(2026, 6, 11));
      expect(d11.single.lat, 46.0);
    });

    test('points legacy (colonnes nulles) restent lisibles', () async {
      final dao = db.sessionTrackPointsDao;
      await dao.insertPoint(
        trailId: 'sentier-bleu',
        lat: 45.0,
        lng: 3.0,
        altitude: 100,
      );

      expect((await dao.getByTrailId('sentier-bleu')).single.sessionId, isNull);
      expect(await dao.getRecordedDayIndexes('sentier-bleu'), isEmpty);
    });
  });
}
