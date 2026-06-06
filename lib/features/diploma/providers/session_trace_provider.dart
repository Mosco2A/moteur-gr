import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';

/// Tracé GPS réel de la dernière session de tracking du sentier actif.
///
/// Finitions V8 F3 : points persistés au fil de l'eau par le tracking
/// (table session_track_points), affichés dans le récap diplôme.
/// Liste vide si aucune session enregistrée.
final sessionTraceProvider =
    FutureProvider<List<SessionTrackPoint>>((ref) async {
  final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
  final db = ref.watch(databaseProvider);
  return db.sessionTrackPointsDao.getByTrailId(trailId);
});
