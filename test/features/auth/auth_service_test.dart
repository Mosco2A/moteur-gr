import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';

/// Tests du modèle AuthUser et des constantes d'authentification.
void main() {
  group('AuthUser', () {
    test('constructeur anonyme', () {
      const user = AuthUser(
        uid: 'test-uid',
        authMethod: AuthMethodValues.anonymous,
        isAnonymous: true,
      );

      expect(user.uid, 'test-uid');
      expect(user.authMethod, AuthMethodValues.anonymous);
      expect(user.isAnonymous, true);
      expect(user.displayName, isNull);
      expect(user.email, isNull);
      expect(user.photoUrl, isNull);
    });

    test('constructeur identifié', () {
      const user = AuthUser(
        uid: 'google-uid',
        authMethod: AuthMethodValues.google,
        displayName: 'Jean Dupont',
        email: 'jean@example.com',
        photoUrl: 'https://photo.url',
        isAnonymous: false,
      );

      expect(user.isAnonymous, false);
      expect(user.displayName, 'Jean Dupont');
      expect(user.email, 'jean@example.com');
      expect(user.authMethod, AuthMethodValues.google);
    });
  });

  group('AuthMethodValues', () {
    test('3 méthodes disponibles', () {
      expect(AuthMethodValues.values.length, 3);
    });

    test('labels corrects', () {
      expect(AuthMethodValues.labelFor(AuthMethodValues.anonymous), 'Anonyme');
      expect(AuthMethodValues.labelFor(AuthMethodValues.google), 'Google');
      expect(AuthMethodValues.labelFor(AuthMethodValues.apple), 'Apple');
    });

    test('fromString avec valeur connue', () {
      expect(AuthMethodValues.fromString('google'), AuthMethodValues.google);
    });

    test('fromString avec valeur inconnue retourne fallback', () {
      expect(AuthMethodValues.fromString('unknown'), AuthMethodValues.fallback);
    });
  });
}
