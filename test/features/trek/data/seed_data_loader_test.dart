
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/data/daos/pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/features/trek/data/seed_data_loader.dart';

void main() {
  group('SeedDataLoader', () {
    test('seedIfNeeded charge les donnees et set le flag', () async {
      // --- Setup : DB in-memory + SharedPreferences mock ---
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());

      final loader = SeedDataLoader(db: db, prefs: prefs);

      // --- Act : premier seed ---
      final result = await loader.seedIfNeeded();

      // --- Assert : seed effectue ---
      expect(result, isTrue);

      // Stages inseres (7 etapes Mare a Mare Centre)
      final stagesDao = StagesDao(db);
      final stages = await stagesDao.getByTrailId('mare-a-mare-centre');
      expect(stages.length, 7);
      expect(stages.first.name, contains('Ghisonaccia'));
      expect(stages.last.name, contains('Porticcio'));

      // POIs inseres (20 POIs)
      final poisDao = PoisDao(db);
      final pois = await poisDao.getByTrailId('mare-a-mare-centre');
      expect(pois.length, 20);

      // GPX track insere
      final tracksDao = TrailGpxTracksDao(db);
      final track = await tracksDao.getById('mare-a-mare-centre');
      expect(track, isNotNull);
      expect(track!.name, 'Mare a Mare Centre');

      // GPX points inseres (simplifies, donc moins que les bruts)
      final pointsDao = TrailGpxPointsDao(db);
      final points = await pointsDao.getByTrackId('mare-a-mare-centre');
      expect(points.length, greaterThan(0));
      expect(points.length, lessThanOrEqualTo(63)); // 63 bruts max

      // Flag SharedPreferences set
      expect(prefs.getBool('data_seeded'), isTrue);

      // --- Act : deuxieme appel (idempotent) ---
      final result2 = await loader.seedIfNeeded();
      expect(result2, isFalse);

      // Donnees inchangees
      final stages2 = await stagesDao.getByTrailId('mare-a-mare-centre');
      expect(stages2.length, 7);

      await db.close();
    });
  });
}
