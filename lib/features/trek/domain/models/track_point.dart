import 'package:freezed_annotation/freezed_annotation.dart';

part 'track_point.freezed.dart';
part 'track_point.g.dart';

/// Point GPS enregistre pendant un trek.
///
/// Represente une position unique avec coordonnees,
/// altitude et horodatage.
@freezed
class TrackPoint with _$TrackPoint {
  const factory TrackPoint({
    /// Latitude en degres decimaux
    required double lat,

    /// Longitude en degres decimaux
    required double lng,

    /// Altitude en metres
    required double elevation,

    /// Horodatage du point (nullable si import GPX sans temps)
    DateTime? timestamp,
  }) = _TrackPoint;

  /// Deserialisation depuis JSON
  factory TrackPoint.fromJson(Map<String, dynamic> json) =>
      _$TrackPointFromJson(json);
}
