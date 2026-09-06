import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/trail_config.dart';
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

/// Chargement initial des donnees depuis les assets.
///
/// Idempotent : ne fait rien si les donnees ont deja ete chargees
/// (flag [_kDataSeeded] dans SharedPreferences).
///
/// Charge les stages (JSON), POIs (JSON), et GPX (parse + simplification
/// Douglas-Peucker), puis insere en batch dans Drift.
class SeedDataLoader {
  /// Cle SharedPreferences du flag de seed.
  ///
  /// Publique pour que l'amorce (`appBootstrapProvider`) puisse la reinitialiser
  /// et forcer un re-seed a chaque lancement tant que la DB est in-memory.
  static const String kDataSeededPrefsKey = 'data_seeded';

  SeedDataLoader({
    required AppDatabase db,
    required SharedPreferences prefs,
    required TrailConfig trailConfig,
  })  : _db = db,
        _prefs = prefs,
        _trailConfig = trailConfig;

  final AppDatabase _db;
  final SharedPreferences _prefs;

  /// Config du sentier actif : fournit trailId, racine des assets
  /// de seed et fiches conseils. Aucun sentier n'est hardcode ici.
  final TrailConfig _trailConfig;

  /// Charge les donnees initiales si ce n'est pas deja fait.
  ///
  /// Retourne true si le seed a ete effectue,
  /// false si les donnees etaient deja presentes.
  Future<bool> seedIfNeeded() async {
    if (_prefs.getBool(kDataSeededPrefsKey) == true) {
      _log.d('Seed deja effectue, skip');
      return false;
    }

    final assetsBase = _trailConfig.seedAssetsBase;
    if (assetsBase == null) {
      _log.d('Pas de seed assets pour ce sentier, skip');
      return false;
    }
    final trailId = _trailConfig.id;

    final sw = Stopwatch()..start();

    // --- 1. Charger les JSON depuis les assets ---
    final stagesJson = await _loadJsonList('$assetsBase/stages.json');
    final poisJson = await _loadJsonList('$assetsBase/pois.json');
    final gpxContent = await rootBundle.loadString('$assetsBase/track.gpx');

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
        // Champ riche OPTIONNEL (parite GR20) : duree estimee par etape en
        // minutes, fournie par la donnee du sentier. Absente -> colonne NULL
        // (l'affichage retombe sur une estimation, cf. stageDurationMinutes).
        estimatedDurationMinutes: json['estimatedDurationMinutes'] == null
            ? const Value.absent()
            : Value((json['estimatedDurationMinutes'] as num).round()),
        // Champs riches OPTIONNELS (parite GR20) : noms depart/arrivee de
        // l'etape, fournis par la donnee du sentier. Absents -> colonnes NULL
        // (l'affichage retombe sur le nom de l'etape, cf. fiche etape).
        departureName: json['departureName'] == null
            ? const Value.absent()
            : Value(json['departureName'] as String),
        arrivalName: json['arrivalName'] == null
            ? const Value.absent()
            : Value(json['arrivalName'] as String),
      );
    }).toList();
    await stagesDao.insertAll(stageCompanions);

    // --- 5. Batch insert POIs ---
    final poisDao = PoisDao(_db);
    final poiCompanions = poisJson.map((p) {
      final json = p as Map<String, dynamic>;
      return PoisCompanion(
        trailId: Value(trailId),
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
      TrailGpxTracksCompanion(
        id: Value(trailId),
        itineraryId: Value(trailId),
        name: Value(_trailConfig.name),
      ),
    );

    // Insertion des points GPX en BATCH (une seule transaction) plutot qu'un
    // insert awaite par point. Sur la DB in-memory de l'isolate UI, la boucle
    // serie bloquait le thread principal proportionnellement au nombre de
    // points (freeze visible au demarrage / a l'ouverture des ecrans data).
    final gpxPointsDao = TrailGpxPointsDao(_db);
    final gpxCompanions = <TrailGpxPointsCompanion>[
      for (var i = 0; i < simplified.length; i++)
        TrailGpxPointsCompanion(
          trackId: Value(trailId),
          lat: Value(simplified[i].lat),
          lng: Value(simplified[i].lng),
          elevation: Value(simplified[i].elevation),
          sequenceIndex: Value(i),
        ),
    ];
    await gpxPointsDao.insertAll(gpxCompanions);

    // --- 8. Charger les fiches conseils (depuis la config sentier) ---
    final allTips = <TipCard>[];
    for (final assetPath in _trailConfig.tipAssetPaths) {
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
    await _prefs.setBool(kDataSeededPrefsKey, true);

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
