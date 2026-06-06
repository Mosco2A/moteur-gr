import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_session.freezed.dart';
part 'follow_session.g.dart';

/// Session de suivi temps reel d un randonneur (E4.10).
///
/// Permet aux proches de suivre la position du randonneur
/// via un shareCode unique de 6 caracteres.
@freezed
abstract class FollowSession with _$FollowSession {
  const factory FollowSession({
    required String id,
    required String trekkerUserId,
    required String shareCode,
    required String createdAt,
    required String expiresAt,
    @Default(true) bool isActive,
  }) = _FollowSession;

  factory FollowSession.fromJson(Map<String, dynamic> json) =>
      _$FollowSessionFromJson(json);
}
