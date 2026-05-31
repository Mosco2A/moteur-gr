import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';
part 'group_member.g.dart';

/// Membre d un groupe de localisation partagee.
@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String uid,
    String? displayName,
    required double lastLat,
    required double lastLng,
    required String lastUpdate,
    String? currentStageId,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}

/// Informations d un groupe de localisation partagee.
/// Design #81460 : 2 mateurs gratuits max.
@freezed
abstract class GroupInfo with _$GroupInfo {
  const factory GroupInfo({
    required String groupCode,
    required String trailId,
    required String createdBy,
    required List<GroupMember> members,
    @Default(2) int maxFreeWatchers,
  }) = _GroupInfo;

  factory GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);
}
