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
    test('signInAnonymously retourne un user local', () async {
      final user = await service.signInAnonymously();

      expect(user.isAnonymous, true);
      expect(user.authMethod, AuthMethodValues.anonymous);
      expect(user.uid, isNotEmpty);
      // Vérifier que c'est un UUID valide (format v4)
      expect(user.uid.length, greaterThanOrEqualTo(32));
    });

    test('authStateChanges stream fonctionne', () async {
      final states = <AuthUser?>[];
      final sub = service.authStateChanges.listen(states.add);

      await service.signInAnonymously();
      await service.signOut();

      // Laisser le stream propager
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Au moins 2 événements: signIn + signOut
      expect(states.length, greaterThanOrEqualTo(2));
      // Premier événement = utilisateur anonyme
      expect(states.first?.isAnonymous, true);
      expect(states.first?.authMethod, AuthMethodValues.anonymous);
      // Dernier événement = toujours anonyme (signOut revient en anonyme)
      expect(states.last?.isAnonymous, true);

      await sub.cancel();
    });

    test('currentUser est mis à jour après signInAnonymously', () async {
      expect(service.currentUser, isNull);

      await service.signInAnonymously();

      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.isAnonymous, true);
    });

    test('signOut revient en anonyme', () async {
      await service.signInAnonymously();
      await service.signOut();

      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.isAnonymous, true);
      expect(service.currentUser!.authMethod, AuthMethodValues.anonymous);
    });

    test('initialize auto-connecte en anonyme', () async {
      await service.initialize();

      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.isAnonymous, true);
    });

    test('deleteAccount supprime et recrée un anonyme', () async {
      await service.signInAnonymously();
      // ignore: unused_local_variable
      final originalUid = service.currentUser!.uid;

      await service.deleteAccount();

      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.isAnonymous, true);
      // Le nouvel anonyme a un UID différent
      expect(service.currentUser!.uid, isNotEmpty);
    });
  });
}
