import 'package:freezed_annotation/freezed_annotation.dart';

part 'past_hike.freezed.dart';
part 'past_hike.g.dart';

/// Une rando passee « notable » (interview des 5 dernieres randos) — StepWays
/// LOT 4, Ph3. La faisabilite en DEDUIT le niveau reel (rythme, endurance
/// multi-jours, habitude du D+) au lieu d'un auto-label biaise.
///
/// [id] = 0 tant que la rando n'est pas persistee (auto-increment Drift).
@freezed
abstract class PastHike with _$PastHike {
  const PastHike._();

  const factory PastHike({
    /// Cle DB (0 si pas encore inseree).
    @Default(0) int id,

    /// Date de la rando (recence).
    required DateTime date,

    /// Nombre de jours.
    @Default(1) int days,

    /// Temps moyen de marche PAR JOUR, en heures.
    @Default(0) double avgWalkHoursPerDay,

    /// Denivele positif TOTAL, en metres.
    @Default(0) int totalElevationGain,

    /// Distance TOTALE, en km.
    @Default(0) double totalDistanceKm,
  }) = _PastHike;

  /// Deserialisation depuis JSON (miroir cloud / prefs).
  factory PastHike.fromJson(Map<String, dynamic> json) =>
      _$PastHikeFromJson(json);

  /// Distance moyenne PAR JOUR, en km (0 si nb de jours invalide).
  double get avgDistancePerDayKm => days > 0 ? totalDistanceKm / days : 0;

  /// Denivele positif moyen PAR JOUR, en metres (0 si nb de jours invalide).
  double get avgElevationGainPerDay =>
      days > 0 ? totalElevationGain / days : 0;
}
