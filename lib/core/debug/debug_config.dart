import 'package:flutter/foundation.dart';

/// Configuration du mode debug du Moteur GR.
///
/// Regroupe les flags de debug : detection emulateur,
/// simulation GPS, logs verbeux. Tous gardes par [kDebugMode] —
/// en release, tout est desactive.
class DebugConfig {
  const DebugConfig({
    this.isEmulator = false,
    this.isGpsSimulated = false,
    this.verboseLogs = false,
  });

  /// True si l'app tourne sur un emulateur/simulateur.
  final bool isEmulator;

  /// True si le GPS est simule (fichier GPX injecte).
  final bool isGpsSimulated;

  /// True pour activer les logs detailles (positions, distances, etc.).
  final bool verboseLogs;

  /// Configuration par defaut en mode release : tout desactive.
  static const release = DebugConfig();

  /// Configuration debug avec detection automatique.
  ///
  /// Active les logs verbeux et la detection emulateur
  /// uniquement en [kDebugMode].
  factory DebugConfig.auto({
    required bool isEmulator,
    bool simulateGps = false,
  }) {
    if (!kDebugMode) return release;

    return DebugConfig(
      isEmulator: isEmulator,
      isGpsSimulated: simulateGps,
      verboseLogs: true,
    );
  }

  /// Copie avec modifications.
  DebugConfig copyWith({
    bool? isEmulator,
    bool? isGpsSimulated,
    bool? verboseLogs,
  }) {
    return DebugConfig(
      isEmulator: isEmulator ?? this.isEmulator,
      isGpsSimulated: isGpsSimulated ?? this.isGpsSimulated,
      verboseLogs: verboseLogs ?? this.verboseLogs,
    );
  }

  @override
  String toString() =>
      'DebugConfig(emulator=$isEmulator, gps=$isGpsSimulated, verbose=$verboseLogs)';
}
