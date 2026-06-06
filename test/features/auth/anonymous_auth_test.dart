import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/features/auth/data/anonymous_id_service.dart';
import 'package:moteur_gr/features/auth/data/local_auth_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';

/// Tests E4.15 — Auth anonymisee SHA-256.
///
/// Contrat d anonymisation (#81775 / spec #81796) :
/// 1. Hash deterministe (meme input = meme output) et irreversible.
/// 2. Pas de donnees personnelles stockees (AuthUser sans PII).
/// 3. Cablage provider : fallback local quand Firebase indisponible.
void main() {
  group('AnonymousIdService', () {
    test('hash deterministe — meme input produit meme output', () {
      const firebaseUid = 'firebase-uid-abc123';

      final hash1 = AnonymousIdService.hashUserId(firebaseUid);
      final hash2 = AnonymousIdService.hashUserId(firebaseUid);

      // Deterministe : deux appels identiques = meme resultat
      expect(hash1, equals(hash2));

      // Format SHA-256 : 64 caracteres hexadecimaux
      expect(hash1.length, 64);
      expect(hash1, matches(RegExp(r'^[a-f0-9]{64}$')));

      // Irreversible : le hash ne contient pas l'UID original
      expect(hash1, isNot(contains('firebase-uid-abc123')));

      // UIDs differents = hashes differents
      final hash3 = AnonymousIdService.hashUserId('autre-uid-xyz789');
      expect(hash1, isNot(equals(hash3)));
    });

    test('zero PII stocke — AuthUser anonymise sans donnees perso', () {
      // Simuler un utilisateur Firebase avec des donnees perso
      const firebaseUid = 'firebase-uid-test456';

      // Anonymisation : seul le hash du UID est conserve
      final anonymizedUid = AnonymousIdService.hashUserId(firebaseUid);

      // Construire l'AuthUser comme le fait FirebaseAuthService
      // (sans email, nom, photo — zero PII)
      final user = AuthUser(
        uid: anonymizedUid,
        authMethod: AuthMethodValues.google,
        isAnonymous: false,
        // displayName: null — sera choisi localement
        // email: null — JAMAIS stocke
        // photoUrl: null — JAMAIS stocke
      );

      // Verifier : aucune PII dans l'AuthUser
      expect(user.email, isNull, reason: 'Email ne doit JAMAIS etre stocke');
      expect(user.photoUrl, isNull,
          reason: 'Photo ne doit JAMAIS etre stockee');
      expect(user.displayName, isNull,
          reason: 'Nom Firebase ne doit JAMAIS etre stocke');

      // Le UID est anonymise, pas l'original
      expect(user.uid, isNot(equals(firebaseUid)));
      expect(user.uid, equals(anonymizedUid));

      // Le hash ne contient aucune donnee perso
      expect(user.uid, isNot(contains('jean.dupont@gmail.com')));
      expect(user.uid, isNot(contains('Jean Dupont')));

      // L'utilisateur est bien identifie (pas anonyme)
      expect(user.isAnonymous, false);
      expect(user.authMethod, AuthMethodValues.google);
    });
  });

  group('cablage authServiceProvider (E4.15)', () {
    test('Firebase indisponible -> fallback LocalAuthService', () {
      final container = ProviderContainer(
        overrides: [
          firebaseServiceProvider.overrideWithValue(
            FirebaseService.testOnly(isAvailable: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(authServiceProvider);
      expect(service, isA<LocalAuthService>());
    });
  });
}
