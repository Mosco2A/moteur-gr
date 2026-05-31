// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItineraryConfig _$ItineraryConfigFromJson(Map<String, dynamic> json) =>
    _ItineraryConfig(
      maxKmPerDay: (json['maxKmPerDay'] as num).toDouble(),
      maxHoursPerDay: (json['maxHoursPerDay'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      difficultyLevel: json['difficultyLevel'] as String,
    );

Map<String, dynamic> _$ItineraryConfigToJson(_ItineraryConfig instance) =>
    <String, dynamic>{
      'maxKmPerDay': instance.maxKmPerDay,
      'maxHoursPerDay': instance.maxHoursPerDay,
      'startDate': instance.startDate.toIso8601String(),
      'difficultyLevel': instance.difficultyLevel,
    };
