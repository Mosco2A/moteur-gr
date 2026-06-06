import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../i18n/translations.g.dart';
import '../data/daos/trail_manifests_dao.dart';
import '../models/trail_manifest.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'delta_update_service.dart';
import 'manifest_service.dart';
import 'update_checker.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// ID de base pour les notifications de MAJ prete.
const _updateReadyNotifBaseId = 6000;

/// Canal de notification pour les MAJ pretes.
const updateReadyChannel = 'update_ready';
const updateReadyChannelDesc = 'Notifications de mise a jour prete';

/// Resultat du telechargement delta pour un sentier.
class UpdateDownloadResult {
  const UpdateDownloadResult({
    required this.trailId,
    required this.success,
    this.tablesUpdated = const [],
    this.tablesSkipped = const [],
    this.error,
  });

  /// Identifiant du sentier mis a jour.
  final String trailId;

  /// True si le delta a ete applique avec succes.
  final bool success;

  /// Tables effectivement re-telechargees (delta).
  final List<String> tablesUpdated;

  /// Tables ignorees (pas de changement).
  final List<String> tablesSkipped;

  /// Message d erreur si echec.
  final String? error;
}

/// Callback pour executer une tache en arriere-plan.
///
/// Abstraction du background work manager pour permettre
/// l injection en test sans dependance directe a workmanager.
typedef BackgroundTaskRunner = Future<void> Function(
  String taskName,
  Future<void> Function() task,
);

/// Runner par defaut : execute la tache directement (foreground).
Future<void> _defaultTaskRunner(
  String taskName,
  Future<void> Function() task,
) async {
  await task();
}

/// Base par defaut des fichiers de donnees sentier.
///
/// Meme bucket que le manifeste du catalogue (catalog_provider).
/// Surchargee par l application hote via le constructeur.
const kDefaultTrailDataBaseUrl = 'https://storage.googleapis.com/moteur-gr';

/// Service de telechargement delta en arriere-plan (E4.11c).
///
/// Orchestre le pipeline : detection MAJ -> delta download -> notification.
/// Seules les tables modifiees sont re-telechargees (delta, pas full).
/// Le telechargement tourne en background via [BackgroundTaskRunner].
/// Reutilise le DeltaUpdateService du moteur (zero duplication) ;
/// l URL du delta est construite depuis [dataBaseUrl] + filePath du
/// manifeste (aucune marque en dur).
///
/// Dependances : E4.11b (UpdateChecker), E4.3 (manifest), E4.4a (download).
class UpdateDownloader {
  UpdateDownloader({
    required this.updateChecker,
    required this.deltaUpdateService,
    required this.manifestService,
    required this.dao,
    required this.connectivityMonitor,
    this.dataBaseUrl = kDefaultTrailDataBaseUrl,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    BackgroundTaskRunner? backgroundRunner,
  })  : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _backgroundRunner = backgroundRunner ?? _defaultTaskRunner;

  final UpdateChecker updateChecker;
  final DeltaUpdateService deltaUpdateService;
  final ManifestService manifestService;
  final TrailManifestsDao dao;
  final ConnectivityMonitor connectivityMonitor;

  /// Base d URL des fichiers de donnees (injectee, jamais en dur).
  final String dataBaseUrl;

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final BackgroundTaskRunner _backgroundRunner;

  /// Telecharge les deltas pour tous les sentiers ayant une MAJ.
  ///
  /// Pipeline :
  /// 1. [UpdateChecker.checkAllForUpdates] detecte les MAJ.
  /// 2. Pour chaque MAJ, recupere le manifeste distant.
  /// 3. [DeltaUpdateService.checkForUpdates] identifie les tables changees.
  /// 4. Telecharge et applique UNIQUEMENT les tables delta.
  /// 5. Notifie l utilisateur quand la MAJ est prete.
  ///
  /// Retourne la liste des resultats (un par sentier traite).
  Future<List<UpdateDownloadResult>> downloadAllUpdates({
    required String manifestUrl,
  }) async {
    final results = <UpdateDownloadResult>[];

    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      _log.d('[UpdateDownloader] Hors ligne, telechargement annule');
      return results;
    }

    final updates = await updateChecker.checkAllForUpdates();
    if (updates.isEmpty) {
      _log.d('[UpdateDownloader] Aucune MAJ a telecharger');
      return results;
    }

    final remoteManifest = await manifestService.fetchManifest(manifestUrl);
    if (remoteManifest == null) {
      _log.e('[UpdateDownloader] Impossible de recuperer le manifeste');
      return results;
    }

