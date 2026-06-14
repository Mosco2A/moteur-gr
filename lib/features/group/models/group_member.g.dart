// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => _GroupMember(
  uid: json['uid'] as String,
  displayName: json['displayName'] as String?,
  lastLat: (json['lastLat'] as num).toDouble(),
  lastLng: (json['lastLng'] as num).toDouble(),
  lastUpdate: json['lastUpdate'] as String,
  currentStageId: json['currentStageId'] as String?,
);

Map<String, dynamic> _$GroupMemberToJson(_GroupMember instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'displayName': instance.displayName,
      'lastLat': instance.lastLat,
      'lastLng': instance.lastLng,
      'lastUpdate': instance.lastUpdate,
      'currentStageId': instance.currentStageId,
    };

_GroupInfo _$GroupInfoFromJson(Map<String, dynamic> json) => _GroupInfo(
  groupCode: json['groupCode'] as String,
  trailId: json['trailId'] as String,
  createdBy: json['createdBy'] as String,
  members: (json['members'] as List<dynamic>)
      .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
      .toList(),
  maxFreeWatchers: (json['maxFreeWatchers'] as num?)?.toInt() ?? 2,
);

Map<String, dynamic> _$GroupInfoToJson(_GroupInfo instance) =>
    <String, dynamic>{
      'groupCode': instance.groupCode,
      'trailId': instance.trailId,
      'createdBy': instance.createdBy,
      'members': instance.members.map((e) => e.toJson()).toList(),
      'maxFreeWatchers': instance.maxFreeWatchers,
    };
