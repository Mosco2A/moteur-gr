import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/trail_config.dart';

/// Moteur central du Moteur GR.
///
/// Point d'entrée unique pour accéder à la configuration du sentier
/// actif. Tous les modules (thème, navigation, GPS, etc.) lisent
/// la config depuis ce provider.
///
/// Initialisation dans main.dart :
/// ```dart
/// void main() {
///   final config = TrailConfig(...);
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
  throw UnimplementedError(
    'trailConfigProvider doit être overridé dans main.dart '
    'avec la configuration du sentier.',
  );
});

/// Nom d'affichage du sentier actif.
final trailNameProvider = Provider<String>((ref) {
  return ref.watch(trailConfigProvider).displayName;
});

/// Identifiant du sentier actif.
final trailIdProvider = Provider<String>((ref) {
  return ref.watch(trailConfigProvider).id;
});
