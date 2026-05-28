// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StageImpl _$$StageImplFromJson(Map<String, dynamic> json) => _$StageImpl(
      id: json['id'] as String,
      nameFr: json['nameFr'] as String,
      nameEn: json['nameEn'] as String,
      nameDe: json['nameDe'] as String? ?? '',
      nameIt: json['nameIt'] as String? ?? '',
      nameEs: json['nameEs'] as String? ?? '',
      distance: (json['distance'] as num).toDouble(),
      elevationGain: (json['elevationGain'] as num).toInt(),
      elevationLoss: (json['elevationLoss'] as num).toInt(),
      estimatedDurationMinutes:
          (json['estimatedDurationMinutes'] as num).toInt(),
      difficulty: json['difficulty'] as String? ?? 'moderate',
      orderIndex: (json['orderIndex'] as num).toInt(),
      startLat: (json['startLat'] as num).toDouble(),
      startLng: (json['startLng'] as num).toDouble(),
      endLat: (json['endLat'] as num).toDouble(),
      endLng: (json['endLng'] as num).toDouble(),
      descriptionFr: json['descriptionFr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      descriptionDe: json['descriptionDe'] as String? ?? '',
      descriptionIt: json['descriptionIt'] as String? ?? '',
      descriptionEs: json['descriptionEs'] as String? ?? '',
    );

Map<String, dynamic> _$$StageImplToJson(_$StageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameFr': instance.nameFr,
      'nameEn': instance.nameEn,
      'nameDe': instance.nameDe,
      'nameIt': instance.nameIt,
      'nameEs': instance.nameEs,
      'distance': instance.distance,
      'elevationGain': instance.elevationGain,
      'elevationLoss': instance.elevationLoss,
      'estimatedDurationMinutes': instance.estimatedDurationMinutes,
      'difficulty': instance.difficulty,
      'orderIndex': instance.orderIndex,
      'startLat': instance.startLat,
      'startLng': instance.startLng,
      'endLat': instance.endLat,
      'endLng': instance.endLng,
      'descriptionFr': instance.descriptionFr,
      'descriptionEn': instance.descriptionEn,
      'descriptionDe': instance.descriptionDe,
      'descriptionIt': instance.descriptionIt,
      'descriptionEs': instance.descriptionEs,
    };
