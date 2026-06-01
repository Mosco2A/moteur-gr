import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/database.dart';
import '../../../core/data/daos/pois_dao.dart';
import '../../../core/data/daos/stages_dao.dart';
import '../../../core/data/daos/trail_gpx_points_dao.dart';
import '../../../core/data/daos/trail_gpx_tracks_dao.dart';
import '../domain/models/track_point.dart' as trek;
import 'gpx_parser.dart';
import '../../../features/tips/domain/models/tip_card.dart';
import 'track_simplifier.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Cle SharedPreferences pour le flag de seed.
const _kDataSeeded = 'data_seeded';

/// Identifiant du sentier Mare a Mare Centre.
const _kTrailId = 'mare-a-mare-centre';

/// Chemin des assets de donnees Mare a Mare Centre.
/// Chemins des fichiers JSON de fiches conseils.
const _kTipAssets = [
  'assets/tips/general_tips.json',
  'assets/tips/mare_a_mare_tips.json',
  'assets/tips/securite_neige.json',
  'assets/tips/securite_incendie.json',
];

const _kAssetsBase = 'assets/data/mare_a_mare_centre';

/// Chargement initial des donnees depuis les assets.
///
/// Idempotent : ne fait rien si les donnees ont deja ete chargees
/// (flag [_kDataSeeded] dans SharedPreferences).
///
/// Charge les stages (JSON), POIs (JSON), et GPX (parse + simplification
/// Douglas-Peucker), puis insere en batch dans Drift.
class SeedDataLoader {
  SeedDataLoader({
    required AppDatabase db,
    required SharedPreferences prefs,
  })  : _db = db,
        _prefs = prefs;

  final AppDatabase _db;
  final SharedPreferences _prefs;

  /// Charge les donnees initiales si ce n'est pas deja fait.
  ///
  /// Retourne true si le seed a ete effectue,
  /// false si les donnees etaient deja presentes.
  Future<bool> seedIfNeeded() async {
    if (_prefs.getBool(_kDataSeeded) == true) {
      _log.d('Seed deja effectue, skip');
      return false;
    }

    final sw = Stopwatch()..start();

    // --- 1. Charger les JSON depuis les assets ---
    final stagesJson = await _loadJsonList('$_kAssetsBase/stages.json');
    final poisJson = await _loadJsonList('$_kAssetsBase/pois.json');
    final gpxContent = await rootBundle.loadString('$_kAssetsBase/track.gpx');

    // --- 2. Parser le GPX ---
    final gpxResult = GpxParser.parse(gpxContent);
    final allPoints = gpxResult.allTrackPoints;

    // --- 3. Simplifier la trace via Douglas-Peucker ---
    final trekPoints = allPoints
        .map((p) => trek.TrackPoint(
              lat: p.lat,
              lng: p.lng,
              elevation: p.altitude,
            ))
        .toList();

    final simplified = DouglasPeucker.simplify(trekPoints);

    // --- 4. Batch insert stages ---
    final stagesDao = StagesDao(_db);
    final stageCompanions = stagesJson.map((s) {
      final json = s as Map<String, dynamic>;
      return StagesCompanion(
        trailId: Value(json['trailId'] as String),
        stageNumber: Value(json['stageNumber'] as int),
        name: Value(json['nameFr'] as String),
        distanceKm: Value((json['distanceKm'] as num).toDouble()),
        elevationGainM: Value(json['elevationGainM'] as int),
        elevationLossM: Value(json['elevationLossM'] as int),
        description: Value(json['descriptionFr'] as String? ?? ''),
        startLat: Value((json['startLat'] as num).toDouble()),
        startLng: Value((json['startLng'] as num).toDouble()),
        endLat: Value((json['endLat'] as num).toDouble()),
        endLng: Value((json['endLng'] as num).toDouble()),
        difficulty: Value(json['difficulty'] as String? ?? 'moderate'),
      );
    }).toList();
    await stagesDao.insertAll(stageCompanions);

    // --- 5. Batch insert POIs ---
    final poisDao = PoisDao(_db);
    final poiCompanions = poisJson.map((p) {
      final json = p as Map<String, dynamic>;
      return PoisCompanion(
        trailId: const Value(_kTrailId),
        stageNumber: Value(json['stageNumber'] as int),
        name: Value(json['nameFr'] as String),
        description: Value(json['descriptionFr'] as String? ?? ''),
        type: Value(json['type'] as String),
        lat: Value((json['lat'] as num).toDouble()),
        lng: Value((json['lng'] as num).toDouble()),
        altitudeM: Value(json['altitudeM'] as int? ?? 0),
      );
    }).toList();
    await poisDao.insertAll(poiCompanions);

    // --- 6. Insert GPX track + points ---
    final gpxTracksDao = TrailGpxTracksDao(_db);
    await gpxTracksDao.insertOrReplace(
      const TrailGpxTracksCompanion(
        id: Value(_kTrailId),
        itineraryId: Value(_kTrailId),
        name: Value('Mare a Mare Centre'),
      ),
    );

    final gpxPointsDao = TrailGpxPointsDao(_db);
    for (var i = 0; i < simplified.length; i++) {
      final pt = simplified[i];
      await gpxPointsDao.insertOrReplace(
        TrailGpxPointsCompanion(
          trackId: const Value(_kTrailId),
          lat: Value(pt.lat),
          lng: Value(pt.lng),
          elevation: Value(pt.elevation),
          sequenceIndex: Value(i),
        ),
      );
    }

    // --- 8. Charger les fiches conseils ---
    final allTips = <TipCard>[];
    for (final assetPath in _kTipAssets) {
      try {
        final tipsJson = await _loadJsonList(assetPath);
        final tips = tipsJson
            .map((t) => TipCard.fromJson(t as Map<String, dynamic>))
            .toList();
        allTips.addAll(tips);
      } catch (e) {
        _log.w('Tip asset $assetPath non trouve ou invalide: $e');
      }
    }
    _log.d('Fiches conseils chargees: ${allTips.length}');

    // --- 7. Marquer comme seed ---
    await _prefs.setBool(_kDataSeeded, true);

    sw.stop();
    _log.i(
      'Seed termine: ${stageCompanions.length} etapes, '
      '${poiCompanions.length} POIs, '
      '${simplified.length} points GPX '
      '(${allPoints.length} bruts -> ${simplified.length} simplifies) '
      'en ${sw.elapsedMilliseconds}ms',
    );

    return true;
  }

  /// Charge et decode un fichier JSON liste depuis les assets.
  Future<List<dynamic>> _loadJsonList(String path) async {
    final content = await rootBundle.loadString(path);
    return json.decode(content) as List<dynamic>;
  }
}
