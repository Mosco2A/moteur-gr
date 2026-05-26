import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group_member.dart';
import '../services/group_tracking_service.dart';

/// Code du groupe actif (null si pas dans un groupe).
final groupCodeProvider = StateProvider<String?>((ref) => null);

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
  final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
  return members.length > 1 ? members.length - 1 : 0;
});
