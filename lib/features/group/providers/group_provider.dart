import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group_member.dart';
import '../services/group_tracking_service.dart';

/// Notifier pour le code du groupe actif (null si pas dans un groupe).
class GroupCodeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? code) => state = code;
}

final groupCodeProvider =
    NotifierProvider<GroupCodeNotifier, String?>(GroupCodeNotifier.new);

/// Stream des membres du groupe actif.
final groupMembersProvider = StreamProvider<List<GroupMember>>((ref) {
  final groupCode = ref.watch(groupCodeProvider);
  if (groupCode == null) return const Stream.empty();

  final service = ref.watch(groupTrackingServiceProvider);
  return service.membersStream(groupCode);
});

/// Indique si un groupe est actif.
final isGroupActiveProvider = Provider<bool>((ref) {
  return ref.watch(groupCodeProvider) != null;
});

/// Nombre de mateurs (membres hors createur).
final watcherCountProvider = Provider<int>((ref) {
  final members = ref.watch(groupMembersProvider).value ?? [];
  return members.length > 1 ? members.length - 1 : 0;
});
