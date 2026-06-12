// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variante_etape.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VarianteEtape _$VarianteEtapeFromJson(Map<String, dynamic> json) =>
    _VarianteEtape(
      id: json['id'] as String,
      etapeBaseId: json['etapeBaseId'] as String,
      label: json['label'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      deniveleM: (json['deniveleM'] as num).toDouble(),
      difficulte: $enumDecode(_$VarianteDifficulteEnumMap, json['difficulte']),
      traceGpxRef: json['traceGpxRef'] as String,
      isOfficielle: json['isOfficielle'] as bool? ?? false,
    );

Map<String, dynamic> _$VarianteEtapeToJson(_VarianteEtape instance) =>
    <String, dynamic>{
      'id': instance.id,
      'etapeBaseId': instance.etapeBaseId,
      'label': instance.label,
      'distanceKm': instance.distanceKm,
      'deniveleM': instance.deniveleM,
      'difficulte': _$VarianteDifficulteEnumMap[instance.difficulte]!,
      'traceGpxRef': instance.traceGpxRef,
      'isOfficielle': instance.isOfficielle,
    };

const _$VarianteDifficulteEnumMap = {
  VarianteDifficulte.facile: 'facile',
  VarianteDifficulte.moyen: 'moyen',
  VarianteDifficulte.difficile: 'difficile',
};

_VarianteSelection _$VarianteSelectionFromJson(Map<String, dynamic> json) =>
    _VarianteSelection(
      selectionParEtape:
          (json['selectionParEtape'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
    );

Map<String, dynamic> _$VarianteSelectionToJson(_VarianteSelection instance) =>
    <String, dynamic>{'selectionParEtape': instance.selectionParEtape};
