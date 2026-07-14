import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../data/drift_trail_data_provider.dart';
import '../domain/trail_data_provider.dart';

/// Provider Riverpod pour TrailDataProvider.
///
/// Fournit une instance de DriftTrailDataProvider connectee
/// a la base de donnees et a la config du sentier actif.
/// Overridable dans les tests avec un mock/fake.
final trailDataProvider = Provider<TrailDataProvider>((ref) {
  final db = ref.watch(databaseProvider);
  final config = ref.watch(trailConfigProvider);
  return DriftTrailDataProvider(db: db, trailConfig: config);
});
