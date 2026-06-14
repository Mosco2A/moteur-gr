import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/defi_service.dart';
import '../domain/user_stats.dart';

/// Statistiques LOCALES de l'utilisateur (F7C-01/F7C-02).
///
/// Source des regles de badges et de la progression des defis (offline-first,
/// R2). Surchargeable en test ; branchera plus tard l'agregation des donnees
/// locales (progres, segments, defis) quand elles seront disponibles. Par
/// defaut vide (aucune realisation).
final userStatsProvider = Provider<UserStats>((ref) => const UserStats());

/// Provider du repository de classement de defi (F7C-02).
///
/// Surchargeable en test (cache pre-rempli) et, plus tard, par l'implementation
/// qui lit le cache local alimente par la sync Firestore (R2).
final defiRankingRepositoryProvider = Provider<DefiRankingRepository>(
  (ref) => InMemoryDefiRankingRepository(),
);

/// Provider du service de defis (progression locale + classement serveur cache).
final defiServiceProvider = Provider<DefiService>((ref) {
  return DefiService(
    rankingRepository: ref.watch(defiRankingRepositoryProvider),
  );
});
