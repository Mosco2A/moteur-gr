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
      // email/photoUrl n'existent plus dans AuthUser (F7) :
      // zero PII garanti a la compilation.
    });

    test('constructeur identifié', () {
      // F7 : le modele n'accepte AUCUNE PII (ni email ni photo),
      // meme pour un utilisateur identifie — pseudo libre uniquement.
      const user = AuthUser(
        uid: 'google-uid',
        authMethod: AuthMethodValues.google,
        displayName: 'Pseudo Libre',
        isAnonymous: false,
      );

      expect(user.isAnonymous, false);
      expect(user.displayName, 'Pseudo Libre');
      expect(user.authMethod, AuthMethodValues.google);
    });
  });

  group('AuthMethodValues', () {
    test('3 méthodes disponibles', () {
      expect(AuthMethodValues.values.length, 3);
    });

    test('labels corrects', () {
      // D4A-03 : pas de « anonyme » cote utilisateur -> « Sans compte ».
      expect(
        AuthMethodValues.labelFor(AuthMethodValues.anonymous),
        'Sans compte',
      );
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
