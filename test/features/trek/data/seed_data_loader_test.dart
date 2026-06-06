import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/data/daos/pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/features/trek/data/seed_data_loader.dart';

/// Config sentier pour le test du seed.
///
/// Le seed est desormais parametre par la config du sentier : l'id, le nom et
/// la racine des assets viennent de [TrailConfig]. On pointe [seedAssetsBase]
/// vers les donnees de seed embarquees ('assets/data/mare_a_mare_centre') que
/// ce test verifie. Geo neutre (Auvergne) ; seuls id/nom/assets sont
/// significatifs car ils pilotent les enregistrements POIs/track/points.
const _seedTrailConfig = TrailConfig(
  id: 'mare-a-mare-centre',
  name: 'Mare a Mare Centre',
  displayName: 'Mare a Mare Centre',
  tagline: 'Seed de test',
  totalStages: 7,
  totalDistanceKm: 0,
  totalElevationGain: 0,
  region: 'Auvergne',
  country: 'France',
  primaryColorValue: 0xFF8B4513,
  secondaryColorValue: 0xFFD2691E,
  gpxAssetPath: 'assets/data/mare_a_mare_centre/track.gpx',
  seedAssetsBase: 'assets/data/mare_a_mare_centre',
);

void main() {
  // Necessaire pour rootBundle.loadString (chargement des assets de seed).
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SeedDataLoader', () {
    test('seedIfNeeded charge les donnees et set le flag', () async {
      // --- Setup : DB in-memory + SharedPreferences mock ---
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());

      final loader = SeedDataLoader(
        db: db,
        prefs: prefs,
        trailConfig: _seedTrailConfig,
      );

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
