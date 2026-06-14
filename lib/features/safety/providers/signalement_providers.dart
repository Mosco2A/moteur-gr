import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/providers/database_provider.dart';
import '../data/signalement_service.dart';

/// Puits distant NO-OP pour les signalements (F6C-03).
///
/// Tant que Firebase n'est pas connecté (avant Phase 4, fiche #84627), aucun
/// push distant réel n'a lieu : les signalements restent en file locale
/// (`syncState=pending`) et la synchronisation différée (F6C-04) sera branchée
/// quand la collection `trail_reports` Firestore sera active. Ce sink échoue
/// donc proprement (sans réseau) pour conserver les reports en attente.
class DeferredReportRemoteSink implements ReportRemoteSink {
  const DeferredReportRemoteSink();

  @override
  Future<RemotePushResult> push(ReportLocalData report) async {
    // Pas de backend connecté : on n'efface rien, le report reste pending.
    return const RemotePushResult.failure(
      'backend distant non connecté (pré-Phase 4)',
    );
  }
}

/// Provider du puits distant des signalements (F6C-03).
///
/// Surchargeable en test (fake) et, plus tard, par l'implémentation Firestore
/// réelle (F6C-04) une fois le backend connecté.
final reportRemoteSinkProvider = Provider<ReportRemoteSink>(
  (ref) => const DeferredReportRemoteSink(),
);

/// Provider du service de signalement terrain offline-first (F6C-02/F6C-03).
final signalementServiceProvider = Provider<SignalementService>((ref) {
  return SignalementService(
    database: ref.watch(databaseProvider),
    remoteSink: ref.watch(reportRemoteSinkProvider),
  );
});

/// Nombre de signalements en attente de synchronisation (badge UI).
///
/// `FutureProvider` rechargé via `ref.invalidate` après chaque création.
final pendingSignalementCountProvider = FutureProvider<int>((ref) {
  return ref.watch(signalementServiceProvider).pendingCount();
});
