import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_app_review_service.dart';

/// E5.17 — Provider singleton du service in-app review.
final inAppReviewServiceProvider = Provider<InAppReviewService>((ref) {
  return InAppReviewService();
});
