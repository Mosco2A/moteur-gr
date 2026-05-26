import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/pois_dao.dart';
import '../../../core/models/poi.dart';
import '../../../core/providers/database_provider.dart';

/// Provider des points d'interet d'un sentier, parametre par trailId.
///
/// Charge les POI depuis la DB Drift et les convertit en PoiModel.
final poisProvider =
    FutureProvider.family<List<PoiModel>, String>((ref, trailId) async {
  final db = ref.watch(databaseProvider);
  final dao = PoisDao(db);
  final rows = await dao.getByTrailId(trailId);
  return rows.map(PoiModel.fromDb).toList();
});
