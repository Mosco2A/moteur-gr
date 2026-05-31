import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_config.freezed.dart';
part 'itinerary_config.g.dart';

/// Configuration d'un itineraire multi-jours.
///
/// Parametres de planification fournis par l'utilisateur :
/// distance max/jour, heures max/jour, date de depart, niveau de difficulte.
@freezed
abstract class ItineraryConfig with _$ItineraryConfig {
  const ItineraryConfig._();

  const factory ItineraryConfig({
    /// Distance maximale par jour en km
    required double maxKmPerDay,

    /// Duree maximale de marche par jour en heures
    required double maxHoursPerDay,

    /// Date de depart prevue
    required DateTime startDate,

    /// Niveau de difficulte (String extensible, ex: easy, moderate, hard)
    required String difficultyLevel,
  }) = _ItineraryConfig;

  /// Deserialisation depuis JSON
  factory ItineraryConfig.fromJson(Map<String, dynamic> json) =>
      _$ItineraryConfigFromJson(json);
}
