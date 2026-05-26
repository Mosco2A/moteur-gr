import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/stages_dao.dart';
import '../../../core/models/stage.dart';
import '../../../core/providers/database_provider.dart';

/// Provider des etapes d'un sentier, parametre par trailId.
///
/// Charge les etapes depuis la DB Drift, les convertit en StageModel,
/// et les trie par numero d'etape.
final stagesProvider =
    FutureProvider.family<List<StageModel>, String>((ref, trailId) async {
  final db = ref.watch(databaseProvider);
  final dao = StagesDao(db);
  final rows = await dao.getByTrailId(trailId);
  return rows.map(StageModel.fromDb).toList();
});
