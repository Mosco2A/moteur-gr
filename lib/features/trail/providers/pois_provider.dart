import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/pois_dao.dart';
import '../../../core/models/poi.dart';
import '../../../core/providers/database_provider.dart';
import '../../trek/providers/seed_provider.dart';

/// Provider des points d'interet d'un sentier, parametre par trailId.
///
/// Charge les POI depuis la DB Drift et les convertit en PoiModel.
/// Attend d'abord [trailSeedProvider] pour garantir le chargement des donnees
/// embarquees du sentier actif (cf. stagesProvider, bug GO-62).
final poisProvider =
    FutureProvider.family<List<PoiModel>, String>((ref, trailId) async {
  await ref.watch(trailSeedProvider.future);

  final db = ref.watch(databaseProvider);
  final dao = PoisDao(db);
  final rows = await dao.getByTrailId(trailId);
  return rows.map(PoiModel.fromDb).toList();
});
