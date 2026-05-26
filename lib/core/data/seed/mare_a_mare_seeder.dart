import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../database.dart';
import '../daos/trail_meta_dao.dart';
import '../daos/trail_itineraries_dao.dart';
import '../daos/trail_stages_dao.dart';
import '../daos/trail_accommodations_dao.dart';
import '../daos/trail_pois_dao.dart';

/// Seeder pour le sentier Mare a Mare Centre.
///
/// Lit le JSON complet depuis les assets et insere les donnees
/// dans les tables Drift dans l'ordre FK :
/// trail_meta -> trail_itineraries -> trail_stages -> trail_accommodations -> trail_pois.
class MareAMareSeeder {
  final AppDatabase _db;

  MareAMareSeeder(this._db);

  // Accesseurs DAOs
  TrailMetaDao get _metaDao => TrailMetaDao(_db);
  TrailItinerariesDao get _itinerariesDao => TrailItinerariesDao(_db);
  TrailStagesDao get _stagesDao => TrailStagesDao(_db);
  TrailAccommodationsDao get _accommodationsDao => TrailAccommodationsDao(_db);
  TrailPoisDao get _poisDao => TrailPoisDao(_db);

  /// Insere les donnees depuis un fichier asset JSON.
  ///
  /// [assetPath] chemin vers le fichier dans les assets Flutter
  /// (ex: 'assets/data/mare_a_mare_centre.json').
  Future<void> seedFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    await seedFromJson(jsonData);
  }

  /// Insere les donnees depuis un Map JSON deja parse.
  ///
  /// Ordre d'insertion respecte les FK :
  /// 1. trail_meta
  /// 2. trail_itineraries (FK -> trail_meta)
  /// 3. trail_stages (FK -> trail_itineraries)
  /// 4. trail_accommodations (FK -> trail_stages)
  /// 5. trail_pois (FK -> trail_stages)
  Future<void> seedFromJson(Map<String, dynamic> jsonData) async {
    // 1. Trail meta
    final meta = jsonData['trail_meta'] as Map<String, dynamic>;
    await _metaDao.insertOrReplace(TrailMetaCompanion(
      id: Value(meta['id'] as String),
      code: Value(meta['code'] as String),
      dataVersion: Value(meta['dataVersion'] as int),
      status: Value(meta['status'] as String? ?? 'active'),
    ));

    // 2. Itineraires
    final itineraries = jsonData['itineraries'] as List<dynamic>;
    for (final it in itineraries) {
      final m = it as Map<String, dynamic>;
      await _itinerariesDao.insertOrReplace(TrailItinerariesCompanion(
        id: Value(m['id'] as String),
        trailId: Value(m['trailId'] as String),
        code: Value(m['code'] as String),
        nameFr: Value(m['nameFr'] as String),
        nameEn: Value(m['nameEn'] as String),
        nameDe: Value(m['nameDe'] as String),
        nameIt: Value(m['nameIt'] as String),
        nameEs: Value(m['nameEs'] as String),
        distanceKm: Value((m['distanceKm'] as num).toDouble()),
        elevationGain: Value(m['elevationGain'] as int),
        stageCount: Value(m['stageCount'] as int),
      ));
    }

    // 3. Etapes
    final stages = jsonData['stages'] as List<dynamic>;
    for (final s in stages) {
      final m = s as Map<String, dynamic>;
      await _stagesDao.insertOrReplace(TrailStagesCompanion(
        id: Value(m['id'] as String),
        itineraryId: Value(m['itineraryId'] as String),
        stageNumber: Value(m['stageNumber'] as int),
        nameFr: Value(m['nameFr'] as String),
        nameEn: Value(m['nameEn'] as String),
        nameDe: Value(m['nameDe'] as String),
        nameIt: Value(m['nameIt'] as String),
        nameEs: Value(m['nameEs'] as String),
        startLat: Value((m['startLat'] as num).toDouble()),
        startLng: Value((m['startLng'] as num).toDouble()),
        endLat: Value((m['endLat'] as num).toDouble()),
        endLng: Value((m['endLng'] as num).toDouble()),
        distanceKm: Value((m['distanceKm'] as num).toDouble()),
        elevationGain: Value(m['elevationGain'] as int),
        elevationLoss: Value(m['elevationLoss'] as int),
        durationMinutes: Value(m['durationMinutes'] as int),
        difficulty: Value(m['difficulty'] as String),
      ));
    }

    // 4. Hebergements
    final accommodations = jsonData['accommodations'] as List<dynamic>;
    for (final a in accommodations) {
      final m = a as Map<String, dynamic>;
      await _accommodationsDao.insertOrReplace(TrailAccommodationsCompanion(
        id: Value(m['id'] as String),
        stageId: Value(m['stageId'] as String),
        nameFr: Value(m['nameFr'] as String),
        nameEn: Value(m['nameEn'] as String),
        nameDe: Value(m['nameDe'] as String),
        nameIt: Value(m['nameIt'] as String),
        nameEs: Value(m['nameEs'] as String),
        type: Value(m['type'] as String),
        lat: Value((m['lat'] as num).toDouble()),
        lng: Value((m['lng'] as num).toDouble()),
        phone: Value(m['phone'] as String?),
        email: Value(m['email'] as String?),
        website: Value(m['website'] as String?),
        capacity: Value(m['capacity'] as int?),
        priceRange: Value(m['priceRange'] as String?),
        bookingUrl: Value(m['bookingUrl'] as String?),
      ));
    }

    // 5. Points d'interet
    final pois = jsonData['pois'] as List<dynamic>;
    for (final p in pois) {
      final m = p as Map<String, dynamic>;
      await _poisDao.insertOrReplace(TrailPoisCompanion(
        id: Value(m['id'] as String),
        stageId: Value(m['stageId'] as String),
        nameFr: Value(m['nameFr'] as String),
        nameEn: Value(m['nameEn'] as String),
        nameDe: Value(m['nameDe'] as String),
        nameIt: Value(m['nameIt'] as String),
        nameEs: Value(m['nameEs'] as String),
        descriptionFr: Value(m['descriptionFr'] as String?),
        descriptionEn: Value(m['descriptionEn'] as String?),
        descriptionDe: Value(m['descriptionDe'] as String?),
        descriptionIt: Value(m['descriptionIt'] as String?),
        descriptionEs: Value(m['descriptionEs'] as String?),
        type: Value(m['type'] as String),
        lat: Value((m['lat'] as num).toDouble()),
        lng: Value((m['lng'] as num).toDouble()),
        elevation: Value(m['elevation'] != null ? (m['elevation'] as num).toDouble() : null),
      ));
    }
  }
}
