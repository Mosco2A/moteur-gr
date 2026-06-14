import '../domain/segment_ranking.dart';

/// Source de lecture du classement de segment (F7A-04).
///
/// OFFLINE-FIRST (R2) : la lecture se fait depuis un CACHE LOCAL du document
/// de classement calcule cote serveur (F7A-03). Aucun calcul de classement
/// cote client. Retourne `null` si aucun classement n'est connu pour le
/// segment (jamais joue, ou cache vide hors-ligne).
abstract interface class SegmentRankingRepository {
  Future<SegmentRanking?> rankingForSegment(String segmentId);
}

/// Implementation par defaut PRE-PHASE 4 (Firebase non connecte, fiche #84627).
///
/// Tant que le backend n'est pas branche, il n'existe pas de document de
/// classement distant a mettre en cache : le repository lit depuis une carte
/// en memoire injectable (vide par defaut). Quand Firestore sera connecte, on
/// branchera une implementation qui lit le cache local alimente par la sync du
/// document `segment_rankings/{segmentId}` (R2), sans changer l'UI.
class InMemorySegmentRankingRepository implements SegmentRankingRepository {
  InMemorySegmentRankingRepository([Map<String, SegmentRanking>? cache])
      : _cache = {...?cache};

  final Map<String, SegmentRanking> _cache;

  /// Alimente le cache local (simulation de la sync du doc serveur).
  void put(SegmentRanking ranking) {
    _cache[ranking.segmentId] = ranking;
  }

  @override
  Future<SegmentRanking?> rankingForSegment(String segmentId) async {
    return _cache[segmentId];
  }
}
