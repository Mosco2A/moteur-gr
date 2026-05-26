import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';

/// Tests du service de notifications.
void main() {
  late NotificationService service;

  setUp(() {
    service = NotificationService();
  });

  group('NotificationService', () {
    test('checkPermissions retourne true en test', () async {
      final granted = await service.checkPermissions();
      expect(granted, true);
    });

    test('requestPermissions retourne true en test', () async {
      final granted = await service.requestPermissions();
      expect(granted, true);
    });

    test('channelMorning a la bonne valeur', () {
      expect(NotificationService.channelMorning, 'morning_reminder');
    });

    test('channelWeather a la bonne valeur', () {
      expect(NotificationService.channelWeather, 'weather_alert');
    });

    test('channelCountdown a la bonne valeur', () {
      expect(NotificationService.channelCountdown, 'countdown');
    });

    test('scheduleMorningReminder ne lance pas d\'exception', () async {
      await expectLater(
        service.scheduleMorningReminder(
          hour: 7,
          minute: 0,
          title: 'Test',
          body: 'Body test',
        ),
        completes,
      );
    });

    test('cancelAll ne lance pas d\'exception', () async {
      await expectLater(service.cancelAll(), completes);
    });
  });
}
