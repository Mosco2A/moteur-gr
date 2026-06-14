import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/segment_ranking_repository.dart';
import '../domain/segment_ranking.dart';

/// Provider du repository de classement de segment (F7A-04).
///
/// Surchargeable en test (cache pre-rempli) et, plus tard, par
/// l'implementation qui lit le cache local alimente par la sync Firestore
/// (offline-first, R2) une fois le backend connecte.
final segmentRankingRepositoryProvider = Provider<SegmentRankingRepository>(
  (ref) => InMemorySegmentRankingRepository(),
);

/// Classement d'un segment, lu depuis le cache local (offline-first).
///
/// `family` indexe par segmentId. Le widget se contente d'afficher : AUCUN
/// calcul de classement cote client (R2).
final segmentRankingProvider =
    FutureProvider.family<SegmentRanking?, String>((ref, segmentId) {
  return ref.watch(segmentRankingRepositoryProvider).rankingForSegment(segmentId);
});
