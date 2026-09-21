import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';

/// Tests de MIGRATION Drift v25 -> v26 (StepWays LOT L3-1, socle de la trace).
///
/// La v26 est STRICTEMENT ADDITIVE : trois colonnes NULLABLES sur
/// session_track_points (session_id, day_index, stage_id). Nullables
/// precisement pour que les points enregistres AVANT la migration restent
/// lisibles — c'est ce que ce test verifie sur une vraie base rembobinee.
///
/// Methode : la migration ne s'execute que si une base persistee est ouverte
/// a une version inferieure au schema courant. On fabrique donc une table
/// session_track_points dans sa forme d'origine (v13), on y insere un point,
/// on ramene user_version a 25, puis on rouvre.
void main() {
  group('Drift migration v25 -> v26 (socle trace StepWays)', () {
    test('la version du schema est au moins 26', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(26));
    });

    test('migration reelle 25 -> 26 : 3 colonnes ajoutees, points preserves',
        () async {
      final dir = await Directory.systemTemp.createTemp('gr_mig_v26_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final file = File('${dir.path}/app.sqlite');

      final seedDb = AppDatabase(NativeDatabase(file));
      await seedDb.customStatement('SELECT 1');

      // Table dans sa forme d'ORIGINE (v13) : indexee par trailId seul.
      await seedDb.customStatement('DROP TABLE IF EXISTS session_track_points');
      await seedDb.customStatement(
        'CREATE TABLE session_track_points ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'trail_id TEXT NOT NULL, '
        'lat REAL NOT NULL, '
        'lng REAL NOT NULL, '
        'altitude REAL NOT NULL, '
        'recorded_at INTEGER NOT NULL)',
      );
      // Un point d'une randonnee d'avant la migration.
      await seedDb.customStatement(
        "INSERT INTO session_track_points "
        "(trail_id, lat, lng, altitude, recorded_at) "
        "VALUES ('mare-a-mare', 42.1, 9.05, 1550, 1780000000)",
      );
      await seedDb.customStatement('PRAGMA user_version = 25');
      await seedDb.close();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final columns = await db
          .customSelect('PRAGMA table_info(session_track_points)')
          .get();
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(names, containsAll(<String>['session_id', 'day_index', 'stage_id']),
          reason: '3 colonnes ajoutees par la migration v26');

      // AUCUNE PERTE : le point d'avant est toujours la, lisible, avec ses
      // nouvelles colonnes a null — c'est pourquoi elles sont nullables.
      final points = await db.sessionTrackPointsDao.getByTrailId('mare-a-mare');
      expect(points.length, 1);
      expect(points.single.altitude, 1550);
      expect(points.single.sessionId, isNull);
      expect(points.single.dayIndex, isNull);
      expect(points.single.stageId, isNull);

      // Et la table accepte desormais un point complet.
      await db.sessionTrackPointsDao.insertPoint(
        trailId: 'mare-a-mare',
        sessionId: 'sess-1',
        dayIndex: 3,
        stageId: 'etape-3',
        lat: 42.2,
        lng: 9.1,
        altitude: 1600,
      );
      expect((await db.sessionTrackPointsDao.getByDayIndex('mare-a-mare', 3)).length, 1);
    });
  });
}
