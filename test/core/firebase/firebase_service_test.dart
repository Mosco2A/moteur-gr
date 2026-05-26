import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';

/// Tests du service Firebase.
void main() {
  group('FirebaseService', () {
    test('initialize avec null projectId retourne isAvailable=false', () async {
      final service = await FirebaseService.initialize(
        firebaseProjectId: null,
      );

      expect(service.isAvailable, false);
    });

    test('isAvailable est false par defaut (sans init)', () async {
      // Simuler le cas ou Firebase.initializeApp echoue
      // (pas de firebase_options.dart configure)
      final service = await FirebaseService.initialize(
        firebaseProjectId: null,
      );

      expect(service.isAvailable, false);
    });

    test('initialize avec projectId mais sans FirebaseOptions retourne false', () async {
      // Sans DefaultFirebaseOptions configure, Firebase.initializeApp
      // va throw une exception, et le service tombe en fallback local
      final service = await FirebaseService.initialize(
        firebaseProjectId: 'test-project-id',
      );

      // En environnement de test sans config Firebase reelle,
      // l init echoue et isAvailable = false (fallback gracieux)
      expect(service.isAvailable, false);
    });
  });
}
