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

    test(
        'FIX CYCLE 2 (issue 3) : offline-first — un timeout court ne fige pas '
        'et retombe en mode local RAPIDEMENT', () async {
      // Cold-boot HORS-LIGNE : `Firebase.initializeApp` peut PENDRE (pas juste
      // jeter) -> sans borne de temps, le premier frame n'est jamais rendu.
      // L'init est desormais bornee par `.timeout(...)` : on verifie qu'avec un
      // delai tres court, `initialize` REND LA MAIN vite (offline-first) et
      // retombe proprement en mode local (isAvailable=false), sans jamais figer.
      final sw = Stopwatch()..start();
      final service = await FirebaseService.initialize(
        firebaseProjectId: 'test-project-id',
        timeout: const Duration(milliseconds: 50),
      );
      sw.stop();

      expect(service.isAvailable, false);
      // Filet anti-hang : la resolution reste bornee (largement sous le delai
      // par defaut de 4 s). On laisse une marge confortable pour la CI.
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)),
          reason: 'initialize ne doit jamais figer le demarrage (offline-first)');
    });
  });
}
