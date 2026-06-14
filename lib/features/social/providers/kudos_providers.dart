import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../data/kudos_service.dart';

/// Puits distant NO-OP pour les kudos (F7B-02).
///
/// Tant que Firebase n'est pas connecte (avant Phase 4, fiche #84627), aucun
/// push distant reel n'a lieu : les kudos restent en file locale
/// (`syncState=pending`). La synchronisation differee (collection kudos,
/// F7B-03) sera branchee quand Firestore sera actif. Ce sink echoue donc
/// proprement (sans reseau) pour conserver les kudos en attente.
class DeferredKudoRemoteSink implements KudoRemoteSink {
  const DeferredKudoRemoteSink();

  @override
  Future<KudoPushResult> push({
    required String docId,
    required String fromUidHash,
    required String targetActivityId,
  }) async {
    return const KudoPushResult.failure(
      'backend distant non connecte (pre-Phase 4)',
    );
  }
}

/// Provider du puits distant des kudos (F7B-02).
final kudoRemoteSinkProvider = Provider<KudoRemoteSink>(
  (ref) => const DeferredKudoRemoteSink(),
);

/// Provider du service de kudos offline-first idempotent (F7B-02).
final kudosServiceProvider = Provider<KudosService>((ref) {
  return KudosService(
    database: ref.watch(databaseProvider),
    remoteSink: ref.watch(kudoRemoteSinkProvider),
  );
});

/// Compteur de kudos d'une activite (cache local), indexe par activityId.
final kudosCountProvider =
    FutureProvider.family<int, String>((ref, activityId) {
  return ref.watch(kudosServiceProvider).kudosCount(activityId);
});
