import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/features/auth/data/local_auth_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';

/// Tests du service d'authentification local.
void main() {
  late LocalAuthService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = LocalAuthService();
  });

  tearDown(() {
    service.dispose();
  });

  group('LocalAuthService', () {
    test('signInAnonymously crée un utilisateur anonyme', () async {
      final user = await service.signInAnonymously();
      expect(user.isAnonymous, true);
      expect(user.authMethod, AuthMethod.anonymous);
      expect(user.uid, isNotEmpty);
    });

    test('currentUser est mis à jour après signInAnonymously', () async {
      await service.signInAnonymously();
      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.isAnonymous, true);
    });

    test('signInWithGoogleSilent retourne null (stub)', () async {
      final user = await service.signInWithGoogleSilent();
      expect(user, isNull);
    });

    test('signInWithApple retourne null (stub)', () async {
      final user = await service.signInWithApple();
      expect(user, isNull);
    });

    test('signOut revient en anonyme', () async {
      await service.signInAnonymously();
      await service.signOut();

      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.isAnonymous, true);
      expect(service.currentUser!.authMethod, AuthMethod.anonymous);
    });

    test('deleteAccount supprime et recrée un anonyme', () async {
      await service.signInAnonymously();

      await service.deleteAccount();

      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.isAnonymous, true);
      expect(service.currentUser!.uid, isNotEmpty);
    });

    test('authStateChanges émet les changements', () async {
      final states = <AuthUser?>[];
      final sub = service.authStateChanges.listen(states.add);

      await service.signInAnonymously();
      await service.signOut();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states.length, greaterThanOrEqualTo(2));

      await sub.cancel();
    });

    test('initialize auto-connecte en anonyme', () async {
      await service.initialize();
      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.isAnonymous, true);
    });
  });
}
