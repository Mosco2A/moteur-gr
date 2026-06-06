// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FollowSession _$FollowSessionFromJson(Map<String, dynamic> json) =>
    _FollowSession(
      id: json['id'] as String,
      trekkerUserId: json['trekkerUserId'] as String,
      shareCode: json['shareCode'] as String,
      createdAt: json['createdAt'] as String,
      expiresAt: json['expiresAt'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$FollowSessionToJson(_FollowSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trekkerUserId': instance.trekkerUserId,
      'shareCode': instance.shareCode,
      'createdAt': instance.createdAt,
      'expiresAt': instance.expiresAt,
      'isActive': instance.isActive,
    };
