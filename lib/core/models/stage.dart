import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/database.dart';

part 'stage.freezed.dart';
part 'stage.g.dart';

/// Modele immutable representant une etape de sentier.
///
/// Convertible depuis/vers la table Drift Stages
/// et depuis JSON (chargement initial des donnees).
@freezed
class StageModel with _$StageModel {
  const StageModel._();

  const factory StageModel({
    /// Cle primaire DB (0 si pas encore insere)
    @Default(0) int id,

    /// Identifiant du sentier parent
    required String trailId,

    /// Numero de l'etape (1-indexed)
    required int stageNumber,

    /// Nom de l'etape
    required String name,

    /// Distance en km
    required double distanceKm,

    /// Denivele positif en metres
    required int elevationGainM,

    /// Denivele negatif en metres
    required int elevationLossM,

    /// Description textuelle
    @Default('') String description,

    /// Latitude du point de depart
    required double startLat,

    /// Longitude du point de depart
    required double startLng,

    /// Latitude du point d'arrivee
    required double endLat,

    /// Longitude du point d'arrivee
    required double endLng,

    /// Difficulte (easy, moderate, hard, extreme)
    @Default('moderate') String difficulty,
  }) = _StageModel;

  /// Construit depuis une ligne Drift (table Stage)
  factory StageModel.fromDb(Stage row) {
    return StageModel(
      id: row.id,
      trailId: row.trailId,
      stageNumber: row.stageNumber,
      name: row.name,
      distanceKm: row.distanceKm,
      elevationGainM: row.elevationGainM,
      elevationLossM: row.elevationLossM,
      description: row.description,
      startLat: row.startLat,
      startLng: row.startLng,
      endLat: row.endLat,
      endLng: row.endLng,
      difficulty: row.difficulty,
    );
  }

  /// Convertit vers un companion Drift pour insertion
  StagesCompanion toCompanion() {
    return StagesCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      name: Value(name),
      distanceKm: Value(distanceKm),
      elevationGainM: Value(elevationGainM),
      elevationLossM: Value(elevationLossM),
      description: Value(description),
      startLat: Value(startLat),
      startLng: Value(startLng),
      endLat: Value(endLat),
      endLng: Value(endLng),
      difficulty: Value(difficulty),
    );
  }

  /// Deserialisation depuis JSON
  factory StageModel.fromJson(Map<String, dynamic> json) =>
      _$StageModelFromJson(json);
}
