// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tip_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TipCard _$TipCardFromJson(Map<String, dynamic> json) => _TipCard(
  id: json['id'] as String,
  titleFr: json['titleFr'] as String,
  titleEn: json['titleEn'] as String? ?? '',
  titleDe: json['titleDe'] as String? ?? '',
  titleIt: json['titleIt'] as String? ?? '',
  titleEs: json['titleEs'] as String? ?? '',
  contentFr: json['contentFr'] as String,
  contentEn: json['contentEn'] as String? ?? '',
  contentDe: json['contentDe'] as String? ?? '',
  contentIt: json['contentIt'] as String? ?? '',
  contentEs: json['contentEs'] as String? ?? '',
  scope: json['scope'] as String? ?? 'all',
  season: json['season'] as String? ?? 'all',
  category: json['category'] as String? ?? 'general',
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  minAltitudeM: (json['minAltitudeM'] as num?)?.toInt(),
  imageAsset: json['imageAsset'] as String?,
  priority: (json['priority'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TipCardToJson(_TipCard instance) => <String, dynamic>{
  'id': instance.id,
  'titleFr': instance.titleFr,
  'titleEn': instance.titleEn,
  'titleDe': instance.titleDe,
  'titleIt': instance.titleIt,
  'titleEs': instance.titleEs,
  'contentFr': instance.contentFr,
  'contentEn': instance.contentEn,
  'contentDe': instance.contentDe,
  'contentIt': instance.contentIt,
  'contentEs': instance.contentEs,
  'scope': instance.scope,
  'season': instance.season,
  'category': instance.category,
  'tags': instance.tags,
  'minAltitudeM': instance.minAltitudeM,
  'imageAsset': instance.imageAsset,
  'priority': instance.priority,
};
