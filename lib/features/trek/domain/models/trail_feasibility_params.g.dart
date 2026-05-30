// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_feasibility_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrailFeasibilityParamsImpl _$$TrailFeasibilityParamsImplFromJson(
        Map<String, dynamic> json) =>
    _$TrailFeasibilityParamsImpl(
      altitudeFactor: (json['altitudeFactor'] as num).toDouble(),
      technicalFactor: (json['technicalFactor'] as num).toDouble(),
      heatFactor: (json['heatFactor'] as num).toDouble(),
      snowFactor: (json['snowFactor'] as num).toDouble(),
      customConditions: (json['customConditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recommendationTemplates:
          (json['recommendationTemplates'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, e as String),
              ) ??
              const {},
    );

Map<String, dynamic> _$$TrailFeasibilityParamsImplToJson(
        _$TrailFeasibilityParamsImpl instance) =>
    <String, dynamic>{
      'altitudeFactor': instance.altitudeFactor,
      'technicalFactor': instance.technicalFactor,
      'heatFactor': instance.heatFactor,
      'snowFactor': instance.snowFactor,
      'customConditions': instance.customConditions,
      'recommendationTemplates': instance.recommendationTemplates,
    };
