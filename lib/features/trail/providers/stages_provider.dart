import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/stages_dao.dart';
import '../../../core/models/stage.dart';
import '../../../core/providers/database_provider.dart';
import '../../trek/providers/seed_provider.dart';

/// Provider des etapes d'un sentier, parametre par trailId.
///
/// Charge les etapes depuis la DB Drift, les convertit en StageModel,
/// et les trie par numero d'etape.
///
/// Attend d'abord [trailSeedProvider] : la base etant in-memory et seedee au
/// demarrage (bug GO-62), on garantit que les donnees embarquees du sentier
/// actif sont chargees avant de lire — sinon la liste serait vide au premier
/// affichage (course entre le seed et la lecture).
final stagesProvider =
    FutureProvider.family<List<StageModel>, String>((ref, trailId) async {
  // Garantit le seed des donnees embarquees avant lecture.
  await ref.watch(trailSeedProvider.future);

  final db = ref.watch(databaseProvider);
  final dao = StagesDao(db);
  final rows = await dao.getByTrailId(trailId);
  return rows.map(StageModel.fromDb).toList();
});
