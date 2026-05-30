import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/map/mbtiles_manager.dart';
import '../../../core/network/connectivity_monitor.dart';

/// Statut de la carte offline pour un sentier.
///
/// Combine l'etat de connectivite et la disponibilite
/// des tuiles MBTiles locales.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef OfflineMapStatus = String;

/// Valeurs connues pour OfflineMapStatus avec fallback generique.
abstract class OfflineMapStatusValues {
  static const String online = 'online';
  static const String offlineAvailable = 'offlineAvailable';
  static const String offlineOnly = 'offlineOnly';
  static const String noMap = 'noMap';
  static const String fallback = online;
  static const List<String> values = [online, offlineAvailable, offlineOnly, noMap];
  static OfflineMapStatus fromString(String value) =>
      values.contains(value) ? value : fallback;
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
  final connectivity = connectivityAsync.valueOrNull ?? ConnectivityStatusValues.online;

  // Disponibilite des tuiles locales
  final manager = ref.watch(mbtilesManagerProvider);
  final hasLocal = await manager.hasMbtiles(trailId);

  // Combiner les deux axes
  if (connectivity == ConnectivityStatusValues.online) {
    return hasLocal ? OfflineMapStatusValues.offlineAvailable : OfflineMapStatusValues.online;
  } else {
    return hasLocal ? OfflineMapStatusValues.offlineOnly : OfflineMapStatusValues.noMap;
  }
});
