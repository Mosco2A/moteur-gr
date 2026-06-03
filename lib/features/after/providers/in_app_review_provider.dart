import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../data/in_app_review_service.dart';

/// E5.17 — Provider singleton du service in-app review.
///
/// Injecte le ReviewRequestsDao depuis la base Drift.
final inAppReviewServiceProvider = Provider<InAppReviewService>((ref) {
  final db = ref.watch(databaseProvider);
  return InAppReviewService(reviewRequestsDao: db.reviewRequestsDao);
});
