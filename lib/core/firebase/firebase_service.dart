import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service d'initialisation Firebase.
///
/// Gere l'initialisation conditionnelle de Firebase :
/// - Si firebaseProjectId est fourni, Firebase est initialise
/// - Si null, le moteur tourne en mode local uniquement
///
/// Ref #81812 B2 offline montagne — persistence Firestore activee
/// pour garantir l'acces aux donnees hors connexion en montagne.
class FirebaseService {
  FirebaseService._({required this.isAvailable});

  /// Constructeur pour les tests unitaires.
  FirebaseService.testOnly({required this.isAvailable});

  /// Factory pour un service Firebase indisponible (mode local/test).
  factory FirebaseService.unavailable() =>
      FirebaseService._(isAvailable: false);

  /// Indique si Firebase est disponible et initialise
  final bool isAvailable;

  /// Initialise Firebase de maniere conditionnelle.
  ///
  /// Si [firebaseProjectId] est null, retourne un service
  /// avec isAvailable = false (mode offline/local).
  /// Les FirebaseOptions doivent etre fournies via
  /// DefaultFirebaseOptions (genere par FlutterFire CLI).
  ///
  /// Active la persistence Firestore pour le mode offline (#81812).
  static Future<FirebaseService> initialize({
    String? firebaseProjectId,
  }) async {
    if (firebaseProjectId == null) {
      return FirebaseService._(isAvailable: false);
    }

    try {
      await Firebase.initializeApp();

      // #81812 B2 offline montagne — persistence Firestore
      // Permet l'acces aux donnees meme sans reseau (sentiers, POI, etapes)
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      return FirebaseService._(isAvailable: true);
    } catch (e) {
      // En cas d echec d init, fallback en mode local
      // plutot que de crasher l app
      return FirebaseService._(isAvailable: false);
    }
  }
}

/// Provider du service Firebase (initialise au demarrage)
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  // Valeur par defaut -- sera override dans main.dart
  // apres initialisation async
  return FirebaseService._(isAvailable: false);
});

/// Provider de commodite : Firebase est-il disponible ?
final isFirebaseAvailableProvider = Provider<bool>((ref) {
  return ref.watch(firebaseServiceProvider).isAvailable;
});
