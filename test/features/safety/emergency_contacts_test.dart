import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/safety/data/emergency_contacts_service.dart';
import 'package:moteur_gr/features/safety/domain/models/emergency_contact.dart';

void main() {
  group('EmergencyContactsService', () {
    late EmergencyContactsService service;

    setUp(() {
      service = EmergencyContactsService();
    });

    test('contacts secours automatiques toujours presents', () {
      // Meme sans contacts personnels, les contacts auto sont la
      final contacts = service.getContacts();

      // Verifier que les contacts automatiques sont presents
      final autoContacts = contacts.where((c) => c.isAutomatic).toList();
      expect(autoContacts.length, greaterThanOrEqualTo(2));

      // Verifier 112 (urgences europeennes)
      final sos112 = autoContacts.where((c) => c.phone == '112');
      expect(sos112, isNotEmpty, reason: '112 doit etre present');

      // Verifier PGHM
      final pghm = autoContacts.where(
        (c) => c.phone == '04 92 22 22 22',
      );
      expect(pghm, isNotEmpty, reason: 'PGHM doit etre present');
    });

    test('appel avec bon numero -- format tel: correct', () {
      // Verifier que le numero PGHM est correct et nettoyable
      final contacts = service.getContacts();
      final pghm = contacts.firstWhere(
        (c) => c.phone.contains('04 92 22 22 22'),
      );

      // Le numero nettoye (sans espaces) doit donner le bon format tel:
      final cleanPhone = pghm.phone.replaceAll(' ', '');
      expect(cleanPhone, equals('0492222222'));

      // Verifier le format URI tel:
      final uri = Uri.parse('tel:$cleanPhone');
      expect(uri.scheme, equals('tel'));
      expect(uri.path, equals('0492222222'));

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
      final original = EmergencyContact(
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
      final service = EmergencyContactsService();
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
