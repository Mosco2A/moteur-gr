import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/providers/database_provider.dart';
import '../data/drift_trail_data_provider.dart';
import '../domain/trail_data_provider.dart';

/// Provider Riverpod pour [TrailDataProvider].
///
/// Par defaut, utilise [DriftTrailDataProvider] avec la base SQLite locale.
/// En tests, overrider ce provider avec une implementation mock/fake :
///
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     trailDataProvider.overrideWithValue(FakeTrailDataProvider()),
///   ],
/// );
/// ```
final trailDataProvider = Provider<TrailDataProvider>((ref) {
  final db = ref.watch(databaseProvider);
  final config = ref.watch(trailConfigProvider);
  return DriftTrailDataProvider(db: db, trailConfig: config);
});

/// Provider pour la configuration du sentier actif.
///
/// Doit etre overridden dans le main() de chaque app sentier
/// (ex: GR20, GR10, TMB) avec la bonne [TrailConfig].
///
/// ```dart
/// runApp(
///   ProviderScope(
///     overrides: [
///       trailConfigProvider.overrideWithValue(gr20Config),
///     ],
///     child: const App(),
///   ),
/// );
/// ```
final trailConfigProvider = Provider<TrailConfig>((ref) {
  throw UnimplementedError(
    'trailConfigProvider doit etre overridden avec la TrailConfig du sentier. '
    'Voir le main() de chaque app sentier.',
  );
});
