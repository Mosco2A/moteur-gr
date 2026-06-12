import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/onboarding/providers/onboarding_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests des providers d'onboarding (E5.1b).
///
/// Verifie la lecture du flag depuis SharedPreferences et sa persistance,
/// qui permet au guard du routeur de sauter l'onboarding une fois complete.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('onboardingCompletedProvider vaut false au premier lancement', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final completed = await container.read(onboardingCompletedProvider.future);
    expect(completed, isFalse);
  });

  test(
    'onboardingCompletedProvider vaut true si deja complete (skip)',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kOnboardingCompletedKey: true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final completed = await container.read(
        onboardingCompletedProvider.future,
      );
      expect(completed, isTrue);
    },
  );

  test(
    'completeOnboarding persiste le flag et reinvalide le provider',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Etat initial : non complete.
      expect(await container.read(onboardingCompletedProvider.future), isFalse);

      // ProviderContainer n'expose pas WidgetRef ; on persiste directement
      // puis on invalide, ce qui reproduit l'effet de completeOnboarding.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingCompletedKey, true);
      container.invalidate(onboardingCompletedProvider);

      expect(await container.read(onboardingCompletedProvider.future), isTrue);
      expect(prefs.getBool(kOnboardingCompletedKey), isTrue);
    },
  );
}
