// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hebergement_peripherique.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HebergementPeripherique _$HebergementPeripheriqueFromJson(
  Map<String, dynamic> json,
) => _HebergementPeripherique(
  id: json['id'] as String,
  nom: json['nom'] as String,
  type: $enumDecode(_$HebergementTypeEnumMap, json['type']),
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  distanceAllerRetourKm: (json['distanceAllerRetourKm'] as num).toDouble(),
  deeplinkUrl: json['deeplinkUrl'] as String,
);

Map<String, dynamic> _$HebergementPeripheriqueToJson(
  _HebergementPeripherique instance,
) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'type': _$HebergementTypeEnumMap[instance.type]!,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'distanceAllerRetourKm': instance.distanceAllerRetourKm,
  'deeplinkUrl': instance.deeplinkUrl,
};

const _$HebergementTypeEnumMap = {
  HebergementType.refuge: 'refuge',
  HebergementType.gite: 'gite',
  HebergementType.hotel: 'hotel',
  HebergementType.camping: 'camping',
  HebergementType.chambreHote: 'chambre_hote',
};
