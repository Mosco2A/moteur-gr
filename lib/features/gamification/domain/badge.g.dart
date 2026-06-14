// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Badge _$BadgeFromJson(Map<String, dynamic> json) => _Badge(
  id: json['id'] as String,
  code: json['code'] as String,
  titre: json['titre'] as String,
  description: json['description'] as String,
  tier: json['tier'] as String,
  iconRef: json['iconRef'] as String,
  obtainedAt: json['obtainedAt'] == null
      ? null
      : DateTime.parse(json['obtainedAt'] as String),
);

Map<String, dynamic> _$BadgeToJson(_Badge instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'titre': instance.titre,
  'description': instance.description,
  'tier': instance.tier,
  'iconRef': instance.iconRef,
  'obtainedAt': instance.obtainedAt?.toIso8601String(),
};
