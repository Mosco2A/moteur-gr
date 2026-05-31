// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Trail _$TrailFromJson(Map<String, dynamic> json) => _Trail(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      tagline: json['tagline'] as String? ?? '',
      totalStages: (json['totalStages'] as num).toInt(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalElevationGain: (json['totalElevationGain'] as num).toInt(),
      region: json['region'] as String,
      country: json['country'] as String,
    );

Map<String, dynamic> _$TrailToJson(_Trail instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'displayName': instance.displayName,
      'tagline': instance.tagline,
      'totalStages': instance.totalStages,
      'totalDistanceKm': instance.totalDistanceKm,
      'totalElevationGain': instance.totalElevationGain,
      'region': instance.region,
      'country': instance.country,
    };
