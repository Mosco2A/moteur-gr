// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrackPoint _$TrackPointFromJson(Map<String, dynamic> json) => _TrackPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      distanceFromStart: (json['distanceFromStart'] as num).toDouble(),
    );

Map<String, dynamic> _$TrackPointToJson(_TrackPoint instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'altitude': instance.altitude,
      'distanceFromStart': instance.distanceFromStart,
    };
