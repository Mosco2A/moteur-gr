// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrackPointImpl _$$TrackPointImplFromJson(Map<String, dynamic> json) =>
    _$TrackPointImpl(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      elevation: (json['elevation'] as num).toDouble(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$TrackPointImplToJson(_$TrackPointImpl instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'elevation': instance.elevation,
      'timestamp': instance.timestamp?.toIso8601String(),
    };
