import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Coffre chiffré ZERO-KNOWLEDGE — primitive commune aux 2 gaps données L7.
///
/// StepWays L7 (B + C). Fournit :
///  - le CHIFFREMENT AUTHENTIFIÉ d'un blob JSON (AES-GCM 256 bits) dans une
///    enveloppe auto-descriptive versionnée (algo + nonce + tag + ciphertext) ;
///  - la DÉRIVATION d'une clé depuis un secret utilisateur (code de reconnexion)
///    via PBKDF2-HMAC-SHA256 (sel aléatoire, itérations élevées) ;
///  - la gestion d'une clé de données LOCALE stockée dans le KEYSTORE OS
///    (`flutter_secure_storage`) — jamais en clair, jamais dans les prefs.
///
/// GARANTIE ZÉRO-KNOWLEDGE : ce service ne produit que du CHIFFRÉ. Un blob
/// [VaultEnvelope] peut être stocké côté serveur (miroir cloud anonyme) sans
/// jamais exposer le clair : sans la clé (dérivée du code, ou dans le keystore
/// local), il est indéchiffrable. Le serveur ne voit ni identité, ni contenu.
///
/// Le sérialisé est du JSON compact base64 — portable (Firestore, fichier,
/// cloud OS) et indépendant de la plateforme.
class SecureVaultService {
  SecureVaultService({
    FlutterSecureStorage? secureStorage,
    AesGcm? cipher,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _cipher = cipher ?? AesGcm.with256bits();

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher;

  /// Version de l'enveloppe (migrations futures d'algo sans casse).
  static const int envelopeVersion = 1;

  /// Longueur du sel PBKDF2 (128 bits).
  static const int saltLength = 16;

  /// Itérations PBKDF2. Compromis sécurité/latence mobile (OWASP >= 100k pour
  /// PBKDF2-HMAC-SHA256 en 2023). Le code de reconnexion étant court, un coût
  /// élevé est la principale défense contre le brute-force hors-ligne.
  static const int pbkdf2Iterations = 120000;

  /// Clé keystore du secret de données LOCAL (backup fiche, gap C).
  static const String _dataKeyStorageKey = 'stepways.vault.dataKey.v1';

  // --- Dérivation de clé depuis le code de reconnexion (gap B) -------------

  /// Dérive une clé AES-256 depuis un [code] utilisateur + un [salt] donné.
  ///
  /// PBKDF2-HMAC-SHA256. Le [salt] doit être stocké AVEC le blob (il n'est pas
  /// secret) et régénéré à chaque (re)chiffrement. Déterministe : même
  /// (code, salt) => même clé (indispensable pour déchiffrer sur un autre tél).
  Future<SecretKey> deriveKeyFromCode(String code, List<int> salt) async {
    final pbkdf2 = Pbkdf2.hmacSha256(
      iterations: pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(code)),
      nonce: salt,
    );
  }

  /// Génère un sel aléatoire cryptographiquement sûr ([saltLength] octets).
  ///
  /// Source = CSPRNG `SecureRandom.fast` (ChaCha). Le sel n'est pas secret ; il
  /// doit seulement être unique et imprévisible par tirage.
  List<int> newSalt() => _randomBytes(saltLength);

  // --- Localisateur zéro-nominatif du coffre (gap B) -----------------------

  /// Contexte de domaine du localisateur (évite la réutilisation cross-usage).
  static const String _locatorContext = 'stepways.recovery.locator.v1';

  /// Dérive un LOCALISATEUR non nominatif depuis le seul [code], pour retrouver
  /// le coffre de reconnexion sur un nouveau téléphone (gap B).
  ///
  /// `SHA-256(contexte : code)` — déterministe (même code => même locator, sur
  /// n'importe quel appareil, hors-ligne) et NON RÉVERSIBLE vers une identité.
  /// AUCUN e-mail, AUCUN nom n'entre dans le calcul : le serveur ne stocke qu'un
  /// hash opaque comme id de document.
  ///
  /// PROPRIÉTÉ DE SÉCURITÉ (à documenter/arbitrer) : le code est le SEUL facteur
  /// (il localise ET déchiffre). Il doit donc être à haute entropie et le
  /// serveur doit limiter le débit (anti-brute-force en ligne). L'e-mail sert
  /// UNIQUEMENT, hors bande, à livrer le code à l'utilisateur légitime (canal
  /// backend — hors de cette couche).
  String computeLocator(String code) {
    final digest = crypto.sha256.convert(utf8.encode('$_locatorContext:$code'));
    return digest.toString();
  }

  // --- Clé de données LOCALE (gap C) ---------------------------------------

  /// Récupère (ou crée+stocke) la clé de données LOCALE dans le keystore OS.
  ///
  /// Utilisée pour chiffrer le backup de la fiche santé sur CE téléphone. La
  /// clé ne quitte jamais le keystore (Android Keystore / iOS Keychain) ; le
  /// blob chiffré, lui, peut être mis dans le miroir cloud anonyme.
  Future<SecretKey> getOrCreateLocalDataKey() async {
    final existing = await _secureStorage.read(key: _dataKeyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return SecretKey(base64Decode(existing));
    }
    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _secureStorage.write(
      key: _dataKeyStorageKey,
      value: base64Encode(bytes),
    );
    return SecretKey(bytes);
  }

  /// Efface la clé de données locale (droit à l'effacement / déconnexion).
  ///
  /// Après effacement, tout blob chiffré avec cette clé devient
  /// définitivement indéchiffrable (sauf blob code-dérivé, indépendant).
  Future<void> deleteLocalDataKey() =>
      _secureStorage.delete(key: _dataKeyStorageKey);

  // --- Chiffrement / déchiffrement d'un blob JSON --------------------------

  /// Chiffre [data] (JSON) avec [key] et retourne une [VaultEnvelope] sérialisée
  /// (chaîne base64/JSON, portable). Nonce aléatoire à chaque appel.
  ///
  /// [salt] est optionnel : conservé dans l'enveloppe uniquement pour les clés
  /// DÉRIVÉES d'un code (gap B), afin que l'autre téléphone puisse re-dériver la
  /// clé. Pour une clé locale (gap C), passer `null`.
  Future<String> encryptJson(
    Map<String, dynamic> data, {
    required SecretKey key,
    List<int>? salt,
  }) async {
    final plaintext = utf8.encode(json.encode(data));
    final secretBox = await _cipher.encrypt(plaintext, secretKey: key);
    final envelope = VaultEnvelope(
      version: envelopeVersion,
      algo: 'AES-GCM-256',
      kdf: salt != null ? 'PBKDF2-HMAC-SHA256/$pbkdf2Iterations' : null,
      salt: salt,
      nonce: secretBox.nonce,
      mac: secretBox.mac.bytes,
      cipherText: secretBox.cipherText,
    );
    return envelope.serialize();
  }

  /// Déchiffre une [VaultEnvelope] sérialisée avec [key] et retourne le JSON.
  ///
  /// Lève [VaultDecryptException] si le blob est corrompu, la clé mauvaise
  /// (échec d'authentification GCM = code de reconnexion faux), ou l'enveloppe
  /// illisible/versionnée inconnue. JAMAIS de clair partiel en cas d'échec.
  Future<Map<String, dynamic>> decryptJson(
    String serialized, {
    required SecretKey key,
  }) async {
    final VaultEnvelope envelope;
    try {
      envelope = VaultEnvelope.deserialize(serialized);
    } catch (e) {
      throw const VaultDecryptException('enveloppe illisible');
    }
    if (envelope.version != envelopeVersion) {
      throw VaultDecryptException('version inconnue: ${envelope.version}');
    }
    try {
      final clear = await _cipher.decrypt(
        SecretBox(
          envelope.cipherText,
          nonce: envelope.nonce,
          mac: Mac(envelope.mac),
        ),
        secretKey: key,
      );
      final decoded = json.decode(utf8.decode(clear));
      if (decoded is! Map<String, dynamic>) {
        throw const VaultDecryptException('contenu inattendu');
      }
      return decoded;
    } on VaultDecryptException {
      rethrow;
    } catch (e) {
      // SecretBoxAuthenticationError (mauvaise clé/altération) ou décodage.
      throw const VaultDecryptException('déchiffrement échoué');
    }
  }

  /// Lit le sel d'une enveloppe sérialisée sans la déchiffrer (gap B : re-dériver
  /// la clé depuis le code + ce sel). Retourne `null` si l'enveloppe n'a pas de
  /// sel (clé locale) ou est illisible.
  List<int>? saltOf(String serialized) {
    try {
      return VaultEnvelope.deserialize(serialized).salt;
    } catch (_) {
      return null;
    }
  }

  List<int> _randomBytes(int length) {
    final random = SecureRandom.fast;
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = random.nextInt(256);
    }
    return out;
  }
}

