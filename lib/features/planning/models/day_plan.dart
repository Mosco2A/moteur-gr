import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/stage.dart';

part 'day_plan.freezed.dart';
part 'day_plan.g.dart';

/// Modèle représentant le plan d'une journée de trek.
///
/// Contient la liste des étapes prévues pour ce jour,
/// les totaux calculés (distance, dénivelé, durée),
/// et un flag indiquant si c'est un jour de repos.
@freezed
abstract class DayPlan with _$DayPlan {
  const DayPlan._();

  const factory DayPlan({
    /// Numéro du jour (1-indexed)
    required int dayNumber,

    /// Liste des étapes prévues ce jour
    required List<StageModel> stages,

    /// Distance totale en km pour ce jour
    required double totalDistanceKm,

    /// Dénivelé positif total en mètres pour ce jour
    required int totalElevationGainM,

    /// Durée estimée en heures (distance/4 + D+/400)
    required double estimatedDurationHours,

    /// True si c'est un jour de repos (aucune étape)
    required bool isRestDay,
  }) = _DayPlan;

  /// Nombre d'étapes prévues ce jour
  int get stageCount => stages.length;

  /// Désérialisation depuis JSON
  factory DayPlan.fromJson(Map<String, dynamic> json) =>
      _$DayPlanFromJson(json);
}
