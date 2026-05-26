import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/notifications/domain/download_reminder_service.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';

/// Mock du DAO pour les tests.
///
/// Simule needsUpdate() avec un flag configurable.
class FakeTrailManifestsDao {
  bool _needsUpdate = true;

  void setNeedsUpdate(bool value) => _needsUpdate = value;

  Future<bool> needsUpdate(String trailId) async => _needsUpdate;
}

/// Mock du NotificationService pour tracer les appels.
class FakeNotificationService extends NotificationService {
  int scheduleCountdownCalls = 0;
  int cancelCalls = 0;
  String? lastTrailName;
  DateTime? lastDepartureDate;
  int? lastCancelId;

  @override
  Future<void> scheduleCountdown({
    required DateTime departureDate,
    required String trailName,
  }) async {
    scheduleCountdownCalls++;
    lastTrailName = trailName;
    lastDepartureDate = departureDate;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls++;
    lastCancelId = id;
  }
}

void main() {
  group('DownloadReminderService', () {
    late FakeNotificationService fakeNotifService;
    late FakeTrailManifestsDao fakeDao;
    late DownloadReminderService service;

    setUp(() {
      fakeNotifService = FakeNotificationService();
      fakeDao = FakeTrailManifestsDao();

      // Le service attend un TrailManifestsDao reel,
      // mais on teste la logique metier via les mocks.
      // On cree le service avec les faux objets castes.
      service = DownloadReminderService(
        notificationService: fakeNotifService,
        manifestsDao: fakeDao as dynamic,
      );
    });

    test('notifie quand J-2 atteint et donnees pas telechargees', () async {
      fakeDao.setNeedsUpdate(true);

      // Depart dans 1 jour (on est dans la fenetre J-2)
      final departure = DateTime.now().add(const Duration(days: 1));

      await service.checkAndNotify('mare-a-mare', departure);

      expect(fakeNotifService.scheduleCountdownCalls, 1);
      expect(fakeNotifService.lastTrailName, 'mare-a-mare');
    });

    test('ne notifie PAS quand donnees deja telechargees', () async {
      fakeDao.setNeedsUpdate(false);

      final departure = DateTime.now().add(const Duration(days: 1));

      await service.checkAndNotify('mare-a-mare', departure);

      expect(fakeNotifService.scheduleCountdownCalls, 0);
    });

    test('ne notifie PAS quand depart trop loin (> J-2)', () async {
      fakeDao.setNeedsUpdate(true);

      // Depart dans 10 jours (hors fenetre J-2)
      final departure = DateTime.now().add(const Duration(days: 10));

      await service.checkAndNotify('mare-a-mare', departure);

      expect(fakeNotifService.scheduleCountdownCalls, 0);
    });

    test('ne notifie PAS quand depart deja passe', () async {
      fakeDao.setNeedsUpdate(true);

      // Depart hier
      final departure = DateTime.now().subtract(const Duration(days: 1));

      await service.checkAndNotify('mare-a-mare', departure);

      expect(fakeNotifService.scheduleCountdownCalls, 0);
    });

    test('cancelReminder appelle cancel sur le service', () async {
      await service.cancelReminder('mare-a-mare');

      expect(fakeNotifService.cancelCalls, 1);
      expect(fakeNotifService.lastCancelId, isNotNull);
    });
  });
}
