import 'package:flutter_test/flutter_test.dart';
import 'package:g20_app/core/config/feature_flags.dart';
import 'package:g20_app/features/booking/domain/models/accommodation_booking.dart';
import 'package:g20_app/features/booking/domain/models/booking_config.dart';

void main() {
  group('FeatureFlags -- booking', () {
    setUp(() {
      FeatureFlags.resetAll();
    });

    test('isBookingEnabled retourne FALSE par defaut', () {
      expect(FeatureFlags.isBookingEnabled('gr20'), isFalse);
      expect(FeatureFlags.isBookingEnabled('mare-a-mare'), isFalse);
      expect(FeatureFlags.isBookingEnabled(''), isFalse);
    });

    test('isBookingEnabled retourne TRUE apres activation', () {
      FeatureFlags.setBookingEnabled('gr20', enabled: true);
      expect(FeatureFlags.isBookingEnabled('gr20'), isTrue);
      expect(FeatureFlags.isBookingEnabled('mare-a-mare'), isFalse);
    });

    test('setBookingEnabled peut desactiver un trail active', () {
      FeatureFlags.setBookingEnabled('gr20', enabled: true);
      expect(FeatureFlags.isBookingEnabled('gr20'), isTrue);
      FeatureFlags.setBookingEnabled('gr20', enabled: false);
      expect(FeatureFlags.isBookingEnabled('gr20'), isFalse);
    });

    test('resetAll remet tous les flags a zero', () {
      FeatureFlags.setBookingEnabled('gr20', enabled: true);
      FeatureFlags.setBookingEnabled('mare-a-mare', enabled: true);
      FeatureFlags.resetAll();
      expect(FeatureFlags.isBookingEnabled('gr20'), isFalse);
      expect(FeatureFlags.isBookingEnabled('mare-a-mare'), isFalse);
    });
  });

  group('AccommodationBooking -- serialization roundtrip', () {
    test('fromJson/toJson roundtrip conserve toutes les donnees', () {
      final now = DateTime(2026, 7, 15, 10, 30);
      final bookedAt = DateTime(2026, 6, 1, 8, 0);
      final original = AccommodationBooking(
        id: 'booking-001',
        accommodationId: 'refuge-ortu',
        trailId: 'gr20',
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
        accommodationId: 'gite-conca',
        trailId: 'gr20',
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
          trailId: 'gr20',
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
          trailId: 'gr20',
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
      final original = BookingConfig(
        trailId: 'gr20',
        bookingEnabled: false,
        bookingMethods: ['phone', 'email', 'web'],
        partnerUrl: 'https://refuges-corse.fr',
        partnerPhone: '+33 4 95 65 28 09',
        partnerEmail: 'reservation@pnrc.fr',
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
      final config = BookingConfig.fromJson({
        'trailId': 'mare-a-mare',
      });
      expect(config.bookingEnabled, isFalse);
      expect(config.bookingMethods, isEmpty);
      expect(config.partnerUrl, isNull);
      expect(config.isOperational, isFalse);
    });

    test('isOperational = true seulement si enabled + methodes', () {
      final disabled = BookingConfig(
        trailId: 'gr20',
        bookingEnabled: false,
        bookingMethods: ['phone'],
      );
      expect(disabled.isOperational, isFalse);

      final noMethods = BookingConfig(
        trailId: 'gr20',
        bookingEnabled: true,
      );
      expect(noMethods.isOperational, isFalse);

      final operational = BookingConfig(
        trailId: 'gr20',
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
        trailId: 'gr20',
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
          trailId: 'gr20',
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
        trailId: 'gr20',
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
        trailId: 'gr20',
        date: DateTime(2026, 7, 1),
        status: BookingStatus.requested,
        contactMethod: ContactMethod.phone,
        bookedAt: DateTime(2026, 6, 1),
      );
      final b = AccommodationBooking(
        id: 'b1',
        accommodationId: 'a1',
        trailId: 'gr20',
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
