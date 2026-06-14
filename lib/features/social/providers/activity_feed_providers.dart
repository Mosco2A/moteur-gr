import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/kudos_feed_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/providers/database_provider.dart';

/// DAO du fil d'activite + kudos (F7B-01), expose pour la lecture du cache.
final kudosFeedDaoProvider = Provider<KudosFeedDao>((ref) {
  return KudosFeedDao(ref.watch(databaseProvider));
});

/// Fil d'activite VISIBLE, LU depuis le cache local (offline-first, R2).
///
/// Masque les activites 'removed' (DSA, F7B-01.visibleActivities). Le widget
/// se contente d'afficher : AUCUNE logique reseau/moderation ici.
final visibleActivitiesProvider =
    FutureProvider<List<ActivityFeedCacheData>>((ref) {
  return ref.watch(kudosFeedDaoProvider).visibleActivities();
});
