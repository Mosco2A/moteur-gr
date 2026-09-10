import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/treks/providers/my_treks_provider.dart';

/// Destinations d'accueil de l'app (StepWays LOT 3, Ph3).
class HomeLocations {
  /// Accueil « maison » : liste/choix des treks (aucune rando active).
  static const maison = '/my-treks';

  /// Accueil « terrain » : cockpit du trek en cours (rando active).
  static const terrain = '/home';
}

/// Sélecteur d'ACCUEIL CONTEXTUEL (StepWays LOT 3, Ph3 — SPEC §2/§3).
///
/// Dérive de [activeTrekIdProvider] : une rando active|paused existe → accueil
/// « terrain » ([HomeLocations.terrain] = `/home`, cockpit) ; sinon accueil
/// « maison » ([HomeLocations.maison] = `/my-treks`, liste des treks).
///
/// Remplace le fallback fixe `/my-treks` du bouton Accueil de l'`AppHeader` (Ph1)
/// par cette dérivation maison/terrain. Le remplacement de `initialLocation` +
/// guard du routeur (SPEC §3) est traité au big-bang (Ph4/L5) ; ici on fournit
/// la dérivation (additive), consommée par l'`AppHeader`.
///
/// SYNCHRONE : lit la valeur COURANTE de `activeTrekIdProvider` (FutureProvider)
/// — pendant le chargement/erreur, on retombe sur « maison » (défaut sûr, aucun
/// cul-de-sac). La synchro de `selectedTrailIdProvider` sur l'id actif est
/// portée par la reprise orpheline (LOT 2) / le cockpit ; le sélecteur ici ne
/// fait QUE choisir la destination.
final homeLocationProvider = Provider<String>((ref) {
  // `.value` de l'AsyncValue<String?> : null pendant le chargement/erreur OU si
  // aucune rando active -> accueil « maison » (défaut sûr, aucun cul-de-sac).
  final activeTrekId = ref.watch(activeTrekIdProvider).value;
  return activeTrekId != null ? HomeLocations.terrain : HomeLocations.maison;
});
