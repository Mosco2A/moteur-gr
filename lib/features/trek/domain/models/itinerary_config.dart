import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_config.freezed.dart';
part 'itinerary_config.g.dart';

/// Configuration d'un itineraire de trek.
///
/// Definit les contraintes de planification (km/jour, heures/jour)
/// et la date de depart. Le niveau de difficulte est un String libre
/// pour extensibilite (#81752).
@freezed
class ItineraryConfig with _$ItineraryConfig {
  const ItineraryConfig._();

  const factory ItineraryConfig({
    /// Distance maximale par jour en km
    required double maxKmPerDay,

    /// Duree maximale de marche par jour en heures
    required double maxHoursPerDay,

    /// Date de depart du trek
    required DateTime startDate,

    /// Niveau de difficulte — String libre, pas enum (#81752)
    /// Valeurs courantes : easy, moderate, hard, extreme
    @Default('moderate') String difficultyLevel,
  }) = _ItineraryConfig;

  /// Deserialisation depuis JSON
  factory ItineraryConfig.fromJson(Map<String, dynamic> json) =>
      _$ItineraryConfigFromJson(json);
}
