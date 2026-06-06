// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_accommodation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StageAccommodation _$StageAccommodationFromJson(Map<String, dynamic> json) =>
    _StageAccommodation(
      id: json['id'] as String,
      stageId: json['stageId'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      nameFr: json['nameFr'] as String,
      nameEn: json['nameEn'] as String? ?? '',
      type: $enumDecode(_$AccommodationTypeEnumMap, json['type']),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      priceRange: json['priceRange'] as String?,
      bookingUrl: json['bookingUrl'] as String?,
    );

Map<String, dynamic> _$StageAccommodationToJson(_StageAccommodation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'stageId': instance.stageId,
      'stageNumber': instance.stageNumber,
      'nameFr': instance.nameFr,
      'nameEn': instance.nameEn,
      'type': _$AccommodationTypeEnumMap[instance.type]!,
      'lat': instance.lat,
      'lng': instance.lng,
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
      'capacity': instance.capacity,
      'priceRange': instance.priceRange,
      'bookingUrl': instance.bookingUrl,
    };

const _$AccommodationTypeEnumMap = {
  AccommodationType.refuge: 'refuge',
  AccommodationType.bergerie: 'bergerie',
  AccommodationType.gite: 'gite',
  AccommodationType.hotel: 'hotel',
  AccommodationType.camping: 'camping',
  AccommodationType.bivouac: 'bivouac',
};
