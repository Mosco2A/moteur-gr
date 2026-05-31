import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../data/database.dart' hide TrailManifest;
import '../data/daos/trail_manifests_dao.dart';
import '../data/daos/trail_stages_dao.dart';
import '../data/daos/trail_accommodations_dao.dart';
import '../data/daos/trail_pois_dao.dart';
import '../data/daos/trail_gpx_tracks_dao.dart';
import '../data/daos/trail_gpx_points_dao.dart';
import '../data/daos/trail_itineraries_dao.dart';
import '../data/daos/trail_meta_dao.dart';
import '../models/delta_update.dart';
import '../models/trail_manifest.dart';
import '../providers/database_provider.dart';
import 'manifest_service.dart';
import 'package:drift/drift.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Service de mise a jour delta des donnees sentier.
class DeltaUpdateService {
  DeltaUpdateService({
    required this.manifestService, required this.trailManifestsDao,
    required this.trailMetaDao, required this.trailItinerariesDao,
    required this.trailStagesDao, required this.trailAccommodationsDao,
    required this.trailPoisDao, required this.trailGpxTracksDao,
    required this.trailGpxPointsDao, http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final ManifestService manifestService;
  final TrailManifestsDao trailManifestsDao;
  final TrailMetaDao trailMetaDao;
  final TrailItinerariesDao trailItinerariesDao;
  final TrailStagesDao trailStagesDao;
  final TrailAccommodationsDao trailAccommodationsDao;
  final TrailPoisDao trailPoisDao;
  final TrailGpxTracksDao trailGpxTracksDao;
  final TrailGpxPointsDao trailGpxPointsDao;
  final http.Client _httpClient;

  Future<DeltaUpdate?> checkForUpdates(String trailId, {required TrailManifest remoteManifest}) async {
    final remoteEntry = remoteManifest.trails.where((t) => t.trailId == trailId).firstOrNull;
    if (remoteEntry == null) return null;
    final localEntry = await trailManifestsDao.getByTrailId(trailId);
    final localVersion = localEntry?.localVersion ?? 0;
    if (localVersion >= remoteEntry.dataVersion) return null;
    return DeltaUpdate(trailId: trailId, fromVersion: localVersion,
      toVersion: remoteEntry.dataVersion,
      changedTables: _inferChangedTables(localVersion, remoteEntry.dataVersion),
      downloadSize: remoteEntry.fileSize);
  }

  Future<void> applyDelta(String trailId, Map<String, dynamic> deltaJson,
      {List<String> changedTables = const []}) async {
    final tables = changedTables.isNotEmpty ? changedTables : deltaJson.keys.toList();
    for (final table in tables) {
      final data = deltaJson[table];
      if (data == null) continue;
      try { await _applyTableDelta(table, data); }
      catch (e) { _log.e('[DeltaUpdate] Erreur $table: $e'); rethrow; }
    }
  }

  Future<void> downloadAndApplyDelta(String trailId, String deltaUrl,
      {List<String> changedTables = const []}) async {
    final response = await _httpClient.get(Uri.parse(deltaUrl));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    await applyDelta(trailId, jsonDecode(response.body) as Map<String, dynamic>, changedTables: changedTables);
  }

  Future<void> _applyTableDelta(String table, dynamic data) async {
    switch (table) {
      case 'trail_meta': await _applyMeta(data as Map<String, dynamic>);
      case 'itineraries': await _applyItin(data as List<dynamic>);
      case 'stages': await _applyStages(data as List<dynamic>);
      case 'accommodations': await _applyAccom(data as List<dynamic>);
      case 'pois': await _applyPois(data as List<dynamic>);
      case 'gpx_tracks': await _applyTracks(data as List<dynamic>);
      case 'gpx_points': await _applyPoints(data as List<dynamic>);
    }
  }

  Future<void> _applyMeta(Map<String, dynamic> m) async {
    await trailMetaDao.insertOrReplace(TrailMetaCompanion(
      id: Value(m['id'] as String), code: Value(m['code'] as String),
      dataVersion: Value(m['data_version'] as int),
      lastSync: Value(DateTime.now().toIso8601String()),
      status: Value(m['status'] as String? ?? 'active')));
  }

  Future<void> _applyItin(List<dynamic> items) async {
    for (final i in items) { final m = i as Map<String, dynamic>;
      await trailItinerariesDao.insertOrReplace(TrailItinerariesCompanion(
        id: Value(m['id'] as String), trailId: Value(m['trail_id'] as String),
        code: Value(m['code'] as String), nameFr: Value(m['name_fr'] as String),
        nameEn: Value(m['name_en'] as String), nameDe: Value(m['name_de'] as String),
        nameIt: Value(m['name_it'] as String), nameEs: Value(m['name_es'] as String),
        distanceKm: Value((m['distance_km'] as num).toDouble()),
        elevationGain: Value(m['elevation_gain'] as int),
        stageCount: Value(m['stage_count'] as int)));
    }
  }

  Future<void> _applyStages(List<dynamic> items) async {
    for (final i in items) { final s = i as Map<String, dynamic>;
      await trailStagesDao.insertOrReplace(TrailStagesCompanion(
        id: Value(s['id'] as String), itineraryId: Value(s['itinerary_id'] as String),
        stageNumber: Value(s['stage_number'] as int),
        nameFr: Value(s['name_fr'] as String), nameEn: Value(s['name_en'] as String),
        nameDe: Value(s['name_de'] as String), nameIt: Value(s['name_it'] as String),
        nameEs: Value(s['name_es'] as String),
        startLat: Value((s['start_lat'] as num).toDouble()),
        startLng: Value((s['start_lng'] as num).toDouble()),
        endLat: Value((s['end_lat'] as num).toDouble()),
        endLng: Value((s['end_lng'] as num).toDouble()),
        distanceKm: Value((s['distance_km'] as num).toDouble()),
        elevationGain: Value(s['elevation_gain'] as int),
        elevationLoss: Value(s['elevation_loss'] as int),
        durationMinutes: Value(s['duration_minutes'] as int),
        difficulty: Value(s['difficulty'] as String)));
    }
  }

  Future<void> _applyAccom(List<dynamic> items) async {
    for (final i in items) { final a = i as Map<String, dynamic>;
      await trailAccommodationsDao.insertOrReplace(TrailAccommodationsCompanion(
        id: Value(a['id'] as String), stageId: Value(a['stage_id'] as String),
        nameFr: Value(a['name_fr'] as String), nameEn: Value(a['name_en'] as String),
        nameDe: Value(a['name_de'] as String), nameIt: Value(a['name_it'] as String),
        nameEs: Value(a['name_es'] as String), type: Value(a['type'] as String),
        lat: Value((a['lat'] as num).toDouble()), lng: Value((a['lng'] as num).toDouble()),
        phone: Value(a['phone'] as String?), email: Value(a['email'] as String?),
        website: Value(a['website'] as String?), capacity: Value(a['capacity'] as int?),
        priceRange: Value(a['price_range'] as String?), bookingUrl: Value(a['booking_url'] as String?)));
    }
  }

  Future<void> _applyPois(List<dynamic> items) async {
    for (final i in items) { final p = i as Map<String, dynamic>;
      await trailPoisDao.insertOrReplace(TrailPoisCompanion(
        id: Value(p['id'] as String), stageId: Value(p['stage_id'] as String),
        nameFr: Value(p['name_fr'] as String), nameEn: Value(p['name_en'] as String),
        nameDe: Value(p['name_de'] as String), nameIt: Value(p['name_it'] as String),
        nameEs: Value(p['name_es'] as String),
        descriptionFr: Value(p['description_fr'] as String?),
        descriptionEn: Value(p['description_en'] as String?),
        descriptionDe: Value(p['description_de'] as String?),
        descriptionIt: Value(p['description_it'] as String?),
        descriptionEs: Value(p['description_es'] as String?),
        type: Value(p['type'] as String),
        lat: Value((p['lat'] as num).toDouble()), lng: Value((p['lng'] as num).toDouble()),
        elevation: Value((p['elevation'] as num?)?.toDouble())));
    }
  }

  Future<void> _applyTracks(List<dynamic> items) async {
    for (final i in items) { final t = i as Map<String, dynamic>;
      await trailGpxTracksDao.insertOrReplace(TrailGpxTracksCompanion(
        id: Value(t['id'] as String), itineraryId: Value(t['itinerary_id'] as String),
        name: Value(t['name'] as String), sourceUrl: Value(t['source_url'] as String?)));
    }
  }

  Future<void> _applyPoints(List<dynamic> items) async {
    for (final i in items) { final p = i as Map<String, dynamic>;
      await trailGpxPointsDao.insertOrReplace(TrailGpxPointsCompanion(
        trackId: Value(p['track_id'] as String),
        lat: Value((p['lat'] as num).toDouble()), lng: Value((p['lng'] as num).toDouble()),
        elevation: Value((p['elevation'] as num).toDouble()),
        sequenceIndex: Value(p['sequence_index'] as int)));
    }
  }

  List<String> _inferChangedTables(int from, int to) {
    return ['trail_meta','itineraries','stages','accommodations','pois','gpx_tracks','gpx_points'];
  }
}

/// Provider Riverpod pour le service de MAJ delta.
final deltaUpdateServiceProvider = Provider<DeltaUpdateService>((ref) {
  final db = ref.watch(databaseProvider);
  return DeltaUpdateService(manifestService: ref.watch(manifestServiceProvider),
    trailManifestsDao: TrailManifestsDao(db), trailMetaDao: TrailMetaDao(db),
    trailItinerariesDao: TrailItinerariesDao(db), trailStagesDao: TrailStagesDao(db),
    trailAccommodationsDao: TrailAccommodationsDao(db), trailPoisDao: TrailPoisDao(db),
    trailGpxTracksDao: TrailGpxTracksDao(db), trailGpxPointsDao: TrailGpxPointsDao(db));
});
