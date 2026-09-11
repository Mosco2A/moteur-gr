import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/secure_vault_service.dart';

/// Tests de la primitive de coffre chiffré ZERO-KNOWLEDGE (StepWays L7 B/C).
///
/// On n'utilise PAS `flutter_secure_storage` ici (keystore natif indispo en
/// test unitaire pur) : on teste le chiffrement/déchiffrement et la dérivation
/// de clé, qui sont la garantie zéro-knowledge. La clé locale keystore est
/// couverte séparément (elle délègue au plugin OS).
void main() {
  // Clé AES-256 fixe pour les round-trips (32 octets).
  final fixedKey = SecretKey(List<int>.generate(32, (i) => i));
  final vault = SecureVaultService();

  const sample = <String, dynamic>{
    'bloodType': 'O-',
    'allergies': 'Pénicilline, arachides',
    'treatments': 'Levothyrox 50mg/j',
    'accents': 'àéîõü — 中文 — €',
    'n': 42,
  };

  group('SecureVaultService — chiffrement AES-GCM', () {
    test(
      'round-trip: encryptJson puis decryptJson restitue les données',
      () async {
        final blob = await vault.encryptJson(sample, key: fixedKey);
        final restored = await vault.decryptJson(blob, key: fixedKey);
        expect(restored, sample);
      },
    );

    test(
      'le blob sérialisé ne contient AUCUN clair (zéro-knowledge)',
      () async {
        final blob = await vault.encryptJson(sample, key: fixedKey);
        // Aucune valeur sensible visible dans le sérialisé.
        expect(blob.contains('Pénicilline'), isFalse);
        expect(blob.contains('Levothyrox'), isFalse);
        expect(blob.contains('O-'), isFalse);
        // Enveloppe auto-descriptive : algo présent, ciphertext base64.
        final map = json.decode(blob) as Map<String, dynamic>;
        expect(map['algo'], 'AES-GCM-256');
        expect(map['v'], SecureVaultService.envelopeVersion);
        expect(map['ct'], isA<String>());
      },
    );

    test(
      'nonce aléatoire : deux chiffrements du même clair diffèrent',
      () async {
        final a = await vault.encryptJson(sample, key: fixedKey);
        final b = await vault.encryptJson(sample, key: fixedKey);
        expect(a, isNot(equals(b)));
        // Mais les deux déchiffrent vers la même valeur.
        expect(await vault.decryptJson(a, key: fixedKey), sample);
        expect(await vault.decryptJson(b, key: fixedKey), sample);
      },
    );

    test(
      'mauvaise clé => VaultDecryptException (authentification GCM)',
      () async {
        final blob = await vault.encryptJson(sample, key: fixedKey);
        final wrongKey = SecretKey(List<int>.generate(32, (i) => 255 - i));
        expect(
          () => vault.decryptJson(blob, key: wrongKey),
          throwsA(isA<VaultDecryptException>()),
        );
      },
    );

    test('blob altéré (tamper) => VaultDecryptException', () async {
      final blob = await vault.encryptJson(sample, key: fixedKey);
      final map = json.decode(blob) as Map<String, dynamic>;
      // Corrompt le ciphertext (flip d'un octet).
      final ct = base64Decode(map['ct'] as String);
      ct[0] = ct[0] ^ 0x01;
      map['ct'] = base64Encode(ct);
      final tampered = json.encode(map);
      expect(
        () => vault.decryptJson(tampered, key: fixedKey),
        throwsA(isA<VaultDecryptException>()),
      );
    });

    test('enveloppe illisible => VaultDecryptException', () async {
      expect(
        () => vault.decryptJson('pas du json', key: fixedKey),
        throwsA(isA<VaultDecryptException>()),
      );
    });
  });

  group('SecureVaultService — dérivation depuis le code de reconnexion', () {
    test('même (code, sel) => même clé (déterministe cross-device)', () async {
      final salt = vault.newSalt();
      final k1 = await vault.deriveKeyFromCode('CODE-1234-ABCD', salt);
      final k2 = await vault.deriveKeyFromCode('CODE-1234-ABCD', salt);
      expect(await k1.extractBytes(), await k2.extractBytes());
    });

    test('codes différents => clés différentes', () async {
      final salt = vault.newSalt();
      final k1 = await vault.deriveKeyFromCode('CODE-AAAA', salt);
      final k2 = await vault.deriveKeyFromCode('CODE-BBBB', salt);
      expect(await k1.extractBytes(), isNot(equals(await k2.extractBytes())));
    });

    test('sels différents => clés différentes (même code)', () async {
      final k1 = await vault.deriveKeyFromCode('CODE', vault.newSalt());
      final k2 = await vault.deriveKeyFromCode('CODE', vault.newSalt());
      expect(await k1.extractBytes(), isNot(equals(await k2.extractBytes())));
    });

    test('scénario B : chiffrer sur tél A, re-dériver la clé sur tél B via le '
        'code + sel de l\'enveloppe, déchiffrer', () async {
      // Tél A : dérive une clé du code, chiffre le coffre, embarque le sel.
      const code = 'ABCD-1234-EFGH';
      final salt = vault.newSalt();
      final keyA = await vault.deriveKeyFromCode(code, salt);
      final blob = await vault.encryptJson(sample, key: keyA, salt: salt);

      // Tél B : lit le sel DANS le blob, re-dérive la clé du même code.
      final saltFromBlob = vault.saltOf(blob);
      expect(saltFromBlob, isNotNull);
      final keyB = await vault.deriveKeyFromCode(code, saltFromBlob!);
      final restored = await vault.decryptJson(blob, key: keyB);
      expect(restored, sample);
    });

    test(
      'scénario B : mauvais code sur tél B => échec (pas de clair)',
      () async {
        const code = 'BON-CODE';
        final salt = vault.newSalt();
        final keyA = await vault.deriveKeyFromCode(code, salt);
        final blob = await vault.encryptJson(sample, key: keyA, salt: salt);

        final wrongKey = await vault.deriveKeyFromCode(
          'MAUVAIS-CODE',
          vault.saltOf(blob)!,
        );
        expect(
          () => vault.decryptJson(blob, key: wrongKey),
          throwsA(isA<VaultDecryptException>()),
        );
      },
    );
  });

  group('VaultEnvelope — sérialisation', () {
    test('serialize/deserialize round-trip', () {
      const env = VaultEnvelope(
        version: 1,
        algo: 'AES-GCM-256',
        kdf: 'PBKDF2-HMAC-SHA256/120000',
        salt: [1, 2, 3, 4],
        nonce: [5, 6, 7, 8, 9, 10, 11, 12],
        mac: [13, 14, 15, 16],
        cipherText: [17, 18, 19],
      );
      final round = VaultEnvelope.deserialize(env.serialize());
      expect(round.version, env.version);
      expect(round.algo, env.algo);
      expect(round.kdf, env.kdf);
      expect(round.salt, env.salt);
      expect(round.nonce, env.nonce);
      expect(round.mac, env.mac);
      expect(round.cipherText, env.cipherText);
    });

    test('toCloudMap ne contient que le blob chiffré + timestamp', () {
      const env = VaultEnvelope(
        version: 1,
        algo: 'AES-GCM-256',
        nonce: [1, 2, 3],
        mac: [4, 5, 6],
        cipherText: [7, 8, 9],
      );
      final map = env.toCloudMap(updatedAt: '2026-09-11T00:00:00.000');
      expect(map.keys.toSet(), {'vault', 'updated_at'});
      expect(map['vault'], isA<String>());
    });
  });
}