    for (final update in updates) {
      final result = await _downloadDelta(
        trailId: update.trailId,
        remoteManifest: remoteManifest,
      );
      results.add(result);
    }

    final successCount = results.where((r) => r.success).length;
    if (successCount > 0) {
      await _notifyUpdateReady(successCount);
    }

    return results;
  }

  /// Telecharge le delta pour un seul sentier.
  ///
  /// Ne re-telecharge que les tables qui ont change entre
  /// la version locale et la version distante.
  Future<UpdateDownloadResult> downloadSingleUpdate({
    required String trailId,
    required String manifestUrl,
  }) async {
    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      return UpdateDownloadResult(
        trailId: trailId,
        success: false,
        error: 'offline',
      );
    }

    final remoteManifest = await manifestService.fetchManifest(manifestUrl);
    if (remoteManifest == null) {
      return UpdateDownloadResult(
        trailId: trailId,
        success: false,
        error: 'manifest_unavailable',
      );
    }

    return _downloadDelta(trailId: trailId, remoteManifest: remoteManifest);
  }

  /// Lance le telechargement de toutes les MAJ en arriere-plan.
  ///
  /// Utilise [BackgroundTaskRunner] pour executer le pipeline
  /// sans bloquer l UI. Par defaut, execute en foreground.
  /// En production, injecter un runner workmanager.
  Future<void> scheduleBackgroundDownload({
    required String manifestUrl,
  }) async {
    await _backgroundRunner(
      'update_download',
      () => downloadAllUpdates(manifestUrl: manifestUrl),
    );
  }

  /// Telecharge et applique le delta pour un sentier.
  Future<UpdateDownloadResult> _downloadDelta({
    required String trailId,
    required TrailManifest remoteManifest,
  }) async {
    try {
      final delta = await deltaUpdateService.checkForUpdates(
        trailId,
        remoteManifest: remoteManifest,
      );

      if (delta == null) {
        _log.d('[UpdateDownloader] Pas de delta pour $trailId');
        return UpdateDownloadResult(
          trailId: trailId,
          success: true,
          tablesSkipped: allTables,
        );
      }

      final changedTables = delta.changedTables;
      final skippedTables =
          allTables.where((t) => !changedTables.contains(t)).toList();

      _log.d(
        '[UpdateDownloader] Delta $trailId: '
        '${changedTables.length} tables a MAJ, '
        '${skippedTables.length} ignorees',
      );

      final remoteEntry =
          remoteManifest.trails.where((t) => t.trailId == trailId).firstOrNull;

      if (remoteEntry == null) {
        return UpdateDownloadResult(
          trailId: trailId,
          success: false,
          error: 'trail_missing_from_manifest',
        );
      }

      await deltaUpdateService.downloadAndApplyDelta(
        trailId,
        '$dataBaseUrl/${remoteEntry.filePath}',
        changedTables: changedTables,
      );

      _log.d('[UpdateDownloader] Delta applique pour $trailId');

      return UpdateDownloadResult(
        trailId: trailId,
        success: true,
        tablesUpdated: changedTables,
        tablesSkipped: skippedTables,
      );
    } catch (e) {
      _log.e('[UpdateDownloader] Erreur delta $trailId: $e');
      return UpdateDownloadResult(
        trailId: trailId,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Notifie l utilisateur que la MAJ est prete (textes Slang).
  Future<void> _notifyUpdateReady(int count) async {
    try {
      final title = t.updates.readyTitle;
      final body = count == 1
          ? t.updates.readyBodyOne
          : t.updates.readyBodyMany(count: count);

      await _notificationsPlugin.show(
        _updateReadyNotifBaseId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            updateReadyChannel,
            updateReadyChannel,
            channelDescription: updateReadyChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
          ),
        ),
      );
      _log.d('[UpdateDownloader] Notification MAJ prete envoyee ($count)');
    } catch (e) {
      _log.e('[UpdateDownloader] Erreur notification: $e');
    }
  }

  /// Liste de toutes les tables possibles.
  static const allTables = [
    'trail_meta',
    'itineraries',
    'stages',
    'accommodations',
    'pois',
    'gpx_tracks',
    'gpx_points',
  ];
}

/// Provider Riverpod pour le service de telechargement delta background.
final updateDownloaderProvider = Provider<UpdateDownloader>((ref) {
  final db = ref.watch(databaseProvider);
  return UpdateDownloader(
    updateChecker: ref.watch(updateCheckerProvider),
    deltaUpdateService: ref.watch(deltaUpdateServiceProvider),
    manifestService: ref.watch(manifestServiceProvider),
    dao: TrailManifestsDao(db),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
  );
});
