import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/review_requests_table.dart';

part 'review_requests_dao.g.dart';

/// DAO pour les operations sur les demandes de review store — E5.17.
///
/// 1 seule demande par trailId. Verifie l'existence avant insertion.
@DriftAccessor(tables: [ReviewRequests])
class ReviewRequestsDao extends DatabaseAccessor<AppDatabase>
    with _$ReviewRequestsDaoMixin {
  ReviewRequestsDao(super.db);

  /// Verifie si une review a deja ete demandee pour ce trailId.
  Future<bool> wasReviewRequested(String trailId) async {
    final query = select(reviewRequests)
      ..where((t) => t.trailId.equals(trailId));
    final results = await query.get();
    return results.isNotEmpty;
  }

  /// Marque une review comme demandee pour ce trailId.
  ///
  /// Ne fait rien si deja marquee (idempotent).
  Future<void> markReviewRequested(String trailId) async {
    final alreadyExists = await wasReviewRequested(trailId);
    if (alreadyExists) return;

    await into(reviewRequests).insert(
      ReviewRequestsCompanion.insert(
        trailId: trailId,
        requestedAt: DateTime.now(),
      ),
    );
  }
}
