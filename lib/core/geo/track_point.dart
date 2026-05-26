import 'package:freezed_annotation/freezed_annotation.dart';

part 'track_point.freezed.dart';
part 'track_point.g.dart';

/// Point GPS sur un trace de sentier.
///
/// Represente un point unique avec coordonnees, altitude
/// et distance cumulee depuis le debut du trace.
@freezed
class TrackPoint with _$TrackPoint {
  const TrackPoint._();

  const factory TrackPoint({
    /// Latitude en degres decimaux
    required double lat,

    /// Longitude en degres decimaux
    required double lng,

    /// Altitude en metres
    required double altitude,

    /// Distance cumulee depuis le debut du trace, en metres
    required double distanceFromStart,
  }) = _TrackPoint;

  /// Deserialisation depuis JSON
  factory TrackPoint.fromJson(Map<String, dynamic> json) =>
      _$TrackPointFromJson(json);
}
