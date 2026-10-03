// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StageVariant _$StageVariantFromJson(Map<String, dynamic> json) =>
    _StageVariant(
      id: json['id'] as String,
      etapeBaseId: json['etapeBaseId'] as String,
      label: json['label'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      deniveleM: (json['deniveleM'] as num).toDouble(),
      difficulte: $enumDecode(_$VariantDifficultyEnumMap, json['difficulte']),
      traceGpxRef: json['traceGpxRef'] as String,
      isOfficielle: json['isOfficielle'] as bool? ?? false,
    );

Map<String, dynamic> _$StageVariantToJson(_StageVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'etapeBaseId': instance.etapeBaseId,
      'label': instance.label,
      'distanceKm': instance.distanceKm,
      'deniveleM': instance.deniveleM,
      'difficulte': _$VariantDifficultyEnumMap[instance.difficulte]!,
      'traceGpxRef': instance.traceGpxRef,
      'isOfficielle': instance.isOfficielle,
    };

const _$VariantDifficultyEnumMap = {
  VariantDifficulty.facile: 'facile',
  VariantDifficulty.moyen: 'moyen',
  VariantDifficulty.difficile: 'difficile',
};

_VariantSelection _$VariantSelectionFromJson(Map<String, dynamic> json) =>
    _VariantSelection(
      selectionParEtape:
          (json['selectionParEtape'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
    );

Map<String, dynamic> _$VariantSelectionToJson(_VariantSelection instance) =>
    <String, dynamic>{'selectionParEtape': instance.selectionParEtape};
