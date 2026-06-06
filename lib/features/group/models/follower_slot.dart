import 'package:freezed_annotation/freezed_annotation.dart';

part 'follower_slot.freezed.dart';
part 'follower_slot.g.dart';

/// Slot de suiveur dans une session de suivi (E4.10).
///
/// 2 slots gratuits par session (#81759). Au-dela, le suiveur
/// voit de la publicite (adSupported) ou doit payer (isPaid).
@freezed
abstract class FollowerSlot with _$FollowerSlot {
  const factory FollowerSlot({
    required String id,
    required String sessionId,
    required String followerName,
    @Default(false) bool isPaid,
    @Default(false) bool adSupported,
  }) = _FollowerSlot;

  factory FollowerSlot.fromJson(Map<String, dynamic> json) =>
      _$FollowerSlotFromJson(json);
}
