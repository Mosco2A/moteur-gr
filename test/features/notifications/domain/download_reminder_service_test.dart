import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/features/notifications/domain/download_reminder_service.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';

/// Mock du DAO pour les tests.
///
/// Etend le vrai [TrailManifestsDao] (pour rester un sous-type accepte par
/// DownloadReminderService) mais court-circuite [needsUpdate] avec un flag
/// configurable. La DB in-memory n'est jamais requetee.
class FakeTrailManifestsDao extends TrailManifestsDao {
  FakeTrailManifestsDao(super.db);

  bool _needsUpdate = true;

  void setNeedsUpdate(bool value) => _needsUpdate = value;

  @override
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
  Future<int> scheduleCountdown({
    required DateTime departureDate,
    required String title,
    required String body,
  }) async {
    scheduleCountdownCalls++;
    // Le service passe le trailId comme titre de la notification.
    lastTrailName = title;
    lastDepartureDate = departureDate;
    return 0;
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
    late AppDatabase db;
    late DownloadReminderService service;

    setUp(() {
      fakeNotifService = FakeNotificationService();
      db = AppDatabase(NativeDatabase.memory());
      fakeDao = FakeTrailManifestsDao(db);

      // fakeDao est un vrai sous-type de TrailManifestsDao (needsUpdate
      // est override) : on peut le passer directement au service.
      service = DownloadReminderService(
        notificationService: fakeNotifService,
        manifestsDao: fakeDao,
      );
    });

    tearDown(() async {
      await db.close();
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
