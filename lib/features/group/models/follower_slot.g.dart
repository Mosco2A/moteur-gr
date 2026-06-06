// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follower_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FollowerSlot _$FollowerSlotFromJson(Map<String, dynamic> json) =>
    _FollowerSlot(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      followerName: json['followerName'] as String,
      isPaid: json['isPaid'] as bool? ?? false,
      adSupported: json['adSupported'] as bool? ?? false,
    );

Map<String, dynamic> _$FollowerSlotToJson(_FollowerSlot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'followerName': instance.followerName,
      'isPaid': instance.isPaid,
      'adSupported': instance.adSupported,
    };
