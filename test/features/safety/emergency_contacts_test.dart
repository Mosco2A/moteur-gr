import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/features/safety/data/emergency_contacts_service.dart';
import 'package:moteur_gr/features/safety/domain/models/emergency_contact.dart';

void main() {
  // Secours regionaux d'un sentier FICTIF (Sentier des Volcans).
  // Aucune correspondance reelle -- fixtures de test neutres.
  const volcansEmergencyNumbers = [
    TrailEmergencyNumber(
      name: 'Secours montagne Volcans',
      phone: '04 00 00 00 00',
    ),
  ];

  group('EmergencyContactsService', () {
    test('112 universel toujours present, sans secours regional hardcode',
        () {
      // Service SANS config sentier : seul le 112 est propose
      final service = EmergencyContactsService();
      final contacts = service.getContacts();

      final autoContacts = contacts.where((c) => c.isAutomatic).toList();
      expect(autoContacts.length, equals(1),
          reason: 'sans config sentier, seul le 112 doit etre present');

      final sos112 = autoContacts.where((c) => c.phone == '112');
      expect(sos112, isNotEmpty, reason: '112 doit etre present');
    });

    test('secours regionaux injectes depuis la config du sentier', () {
      // Service AVEC config sentier fictif : 112 + secours regional
      final service = EmergencyContactsService(
        trailEmergencyNumbers: volcansEmergencyNumbers,
      );
      final contacts = service.getContacts();

      final autoContacts = contacts.where((c) => c.isAutomatic).toList();
      expect(autoContacts.length, equals(2));

      // 112 d'abord, secours regional du sentier ensuite
      expect(autoContacts.first.phone, equals('112'));
      expect(autoContacts.last.name, equals('Secours montagne Volcans'));
      expect(autoContacts.last.phone, equals('04 00 00 00 00'));
    });

    test('appel avec bon numero -- format tel: correct', () {
      final service = EmergencyContactsService(
        trailEmergencyNumbers: volcansEmergencyNumbers,
      );
      final contacts = service.getContacts();
      final regional = contacts.firstWhere(
        (c) => c.phone.contains('04 00 00 00 00'),
      );

      // Le numero nettoye (sans espaces) doit donner le bon format tel:
      final cleanPhone = regional.phone.replaceAll(' ', '');
      expect(cleanPhone, equals('0400000000'));

      // Verifier le format URI tel:
      final uri = Uri.parse('tel:$cleanPhone');
      expect(uri.scheme, equals('tel'));
      expect(uri.path, equals('0400000000'));

      // Verifier aussi le 112
      final sos = contacts.firstWhere((c) => c.phone == '112');
      final sosClean = sos.phone.replaceAll(' ', '');
      final sosUri = Uri.parse('tel:$sosClean');
      expect(sosUri.scheme, equals('tel'));
      expect(sosUri.path, equals('112'));
    });
  });

  group('EmergencyContact -- model', () {
    test('fromJson/toJson roundtrip', () {
      const original = EmergencyContact(
        id: 'contact-1',
        name: 'Maman',
        phone: '06 12 34 56 78',
        priority: 1,
        isAutomatic: false,
      );
      final json = original.toJson();
      final restored = EmergencyContact.fromJson(json);
      expect(restored, equals(original));
    });

    test('contacts personnels ordonnes avant automatiques', () {
      final service = EmergencyContactsService(
        trailEmergencyNumbers: volcansEmergencyNumbers,
      );
      service.addContact(const EmergencyContact(
        id: 'perso-1',
        name: 'Contact perso',
        phone: '06 00 00 00 01',
        priority: 1,
      ));
      final contacts = service.getContacts();

      // Le premier contact doit etre personnel
      expect(contacts.first.isAutomatic, isFalse);
      // Les derniers doivent etre automatiques
      expect(contacts.last.isAutomatic, isTrue);
    });
  });
}
