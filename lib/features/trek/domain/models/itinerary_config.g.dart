// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItineraryConfigImpl _$$ItineraryConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$ItineraryConfigImpl(
      maxKmPerDay: (json['maxKmPerDay'] as num).toDouble(),
      maxHoursPerDay: (json['maxHoursPerDay'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      difficultyLevel: json['difficultyLevel'] as String,
    );

Map<String, dynamic> _$$ItineraryConfigImplToJson(
        _$ItineraryConfigImpl instance) =>
    <String, dynamic>{
      'maxKmPerDay': instance.maxKmPerDay,
      'maxHoursPerDay': instance.maxHoursPerDay,
      'startDate': instance.startDate.toIso8601String(),
      'difficultyLevel': instance.difficultyLevel,
    };
