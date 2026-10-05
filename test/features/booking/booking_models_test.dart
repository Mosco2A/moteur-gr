import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/booking/domain/models/accommodation_booking.dart';
import 'package:moteur_gr/features/booking/domain/models/booking_config.dart';

void main() {
  // LE GROUPE « FeatureFlags -- booking » EST PARTI AVEC SON DRAPEAU
  // (lot produit P1, #101255). Il verifiait `isBookingEnabled`, qui ne gardait
  // qu'une chose : la route /booking, retiree faute de porte, de donnee et de
  // test. Garder quatre tests sur un drapeau que plus aucun code de production
  // ne lit, c'est tenir au vert une mesure qui ne mesure plus rien. Le
  // mecanisme generique (`setOverride`, `clearOverrides`) reste couvert par
  // `test/features/goodies/goodies_models_test.dart`, dont le drapeau, lui, a
  // encore sa route.
  //
  // CE QUI RESTE ICI, ET POURQUOI. Les modeles `AccommodationBooking` et
  // `BookingConfig` sont du DOMAINE de `booking` : l'arbitrage #101255 le garde
  // entier, parce que c'est lui que le planning lit.

  group('AccommodationBooking -- serialization roundtrip', () {
    test('fromJson/toJson roundtrip conserve toutes les donnees', () {
      final now = DateTime(2026, 7, 15, 10, 30);
      final bookedAt = DateTime(2026, 6, 1, 8, 0);
      final original = AccommodationBooking(
        id: 'booking-001',
        accommodationId: 'refuge-cratere',
        trailId: 'sentier-volcans',
        date: now,
        status: BookingStatus.requested,
        contactMethod: ContactMethod.phone,
        bookedAt: bookedAt,
        notes: 'Confirmation attendue',
      );
      final json = original.toJson();
      final restored = AccommodationBooking.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.accommodationId, original.accommodationId);
      expect(restored.trailId, original.trailId);
      expect(restored.date, original.date);
      expect(restored.status, original.status);
      expect(restored.contactMethod, original.contactMethod);
      expect(restored.bookedAt, original.bookedAt);
      expect(restored.notes, original.notes);
    });

    test('fromJson/toJson roundtrip avec notes null', () {
      final original = AccommodationBooking(
        id: 'booking-002',
        accommodationId: 'gite-puy',
        trailId: 'sentier-volcans',
        date: DateTime(2026, 8, 1),
        status: BookingStatus.confirmed,
        contactMethod: ContactMethod.email,
        bookedAt: DateTime(2026, 7, 20),
      );
      final json = original.toJson();
      final restored = AccommodationBooking.fromJson(json);
      expect(restored.notes, isNull);
      expect(restored.status, BookingStatus.confirmed);
      expect(restored.contactMethod, ContactMethod.email);
    });

    test('tous les statuts survivent au roundtrip', () {
      for (final status in BookingStatus.values) {
        final booking = AccommodationBooking(
          id: 'test-status',
          accommodationId: 'refuge-test',
          trailId: 'sentier-volcans',
          date: DateTime(2026, 7, 1),
          status: status,
          contactMethod: ContactMethod.web,
          bookedAt: DateTime(2026, 6, 1),
        );
        final restored = AccommodationBooking.fromJson(booking.toJson());
        expect(restored.status, status);
      }
    });

    test('toutes les methodes de contact survivent au roundtrip', () {
      for (final method in ContactMethod.values) {
        final booking = AccommodationBooking(
          id: 'test-method',
          accommodationId: 'refuge-test',
          trailId: 'sentier-volcans',
          date: DateTime(2026, 7, 1),
          status: BookingStatus.requested,
          contactMethod: method,
          bookedAt: DateTime(2026, 6, 1),
        );
        final restored = AccommodationBooking.fromJson(booking.toJson());
        expect(restored.contactMethod, method);
      }
    });
  });

  group('BookingConfig -- serialization roundtrip', () {
    test('fromJson/toJson roundtrip conserve toutes les donnees', () {
      const original = BookingConfig(
        trailId: 'sentier-volcans',
        bookingEnabled: false,
        bookingMethods: ['phone', 'email', 'web'],
        partnerUrl: 'https://refuges-volcans.example',
        partnerPhone: '+33 4 73 00 00 00',
        partnerEmail: 'reservation@volcans.example',
      );
      final json = original.toJson();
      final restored = BookingConfig.fromJson(json);
      expect(restored.trailId, original.trailId);
      expect(restored.bookingEnabled, original.bookingEnabled);
      expect(restored.bookingMethods, original.bookingMethods);
      expect(restored.partnerUrl, original.partnerUrl);
      expect(restored.partnerPhone, original.partnerPhone);
      expect(restored.partnerEmail, original.partnerEmail);
    });

    test('defauts corrects : bookingEnabled=false, methods=vide', () {
      final config = BookingConfig.fromJson({'trailId': 'mare-a-mare'});
      expect(config.bookingEnabled, isFalse);
      expect(config.bookingMethods, isEmpty);
      expect(config.partnerUrl, isNull);
      expect(config.isOperational, isFalse);
    });

    test('isOperational = true seulement si enabled + methodes', () {
      const disabled = BookingConfig(
        trailId: 'sentier-volcans',
        bookingEnabled: false,
        bookingMethods: ['phone'],
      );
      expect(disabled.isOperational, isFalse);

      const noMethods = BookingConfig(
        trailId: 'sentier-volcans',
        bookingEnabled: true,
      );
      expect(noMethods.isOperational, isFalse);

      const operational = BookingConfig(
        trailId: 'sentier-volcans',
        bookingEnabled: true,
        bookingMethods: ['phone'],
      );
      expect(operational.isOperational, isTrue);
    });
  });

  group('AccommodationBooking -- computed + copyWith + equality', () {
    test('isActive retourne false pour cancelled', () {
      final booking = AccommodationBooking(
        id: 'b1',
        accommodationId: 'a1',
        trailId: 'sentier-volcans',
        date: DateTime(2026, 7, 1),
        status: BookingStatus.cancelled,
        contactMethod: ContactMethod.phone,
        bookedAt: DateTime(2026, 6, 1),
      );
      expect(booking.isActive, isFalse);
    });

    test('isActive retourne true pour requested et confirmed', () {
      for (final status in [BookingStatus.requested, BookingStatus.confirmed]) {
        final booking = AccommodationBooking(
          id: 'b1',
          accommodationId: 'a1',
          trailId: 'sentier-volcans',
          date: DateTime(2026, 7, 1),
          status: status,
          contactMethod: ContactMethod.phone,
          bookedAt: DateTime(2026, 6, 1),
        );
        expect(booking.isActive, isTrue);
      }
    });

    test('copyWith cree une copie avec modification', () {
      final original = AccommodationBooking(
        id: 'b1',
        accommodationId: 'a1',
        trailId: 'sentier-volcans',
        date: DateTime(2026, 7, 1),
        status: BookingStatus.requested,
        contactMethod: ContactMethod.phone,
        bookedAt: DateTime(2026, 6, 1),
        notes: 'test',
      );
      final modified = original.copyWith(
        status: BookingStatus.confirmed,
        notes: 'Confirme par telephone',
      );
      expect(modified.id, original.id);
      expect(modified.status, BookingStatus.confirmed);
      expect(modified.notes, 'Confirme par telephone');
      expect(modified.contactMethod, original.contactMethod);
    });

    test('egalite structurelle fonctionne', () {
      final a = AccommodationBooking(
        id: 'b1',
        accommodationId: 'a1',
        trailId: 'sentier-volcans',
        date: DateTime(2026, 7, 1),
        status: BookingStatus.requested,
        contactMethod: ContactMethod.phone,
        bookedAt: DateTime(2026, 6, 1),
      );
      final b = AccommodationBooking(
        id: 'b1',
        accommodationId: 'a1',
        trailId: 'sentier-volcans',
        date: DateTime(2026, 7, 1),
        status: BookingStatus.requested,
        contactMethod: ContactMethod.phone,
        bookedAt: DateTime(2026, 6, 1),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
