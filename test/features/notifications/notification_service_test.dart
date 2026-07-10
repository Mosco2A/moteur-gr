import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Fake platform pour les tests unitaires.
class FakeNotificationsPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FlutterLocalNotificationsPlatform {
  bool cancelAllCalled = false;

  // Pas un override : la plateforme de base n'expose pas initialize,
  // mais le fake en a besoin pour le pipeline du service.
  Future<bool?> initialize(
    String? defaultIcon, {
    List<DarwinNotificationCategory>? notificationCategories,
  }) async => true;

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {}

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async => [];
}

/// Tests du service de notifications E3.8a.
///
/// Valide les canaux, les permissions, la garde date passee
/// et le cancelAll via un fake platform.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  late FakeNotificationsPlatform fakePlatform;
  late NotificationService service;

  setUp(() {
    fakePlatform = FakeNotificationsPlatform();
    FlutterLocalNotificationsPlatform.instance = fakePlatform;
    service = NotificationService();
  });

  group('NotificationService', () {
    test('canaux ont les bonnes valeurs', () {
      expect(NotificationService.channelMorning, 'morning_reminder');
      expect(NotificationService.channelWeather, 'weather_alert');
      expect(NotificationService.channelCountdown, 'countdown');
      expect(NotificationService.channelOffTrack, 'offtrack_alert');
    });

    test('canal hors-trace : constantes coherentes', () {
      // Canal dedie generique (aucun sentier en dur) + description non vide.
      expect(NotificationService.channelOffTrack, 'offtrack_alert');
      expect(NotificationService.channelOffTrackDesc, isNotEmpty);
    });

    test('showOffTrackAlert / cancelOffTrackAlert n echouent pas (pipeline)',
        () async {
      // Le plugin route show/cancel via MethodChannel natif (non observable ici
      // sans mock du channel) ; on valide surtout que le pipeline du service ne
      // leve pas. Le CABLAGE transitions -> notification est couvert par le test
      // d'integration off_track_provider_test (spy sur le service).
      await service.showOffTrackAlert(title: 'T', body: 'B');
      await service.cancelOffTrackAlert();
    });

    test('checkPermissions retourne true en environnement test', () async {
      expect(await service.checkPermissions(), true);
    });

    test('scheduleWeatherAlert ignore les dates passees et retourne id correct', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final id = await service.scheduleWeatherAlert(
        dateTime: pastDate,
        title: 'Orage prevu',
        body: 'Evitez les cretes',
        alertIndex: 3,
      );
      // Id = _weatherBaseId + alertIndex = 2003
      expect(id, 2003);
    });

    test('cancelAll delegue au plugin', () async {
      await service.cancelAll();
      expect(fakePlatform.cancelAllCalled, true);
    });
  });
}
