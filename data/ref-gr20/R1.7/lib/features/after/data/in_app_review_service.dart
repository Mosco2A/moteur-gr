import 'package:hive/hive.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../core/constants/hive_boxes.dart';

/// E5.17 — Service de demande d'avis store post-trek.
///
/// Conditions :
/// - Trek termine (verifie par l'appelant via le provider)
/// - Jamais demande pour ce trailId (flag persistant Hive)
/// - 1 SEULE demande par trek, jamais 2 fois le meme
class InAppReviewService {
  InAppReviewService({InAppReview? inAppReview})
      : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  /// Verifie si la review a deja ete demandee pour ce trailId.
  Future<bool> wasReviewRequested(String trailId) async {
    final box = await _openBox();
    return box.get(trailId, defaultValue: false) as bool;
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
    await _markReviewRequested(trailId);

    // 4. Lancer la demande native
    await _inAppReview.requestReview();
    return true;
  }

  /// Marque la review comme demandee pour ce trailId.
  Future<void> _markReviewRequested(String trailId) async {
    final box = await _openBox();
    await box.put(trailId, true);
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(HiveBoxes.reviewRequested)) {
      return Hive.box(HiveBoxes.reviewRequested);
    }
    return Hive.openBox(HiveBoxes.reviewRequested);
  }
}
