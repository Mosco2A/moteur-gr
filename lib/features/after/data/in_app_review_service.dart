import 'package:in_app_review/in_app_review.dart';

import '../../../core/data/daos/review_requests_dao.dart';

/// E5.17 — Service de demande d'avis store post-trek.
///
/// Conditions :
/// - Trek termine (verifie par l'appelant via le provider)
/// - Jamais demande pour ce trailId (flag persistant Drift)
/// - 1 SEULE demande par trek, jamais 2 fois le meme
///
/// Adaptation Moteur-GR : utilise Drift (ReviewRequestsDao) au lieu
/// de Hive (HiveBoxes.reviewRequested) du GR20.
class InAppReviewService {
  InAppReviewService({
    required ReviewRequestsDao reviewRequestsDao,
    InAppReview? inAppReview,
  })  : _reviewRequestsDao = reviewRequestsDao,
        _inAppReview = inAppReview ?? InAppReview.instance;

  final ReviewRequestsDao _reviewRequestsDao;
  final InAppReview _inAppReview;

  /// Verifie si la review a deja ete demandee pour ce trailId.
  Future<bool> wasReviewRequested(String trailId) async {
    return _reviewRequestsDao.wasReviewRequested(trailId);
  }

  /// Demande un avis store si les conditions sont reunies.
  ///
  /// Retourne `true` si la demande a ete faite, `false` si deja demande
  /// ou si le store n'est pas disponible.
  Future<bool> requestReviewIfEligible(String trailId) async {
    // 1. Verifier si deja demande pour ce trek
    final alreadyRequested = await wasReviewRequested(trailId);
    if (alreadyRequested) return false;

    // 2. Verifier disponibilite du store
    final isAvailable = await _inAppReview.isAvailable();
    if (!isAvailable) return false;

    // 3. Marquer AVANT la demande (evite les doublons en cas de crash)
    await _reviewRequestsDao.markReviewRequested(trailId);

    // 4. Lancer la demande native
    await _inAppReview.requestReview();
    return true;
  }
}
