// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShareLink _$ShareLinkFromJson(Map<String, dynamic> json) => _ShareLink(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  type: json['type'] as String,
  url: json['url'] as String,
  activatedAt: json['activatedAt'] as String?,
);

Map<String, dynamic> _$ShareLinkToJson(_ShareLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'type': instance.type,
      'url': instance.url,
      'activatedAt': instance.activatedAt,
    };
