// Service de persistence des reservations.
//
// Utilise Firestore (cloud) + SharedPreferences (cache local
// offline-first, JSON encode). Le moteur n'utilise pas Hive :
// la persistence locale structurelle est Drift, et ce cache
// leger de reservations passe par SharedPreferences.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/accommodation_booking.dart';

/// Cle SharedPreferences pour le cache local des reservations.
const String kBookingsPrefsKey = 'accommodation_bookings';

/// Nom de la collection Firestore pour les reservations.
const String kBookingsCollection = 'accommodation_bookings';

/// Service de persistence pour les reservations d'hebergement.
///
/// Ecrit dans Firestore (source de verite) et cache localement
/// dans SharedPreferences (offline-first).
class BookingDataService {
  BookingDataService({
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _prefs = prefs;

  final FirebaseFirestore _firestore;
  SharedPreferences? _prefs;

  /// Reference a la collection Firestore.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(kBookingsCollection);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Lit le cache local (map id -> booking JSON).
  Future<Map<String, dynamic>> _readCache() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(kBookingsPrefsKey);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, dynamic>.from(json.decode(raw) as Map);
  }

  /// Ecrit le cache local.
  Future<void> _writeCache(Map<String, dynamic> cache) async {
    final prefs = await _getPrefs();
    await prefs.setString(kBookingsPrefsKey, json.encode(cache));
  }

  /// Sauvegarde une reservation (Firestore + cache local).
  Future<void> saveBooking(AccommodationBooking booking) async {
    final bookingJson = booking.toJson();

    // Firestore (source de verite)
    await _collection.doc(booking.id).set(bookingJson);

    // Cache local
    final cache = await _readCache();
    cache[booking.id] = bookingJson;
    await _writeCache(cache);
  }

  /// Recupere les reservations pour un trail depuis le cache local.
  ///
  /// Offline-first : lit le cache local, pas Firestore.
  Future<List<AccommodationBooking>> getBookingsForTrail(
    String trailId,
  ) async {
    final cache = await _readCache();
    final bookings = <AccommodationBooking>[];

    for (final raw in cache.values) {
      final bookingJson = Map<String, dynamic>.from(raw as Map);
      final booking = AccommodationBooking.fromJson(bookingJson);
      if (booking.trailId == trailId) {
        bookings.add(booking);
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

    // Cache local
    final cache = await _readCache();
    final raw = cache[bookingId];
    if (raw != null) {
      final bookingJson = Map<String, dynamic>.from(raw as Map);
      bookingJson['status'] = newStatus.name;
      cache[bookingId] = bookingJson;
      await _writeCache(cache);
    }
  }

  /// Supprime une reservation (annulation physique).
  Future<void> deleteBooking(String bookingId) async {
    await _collection.doc(bookingId).delete();

    final cache = await _readCache();
    cache.remove(bookingId);
    await _writeCache(cache);
  }
}
