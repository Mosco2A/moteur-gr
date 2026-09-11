// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'past_hike.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PastHike _$PastHikeFromJson(Map<String, dynamic> json) => _PastHike(
  id: (json['id'] as num?)?.toInt() ?? 0,
  date: DateTime.parse(json['date'] as String),
  days: (json['days'] as num?)?.toInt() ?? 1,
  avgWalkHoursPerDay: (json['avgWalkHoursPerDay'] as num?)?.toDouble() ?? 0,
  totalElevationGain: (json['totalElevationGain'] as num?)?.toInt() ?? 0,
  totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$PastHikeToJson(_PastHike instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'days': instance.days,
  'avgWalkHoursPerDay': instance.avgWalkHoursPerDay,
  'totalElevationGain': instance.totalElevationGain,
  'totalDistanceKm': instance.totalDistanceKm,
};
