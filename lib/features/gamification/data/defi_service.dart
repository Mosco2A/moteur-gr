import '../domain/defi_ranking.dart';
import '../domain/defi_saisonnier.dart';
import '../domain/user_stats.dart';

/// Source de lecture du classement de defi (F7C-02).
///
/// OFFLINE-FIRST (R2) : lecture depuis un CACHE LOCAL du document de classement
/// calcule cote serveur (Cloud Function classementDefi). Aucun calcul de
/// classement cote client. Retourne `null` si aucun classement connu.
abstract interface class DefiRankingRepository {
  Future<DefiRanking?> rankingForDefi(String defiId);
}

/// Implementation PRE-PHASE 4 (Firebase non connecte) : cache en memoire
/// injectable (vide par defaut). Branchera la lecture du cache local alimente
/// par la sync du doc `defi_rankings/{defiId}` quand Firestore sera actif.
class InMemoryDefiRankingRepository implements DefiRankingRepository {
  InMemoryDefiRankingRepository([Map<String, DefiRanking>? cache])
      : _cache = {...?cache};

  final Map<String, DefiRanking> _cache;

  void put(DefiRanking ranking) => _cache[ranking.defiId] = ranking;

  @override
  Future<DefiRanking?> rankingForDefi(String defiId) async => _cache[defiId];
}

/// Service des defis saisonniers (F7C-02, Phase 7 gamification).
///
/// - PROGRESSION : calculee LOCALEMENT a partir des [UserStats] (offline-first,
///   R2). Aucune dependance serveur pour voir sa progression.
/// - CLASSEMENT : lu depuis le cache du document calcule COTE SERVEUR (Cloud
///   Function classementDefi, meme pattern k-anonymat que F7A-03 : agregation
///   par tranche, k>=5, pas de timestamp fin, libelles PSEUDONYMES). Le client
///   ne calcule JAMAIS le classement.
class DefiService {
  DefiService({required DefiRankingRepository rankingRepository})
      : _rankingRepository = rankingRepository;

  final DefiRankingRepository _rankingRepository;

  /// Progression LOCALE de l'utilisateur vers l'objectif du [defi], a partir
  /// de ses [stats]. Fonction pure (offline-first, R2).
  DefiProgress localProgress(DefiSaisonnier defi, UserStats stats) {
    final current = switch (defi.typeObjectif) {
      DefiObjectif.distance => 0.0, // distance cumulee : alimentee en amont
      DefiObjectif.denivele => stats.totalElevationGainM,
      DefiObjectif.segments => stats.segmentsCompleted.toDouble(),
      _ => 0.0,
    };
    return DefiProgress(
      defiId: defi.id,
      current: current,
      target: defi.cible,
    );
  }

  /// Classement du defi, lu depuis le cache local (offline-first, R2).
  Future<DefiRanking?> ranking(String defiId) =>
      _rankingRepository.rankingForDefi(defiId);
}
