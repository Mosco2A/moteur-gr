import 'package:freezed_annotation/freezed_annotation.dart';

import 'stage.dart';

part 'itinerary_day.freezed.dart';
part 'itinerary_day.g.dart';

/// Modele immutable representant une journee d'itineraire.
///
/// Contient les etapes prevues pour ce jour avec les totaux
/// (distance, denivele, duree estimee).
@freezed
class ItineraryDay with _$ItineraryDay {
  const ItineraryDay._();

  const factory ItineraryDay({
    /// Numero du jour (1-indexed)
    required int dayNumber,

    /// Liste des etapes prevues ce jour
    required List<Stage> stages,

    /// Distance totale en km pour ce jour
    required double totalDistance,

    /// Denivele total en metres pour ce jour
    required int totalElevation,

    /// Duree estimee en heures pour ce jour
    required double estimatedHours,
  }) = _ItineraryDay;

  /// Nombre d'etapes prevues ce jour
  int get stageCount => stages.length;

  /// Deserialisation depuis JSON
  factory ItineraryDay.fromJson(Map<String, dynamic> json) =>
      _$ItineraryDayFromJson(json);
}
