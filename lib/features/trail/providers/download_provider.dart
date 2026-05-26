import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/pois_dao.dart';
import '../../../core/data/daos/stages_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/providers/database_provider.dart';

/// Notifier pour le chargement des donnees d'un sentier.
///
/// Charge les donnees JSON depuis les assets Flutter
/// et les insere dans la base Drift locale.
/// Utilise pour l'initialisation offline-first.
class DownloadNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Etat initial : rien a faire
  }

  /// Charge les donnees d'un sentier depuis les assets JSON
  ///
  /// [trailId] : identifiant du sentier a charger
  /// [assetPath] : chemin vers le fichier JSON dans les assets
  Future<void> loadTrailData(String trailId, String assetPath) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseProvider);
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      // Charger les etapes
      final stagesJson = data['stages'] as List<dynamic>? ?? [];
      final stagesDao = StagesDao(db);
      await stagesDao.deleteByTrailId(trailId);

      final stageCompanions = stagesJson.map((s) {
        final stage = s as Map<String, dynamic>;
        return StagesCompanion(
          trailId: Value(trailId),
          stageNumber: Value(stage['stageNumber'] as int),
          name: Value(stage['name'] as String),
          distanceKm: Value((stage['distanceKm'] as num).toDouble()),
          elevationGainM: Value(stage['elevationGainM'] as int),
          elevationLossM: Value(stage['elevationLossM'] as int),
          description: Value(stage['description'] as String? ?? ''),
          startLat: Value((stage['startLat'] as num).toDouble()),
          startLng: Value((stage['startLng'] as num).toDouble()),
          endLat: Value((stage['endLat'] as num).toDouble()),
          endLng: Value((stage['endLng'] as num).toDouble()),
          difficulty: Value(stage['difficulty'] as String? ?? 'moderate'),
        );
      }).toList();

      await stagesDao.insertAll(stageCompanions);

      // Charger les POI
      final poisJson = data['pois'] as List<dynamic>? ?? [];
      final poisDao = PoisDao(db);
      await poisDao.deleteByTrailId(trailId);

      final poiCompanions = poisJson.map((p) {
        final poi = p as Map<String, dynamic>;
        return PoisCompanion(
          trailId: Value(trailId),
          stageNumber: Value(poi['stageNumber'] as int),
          name: Value(poi['name'] as String),
          description: Value(poi['description'] as String? ?? ''),
          type: Value(poi['type'] as String),
          lat: Value((poi['lat'] as num).toDouble()),
          lng: Value((poi['lng'] as num).toDouble()),
          altitudeM: Value(poi['altitudeM'] as int? ?? 0),
          openingHours: Value(poi['openingHours'] as String?),
        );
      }).toList();

      await poisDao.insertAll(poiCompanions);
    });
  }
}

/// Provider du notifier de telechargement
final downloadNotifierProvider =
    AsyncNotifierProvider<DownloadNotifier, void>(DownloadNotifier.new);
