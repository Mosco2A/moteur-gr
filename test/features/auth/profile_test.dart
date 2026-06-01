import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/features/auth/data/local_auth_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';

/// Tests profil : sauvegarde pseudo + avatar.
void main() {
  late LocalAuthService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = LocalAuthService();
  });

  tearDown(() {
    service.dispose();
  });

  group('Profile - sauvegarde pseudo', () {
    test('updateDisplayName sauvegarde et notifie', () async {
      await service.signInAnonymously();
      expect(service.currentUser!.displayName, isNull);

      final states = <AuthUser?>[];
      final sub = service.authStateChanges.listen(states.add);

      await service.updateDisplayName('MontagnardFou');

      // Attendre propagation du stream
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.currentUser!.displayName, 'MontagnardFou');
      expect(states.any((u) => u?.displayName == 'MontagnardFou'), isTrue);

      await sub.cancel();
    });

    test('updateDisplayName vide remet displayName a null', () async {
      await service.signInAnonymously();
      await service.updateDisplayName('Randonneur42');
      expect(service.currentUser!.displayName, 'Randonneur42');

      await service.updateDisplayName('   ');
      expect(service.currentUser!.displayName, isNull);
    });

    test('updateAvatarIndex sauvegarde et clamp 0-7', () async {
      await service.signInAnonymously();
      expect(service.currentUser!.avatarIndex, 0);

      await service.updateAvatarIndex(5);
      expect(service.currentUser!.avatarIndex, 5);

      // Clamp a 7 max
      await service.updateAvatarIndex(99);
      expect(service.currentUser!.avatarIndex, 7);

      // Clamp a 0 min
      await service.updateAvatarIndex(-3);
      expect(service.currentUser!.avatarIndex, 0);
    });

    test('pseudo persiste apres re-initialize', () async {
      await service.signInAnonymously();
      await service.updateDisplayName('TrekkerPro');
      await service.updateAvatarIndex(3);

      // Simuler un redemarrage
      final service2 = LocalAuthService();
      await service2.initialize();

      expect(service2.currentUser!.displayName, 'TrekkerPro');
      expect(service2.currentUser!.avatarIndex, 3);

      service2.dispose();
    });
  });
}
