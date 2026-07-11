import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

/// Providers du HUB d'accueil (E07 / LOT-A).
///
/// Le HUB ne cree AUCUN etat metier : il derive uniquement des providers
/// existants (auth, trek, config sentier) que l'ecran consomme en lecture
/// seule (AM-5). Ce fichier n'expose que la derivation strictement propre au
/// HUB : le prenom d'affichage de la salutation (RF-3).

/// Prenom d'affichage pour la salutation du HUB (RF-3, #F03).
///
/// Le modele [AuthUser] est ZERO PII (#81775) : `displayName` est un pseudonyme
/// libre (E00 par6bis), null si l'utilisateur n'en a pas saisi. Ce provider
/// derive ce pseudonyme depuis [authStateProvider] et le normalise :
/// - retourne le pseudonyme s'il est non vide ;
/// - retourne `null` sinon (l'UI applique alors le repli localise
///   « Randonneur » via `t.hub.greetingFallback`, jamais code en dur ici).
///
/// Aucun etat cree : simple derivation `select` de l'auth (respecte AM-5).
final displayNameProvider = Provider<String?>((ref) {
  final name = ref.watch(
    authStateProvider.select((user) => user?.displayName),
  );
  if (name == null) return null;
  final trimmed = name.trim();
  return trimmed.isEmpty ? null : trimmed;
});
