import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/providers/database_provider.dart';
import '../data/waypoint_service.dart';

/// Puits distant NO-OP des waypoints communautaires (F8A-02).
///
/// Tant que Firebase n'est pas connecte (avant Phase 4, fiche #84627), aucun
/// push/pull distant reel n'a lieu : les contributions restent en file locale
/// (`syncState=pending`) et la synchronisation differee sera branchee quand les
/// collections `waypoints` / `waypoint_comments` Firestore (regles F8A-03)
/// seront actives. Ce sink echoue donc PROPREMENT (sans reseau) au push pour
/// conserver les contributions en attente, et renvoie un pull vide.
class DeferredWaypointRemoteSink implements WaypointRemoteSink {
  const DeferredWaypointRemoteSink();

  @override
  Future<WaypointPushResult> pushWaypoint(WaypointData waypoint) async {
    return const WaypointPushResult.failure(
      'backend distant non connecte (pre-Phase 4)',
    );
  }

  @override
  Future<WaypointPushResult> pushComment(WaypointCommentData comment) async {
    return const WaypointPushResult.failure(
      'backend distant non connecte (pre-Phase 4)',
    );
  }

  @override
  Future<WaypointRemotePull> pull({
    required String trailId,
    DateTime? since,
  }) async {
    // Pas de backend connecte : aucune donnee distante a fusionner.
    return const WaypointRemotePull();
  }
}

/// Provider du puits distant des waypoints (F8A-02).
///
/// Surchargeable en test (fake) et, plus tard, par l'implementation Firestore
/// reelle une fois le backend connecte (collections sous regles F8A-03).
final waypointRemoteSinkProvider = Provider<WaypointRemoteSink>(
  (ref) => const DeferredWaypointRemoteSink(),
);

/// Provider du service de waypoints communautaires offline-first (F8A-02).
final waypointServiceProvider = Provider<WaypointService>((ref) {
  return WaypointService(
    database: ref.watch(databaseProvider),
    remoteSink: ref.watch(waypointRemoteSinkProvider),
  );
});

/// Nombre de contributions en attente de synchronisation (badge UI).
///
/// `FutureProvider` recharge via `ref.invalidate` apres chaque contribution.
final pendingWaypointContributionsProvider = FutureProvider<int>((ref) {
  return ref.watch(waypointServiceProvider).pendingCount();
});
