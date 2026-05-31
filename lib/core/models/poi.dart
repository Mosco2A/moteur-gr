import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/database.dart';

part 'poi.freezed.dart';
part 'poi.g.dart';

/// Modele immutable representant un point d'interet.
///
/// Le type est un String extensible (ex: 'water', 'refuge', 'danger').
/// Utiliser PoiTypeConfig.getStyle(type) pour obtenir icone/couleur.
/// Convertible depuis/vers la table Drift Pois et depuis JSON.
@freezed
abstract class PoiModel with _$PoiModel {
  const PoiModel._();

  const factory PoiModel({
    /// Cle primaire DB (0 si pas encore insere)
    @Default(0) int id,

    /// Identifiant du sentier parent
    required String trailId,

    /// Numero de l'etape associee
    required int stageNumber,

    /// Nom du POI
    required String name,

    /// Description
    @Default('') String description,

    /// Type de POI (String extensible, ex: water, refuge, danger)
    required String type,

    /// Latitude
    required double lat,

    /// Longitude
    required double lng,

    /// Altitude en metres
    @Default(0) int altitudeM,

    /// Horaires d'ouverture (nullable)
    String? openingHours,
  }) = _PoiModel;

  /// Construit depuis une ligne Drift (table Poi)
  factory PoiModel.fromDb(Poi row) {
    return PoiModel(
      id: row.id,
      trailId: row.trailId,
      stageNumber: row.stageNumber,
      name: row.name,
      description: row.description,
      type: row.type,
      lat: row.lat,
      lng: row.lng,
      altitudeM: row.altitudeM,
      openingHours: row.openingHours,
    );
  }

  /// Convertit vers un companion Drift pour insertion
  PoisCompanion toCompanion() {
    return PoisCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      lat: Value(lat),
      lng: Value(lng),
      altitudeM: Value(altitudeM),
      openingHours: Value(openingHours),
    );
  }

  /// Deserialisation depuis JSON
  factory PoiModel.fromJson(Map<String, dynamic> json) =>
      _$PoiModelFromJson(json);
}
