import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/progress_dao.dart';
import '../../../core/models/user_progress.dart';
import '../../../core/providers/database_provider.dart';

/// Provider de la progression utilisateur sur un sentier.
///
/// Retourne null si aucune progression n'existe encore.
final progressProvider =
    FutureProvider.family<UserProgressModel?, String>((ref, trailId) async {
  final db = ref.watch(databaseProvider);
  final dao = ProgressDao(db);
  final row = await dao.getByTrailId(trailId);
  if (row == null) return null;
  return UserProgressModel.fromDb(row);
});
