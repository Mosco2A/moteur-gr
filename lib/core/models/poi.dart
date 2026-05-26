import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/database.dart';

part 'poi.freezed.dart';
part 'poi.g.dart';

/// Types de points d'interet supportes par le moteur.
enum PoiType {
  shelter,
  water,
  viewpoint,
  campsite,
  restaurant,
  emergency,
  danger,
  shop;

  /// Conversion depuis string (nom de l'enum)
  static PoiType fromString(String value) {
    return PoiType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PoiType.viewpoint,
    );
  }
}

/// Modele immutable representant un point d'interet.
///
/// Convertible depuis/vers la table Drift Pois
/// et depuis JSON (chargement initial des donnees).
@freezed
class PoiModel with _$PoiModel {
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

    /// Type de POI
    required PoiType type,

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
      type: PoiType.fromString(row.type),
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
      type: Value(type.name),
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
