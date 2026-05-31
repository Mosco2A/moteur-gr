import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/models/stage.dart';

part 'itinerary_day.freezed.dart';
part 'itinerary_day.g.dart';

/// Modele immutable representant une journee d'itineraire.
///
/// Regroupe les etapes prevues pour un jour donne,
/// avec les totaux calcules (distance, denivele, duree estimee).
@freezed
abstract class ItineraryDay with _$ItineraryDay {
  const ItineraryDay._();

  const factory ItineraryDay({
    /// Numero du jour (1-indexed)
    required int dayNumber,

    /// Liste des etapes prevues ce jour
    required List<StageModel> stages,

    /// Distance totale en km pour ce jour
    required double totalDistance,

    /// Denivele positif total en metres pour ce jour
    required int totalElevation,

    /// Duree estimee en heures
    required double estimatedHours,
  }) = _ItineraryDay;

  /// Nombre d'etapes prevues ce jour
  int get stageCount => stages.length;

  /// Deserialisation depuis JSON
  factory ItineraryDay.fromJson(Map<String, dynamic> json) =>
      _$ItineraryDayFromJson(json);
}
