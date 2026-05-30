import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/trek_session_manager.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';

void main() {
  group('TrekSessionManager', () {
    // --- Stockage en memoire pour les tests ---
    late List<TrekSession> activeSessions;
    late List<String> deletedIds;
    late Map<String, String> updatedStatuses;
    late TrekSessionManager manager;
    late DateTime fakeNow;

    setUp(() {
      activeSessions = [];
      deletedIds = [];
      updatedStatuses = {};
      fakeNow = DateTime.utc(2026, 6, 15, 10, 0);

      manager = TrekSessionManager(
        onFindActiveSessions: () async => activeSessions,
        onDeleteSession: (id) async {
          deletedIds.add(id);
        },
        onUpdateSessionStatus: (id, status) async {
          updatedStatuses[id] = status;
        },
        clock: () => fakeNow,
      );
    });

    test('checkPendingSession detecte une session orpheline', () async {
      // Simuler une session active laissee par un crash (2h avant)
      final orphan = TrekSession(
        id: 'crash-session-001',
        trailId: 'gr20-nord',
        startedAt: fakeNow.subtract(const Duration(hours: 2)),
        status: 'active',
      );
      activeSessions.add(orphan);

      final pending = await manager.checkPendingSession();

      expect(pending, isNotNull);
      expect(pending!.session.id, equals('crash-session-001'));
      expect(pending.session.trailId, equals('gr20-nord'));
      expect(pending.session.status, equals('active'));
      expect(pending.age.inHours, equals(2));
      expect(pending.isExpired, isFalse);
    });

    test('checkPendingSession retourne null sans session active', () async {
      final pending = await manager.checkPendingSession();
      expect(pending, isNull);
    });

    test('checkPendingSession prend la session la plus recente', () async {
      final older = TrekSession(
        id: 'old-session',
        trailId: 'gr20-sud',
        startedAt: fakeNow.subtract(const Duration(days: 3)),
        status: 'active',
      );
      final newer = TrekSession(
        id: 'new-session',
        trailId: 'gr20-nord',
        startedAt: fakeNow.subtract(const Duration(hours: 1)),
        status: 'active',
      );
      activeSessions.addAll([older, newer]);

      final pending = await manager.checkPendingSession();

      expect(pending, isNotNull);
      expect(pending!.session.id, equals('new-session'));
    });

    test('cleanOrphans supprime sessions de plus de 7 jours', () async {
      final expired = TrekSession(
        id: 'expired-session',
        trailId: 'gr20-nord',
        startedAt: fakeNow.subtract(const Duration(days: 10)),
        status: 'active',
      );
      final recent = TrekSession(
        id: 'recent-session',
        trailId: 'gr20-sud',
        startedAt: fakeNow.subtract(const Duration(hours: 3)),
        status: 'active',
      );
      activeSessions.addAll([expired, recent]);

      final cleaned = await manager.cleanOrphans();

      expect(cleaned, equals(1));
      expect(updatedStatuses['expired-session'], equals('abandoned'));
      expect(deletedIds, contains('expired-session'));
      expect(deletedIds, isNot(contains('recent-session')));
    });

    test('cleanOrphans retourne 0 sans session expiree', () async {
      final recent = TrekSession(
        id: 'recent-session',
        trailId: 'mare-a-mare',
        startedAt: fakeNow.subtract(const Duration(days: 2)),
        status: 'active',
      );
      activeSessions.add(recent);

      final cleaned = await manager.cleanOrphans();

      expect(cleaned, equals(0));
      expect(deletedIds, isEmpty);
      expect(updatedStatuses, isEmpty);
    });

    test('PendingSession.isExpired a 7 jours', () {
      final session = TrekSession(
        id: 'test',
        trailId: 'gr20',
        startedAt: DateTime.utc(2026, 6, 1),
        status: 'active',
      );

      final expired = PendingSession(
        session: session,
        age: const Duration(days: 7),
      );
      expect(expired.isExpired, isTrue);

      final notExpired = PendingSession(
        session: session,
        age: const Duration(days: 6, hours: 23),
      );
      expect(notExpired.isExpired, isFalse);
    });
  });
}
