import 'dart:io';

import 'package:flutter/foundation.dart';

/// Detecte si l'application tourne sur un emulateur.
///
/// Utilise les fingerprints Android (android.os.Build) sur Android
/// et le modele de device sur iOS pour determiner si l'environnement
/// est emule. Garde par [kDebugMode] — retourne toujours false en release.
class EmulatorDetector {
  EmulatorDetector._();

  /// Indicateurs Android typiques d'un emulateur.
  ///
  /// Fingerprints contenant 'generic', 'sdk', 'google_sdk',
  /// ou hardware 'goldfish'/'ranchu' signalent un AVD.
  static const _androidEmulatorMarkers = [
    'generic',
    'sdk',
    'google_sdk',
    'goldfish',
    'ranchu',
    'emulator',
  ];

  /// Modeles iOS typiques du simulateur Xcode.
  static const _iosSimulatorMarkers = [
    'simulator',
    'x86_64',
  ];

  /// Detecte si l'app tourne sur un emulateur/simulateur.
  ///
  /// En release mode, retourne toujours `false` pour eviter
  /// toute fuite d'information sur l'environnement.
  ///
  /// Accepte un [fingerprint] optionnel pour faciliter les tests
  /// unitaires sans dependre de la plateforme reelle.
  static bool detect({String? fingerprint}) {
    if (!kDebugMode) return false;

    // Si un fingerprint est fourni (tests), l'utiliser directement
    if (fingerprint != null) {
      return _matchesMarkers(fingerprint, _androidEmulatorMarkers);
    }

    // Detection plateforme reelle
    try {
      if (Platform.isAndroid) {
        return _detectAndroid();
      } else if (Platform.isIOS) {
        return _detectIos();
      }
    } catch (_) {
      // Platform non supportee (web, desktop en test)
      return false;
    }

    return false;
  }

  /// Detection Android via les proprietes systeme.
  ///
  /// Verifie si le fingerprint ou le hardware contient
  /// des marqueurs d'emulateur connus.
  static bool _detectAndroid() {
    // En environnement reel, on lirait android.os.Build.FINGERPRINT
    // et android.os.Build.HARDWARE via un MethodChannel.
    // Ici on fournit le squelette — l'integration native viendra en E1.x.
    return false;
  }

  /// Detection iOS via le modele de device.
  ///
  /// Le simulateur Xcode expose un modele contenant 'x86_64'
  /// ou 'Simulator'.
  static bool _detectIos() {
    // Meme principe — integration native en E1.x.
    return false;
  }

  /// Verifie si un fingerprint matche un des marqueurs.
  static bool _matchesMarkers(String fingerprint, List<String> markers) {
    final lower = fingerprint.toLowerCase();
    return markers.any((marker) => lower.contains(marker));
  }
}
