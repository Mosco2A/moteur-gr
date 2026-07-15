// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_feasibility_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrailFeasibilityParams _$TrailFeasibilityParamsFromJson(
  Map<String, dynamic> json,
) => _TrailFeasibilityParams(
  altitudeFactor: (json['altitudeFactor'] as num).toDouble(),
  technicalFactor: (json['technicalFactor'] as num).toDouble(),
  heatFactor: (json['heatFactor'] as num).toDouble(),
  snowFactor: (json['snowFactor'] as num).toDouble(),
  customConditions:
      (json['customConditions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  recommendationTemplates:
      (json['recommendationTemplates'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$TrailFeasibilityParamsToJson(
  _TrailFeasibilityParams instance,
) => <String, dynamic>{
  'altitudeFactor': instance.altitudeFactor,
  'technicalFactor': instance.technicalFactor,
  'heatFactor': instance.heatFactor,
  'snowFactor': instance.snowFactor,
  'customConditions': instance.customConditions,
  'recommendationTemplates': instance.recommendationTemplates,
};
