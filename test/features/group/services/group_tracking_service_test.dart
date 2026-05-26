import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/features/group/models/group_member.dart';
import 'package:moteur_gr/features/group/services/group_tracking_service.dart';

void main() {
  late GroupTrackingService svc;
  setUp(() { svc = GroupTrackingService(firebaseService: FirebaseService.testOnly(isAvailable: false)); });
  tearDown(() { svc.dispose(); });

  group('createGroup', () {
    test('null si Firebase non dispo', () async { expect(await svc.createGroup('gr20', uid: 'u1'), isNull); });
  });
  group('joinGroup', () {
    test('false si Firebase non dispo', () async { expect(await svc.joinGroup('ABC', uid: 'u1'), isFalse); });
  });
  group('leaveGroup', () {
    test('no exception si pas de groupe', () async { await svc.leaveGroup(); });
  });
  group('sharePosition', () {
    test('no-op si Firebase non dispo', () async { await svc.sharePosition(42.5, 8.9, stageId: 's1'); });
  });
  group('membersStream', () {
    test('stream vide si Firebase non dispo', () async {
      expect(await svc.membersStream('ABC').toList(), isEmpty);
    });
  });
  group('isFreeLimitReached', () {
    test('false si < 2 mateurs', () {
      const g = GroupInfo(groupCode: 'A', trailId: 'gr20', createdBy: 'u1', members: [
        GroupMember(uid: 'u1', lastLat: 42.0, lastLng: 8.0, lastUpdate: '2026-05-26T12:00:00Z'),
        GroupMember(uid: 'u2', lastLat: 42.1, lastLng: 8.1, lastUpdate: '2026-05-26T12:00:00Z')]);
      expect(svc.isFreeLimitReached(g), isFalse);
    });
    test('true si >= 2 mateurs', () {
      const g = GroupInfo(groupCode: 'A', trailId: 'gr20', createdBy: 'u1', members: [
        GroupMember(uid: 'u1', lastLat: 42.0, lastLng: 8.0, lastUpdate: '2026-05-26T12:00:00Z'),
        GroupMember(uid: 'u2', lastLat: 42.1, lastLng: 8.1, lastUpdate: '2026-05-26T12:00:00Z'),
        GroupMember(uid: 'u3', lastLat: 42.2, lastLng: 8.2, lastUpdate: '2026-05-26T12:00:00Z')]);
      expect(svc.isFreeLimitReached(g), isTrue);
    });
    test('respecte maxFreeWatchers custom', () {
      const g = GroupInfo(groupCode: 'A', trailId: 'gr20', createdBy: 'u1', maxFreeWatchers: 5, members: [
        GroupMember(uid: 'u1', lastLat: 42.0, lastLng: 8.0, lastUpdate: '2026-05-26T12:00:00Z'),
        GroupMember(uid: 'u2', lastLat: 42.1, lastLng: 8.1, lastUpdate: '2026-05-26T12:00:00Z'),
        GroupMember(uid: 'u3', lastLat: 42.2, lastLng: 8.2, lastUpdate: '2026-05-26T12:00:00Z')]);
      expect(svc.isFreeLimitReached(g), isFalse);
    });
  });
}
