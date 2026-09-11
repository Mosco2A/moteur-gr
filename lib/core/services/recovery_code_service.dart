import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service du CODE DE RECONNEXION (StepWays — modèle « code-sur-tel » blindé).
///
/// Décision Chris 11/09 (#99784) : la reconnexion de compte est ZÉRO-KNOWLEDGE
/// STRICT. Le code de reconnexion VIT SUR LE TÉLÉPHONE ; l'app l'AFFICHE à la
/// demande (réglage + nudge onboarding). AUCUN envoi mail/SMS. Ce code EST la
/// clé du coffre chiffré (profil + fiche santé + solde wallet) : il se garde
/// comme un mot de passe. Le perdre = données irrécupérables (prix du
/// zéro-nominatif, pas de backdoor) — d'où l'importance de le noter tôt.
///
/// RÔLE de ce service (couche « secret local ») : GÉNÉRER une seule fois un code
/// à haute entropie, le PERSISTER dans le KEYSTORE OS (`flutter_secure_storage`,
/// jamais en clair dans les prefs), et l'exposer à l'UI qui l'affiche. La
/// DÉRIVATION de clé et le chiffrement du coffre restent portés par
/// [SecureVaultService] (AES-GCM 256 + PBKDF2, livré L7) ; ce service ne fait
/// QUE gérer le secret lui-même. Cross-platform (le code est à NOUS, pas à l'OS).
class RecoveryCodeService {
  RecoveryCodeService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  /// Clé keystore du code de reconnexion (versionnée, migrations futures).
  static const String storageKey = 'stepways.recovery.code.v1';

  /// Alphabet du code : SANS caractères ambigus (0/O, 1/I/L) pour une
  /// recopie manuelle fiable — le code se lit et se note à la main.
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Nombre de groupes et taille d'un groupe : 4 groupes de 4 = 16 caractères
  /// (~78 bits d'entropie sur cet alphabet de 30) — largement suffisant contre
  /// le brute-force en ligne (le serveur limite en plus le débit sur le locator).
  static const int _groupCount = 4;
  static const int _groupSize = 4;

  /// Récupère le code EXISTANT, ou en génère+persiste un nouveau au 1er appel.
  ///
  /// Idempotent : une fois créé, le MÊME code est renvoyé à chaque appel (il ne
  /// doit jamais changer sous les pieds de l'utilisateur — c'est la clé de son
  /// coffre). Persisté dans le keystore OS.
  Future<String> getOrCreate() async {
    final existing = await _secureStorage.read(key: storageKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final code = _generate();
    await _secureStorage.write(key: storageKey, value: code);
    return code;
  }

  /// Lit le code s'il existe déjà, sans en créer (null si jamais généré).
  Future<String?> peek() => _secureStorage.read(key: storageKey);

  /// Génère un code lisible « XXXX-XXXX-XXXX-XXXX » via un CSPRNG.
  String _generate() {
    final rng = Random.secure();
    final groups = List.generate(_groupCount, (_) {
      final chars = List.generate(
        _groupSize,
        (_) => _alphabet[rng.nextInt(_alphabet.length)],
      );
      return chars.join();
    });
    return groups.join('-');
  }
}

/// Provider Riverpod du service de code de reconnexion (singleton app-wide).
final recoveryCodeServiceProvider = Provider<RecoveryCodeService>(
  (ref) => RecoveryCodeService(),
);

/// Le code de reconnexion (créé au 1er accès, puis stable). FutureProvider lu
/// par l'écran d'affichage et le nudge d'onboarding.
final recoveryCodeProvider = FutureProvider<String>((ref) {
  return ref.watch(recoveryCodeServiceProvider).getOrCreate();
});
