import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/database.dart';

part 'user_progress.freezed.dart';

/// Modele immutable representant la progression utilisateur.
///
/// Convertible depuis/vers la table Drift UserProgressEntries.
/// Pas de fromJson car les donnees viennent uniquement de la DB locale.
@freezed
class UserProgressModel with _$UserProgressModel {
  const UserProgressModel._();

  const factory UserProgressModel({
    /// Cle primaire DB (0 si pas encore insere)
    @Default(0) int id,

    /// Identifiant du sentier
    required String trailId,

    /// Etape courante (1-indexed)
    @Default(1) int currentStage,

    /// Distance totale parcourue en km
    @Default(0.0) double totalDistanceWalkedKm,

    /// Denivele positif total cumule en metres
    @Default(0) int totalElevationGainedM,

    /// Temps total de marche en minutes
    @Default(0) int totalTimeMinutes,

    /// Sentier complete ou non
    @Default(false) bool isCompleted,

    /// Date de debut du sentier
    DateTime? startedAt,

    /// Date de fin du sentier
    DateTime? completedAt,
  }) = _UserProgressModel;

  /// Construit depuis une ligne Drift (table UserProgressEntry)
  factory UserProgressModel.fromDb(UserProgressEntry row) {
    return UserProgressModel(
      id: row.id,
      trailId: row.trailId,
      currentStage: row.currentStage,
      totalDistanceWalkedKm: row.totalDistanceWalkedKm,
      totalElevationGainedM: row.totalElevationGainedM,
      totalTimeMinutes: row.totalTimeMinutes,
      isCompleted: row.isCompleted,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
    );
  }

  /// Convertit vers un companion Drift pour insertion/update
  UserProgressEntriesCompanion toCompanion() {
    return UserProgressEntriesCompanion(
      trailId: Value(trailId),
      currentStage: Value(currentStage),
      totalDistanceWalkedKm: Value(totalDistanceWalkedKm),
      totalElevationGainedM: Value(totalElevationGainedM),
      totalTimeMinutes: Value(totalTimeMinutes),
      isCompleted: Value(isCompleted),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
    );
  }
}
