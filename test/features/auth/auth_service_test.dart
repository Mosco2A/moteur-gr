import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';

/// Tests du modèle AuthUser et des enums d'authentification.
void main() {
  group('AuthUser', () {
    test('constructeur anonyme', () {
      const user = AuthUser(
        uid: 'test-uid',
        authMethod: AuthMethod.anonymous,
        isAnonymous: true,
      );

      expect(user.uid, 'test-uid');
      expect(user.authMethod, AuthMethod.anonymous);
      expect(user.isAnonymous, true);
      expect(user.displayName, isNull);
      expect(user.email, isNull);
      expect(user.photoUrl, isNull);
    });

    test('constructeur identifié', () {
      const user = AuthUser(
        uid: 'google-uid',
        authMethod: AuthMethod.google,
        displayName: 'Jean Dupont',
        email: 'jean@example.com',
        photoUrl: 'https://photo.url',
        isAnonymous: false,
      );

      expect(user.isAnonymous, false);
      expect(user.displayName, 'Jean Dupont');
      expect(user.email, 'jean@example.com');
      expect(user.authMethod, AuthMethod.google);
    });
  });

  group('AuthMethod', () {
    test('3 méthodes disponibles', () {
      expect(AuthMethod.values.length, 3);
    });

    test('labels corrects', () {
      expect(AuthMethod.anonymous.label, 'Anonyme');
      expect(AuthMethod.google.label, 'Google');
      expect(AuthMethod.apple.label, 'Apple');
    });
  });
}
