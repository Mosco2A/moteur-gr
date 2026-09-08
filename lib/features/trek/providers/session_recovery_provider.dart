import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../data/trek_session_manager.dart';

/// Gestionnaire de reprise apres crash ([TrekSessionManager]) branche sur Drift
/// (StepWays LOT 2, C4 — reprise orpheline au boot).
///
/// Le manager etait defini mais N'ETAIT INSTANCIE NULLE PART (ni provider, ni
/// boot) : `checkPendingSession`/`cleanOrphans` n'etaient jamais appeles. Ce
/// provider le cable enfin sur les callbacks du [TrekSessionsDao] :
///  * `findActiveSessions` (inclut `paused`, gap C4a) — sessions en cours ;
///  * `updateStatus` / `deleteSession` — nettoyage des orphelines.
final trekSessionRecoveryManagerProvider = Provider<TrekSessionManager>((ref) {
  final dao = ref.watch(databaseProvider).trekSessionsDao;
  return TrekSessionManager(
    onFindActiveSessions: dao.findActiveSessions,
    onDeleteSession: dao.deleteSession,
    onUpdateSessionStatus: dao.updateStatus,
  );
});

/// Session orpheline detectee au boot (ou null), APRES nettoyage des vieilles.
///
/// StepWays LOT 2, C4 — reprise orpheline enfin cablee (spec §3) :
///   1. [TrekSessionManager.cleanOrphans] solde les sessions en cours de plus de
///      7 jours (abandonnees + supprimees) — pas de reprise d'une rando fantome ;
///   2. [TrekSessionManager.checkPendingSession] remonte la session en cours la
///      plus recente restante -> l'UI (Phase 4-5) propose Reprendre/Abandonner.
///
/// FutureProvider awaite au boot par `appBootstrapProvider`. Best-effort : toute
/// erreur retombe sur `null` (pas de reprise proposee) plutot que de bloquer le
/// demarrage de l'app.
final pendingSessionProvider = FutureProvider<PendingSession?>((ref) async {
  final manager = ref.watch(trekSessionRecoveryManagerProvider);
  try {
    await manager.cleanOrphans();
    return await manager.checkPendingSession();
  } catch (_) {
    return null;
  }
});
