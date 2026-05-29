import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/providers/database_provider.dart';
import '../data/drift_trail_data_provider.dart';
import '../domain/models/stage.dart';
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

/// Provider des etapes du sentier actif pour le mode trek.
///
/// Charge les etapes depuis [TrailDataProvider.getStages()]
/// (implementation Drift injectee via [trailDataProvider]).
/// Resultat en cache tant que le provider est vivant.
///
/// Usage dans un Consumer :
/// ```dart
/// Consumer(
///   builder: (context, ref, _) {
///     final stagesAsync = ref.watch(trekStagesProvider);
///     return stagesAsync.when(...);
///   },
/// )
/// ```
final trekStagesProvider = FutureProvider<List<Stage>>((ref) async {
  final provider = ref.watch(trailDataProvider);
  return provider.getStages();
});

/// Provider pour l identifiant du sentier actif en mode trek.
///
/// Permet aux ecrans de navigation (StageListScreen, StageDetailScreen)
/// de connaitre le sentier en cours sans dependre de parametres d URL.
/// Initialement vide --- doit etre mis a jour au demarrage du trek.
final currentTrailIdProvider = StateProvider<String>((ref) => '');

/// Provider pour charger une etape par son identifiant.
///
/// Parametre par l id de l etape (format: trailId-N).
/// Charge toutes les etapes via [trekStagesProvider] puis filtre.
/// Retourne null si aucune etape ne correspond.
final stageByIdProvider =
    FutureProvider.family<Stage?, String>((ref, id) async {
  final stages = await ref.watch(trekStagesProvider.future);
  return stages.where((s) => s.id == id).firstOrNull;
});
