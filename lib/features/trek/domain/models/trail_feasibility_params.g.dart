// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_feasibility_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrailFeasibilityParamsImpl _$$TrailFeasibilityParamsImplFromJson(
        Map<String, dynamic> json) =>
    _$TrailFeasibilityParamsImpl(
      altitudeFactor: (json['altitudeFactor'] as num?)?.toDouble() ?? 1.0,
      technicalFactor: (json['technicalFactor'] as num?)?.toDouble() ?? 1.0,
      heatFactor: (json['heatFactor'] as num?)?.toDouble() ?? 1.0,
      snowFactor: (json['snowFactor'] as num?)?.toDouble() ?? 1.0,
      customConditions:
          (json['customConditions'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toDouble()),
              ) ??
              const {},
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
