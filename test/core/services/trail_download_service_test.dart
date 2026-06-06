import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/sync_queue_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/models/download_progress.dart';
import 'package:moteur_gr/core/services/trail_download_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';

class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;
  void setStatus(ConnectivityStatus s) => _status = s;
  @override
  Future<ConnectivityStatus> checkStatus() async => _status;
}

Map<String, dynamic> makeTrailData() {
  return {
    'trail_meta': {'id': 't1', 'code': 'sentier-volcans', 'data_version': 3, 'status': 'active'},
    'itineraries': [{'id': 'i1', 'trail_id': 't1', 'code': 'ns', 'name_fr': 'NS', 'name_en': 'NS', 'name_de': 'NS', 'name_it': 'NS', 'name_es': 'NS', 'distance_km': 180.0, 'elevation_gain': 13000, 'stage_count': 16}],
    'stages': [{'id': 's1', 'itinerary_id': 'i1', 'stage_number': 1, 'name_fr': 'E1', 'name_en': 'E1', 'name_de': 'E1', 'name_it': 'E1', 'name_es': 'E1', 'start_lat': 45.5, 'start_lng': 2.9, 'end_lat': 45.47, 'end_lng': 2.96, 'distance_km': 12.0, 'elevation_gain': 1500, 'elevation_loss': 100, 'duration_minutes': 420, 'difficulty': 'hard'}],
    'accommodations': [{'id': 'a1', 'stage_id': 's1', 'name_fr': 'Ref', 'name_en': 'Sh', 'name_de': 'H', 'name_it': 'R', 'name_es': 'R', 'type': 'refuge', 'lat': 45.47, 'lng': 2.96, 'phone': '+33', 'email': null, 'website': null, 'capacity': 30, 'price_range': '14EUR', 'booking_url': null}],
    'pois': [{'id': 'p1', 'stage_id': 's1', 'name_fr': 'Src', 'name_en': 'Sp', 'name_de': 'Q', 'name_it': 'S', 'name_es': 'F', 'description_fr': 'E', 'description_en': 'W', 'description_de': null, 'description_it': null, 'description_es': null, 'type': 'water', 'lat': 45.49, 'lng': 2.93, 'elevation': 1400.0}],
    'gpx_tracks': [{'id': 'tk1', 'itinerary_id': 'i1', 'name': 'Sentier des Volcans', 'source_url': null}],
    'gpx_points': [{'track_id': 'tk1', 'lat': 45.5, 'lng': 2.9, 'elevation': 275.0, 'sequence_index': 0}, {'track_id': 'tk1', 'lat': 45.49, 'lng': 2.93, 'elevation': 1400.0, 'sequence_index': 1}],
  };
}

