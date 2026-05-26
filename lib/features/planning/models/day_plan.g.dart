// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DayPlanImpl _$$DayPlanImplFromJson(Map<String, dynamic> json) =>
    _$DayPlanImpl(
      dayNumber: (json['dayNumber'] as num).toInt(),
      stages: (json['stages'] as List<dynamic>)
          .map((e) => StageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalElevationGainM: (json['totalElevationGainM'] as num).toInt(),
      estimatedDurationHours:
          (json['estimatedDurationHours'] as num).toDouble(),
      isRestDay: json['isRestDay'] as bool,
    );

Map<String, dynamic> _$$DayPlanImplToJson(_$DayPlanImpl instance) =>
    <String, dynamic>{
      'dayNumber': instance.dayNumber,
      'stages': instance.stages,
      'totalDistanceKm': instance.totalDistanceKm,
      'totalElevationGainM': instance.totalElevationGainM,
      'estimatedDurationHours': instance.estimatedDurationHours,
      'isRestDay': instance.isRestDay,
    };
