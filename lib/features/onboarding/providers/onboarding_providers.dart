import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routing/app_router.dart' show hasCompletedOnboarding;

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
/// [onboardingCompletedProvider] pour forcer sa relecture.
///
/// FIX boucle /catalog -> /onboarding (LOT 0) : met AUSSI a jour la variable
/// globale [hasCompletedOnboarding]. C'est ELLE (et non le provider) que lit le
/// guard synchrone `redirectForPath` (`app_router.dart`), lequel n'a pas de
/// `refreshListenable`. Sans cette ligne, apres `completeOnboarding` la globale
/// restait `false` (initialisee au boot depuis les prefs, premier lancement) et
/// le guard renvoyait `/catalog` -> `/onboarding` en boucle. On persiste (prefs,
/// contrat au prochain lancement), on rafraichit le provider (consommateurs
/// eventuels) ET on aligne la globale (contrat du guard).
Future<void> completeOnboarding(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingCompletedKey, true);
  hasCompletedOnboarding = true;
  ref.invalidate(onboardingCompletedProvider);
}
