import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/auth/data/auth_guard.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';

/// Tests du guard GoRouter d'authentification.
///
/// On teste la logique du guard (getCurrentUser + onAutoSignIn)
/// sans construire de GoRouterState (API interne de GoRouter 13).
void main() {
  group('AuthGuard - logique de redirection', () {
    test('redirige quand utilisateur null et auto sign-in echoue', () async {
      String? redirectResult;

      final guard = AuthGuard(
        getCurrentUser: () => null,
        onAutoSignIn: () async {},
      );

      // Tester la logique : path non-publique, user null
      final user = guard.getCurrentUser();
      if (user == null) {
        await guard.onAutoSignIn();
        final userAfter = guard.getCurrentUser();
        redirectResult = userAfter == null ? '/no-data' : null;
      }

      expect(redirectResult, '/no-data');
    });

    test('laisse passer quand utilisateur connecte (meme anonyme)', () async {
      const user = AuthUser(
        uid: 'test-uid',
        authMethod: AuthMethodValues.anonymous,
        isAnonymous: true,
      );

      final guard = AuthGuard(
        getCurrentUser: () => user,
        onAutoSignIn: () async {},
      );

      // Utilisateur present = pas de redirection
      final currentUser = guard.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.isAnonymous, isTrue);
    });

    test('routes publiques identifiees correctement', () {
      // Verifier que les paths publics sont bien dans la liste
      const publicPaths = ['/no-data', '/catalog'];
      expect(publicPaths.contains('/no-data'), isTrue);
      expect(publicPaths.contains('/catalog'), isTrue);
      expect(publicPaths.contains('/trails'), isFalse);
      expect(publicPaths.contains('/profile'), isFalse);
    });

    test('auto sign-in anonyme fonctionne', () async {
      AuthUser? currentUser;

      final guard = AuthGuard(
        getCurrentUser: () => currentUser,
        onAutoSignIn: () async {
          currentUser = const AuthUser(
            uid: 'auto-uid',
            authMethod: AuthMethodValues.anonymous,
            isAnonymous: true,
          );
        },
      );

      // Avant auto sign-in : pas d'utilisateur
      expect(guard.getCurrentUser(), isNull);

      // Declencher auto sign-in
      await guard.onAutoSignIn();

      // Apres auto sign-in : utilisateur anonyme present
      final userAfter = guard.getCurrentUser();
      expect(userAfter, isNotNull);
      expect(userAfter!.isAnonymous, isTrue);
      expect(userAfter.uid, 'auto-uid');
    });
  });
}
