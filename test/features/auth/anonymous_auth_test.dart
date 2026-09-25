import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/features/auth/data/anonymous_id_service.dart';
import 'package:moteur_gr/features/auth/data/local_auth_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests E4.15 — Auth anonymisee SHA-256.
///
/// Contrat d anonymisation (#81775 / spec #81796) :
/// 1. Hash deterministe (meme input = meme output) et irreversible.
/// 2. Pas de donnees personnelles stockees (AuthUser sans PII).
/// 3. Cablage provider : fallback local quand Firebase indisponible.
///
/// INSTABILITE REPAREE (tache 561, J3) — ce fichier passait une fois sur trois
/// sous charge parallele, et deux fois sur deux en isolation. Il n'y avait rien
/// d'aleatoire : `authServiceProvider` lance `LocalAuthService.initialize()` en
/// fire-and-forget (`unawaited`), et ce test laissait DEUX erreurs asynchrones
/// sans porteur derriere lui.
///
///   1. `SharedPreferences.getInstance()` sans valeurs mockees lance
///      `MissingPluginException` (aucun binding de plugin en test unitaire).
///   2. Le `container.dispose()` du tearDown fermait le StreamController pendant
///      que l'initialisation etait encore en vol -> `Bad state: Cannot add new
///      events after calling close`.
///
/// Dans les deux cas l'erreur arrive APRES la fin du test. En isolation, le
/// fichier se termine avant qu'elle ne remonte : vert. Dans la suite complete,
/// l'ordonnancement decale son arrivee, elle atterrit dans la zone d'un test
/// encore en cours et le fait tomber : rouge, sur un test qui n'y est pour rien.
/// Correction : prefs mockees (cause 1), attente explicite de la fin de
/// l'initialisation avant le dispose (cause 2), et garde-fou cote service
/// (`LocalAuthService._emit`) pour que ce ne soit plus jamais une erreur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Sans ceci, le `initialize()` fire-and-forget du provider explose en
    // MissingPluginException hors de tout porteur d'erreur.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

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

      // Verifier : aucune PII dans l'AuthUser.
      // email/photoUrl n'existent PLUS dans le modele (F7) : le
      // contrat zero PII est garanti a la compilation, plus fort
      // qu'une assertion runtime.
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
    test('Firebase indisponible -> fallback LocalAuthService', () async {
      final container = ProviderContainer(
        overrides: [
          firebaseServiceProvider.overrideWithValue(
            FirebaseService.testOnly(isAvailable: false),
          ),
        ],
      );

      final service = container.read(authServiceProvider);
      expect(service, isA<LocalAuthService>());

      // L'initialisation lancee par le provider est fire-and-forget : on la
      // laisse s'achever AVANT de fermer le container, sinon on part en
      // laissant du travail en vol — la cause meme de l'instabilite.
      await pumpEventQueue();
      container.dispose();
      await pumpEventQueue();
    });

    test('un dispose PENDANT l initialisation ne leve plus rien (J3)',
        () async {
      final container = ProviderContainer(
        overrides: [
          firebaseServiceProvider.overrideWithValue(
            FirebaseService.testOnly(isAvailable: false),
          ),
        ],
      );
      container.read(authServiceProvider);
      // Dispose IMMEDIAT : le `initialize()` est encore en vol et va vouloir
      // emettre sur un controller deja ferme. C'etait `Bad state: Cannot add
      // new events after calling close`, une erreur asynchrone imputee au test
      // suivant. Elle ne doit plus se produire du tout.
      container.dispose();
      await pumpEventQueue();
    });

    test('emettre apres dispose est sans effet, jamais une erreur', () async {
      final service = LocalAuthService();
      final seen = <AuthUser?>[];
      final sub = service.authStateChanges.listen(seen.add);
      await service.signInAnonymously();
      await pumpEventQueue();
      expect(seen.length, 1);

      service.dispose();
      // Apres dispose, toute emission est absorbee : aucune exception.
      await service.signInAnonymously();
      await service.signOut();
      await service.updateAvatarIndex(3);
      await pumpEventQueue();
      expect(seen.length, 1, reason: 'plus personne n ecoute, rien n est emis');
      await sub.cancel();
    });
  });
}
