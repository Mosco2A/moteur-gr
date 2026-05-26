import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../data/database.dart';
import '../data/daos/sync_queue_dao.dart';
import '../data/daos/trail_meta_dao.dart';
import '../data/daos/trail_itineraries_dao.dart';
import '../data/daos/trail_stages_dao.dart';
import '../data/daos/trail_accommodations_dao.dart';
import '../data/daos/trail_pois_dao.dart';
import '../data/daos/trail_gpx_tracks_dao.dart';
import '../data/daos/trail_gpx_points_dao.dart';
import '../models/download_progress.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Nombre maximum de tentatives en cas d'erreur reseau.
const _maxRetries = 3;

/// Etapes d'insertion dans l'ordre des FK.
const _insertionSteps = [
  'trail_meta',
  'itineraries',
  'stages',
  'accommodations',
  'pois',
  'gpx_tracks',
  'gpx_points',
];

/// Service de telechargement des donnees sentier depuis Firebase Storage.
class TrailDownloadService {
  TrailDownloadService({
    required this.syncQueueDao,
    required this.trailMetaDao,
    required this.trailItinerariesDao,
    required this.trailStagesDao,
    required this.trailAccommodationsDao,
    required this.trailPoisDao,
    required this.trailGpxTracksDao,
    required this.trailGpxPointsDao,
    required this.connectivityMonitor,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final SyncQueueDao syncQueueDao;
  final TrailMetaDao trailMetaDao;
  final TrailItinerariesDao trailItinerariesDao;
  final TrailStagesDao trailStagesDao;
  final TrailAccommodationsDao trailAccommodationsDao;
  final TrailPoisDao trailPoisDao;
  final TrailGpxTracksDao trailGpxTracksDao;
  final TrailGpxPointsDao trailGpxPointsDao;
  final ConnectivityMonitor connectivityMonitor;
  final http.Client _httpClient;

  /// Telecharge et insere les donnees d'un sentier.
  Stream<DownloadProgress> downloadTrail(String trailId, String dataUrl) async* {
    _log.d('[TrailDownloadService] Debut telechargement $trailId');

    yield DownloadProgress(
      trailId: trailId, status: DownloadStatus.downloading,
      bytesDownloaded: 0, totalBytes: 0, currentStep: 'downloading',
    );

    Map<String, dynamic>? trailData;
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      final status = await connectivityMonitor.checkStatus();
      if (status == ConnectivityStatus.offline) {
        yield DownloadProgress(
          trailId: trailId, status: DownloadStatus.paused,
          bytesDownloaded: 0, totalBytes: 0, currentStep: 'downloading',
          error: 'Hors ligne',
        );
        return;
      }

      try {
        final response = await _httpClient.get(Uri.parse(dataUrl));
        if (response.statusCode == 200) {
          trailData = jsonDecode(response.body) as Map<String, dynamic>;
          yield DownloadProgress(
            trailId: trailId, status: DownloadStatus.downloading,
            bytesDownloaded: response.contentLength ?? response.body.length,
            totalBytes: response.contentLength ?? response.body.length,
            currentStep: 'downloaded',
          );
          break;
        }
        _log.w('[TrailDownloadService] HTTP ${response.statusCode}');
        retryCount++;
      } catch (e) {
        _log.e('[TrailDownloadService] Erreur HTTP: $e');
        retryCount++;
      }

      if (retryCount < _maxRetries) {
        await Future<void>.delayed(Duration(seconds: retryCount * 2));
      }
    }

    if (trailData == null) {
      yield DownloadProgress(
        trailId: trailId, status: DownloadStatus.error,
        bytesDownloaded: 0, totalBytes: 0, currentStep: 'downloading',
        error: 'Echec telechargement apres $_maxRetries tentatives',
      );
      return;
    }

    // --- Phase 2 : SyncQueue actions ---
    final existingActions = await syncQueueDao.getByTrailId(trailId);
    final completedActions = existingActions
        .where((a) => a.status == 'completed').map((a) => a.action).toSet();

    final now = DateTime.now().toIso8601String();
    for (final step in _insertionSteps) {
      final action = 'insert_$step';
      if (!completedActions.contains(action)) {
        final existsPending = existingActions.any(
          (a) => a.action == action && a.status == 'pending',
        );
        if (!existsPending) {
          await syncQueueDao.insertOrReplace(SyncQueueCompanion(
            trailId: Value(trailId), action: Value(action),
            status: const Value('pending'), createdAt: Value(now),
          ));
        }
      }
    }

    // --- Phase 3 : Insertion table par table dans l'ordre FK ---
    final totalSteps = _insertionSteps.length;
    int completedStepCount = completedActions.length;

    for (final step in _insertionSteps) {
      final action = 'insert_$step';
      if (completedActions.contains(action)) continue;

      yield DownloadProgress(
        trailId: trailId, status: DownloadStatus.downloading,
        bytesDownloaded: completedStepCount, totalBytes: totalSteps,
        currentStep: step,
      );

      final pendingActions = await syncQueueDao.getByTrailId(trailId);
      final syncAction = pendingActions.firstWhere(
        (a) => a.action == action && a.status == 'pending',
        orElse: () => pendingActions.firstWhere((a) => a.action == action),
      );

      try {
        await _insertStep(step, trailData);
        await syncQueueDao.markCompleted(syncAction.id);
        completedStepCount++;
      } catch (e) {
        _log.e('[TrailDownloadService] Erreur insertion $step: $e');
        await syncQueueDao.incrementRetry(syncAction.id);
        if (syncAction.retryCount + 1 >= _maxRetries) {
          await syncQueueDao.markFailed(syncAction.id, e.toString());
          yield DownloadProgress(
            trailId: trailId, status: DownloadStatus.error,
            bytesDownloaded: completedStepCount, totalBytes: totalSteps,
            currentStep: step, error: 'Echec insertion $step: $e',
          );
          return;
        }
        yield DownloadProgress(
          trailId: trailId, status: DownloadStatus.paused,
          bytesDownloaded: completedStepCount, totalBytes: totalSteps,
          currentStep: step, error: 'Retry insertion $step',
        );
        return;
      }
    }

    yield DownloadProgress(
      trailId: trailId, status: DownloadStatus.completed,
      bytesDownloaded: totalSteps, totalBytes: totalSteps,
      currentStep: 'completed',
    );
  }

  /// Insere les donnees d'une etape du pipeline dans les DAOs.
  Future<void> _insertStep(String step, Map<String, dynamic> data) async {
    switch (step) {
      case 'trail_meta': await _insertTrailMeta(data['trail_meta'] as Map<String, dynamic>);
      case 'itineraries': await _insertItineraries(data['itineraries'] as List<dynamic>);
      case 'stages': await _insertStages(data['stages'] as List<dynamic>);
      case 'accommodations': await _insertAccommodations(data['accommodations'] as List<dynamic>);
      case 'pois': await _insertPois(data['pois'] as List<dynamic>);
      case 'gpx_tracks': await _insertGpxTracks(data['gpx_tracks'] as List<dynamic>);
      case 'gpx_points': await _insertGpxPoints(data['gpx_points'] as List<dynamic>);
    }
  }

  Future<void> _insertTrailMeta(Map<String, dynamic> meta) async {
    await trailMetaDao.insertOrReplace(TrailMetaCompanion(
      id: Value(meta['id'] as String), code: Value(meta['code'] as String),
      dataVersion: Value(meta['data_version'] as int),
      lastSync: Value(DateTime.now().toIso8601String()),
      status: Value(meta['status'] as String? ?? 'active'),
    ));
  }

  Future<void> _insertItineraries(List<dynamic> itineraries) async {
    for (final item in itineraries) {
      final it = item as Map<String, dynamic>;
      await trailItinerariesDao.insertOrReplace(TrailItinerariesCompanion(
        id: Value(it['id'] as String),
        trailId: Value(it['trail_id'] as String),
        code: Value(it['code'] as String),
        nameFr: Value(it['name_fr'] as String),
        nameEn: Value(it['name_en'] as String),
        nameDe: Value(it['name_de'] as String),
        nameIt: Value(it['name_it'] as String),
        nameEs: Value(it['name_es'] as String),
        distanceKm: Value((it['distance_km'] as num).toDouble()),
        elevationGain: Value(it['elevation_gain'] as int),
        stageCount: Value(it['stage_count'] as int),
      ));
    }
  }

  Future<void> _insertStages(List<dynamic> stages) async {
    for (final item in stages) {
      final s = item as Map<String, dynamic>;
      await trailStagesDao.insertOrReplace(TrailStagesCompanion(
        id: Value(s['id'] as String),
        itineraryId: Value(s['itinerary_id'] as String),
        stageNumber: Value(s['stage_number'] as int),
        nameFr: Value(s['name_fr'] as String),
        nameEn: Value(s['name_en'] as String),
        nameDe: Value(s['name_de'] as String),
        nameIt: Value(s['name_it'] as String),
        nameEs: Value(s['name_es'] as String),
        startLat: Value((s['start_lat'] as num).toDouble()),
        startLng: Value((s['start_lng'] as num).toDouble()),
        endLat: Value((s['end_lat'] as num).toDouble()),
        endLng: Value((s['end_lng'] as num).toDouble()),
        distanceKm: Value((s['distance_km'] as num).toDouble()),
        elevationGain: Value(s['elevation_gain'] as int),
        elevationLoss: Value(s['elevation_loss'] as int),
        durationMinutes: Value(s['duration_minutes'] as int),
        difficulty: Value(s['difficulty'] as String),
      ));
    }
  }

  Future<void> _insertAccommodations(List<dynamic> accommodations) async {
    for (final item in accommodations) {
      final ac = item as Map<String, dynamic>;
      await trailAccommodationsDao.insertOrReplace(TrailAccommodationsCompanion(
        id: Value(ac['id'] as String),
        stageId: Value(ac['stage_id'] as String),
        nameFr: Value(ac['name_fr'] as String),
        nameEn: Value(ac['name_en'] as String),
        nameDe: Value(ac['name_de'] as String),
        nameIt: Value(ac['name_it'] as String),
        nameEs: Value(ac['name_es'] as String),
        type: Value(ac['type'] as String),
        lat: Value((ac['lat'] as num).toDouble()),
        lng: Value((ac['lng'] as num).toDouble()),
        phone: Value(ac['phone'] as String?),
        email: Value(ac['email'] as String?),
        website: Value(ac['website'] as String?),
        capacity: Value(ac['capacity'] as int?),
        priceRange: Value(ac['price_range'] as String?),
        bookingUrl: Value(ac['booking_url'] as String?),
      ));
    }
  }

  Future<void> _insertPois(List<dynamic> pois) async {
    for (final item in pois) {
      final p = item as Map<String, dynamic>;
      await trailPoisDao.insertOrReplace(TrailPoisCompanion(
        id: Value(p['id'] as String),
        stageId: Value(p['stage_id'] as String),
        nameFr: Value(p['name_fr'] as String),
        nameEn: Value(p['name_en'] as String),
        nameDe: Value(p['name_de'] as String),
        nameIt: Value(p['name_it'] as String),
        nameEs: Value(p['name_es'] as String),
        descriptionFr: Value(p['description_fr'] as String?),
        descriptionEn: Value(p['description_en'] as String?),
        descriptionDe: Value(p['description_de'] as String?),
        descriptionIt: Value(p['description_it'] as String?),
        descriptionEs: Value(p['description_es'] as String?),
        type: Value(p['type'] as String),
        lat: Value((p['lat'] as num).toDouble()),
        lng: Value((p['lng'] as num).toDouble()),
        elevation: Value((p['elevation'] as num?)?.toDouble()),
      ));
    }
  }

  Future<void> _insertGpxTracks(List<dynamic> tracks) async {
    for (final item in tracks) {
      final t = item as Map<String, dynamic>;
      await trailGpxTracksDao.insertOrReplace(TrailGpxTracksCompanion(
        id: Value(t['id'] as String), itineraryId: Value(t['itinerary_id'] as String),
        name: Value(t['name'] as String), sourceUrl: Value(t['source_url'] as String?),
      ));
    }
  }

  Future<void> _insertGpxPoints(List<dynamic> points) async {
    for (final item in points) {
      final p = item as Map<String, dynamic>;
      await trailGpxPointsDao.insertOrReplace(TrailGpxPointsCompanion(
        trackId: Value(p['track_id'] as String),
        lat: Value((p['lat'] as num).toDouble()),
        lng: Value((p['lng'] as num).toDouble()),
        elevation: Value((p['elevation'] as num).toDouble()),
        sequenceIndex: Value(p['sequence_index'] as int),
      ));
    }
  }
}

/// Provider Riverpod pour le service de telechargement.
final trailDownloadServiceProvider = Provider<TrailDownloadService>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  return TrailDownloadService(
    syncQueueDao: SyncQueueDao(db), trailMetaDao: TrailMetaDao(db),
    trailItinerariesDao: TrailItinerariesDao(db),
    trailStagesDao: TrailStagesDao(db),
    trailAccommodationsDao: TrailAccommodationsDao(db),
    trailPoisDao: TrailPoisDao(db),
    trailGpxTracksDao: TrailGpxTracksDao(db),
    trailGpxPointsDao: TrailGpxPointsDao(db),
    connectivityMonitor: connectivity,
  );
});