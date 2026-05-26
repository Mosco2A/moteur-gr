import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';

class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatus.online;
  void setStatus(ConnectivityStatus s) => _status = s;
  @override
  Future<ConnectivityStatus> checkStatus() async => _status;
}

void main() {
  late AppDatabase db;
  late TrailManifestsDao dao;
  late DeltaUpdateService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailManifestsDao(db);
    final conn = FakeConnectivityMonitor();
    svc = DeltaUpdateService(
      manifestService: ManifestService(dao: dao, connectivityMonitor: conn),
      trailManifestsDao: dao, trailMetaDao: TrailMetaDao(db),
      trailItinerariesDao: TrailItinerariesDao(db), trailStagesDao: TrailStagesDao(db),
      trailAccommodationsDao: TrailAccommodationsDao(db), trailPoisDao: TrailPoisDao(db),
      trailGpxTracksDao: TrailGpxTracksDao(db), trailGpxPointsDao: TrailGpxPointsDao(db));
  });
  tearDown(() async { await db.close(); });

  TrailManifest mk({int v = 3}) => TrailManifest(schemaVersion: 1, trails: [
    TrailManifestEntry(trailId: 'gr20', dataVersion: v, hash: 'h',
      filePath: 'p', fileSize: 524288, status: 'active', lastUpdated: '2026-05-26T12:00:00Z')]);

  group('checkForUpdates', () {
    test('null si absent', () async {
      expect(await svc.checkForUpdates('gr20',
        remoteManifest: const TrailManifest(schemaVersion: 1, trails: [])), isNull);
    });
    test('null si a jour', () async {
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('gr20'), dataVersion: const Value(3), hash: const Value('h'),
        filePath: const Value('p'), fileSize: const Value(100), status: const Value('active'),
        lastUpdated: const Value('2026-01-01'), localVersion: const Value(3)));
      expect(await svc.checkForUpdates('gr20', remoteManifest: mk(v: 3)), isNull);
    });
    test('DeltaUpdate si MAJ dispo', () async {
      await dao.insertOrReplace(TrailManifestsCompanion(
        trailId: const Value('gr20'), dataVersion: const Value(1), hash: const Value('h'),
        filePath: const Value('p'), fileSize: const Value(100), status: const Value('active'),
        lastUpdated: const Value('2026-01-01'), localVersion: const Value(1)));
      final r = await svc.checkForUpdates('gr20', remoteManifest: mk(v: 3));
      expect(r, isNotNull); expect(r!.fromVersion, 1); expect(r.toVersion, 3);
    });
    test('DeltaUpdate si jamais telecharge', () async {
      final r = await svc.checkForUpdates('gr20', remoteManifest: mk(v: 2));
      expect(r, isNotNull); expect(r!.fromVersion, 0);
    });
  });

  group('applyDelta', () {
    test('applique stages', () async {
      await svc.applyDelta('gr20', {'stages': [
        {'id': 's1', 'itinerary_id': 'i1', 'stage_number': 1, 'name_fr': 'Cal',
          'name_en': 'C', 'name_de': 'C', 'name_it': 'C', 'name_es': 'C',
          'start_lat': 42.5, 'start_lng': 8.8, 'end_lat': 42.4, 'end_lng': 8.9,
          'distance_km': 12.0, 'elevation_gain': 1500, 'elevation_loss': 200,
          'duration_minutes': 420, 'difficulty': 'difficile'}]});
      final stages = await TrailStagesDao(db).getByItineraryId('i1');
      expect(stages.length, 1); expect(stages.first.nameFr, 'Cal');
    });
    test('respecte changedTables', () async {
      await svc.applyDelta('gr20', {
        'stages': [{'id': 's1', 'itinerary_id': 'i1', 'stage_number': 1, 'name_fr': 'A',
          'name_en': 'A', 'name_de': 'A', 'name_it': 'A', 'name_es': 'A',
          'start_lat': 42.0, 'start_lng': 8.0, 'end_lat': 42.1, 'end_lng': 8.1,
          'distance_km': 10.0, 'elevation_gain': 500, 'elevation_loss': 200,
          'duration_minutes': 300, 'difficulty': 'moyen'}],
        'pois': [{'id': 'p1', 'stage_id': 's1', 'name_fr': 'S', 'name_en': 'S',
          'name_de': 'Q', 'name_it': 'S', 'name_es': 'F', 'type': 'water',
          'lat': 42.05, 'lng': 8.05}],
      }, changedTables: ['stages']);
      expect((await TrailStagesDao(db).getByItineraryId('i1')).length, 1);
      expect(await TrailPoisDao(db).getByStageId('s1'), isEmpty);
    });
  });
}
