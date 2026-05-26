// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrackPointImpl _$$TrackPointImplFromJson(Map<String, dynamic> json) =>
    _$TrackPointImpl(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      distanceFromStart: (json['distanceFromStart'] as num).toDouble(),
    );

Map<String, dynamic> _$$TrackPointImplToJson(_$TrackPointImpl instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'altitude': instance.altitude,
      'distanceFromStart': instance.distanceFromStart,
    };
