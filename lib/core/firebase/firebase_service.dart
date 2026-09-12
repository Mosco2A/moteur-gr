import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/error_handler.dart';

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

  /// Delai maximum d'attente de l'init Firebase au demarrage (offline-first).
  ///
  /// Cold-boot HORS-LIGNE : `Firebase.initializeApp()` peut RESTER PENDU
  /// (resolution DNS / tentative de contact des serveurs Google sans reseau) —
  /// le `try/catch` ne rattrape pas un HANG, seulement une erreur. Sans borne de
  /// temps, le premier frame n'est jamais rendu et l'app se fige au demarrage
  /// (bug cycle 1 persona S4/offline). On borne donc l'init : au-dela, on
  /// retombe en mode local (Firebase indisponible) et l'app demarre quand meme.
  /// Le cache Firestore local (#81812) reste utilisable une fois le reseau revenu
  /// et l'app relancee ; en attendant, tout le moteur fonctionne offline-first
  /// (donnees embarquees / Drift).
  static const Duration _initTimeout = Duration(seconds: 4);

  /// Initialise Firebase de maniere conditionnelle.
  ///
  /// Si [firebaseProjectId] est null, retourne un service
  /// avec isAvailable = false (mode offline/local).
  /// Les FirebaseOptions doivent etre fournies via
  /// DefaultFirebaseOptions (genere par FlutterFire CLI).
  ///
  /// Active la persistence Firestore pour le mode offline (#81812).
  ///
  /// OFFLINE-FIRST (fix cycle 2, issue 3) : l'init est bornee par [_initTimeout]
  /// (`.timeout(...)`). Un cold-boot sans reseau ou un SDK qui pend ne fige plus
  /// le demarrage — au dela du delai, on bascule proprement en mode local (comme
  /// pour toute autre erreur d'init), l'app s'ouvre offline-first.
  static Future<FirebaseService> initialize({
    String? firebaseProjectId,
    @visibleForTesting Duration? timeout,
  }) async {
    if (firebaseProjectId == null) {
      return FirebaseService._(isAvailable: false);
    }

    try {
      // Borne de temps : offline, `initializeApp` peut PENDRE (pas juste jeter).
      await Firebase.initializeApp().timeout(timeout ?? _initTimeout);

      // #81812 B2 offline montagne — persistence Firestore
      // Permet l'acces aux donnees meme sans reseau (sentiers, POI, etapes)
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      return FirebaseService._(isAvailable: true);
    } on Object catch (e, st) {
      // En cas d'echec OU de TIMEOUT (TimeoutException) d'init, fallback en mode
      // local plutot que de crasher/figer l'app (offline-first). Trace via le
      // handler d'erreurs (aucun catch silencieux).
      ErrorHandler.log(e, stackTrace: st, context: 'FirebaseService.initialize');
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
