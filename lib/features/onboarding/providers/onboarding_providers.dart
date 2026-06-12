import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cle SharedPreferences pour le flag d'onboarding complete.
///
/// Convention alignee sur [SettingsKeys] (prefixe explicite, valeur stable).
const String kOnboardingCompletedKey = 'onboarding_completed';

/// Provider async qui lit le flag d'onboarding depuis SharedPreferences.
///
/// Retourne `true` si l'onboarding a deja ete complete, `false` sinon
/// (premier lancement). Consomme par le redirect GoRouter pour decider
/// d'afficher ou non l'ecran d'accueil ([OnboardingScreen]).
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kOnboardingCompletedKey) ?? false;
});

/// Marque l'onboarding comme termine dans SharedPreferences.
///
/// Appele par [OnboardingScreen] quand l'utilisateur termine la
/// derniere page ou utilise le bouton « Passer ». Invalide
/// [onboardingCompletedProvider] pour forcer sa relecture (le guard
/// du routeur verra alors `true` et ne reaffichera plus l'onboarding).
Future<void> completeOnboarding(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingCompletedKey, true);
  ref.invalidate(onboardingCompletedProvider);
}
