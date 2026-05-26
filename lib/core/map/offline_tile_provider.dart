import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'mbtiles_manager.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Fabrique de TileProvider pour le mode offline/online.
///
/// Si un fichier .mbtiles est disponible localement, retourne
/// un MbTilesTileProvider. Sinon, retourne un NetworkTileProvider
/// vers les tuiles OSM en ligne.
class OfflineTileProvider {
  OfflineTileProvider({required this.mbtilesManager});

  final MBTilesManager mbtilesManager;

  /// URL template des tuiles OSM par defaut (mode online).
  static const defaultTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Retourne le TileProvider adapte pour le sentier [trailId].
  ///
  /// Verifie si un fichier MBTiles local existe :
  /// - Si oui : ouvre le fichier et cree un MbTilesTileProvider.
  /// - Si non : retourne un NetworkTileProvider (tuiles OSM).
  Future<TileProvider> getTileProvider(String trailId) async {
    final hasLocal = await mbtilesManager.hasMbtiles(trailId);

    if (hasLocal) {
      try {
        final path = await mbtilesManager.getMbtilesPath(trailId);
        _log.d('[OfflineTileProvider] Tuiles MBTiles locales: $path');
        return MbTilesTileProvider.fromPath(path);
      } catch (e) {
        _log.e('[OfflineTileProvider] Erreur ouverture MBTiles: $e');
        // Fallback sur le mode en ligne en cas d'erreur
        return NetworkTileProvider();
      }
    }

    _log.d('[OfflineTileProvider] Pas de MBTiles local, mode en ligne');
    return NetworkTileProvider();
  }
}

/// Provider du OfflineTileProvider.
final offlineTileProviderFactoryProvider =
    Provider<OfflineTileProvider>((ref) {
  final manager = ref.watch(mbtilesManagerProvider);
  return OfflineTileProvider(mbtilesManager: manager);
});

/// Provider family qui retourne le TileProvider adapte par trailId.
///
/// Utilise FutureProvider.family pour mettre en cache le resultat
/// par sentier. Resout automatiquement vers MBTiles local ou OSM online.
final tileProviderForTrailProvider =
    FutureProvider.family<TileProvider, String>((ref, trailId) async {
  final factory = ref.watch(offlineTileProviderFactoryProvider);
  return factory.getTileProvider(trailId);
});