/// Enveloppe auto-descriptive d'un blob chiffré (sérialisable JSON/base64).
///
/// Tous les champs binaires sont encodés base64 dans le JSON. Le [salt] et le
/// [kdf] ne sont présents que pour les clés dérivées d'un code (gap B).
class VaultEnvelope {
  const VaultEnvelope({
    required this.version,
    required this.algo,
    required this.nonce,
    required this.mac,
    required this.cipherText,
    this.kdf,
    this.salt,
  });

  final int version;
  final String algo;
  final String? kdf;
  final List<int>? salt;
  final List<int> nonce;
  final List<int> mac;
  final List<int> cipherText;

  /// Sérialise en chaîne JSON compacte (champs binaires en base64).
  String serialize() {
    final map = <String, dynamic>{
      'v': version,
      'algo': algo,
      'nonce': base64Encode(nonce),
      'mac': base64Encode(mac),
      'ct': base64Encode(cipherText),
    };
    if (kdf != null) map['kdf'] = kdf;
    if (salt != null) map['salt'] = base64Encode(salt!);
    return json.encode(map);
  }

  /// Parse une enveloppe sérialisée. Lève si un champ requis manque.
  factory VaultEnvelope.deserialize(String serialized) {
    final map = json.decode(serialized) as Map<String, dynamic>;
    final salt = map['salt'] as String?;
    return VaultEnvelope(
      version: map['v'] as int,
      algo: map['algo'] as String,
      kdf: map['kdf'] as String?,
      salt: salt != null ? base64Decode(salt) : null,
      nonce: base64Decode(map['nonce'] as String),
      mac: base64Decode(map['mac'] as String),
      cipherText: base64Decode(map['ct'] as String),
    );
  }

  /// Représentation Firestore-friendly (Map de primitives) du blob chiffré.
  ///
  /// Pratique pour le miroir cloud anonyme : on n'y met QUE l'enveloppe (donc
  /// du chiffré) sous `users/{hash}/...`. Aucun clair, aucun nominatif.
  Map<String, dynamic> toCloudMap({required String updatedAt}) => {
        'vault': serialize(),
        'updated_at': updatedAt,
      };
}

/// Échec de déchiffrement du coffre (clé fausse, blob altéré, version inconnue).
class VaultDecryptException implements Exception {
  const VaultDecryptException(this.reason);
  final String reason;
  @override
  String toString() => 'VaultDecryptException: $reason';
}

/// Provider Riverpod du coffre chiffré (singleton app-wide).
final secureVaultServiceProvider = Provider<SecureVaultService>(
  (ref) => SecureVaultService(),
);
