// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PoiModelImpl _$$PoiModelImplFromJson(Map<String, dynamic> json) =>
    _$PoiModelImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      trailId: json['trailId'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: $enumDecode(_$PoiTypeEnumMap, json['type']),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      altitudeM: (json['altitudeM'] as num?)?.toInt() ?? 0,
      openingHours: json['openingHours'] as String?,
    );

Map<String, dynamic> _$$PoiModelImplToJson(_$PoiModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trailId': instance.trailId,
      'stageNumber': instance.stageNumber,
      'name': instance.name,
      'description': instance.description,
      'type': _$PoiTypeEnumMap[instance.type]!,
      'lat': instance.lat,
      'lng': instance.lng,
      'altitudeM': instance.altitudeM,
      'openingHours': instance.openingHours,
    };

const _$PoiTypeEnumMap = {
  PoiType.shelter: 'shelter',
  PoiType.water: 'water',
  PoiType.viewpoint: 'viewpoint',
  PoiType.campsite: 'campsite',
  PoiType.restaurant: 'restaurant',
  PoiType.emergency: 'emergency',
  PoiType.danger: 'danger',
  PoiType.shop: 'shop',
};
