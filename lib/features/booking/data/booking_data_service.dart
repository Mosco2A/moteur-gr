// Service de persistence des reservations.
//
// Utilise Firestore (cloud) + Hive (cache local offline-first).
// Le schema Hive remplace la table Drift specifiee dans le design original,
// car le projet utilise Hive/Firestore, pas Drift.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../domain/models/accommodation_booking.dart';

/// Nom de la box Hive pour le cache local des reservations.
const String kBookingsBoxName = 'accommodation_bookings';

/// Nom de la collection Firestore pour les reservations.
const String kBookingsCollection = 'accommodation_bookings';

/// Service de persistence pour les reservations d'hebergement.
///
/// Ecrit dans Firestore (source de verite) et cache dans Hive (offline).
/// Pattern identique a TrekService et FeedbackService.
class BookingDataService {
  BookingDataService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Reference a la collection Firestore.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(kBookingsCollection);

  /// Sauvegarde une reservation (Firestore + Hive).
  Future<void> saveBooking(AccommodationBooking booking) async {
    final json = booking.toJson();

    // Firestore (source de verite)
    await _collection.doc(booking.id).set(json);

    // Cache local Hive
    final box = await Hive.openBox<Map>(kBookingsBoxName);
    await box.put(booking.id, json);
  }

  /// Recupere les reservations pour un trail depuis le cache Hive.
  ///
  /// Offline-first : lit le cache local, pas Firestore.
  Future<List<AccommodationBooking>> getBookingsForTrail(
    String trailId,
  ) async {
    final box = await Hive.openBox<Map>(kBookingsBoxName);
    final bookings = <AccommodationBooking>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        final json = Map<String, dynamic>.from(raw);
        final booking = AccommodationBooking.fromJson(json);
        if (booking.trailId == trailId) {
          bookings.add(booking);
        }
      }
    }

    // Trier par date de nuitee (plus proche en premier)
    bookings.sort((a, b) => a.date.compareTo(b.date));
    return bookings;
  }

  /// Met a jour le statut d'une reservation.
  Future<void> updateStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    // Firestore
    await _collection.doc(bookingId).update({
      'status': newStatus.name,
    });

    // Cache Hive
    final box = await Hive.openBox<Map>(kBookingsBoxName);
    final raw = box.get(bookingId);
    if (raw != null) {
      final json = Map<String, dynamic>.from(raw);
      json['status'] = newStatus.name;
      await box.put(bookingId, json);
    }
  }

  /// Supprime une reservation (annulation physique).
  Future<void> deleteBooking(String bookingId) async {
    await _collection.doc(bookingId).delete();

    final box = await Hive.openBox<Map>(kBookingsBoxName);
    await box.delete(bookingId);
  }
}
