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

/// Marque l'onboarding comme termine.
///
/// Appele par [OnboardingScreen] quand l'utilisateur termine la derniere page
/// (« Commencer »), « Passe » l'accueil, ou clique « Parcourir le catalogue ».
///
/// Effectue DEUX choses, dans cet ordre :
///   1. met a jour le drapeau GLOBAL synchrone [hasCompletedOnboarding] que LIT
///      le guard du routeur (redirectForPath). C'est le point CRITIQUE : sans
///      cette ligne, le guard continuait de voir `false` apres l'onboarding et
///      RENVOYAIT l'utilisateur vers /onboarding des qu'il entrait dans un
///      sentier (context.go('/map')). Resultat ressenti : « Passer / Commencer /
///      Parcourir ne font rien » (bug GO-62). On le pose AVANT toute navigation.
///   2. persiste le flag dans SharedPreferences (relances suivantes) et invalide
///      [onboardingCompletedProvider] pour relecture coherente.
Future<void> completeOnboarding(WidgetRef ref) async {
  // 1. Drapeau memoire lu par le guard -> effet immediat sur la navigation.
  hasCompletedOnboarding = true;
  // 2. Persistance + relecture du provider.
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingCompletedKey, true);
  ref.invalidate(onboardingCompletedProvider);
}
