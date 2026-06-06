// E5.20a -- Tests widget lockscreen enrichi sante + GPS (R1.11).
//
// VRAIS tests : LockscreenWidgetService REELLEMENT instancie
// (avec EmergencyContactsService et secours regionaux d'un sentier
// FICTIF injectes). Les 2 tests EXIGES par la spec V8 :
// - La notification contient les infos sante
// - Le GPS est mis a jour dans la notification
//
// Fixtures : sentier fictif "Sentier des Volcans" (Auvergne),
// coordonnees fictives — aucune donnee de sentier reel.

import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/features/safety/data/emergency_contacts_service.dart';
import 'package:moteur_gr/features/safety/data/lockscreen_widget_service.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';

void main() {
  // Service contacts reel, secours regionaux du sentier FICTIF.
  EmergencyContactsService buildContactsService() {
    return EmergencyContactsService(
      trailEmergencyNumbers: const [
        TrailEmergencyNumber(
          name: 'Secours montagne Volcans',
          phone: '04 00 00 00 00',
        ),
      ],
    );
  }

  LockscreenWidgetService buildService(
    EmergencyContactsService contactsService,
  ) {
    return LockscreenWidgetService(
      contactsService: contactsService,
      trailName: 'Sentier des Volcans',
    );
  }

  group('LockscreenWidgetService -- R1.11', () {
    test('la notification contient les infos sante', () async {
      final contactsService = buildContactsService();
      final service = buildService(contactsService);

      // Enrichir avec les donnees sante du randonneur
      await service.updateSecurityData(
        healthInfo: const HealthInfo(
          bloodType: 'O+',
          allergies: 'Penicilline',
          treatments: 'Antihistaminique 10mg/j',
        ),
        latitude: 45.51234,
        longitude: 2.96543,
        stageName: 'Crete des Puys',
        stageIndex: 3,
      );

      // Titre : base sur le sentier actif injecte, pas hardcode
      expect(service.notificationTitle,
          equals('Secours Sentier des Volcans'));

      // Corps de la notification (service reellement sollicite)
      final content = service
          .buildNotificationContent(contactsService.getContacts());

      // Infos sante presentes
      expect(content, contains('SANTE'));
      expect(content, contains('Sang: O+'));
      expect(content, contains('Allergies: Penicilline'));
      expect(content, contains('Traitements: Antihistaminique 10mg/j'));

      // Contacts secours presents (112 + secours regional injecte)
      expect(content, contains('112'));
      expect(content, contains('Secours montagne Volcans'));

      // Etape en cours presente
      expect(content, contains('Etape 3: Crete des Puys'));

      // Payload iOS : memes donnees dans le widget lockscreen
      final payload = service
          .buildIosSecurityPayload(contactsService.getContacts());
      expect(payload['health_info'], isNotNull);
      expect((payload['health_info'] as Map)['bloodType'], equals('O+'));
      expect(payload['contacts'], isNotEmpty);
      expect((payload['stage'] as Map)['index'], equals(3));

      // securityData expose les memes donnees
      expect(service.securityData.hasHealthInfo, isTrue);
      expect(service.securityData.hasGpsPosition, isTrue);
    });

    test('le GPS est mis a jour dans la notification', () async {
      final contactsService = buildContactsService();
      final service = buildService(contactsService);

      // Position initiale
      await service.updateSecurityData(
        latitude: 45.51234,
        longitude: 2.96543,
        stageName: 'Col du Lac Vert',
        stageIndex: 2,
      );
      final contentBefore = service
          .buildNotificationContent(contactsService.getContacts());
      expect(contentBefore, contains('GPS: 45.51234, 2.96543'));

      // Le randonneur avance : nouvelle position GPS
      await service.updateSecurityData(
        latitude: 45.53891,
        longitude: 2.99012,
        stageName: 'Col du Lac Vert',
        stageIndex: 2,
      );
      final contentAfter = service
          .buildNotificationContent(contactsService.getContacts());

      // La notification reflete la NOUVELLE position
      expect(contentAfter, contains('GPS: 45.53891, 2.99012'));
      expect(contentAfter, isNot(contains('GPS: 45.51234, 2.96543')));

      // Payload iOS egalement mis a jour
      final payload = service
          .buildIosSecurityPayload(contactsService.getContacts());
      expect((payload['gps'] as Map)['latitude'], equals(45.53891));
      expect((payload['gps'] as Map)['longitude'], equals(2.99012));

      // Sans donnees sante : pas de section SANTE dans la notif
      expect(contentAfter, isNot(contains('SANTE')));

      // hasGpsPosition coherent
      expect(service.securityData.hasGpsPosition, isTrue);
      expect(service.securityData.hasHealthInfo, isFalse);
    });
  });

  group('LockscreenSecurityData -- modele', () {
    test('detection presence sante et GPS', () {
      const emptyData = LockscreenSecurityData();
      expect(emptyData.hasHealthInfo, isFalse);
      expect(emptyData.hasGpsPosition, isFalse);

      // HealthInfo vide => hasHealthInfo false
      const emptyHealthData = LockscreenSecurityData(
        healthInfo: HealthInfo(),
      );
      expect(emptyHealthData.hasHealthInfo, isFalse);

      // GPS partiel (latitude seule) => false
      const partialGps = LockscreenSecurityData(latitude: 45.51);
      expect(partialGps.hasGpsPosition, isFalse);

      // Donnees completes => true
      const fullData = LockscreenSecurityData(
        healthInfo: HealthInfo(bloodType: 'A-'),
        latitude: 45.51,
        longitude: 2.96,
        stageName: 'Puy de la Vache',
        stageIndex: 1,
      );
      expect(fullData.hasHealthInfo, isTrue);
      expect(fullData.hasGpsPosition, isTrue);
    });
  });
}
