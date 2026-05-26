import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/mbtiles_manager.dart';
import '../../../core/network/connectivity_monitor.dart';

/// Statut de la carte offline pour un sentier.
///
/// Combine l'etat de connectivite et la disponibilite
/// des tuiles MBTiles locales.
enum OfflineMapStatus {
  /// En ligne, tuiles servies depuis le reseau.
  online,

  /// Tuiles MBTiles disponibles localement (hors-ligne possible).
  offlineAvailable,

  /// Hors-ligne avec tuiles locales — mode offline actif.
  offlineOnly,

  /// Hors-ligne sans tuiles locales — pas de carte disponible.
  noMap,
}

/// Provider qui verifie si une carte offline est disponible pour un sentier.
final isOfflineMapAvailableProvider =
    FutureProvider.family<bool, String>((ref, trailId) async {
  final manager = ref.watch(mbtilesManagerProvider);
  return manager.hasMbtiles(trailId);
});

/// Provider combine du statut carte offline par sentier.
///
/// Combine le ConnectivityMonitor (online/offline) et le MBTilesManager
/// (presence de tuiles locales) pour determiner le OfflineMapStatus.
final offlineMapStatusProvider =
    FutureProvider.family<OfflineMapStatus, String>((ref, trailId) async {
  // Etat de connectivite
  final connectivityAsync = ref.watch(connectivityProvider);
  final connectivity = connectivityAsync.valueOrNull ?? ConnectivityStatus.online;

  // Disponibilite des tuiles locales
  final manager = ref.watch(mbtilesManagerProvider);
  final hasLocal = await manager.hasMbtiles(trailId);

  // Combiner les deux axes
  if (connectivity == ConnectivityStatus.online) {
    return hasLocal ? OfflineMapStatus.offlineAvailable : OfflineMapStatus.online;
  } else {
    return hasLocal ? OfflineMapStatus.offlineOnly : OfflineMapStatus.noMap;
  }
});