void main() {
  late AppDatabase db;
  late SyncQueueDao syncQueueDao;
  late TrailMetaDao trailMetaDao;
  late TrailItinerariesDao trailItinerariesDao;
  late TrailStagesDao trailStagesDao;
  late TrailAccommodationsDao trailAccommodationsDao;
  late TrailPoisDao trailPoisDao;
  late TrailGpxTracksDao trailGpxTracksDao;
  late TrailGpxPointsDao trailGpxPointsDao;
  late FakeConnectivityMonitor connectivity;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    syncQueueDao = SyncQueueDao(db);
    trailMetaDao = TrailMetaDao(db);
    trailItinerariesDao = TrailItinerariesDao(db);
    trailStagesDao = TrailStagesDao(db);
    trailAccommodationsDao = TrailAccommodationsDao(db);
    trailPoisDao = TrailPoisDao(db);
    trailGpxTracksDao = TrailGpxTracksDao(db);
    trailGpxPointsDao = TrailGpxPointsDao(db);
    connectivity = FakeConnectivityMonitor();
  });
  tearDown(() async { await db.close(); });

  TrailDownloadService makeService({http.Client? httpClient}) {
    return TrailDownloadService(
      syncQueueDao: syncQueueDao,
      trailMetaDao: trailMetaDao,
      trailItinerariesDao: trailItinerariesDao,
      trailStagesDao: trailStagesDao,
      trailAccommodationsDao: trailAccommodationsDao,
      trailPoisDao: trailPoisDao,
      trailGpxTracksDao: trailGpxTracksDao,
      trailGpxPointsDao: trailGpxPointsDao,
      connectivityMonitor: connectivity, httpClient: httpClient,
    );
  }

  group('flow complet', () {
    test('insere toutes les tables', () async {
      final mc = MockClient((r) async => http.Response(jsonEncode(makeTrailData()), 200));
      final svc = makeService(httpClient: mc);
      final evts = <DownloadProgress>[];
      await for (final e in svc.downloadTrail('sentier-volcans', 'https://example.com/d.json')) { evts.add(e); }
      expect(evts.last.status, DownloadStatusValues.completed);
      expect((await trailMetaDao.getAll()).length, 1);
      expect((await trailGpxPointsDao.getAll()).length, 2);
    });
    test('etapes progression', () async {
      final mc = MockClient((r) async => http.Response(jsonEncode(makeTrailData()), 200));
      final svc = makeService(httpClient: mc);
      final steps = <String>[];
      await for (final e in svc.downloadTrail('sentier-volcans', 'https://example.com/d.json')) { steps.add(e.currentStep); }
      expect(steps.first, 'downloading');
      expect(steps.last, 'completed');
    });
  });

  group('erreur reseau', () {
    test('paused offline', () async {
      connectivity.setStatus(ConnectivityStatusValues.offline);
      final svc = makeService();
      final evts = <DownloadProgress>[];
      await for (final e in svc.downloadTrail('sentier-volcans', 'https://example.com/d.json')) { evts.add(e); }
      expect(evts.last.status, DownloadStatusValues.paused);
    });
    test('error retries', () async {
      final mc = MockClient((r) async => http.Response('Err', 500));
      final svc = makeService(httpClient: mc);
      final evts = <DownloadProgress>[];
      await for (final e in svc.downloadTrail('sentier-volcans', 'https://example.com/d.json')) { evts.add(e); }
      expect(evts.last.status, DownloadStatusValues.error);
    });
  });

  group('reprise', () {
    test('skip completees', () async {
      final now = DateTime.now().toIso8601String();
      await syncQueueDao.insertOrReplace(SyncQueueCompanion(trailId: const Value('sentier-volcans'), action: const Value('insert_trail_meta'), status: const Value('completed'), createdAt: Value(now), completedAt: Value(now)));
      await syncQueueDao.insertOrReplace(SyncQueueCompanion(trailId: const Value('sentier-volcans'), action: const Value('insert_itineraries'), status: const Value('completed'), createdAt: Value(now), completedAt: Value(now)));
      final mc = MockClient((r) async => http.Response(jsonEncode(makeTrailData()), 200));
      final svc = makeService(httpClient: mc);
      final steps = <String>[];
      await for (final e in svc.downloadTrail('sentier-volcans', 'https://example.com/d.json')) {
        if (e.status == DownloadStatusValues.downloading && e.currentStep != 'downloading' && e.currentStep != 'downloaded') steps.add(e.currentStep);
      }
      expect(steps.contains('trail_meta'), isFalse);
      expect(steps.contains('stages'), isTrue);
    });
  });

  group('sync_queue tracking', () {
    test('7 actions completees', () async {
      final mc = MockClient((r) async => http.Response(jsonEncode(makeTrailData()), 200));
      final svc = makeService(httpClient: mc);
      await for (final _ in svc.downloadTrail('sentier-volcans', 'https://example.com/d.json')) {}
      final acts = await syncQueueDao.getByTrailId('sentier-volcans');
      expect(acts.length, 7);
      for (final x in acts) { expect(x.status, 'completed'); }
    });
  });
}