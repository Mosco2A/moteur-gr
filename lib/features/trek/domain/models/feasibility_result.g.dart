// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feasibility_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeasibilityResultImpl _$$FeasibilityResultImplFromJson(
        Map<String, dynamic> json) =>
    _$FeasibilityResultImpl(
      score: (json['score'] as num).toDouble(),
      recommendedDays: (json['recommendedDays'] as num).toInt(),
      warnings:
          (json['warnings'] as List<dynamic>).map((e) => e as String).toList(),
      isGroupAssessment: json['isGroupAssessment'] as bool? ?? false,
      worstProfileIndex: (json['worstProfileIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$FeasibilityResultImplToJson(
        _$FeasibilityResultImpl instance) =>
    <String, dynamic>{
      'score': instance.score,
      'recommendedDays': instance.recommendedDays,
      'warnings': instance.warnings,
      'isGroupAssessment': instance.isGroupAssessment,
      'worstProfileIndex': instance.worstProfileIndex,
    };
