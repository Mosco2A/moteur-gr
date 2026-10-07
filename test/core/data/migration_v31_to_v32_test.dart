import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/database.dart';

/// Tests de MIGRATION Drift v31 -> v32 (lot 671-03, le recalage sur le trace).
///
/// La v32 est STRICTEMENT ADDITIVE : UNE colonne texte NULLABLE sur
/// session_track_points, `source`, qui dit si un point est un releve reel
/// (`gps`) ou un point estime le long du trace (`estime`). Nullable pour que
/// les points enregistres AVANT la migration restent lisibles, et comptent
/// comme des releves reels.
///
/// Methode, celle de `migration_v25_to_v26_test.dart` : une table
/// session_track_points dans sa forme v31 (avec les colonnes de la v26, sans
/// `source`), des points d'une randonnee deja enregistree, user_version
/// ramene a 31, puis on rouvre.
void main() {
  Future<File> baseEnV31AvecDesPoints() async {
    final dir = await Directory.systemTemp.createTemp('gr_mig_v32_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final file = File('${dir.path}/app.sqlite');
    final seedDb = AppDatabase(NativeDatabase(file));
    await seedDb.customStatement('SELECT 1');
    await seedDb.customStatement('DROP TABLE IF EXISTS session_track_points');
    // Forme v31 : les trois colonnes de la v26, pas d'origine.
    await seedDb.customStatement(
      'CREATE TABLE session_track_points ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'trail_id TEXT NOT NULL, '
      'session_id TEXT NULL, '
      'day_index INTEGER NULL, '
      'stage_id TEXT NULL, '
      'lat REAL NOT NULL, '
      'lng REAL NOT NULL, '
      'altitude REAL NOT NULL, '
      'recorded_at INTEGER NOT NULL)',
    );
    for (var i = 0; i < 3; i++) {
      await seedDb.customStatement(
        'INSERT INTO session_track_points '
        '(trail_id, session_id, day_index, lat, lng, altitude, recorded_at) '
        "VALUES ('mare-a-mare', 'sess-v31', 1, ${42.1 + i * 0.001}, 9.05, "
        '${1550 + i}, ${1780000000 + i * 180})',
      );
    }
    await seedDb.customStatement('PRAGMA user_version = 31');
    await seedDb.close();
    return file;
  }

  group('Drift migration v31 -> v32 (origine des points de trace)', () {
    test('la version du schema est au moins 32', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(32));
    });

    test('une base v31 reelle rouverte en v32 ne perd AUCUN point, et leur '
        'origine vaut nul', () async {
      final db = AppDatabase(NativeDatabase(await baseEnV31AvecDesPoints()));
      addTearDown(db.close);

      final columns = await db
          .customSelect('PRAGMA table_info(session_track_points)')
          .get();
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(names, contains('source'), reason: 'colonne ajoutee en v32');
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.first, 32);

      final points = await db.sessionTrackPointsDao.getBySessionId(
        'sess-v31',
        read: TrackPointsRead.withEstimated,
      );
      expect(points, hasLength(3), reason: 'aucun point perdu en chemin');
      expect(points.map((p) => p.altitude), [1550, 1551, 1552]);
      expect(points.every((p) => p.source == null), isTrue);
      // Un point d'avant la v32 est un releve reel : la lecture des seuls
      // releves le rend.
      expect(
        await db.sessionTrackPointsDao.getBySessionId(
          'sess-v31',
          read: TrackPointsRead.gpsOnly,
        ),
        hasLength(3),
      );
    });

    test('un point insere avec l origine estime se relit avec cette origine, '
        'et le filtre rend exactement ce qu on lui demande', () async {
      final db = AppDatabase(NativeDatabase(await baseEnV31AvecDesPoints()));
      addTearDown(db.close);
      final dao = db.sessionTrackPointsDao;
      Future<void> add(TrackPointSource source, double lat) => dao.insertPoint(
        trailId: 'mare-a-mare',
        sessionId: 'sess-v31',
        dayIndex: 1,
        lat: lat,
        lng: 9.05,
        altitude: 1600,
        source: source,
      );
      await add(TrackPointSource.estimated, 42.2);
      await add(TrackPointSource.gps, 42.3);

      final all = await dao.getByTrailId(
        'mare-a-mare',
        read: TrackPointsRead.withEstimated,
      );
      expect(all, hasLength(5));
      expect(all.map((p) => TrackPointSource.fromStored(p.source)).toList(), [
        TrackPointSource.gps,
        TrackPointSource.gps,
        TrackPointSource.gps,
        TrackPointSource.estimated,
        TrackPointSource.gps,
      ]);
      expect(all[3].source, 'estime');
      expect(all[4].source, 'gps');

      final gpsOnly = await dao.getByTrailId(
        'mare-a-mare',
        read: TrackPointsRead.gpsOnly,
      );
      expect(gpsOnly, hasLength(4));
      expect(gpsOnly.any((p) => p.source == 'estime'), isFalse);
      for (final read in TrackPointsRead.values) {
        final day = await dao.getByDayIndex('mare-a-mare', 1, read: read);
        final byDay = await dao.getByCalendarDay(
          'mare-a-mare',
          all[3].recordedAt,
          read: read,
        );
        final expected = read == TrackPointsRead.gpsOnly ? 4 : 5;
        expect(day, hasLength(expected), reason: '$read par jour de marche');
        expect(byDay.where((p) => p.lat == 42.2), hasLength(expected - 4));
      }
    });

    test('rejouer la marche sur une colonne deja posee ne leve pas', () async {
      final file = await baseEnV31AvecDesPoints();
      final first = AppDatabase(NativeDatabase(file));
      await first.customStatement('SELECT 1');
      await first.customStatement('PRAGMA user_version = 31');
      await first.close();
      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);
      expect(
        await second.sessionTrackPointsDao.getByTrailId(
          'mare-a-mare',
          read: TrackPointsRead.gpsOnly,
        ),
        hasLength(3),
      );
    });

    test('l origine se lit avec tolerance : absente ou inconnue, c est un '
        'releve reel', () {
      expect(TrackPointSource.fromStored(null), TrackPointSource.gps);
      expect(TrackPointSource.fromStored('gps'), TrackPointSource.gps);
      expect(TrackPointSource.fromStored('estime'), TrackPointSource.estimated);
      expect(TrackPointSource.fromStored('futur'), TrackPointSource.gps);
    });
  });
}
