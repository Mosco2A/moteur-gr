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

/// Identite d'un point d'eau pour le crowdsourcing partage (I1).
///
/// Sert de cle de famille a [waterSourceStatusProvider] : deux appareils qui
/// signalent LE MEME point d'eau partagent la meme identite (sentier + etape +
/// nom), donc le compteur et le dernier statut s'agregent.
class WaterSourceRef {
  const WaterSourceRef({
    required this.trailId,
    required this.stageNumber,
    required this.poiName,
  });

  final String trailId;
  final int stageNumber;
  final String poiName;

  @override
  bool operator ==(Object other) =>
      other is WaterSourceRef &&
      other.trailId == trailId &&
      other.stageNumber == stageNumber &&
      other.poiName == poiName;

  @override
  int get hashCode => Object.hash(trailId, stageNumber, poiName);
}

/// Etat partage d'un point d'eau (dernier statut + compteur, offline-first, I1).
///
/// Rechargé via `ref.invalidate` après un nouveau signalement de statut. Lit le
/// cache local (source de vérité hors-ligne) via [SignalementService].
final waterSourceStatusProvider =
    FutureProvider.family<WaterSourceStatus, WaterSourceRef>((ref, src) {
  return ref.watch(signalementServiceProvider).waterStatusFor(
        trailId: src.trailId,
        stageNumber: src.stageNumber,
        poiName: src.poiName,
      );
});
