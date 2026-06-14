// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItineraryDay _$ItineraryDayFromJson(Map<String, dynamic> json) =>
    _ItineraryDay(
      dayNumber: (json['dayNumber'] as num).toInt(),
      stages: (json['stages'] as List<dynamic>)
          .map((e) => StageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistance: (json['totalDistance'] as num).toDouble(),
      totalElevation: (json['totalElevation'] as num).toInt(),
      estimatedHours: (json['estimatedHours'] as num).toDouble(),
    );

Map<String, dynamic> _$ItineraryDayToJson(_ItineraryDay instance) =>
    <String, dynamic>{
      'dayNumber': instance.dayNumber,
      'stages': instance.stages.map((e) => e.toJson()).toList(),
      'totalDistance': instance.totalDistance,
      'totalElevation': instance.totalElevation,
      'estimatedHours': instance.estimatedHours,
    };
