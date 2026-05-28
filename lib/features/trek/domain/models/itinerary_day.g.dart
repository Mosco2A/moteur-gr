// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItineraryDayImpl _$$ItineraryDayImplFromJson(Map<String, dynamic> json) =>
    _$ItineraryDayImpl(
      dayNumber: (json['dayNumber'] as num).toInt(),
      stages: (json['stages'] as List<dynamic>)
          .map((e) => Stage.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistance: (json['totalDistance'] as num).toDouble(),
      totalElevation: (json['totalElevation'] as num).toInt(),
      estimatedHours: (json['estimatedHours'] as num).toDouble(),
    );

Map<String, dynamic> _$$ItineraryDayImplToJson(_$ItineraryDayImpl instance) =>
    <String, dynamic>{
      'dayNumber': instance.dayNumber,
      'stages': instance.stages,
      'totalDistance': instance.totalDistance,
      'totalElevation': instance.totalElevation,
      'estimatedHours': instance.estimatedHours,
    };
