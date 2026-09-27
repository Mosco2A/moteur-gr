// LOT 596 (C3) — LES REGLAGES DE NOTIFICATION NE SONT JAMAIS ECRITS.
//
// CONSTAT DE CHRIS, DE SA PROPRE MAIN : « on coupe, on relance, tout est
// revenu ». Deux defauts independants le produisent :
//
//   1. `NotificationSettingsNotifier.build()` rend `const NotificationSettings()`
//      — les valeurs par defaut, a CHAQUE demarrage. Aucun `SharedPreferences`,
//      aucun Drift, aucune ecriture : les cinq mutateurs ne touchent que `state`.
//      Couper un rappel ne survit donc pas a la fermeture de l'appli.
//
//   2. `NotificationService.checkPermissions()` etait `async => true`. En dur.
//      L'appli croyait TOUJOURS avoir le droit de notifier, meme quand le
//      randonneur l'avait refuse au systeme. Un rappel de securite qu'on croit
//      arme et qui n'arrivera jamais est pire que pas de rappel du tout.
//
//   3. Corollaire du meme mensonge : `toggleMorningReminder(false)` planifiait
//      quand on activait mais n'ANNULAIT RIEN quand on coupait. La notification
//      systeme restait armee apres que l'utilisateur l'ait eteinte.
//
// CES TESTS ONT ETE ECRITS ROUGES, AVANT LA CORRECTION. C'est la regle du lot.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';
import 'package:moteur_gr/features/notifications/providers/notification_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Service espion : note ce qui a ete planifie et ce qui a ete annule.
class ServiceEspion extends NotificationService {
  ServiceEspion({this.permission = true});

  /// Ce que la permission systeme repond reellement.
  bool permission;

  final List<int> annules = <int>[];
  int planificationsMatin = 0;

  @override
  Future<bool> checkPermissions() async => permission;

  @override
  Future<int> scheduleMorningReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    planificationsMatin++;
    return 1000;
  }

  @override
  Future<void> cancel(int id) async => annules.add(id);
}

/// Fake plateforme ANDROID : permet de verifier que `checkPermissions` demande
/// vraiment au systeme au lieu de repondre oui tout seul.
class FakeAndroidPlateforme extends Fake
    with MockPlatformInterfaceMixin
    implements AndroidFlutterLocalNotificationsPlugin {
  FakeAndroidPlateforme({required this.autorise});

  final bool autorise;
  bool aEteInterroge = false;

  @override
  Future<bool?> areNotificationsEnabled() async {
    aEteInterroge = true;
    return autorise;
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancel(int id, {String? tag}) async {}

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      <PendingNotificationRequest>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  group('LOT 596 C3 — un reglage qu on coupe reste coupe', () {
    test(
        'ON COUPE, ON RELANCE : le rappel du matin est TOUJOURS coupe '
        '(le constat de Chris)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = ServiceEspion();

      // Premiere « session » de l'appli : l'utilisateur coupe le rappel.
      final premier = ProviderContainer(overrides: [
        notificationServiceProvider.overrideWithValue(service),
      ]);
      premier.read(notificationSettingsProvider); // force le build
      await Future<void>.delayed(Duration.zero); // laisse le chargement passer
      premier
          .read(notificationSettingsProvider.notifier)
          .toggleMorningReminder(false);
      premier
          .read(notificationSettingsProvider.notifier)
          .toggleOffTrackAlerts(false);
      premier.read(notificationSettingsProvider.notifier).setMorningTime(9, 30);
      // Laisse l'ecriture asynchrone se poser avant de « fermer l'appli ».
      await Future<void>.delayed(Duration.zero);
      premier.dispose();

      // L'appli redemarre : MEME stockage, nouveau container.
      final second = ProviderContainer(overrides: [
        notificationServiceProvider.overrideWithValue(service),
      ]);
      second.read(notificationSettingsProvider);
      await Future<void>.delayed(Duration.zero);
      final apresRelance = second.read(notificationSettingsProvider);

      expect(apresRelance.morningReminderEnabled, isFalse,
          reason: 'coupe puis relance : le rappel du matin est revenu tout '
              'seul — le reglage n a jamais ete ecrit');
      expect(apresRelance.offTrackAlerts, isFalse,
          reason: 'l alerte hors-trace coupee est revenue toute seule');
      expect(apresRelance.morningReminderHour, 9,
          reason: 'l heure choisie par l utilisateur n a pas survecu');
      expect(apresRelance.morningReminderMinute, 30);
      second.dispose();
    });

    test('les valeurs par defaut restent celles du produit au tout premier '
        'demarrage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer(overrides: [
        notificationServiceProvider.overrideWithValue(ServiceEspion()),
      ]);
      // LECTURE SYNCHRONE, sans attendre : les consommateurs existants
      // (off_track_provider_test) lisent l'etat juste apres le build.
      final immediat = container.read(notificationSettingsProvider);
      expect(immediat.offTrackAlerts, isTrue,
          reason: 'la securite hors-trace doit etre ON tant que rien n est '
              'charge — jamais un trou de securite pendant le chargement');
      expect(immediat.morningReminderEnabled, isTrue);
      container.dispose();
    });

    test('COUPER le rappel du matin ANNULE la notification systeme', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = ServiceEspion();
      final container = ProviderContainer(overrides: [
        notificationServiceProvider.overrideWithValue(service),
      ]);
      container.read(notificationSettingsProvider);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(notificationSettingsProvider.notifier);
      notifier.toggleMorningReminder(true);
      expect(service.planificationsMatin, greaterThan(0),
          reason: 'activer doit planifier');

      notifier.toggleMorningReminder(false);
      await Future<void>.delayed(Duration.zero);
      expect(service.annules, isNotEmpty,
          reason: 'couper le rappel du matin laisse la notification armee dans '
              'le systeme : l utilisateur la recevra quand meme');
      container.dispose();
    });
  });

  group('LOT 596 C3 — la permission est DEMANDEE, pas supposee', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('sur Android, checkPermissions INTERROGE le systeme et rapporte son '
        'refus', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final plateforme = FakeAndroidPlateforme(autorise: false);
      FlutterLocalNotificationsPlatform.instance = plateforme;

      final service = NotificationService();
      final accorde = await service.checkPermissions();

      expect(plateforme.aEteInterroge, isTrue,
          reason: 'checkPermissions repond sans jamais demander au systeme : '
              'l appli croit avoir le droit de notifier');
      expect(accorde, isFalse,
          reason: 'le systeme a REFUSE les notifications et l appli repond '
              'quand meme oui');
    });

    test('sur Android, un systeme qui autorise est rapporte comme tel',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final plateforme = FakeAndroidPlateforme(autorise: true);
      FlutterLocalNotificationsPlatform.instance = plateforme;

      expect(await NotificationService().checkPermissions(), isTrue);
    });

    test('le refus du systeme se voit dans l etat des reglages', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer(overrides: [
        notificationServiceProvider
            .overrideWithValue(ServiceEspion(permission: false)),
      ]);
      container.read(notificationSettingsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(notificationSettingsProvider).permissionGranted,
          isFalse,
          reason: 'le randonneur a refuse les notifications au systeme et '
              'l ecran de reglages ne le sait pas');
      container.dispose();
    });
  });
}
