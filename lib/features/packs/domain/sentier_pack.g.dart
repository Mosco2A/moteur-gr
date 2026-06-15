// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentier_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SentierPack _$SentierPackFromJson(Map<String, dynamic> json) => _SentierPack(
  id: json['id'] as String,
  nom: json['nom'] as String,
  trailId: json['trailId'] as String,
  type: json['type'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$SentierPackToJson(_SentierPack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'trailId': instance.trailId,
      'type': instance.type,
      'description': instance.description,
    };
