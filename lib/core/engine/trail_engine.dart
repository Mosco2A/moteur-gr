import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/trail_config.dart';
import '../config/trail_selection.dart';

/// Moteur central du Moteur GR.
///
/// Point d'entrée unique pour accéder à la configuration du sentier
/// actif. Tous les modules (thème, navigation, GPS, etc.) lisent
/// la config depuis ce provider.
///
/// Multi-sentiers (F8D-01, #84627) : par défaut, la config active est RÉSOLUE
/// depuis la sélection de l'utilisateur ([selectedTrailIdProvider]) sur le
/// catalogue ([resolvedTrailConfigProvider]). Changer de sentier (F8D-02) =
/// écrire le nouvel id dans [selectedTrailIdProvider] ; toute l'app suit.
///
/// Override possible (mono-sentier dédié, tests) — l'override prime toujours :
/// ```dart
/// void main() {
///   const config = TrailConfig(...);
///   runApp(
///     ProviderScope(
///       overrides: [
///         trailConfigProvider.overrideWithValue(config),
///       ],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
final trailConfigProvider = Provider<TrailConfig>((ref) {
  // Par défaut : sentier sélectionné, résolu sur le catalogue (genericité).
  return ref.watch(resolvedTrailConfigProvider);
});

/// Nom d'affichage du sentier actif.
final trailNameProvider = Provider<String>((ref) {
  return ref.watch(trailConfigProvider).displayName;
});

/// Identifiant du sentier actif.
final trailIdProvider = Provider<String>((ref) {
  return ref.watch(trailConfigProvider).id;
});
