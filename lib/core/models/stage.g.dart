// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StageModelImpl _$$StageModelImplFromJson(Map<String, dynamic> json) =>
    _$StageModelImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      trailId: json['trailId'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      name: json['name'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toInt(),
      elevationLossM: (json['elevationLossM'] as num).toInt(),
      description: json['description'] as String? ?? '',
      startLat: (json['startLat'] as num).toDouble(),
      startLng: (json['startLng'] as num).toDouble(),
      endLat: (json['endLat'] as num).toDouble(),
      endLng: (json['endLng'] as num).toDouble(),
      difficulty: json['difficulty'] as String? ?? 'moderate',
    );

Map<String, dynamic> _$$StageModelImplToJson(_$StageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trailId': instance.trailId,
      'stageNumber': instance.stageNumber,
      'name': instance.name,
      'distanceKm': instance.distanceKm,
      'elevationGainM': instance.elevationGainM,
      'elevationLossM': instance.elevationLossM,
      'description': instance.description,
      'startLat': instance.startLat,
      'startLng': instance.startLng,
      'endLat': instance.endLat,
      'endLng': instance.endLng,
      'difficulty': instance.difficulty,
    };
