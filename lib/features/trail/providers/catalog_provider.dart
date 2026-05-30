import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/data/daos/trail_manifests_dao.dart';
import '../../../core/data/daos/trail_meta_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/models/download_progress.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/manifest_service.dart';
import '../../../core/services/trail_download_service.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

// --- Modeles internes au catalogue ---

/// Statut local d'un sentier dans le catalogue.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef TrailLocalStatus = String;

/// Valeurs connues pour TrailLocalStatus avec fallback generique.
abstract class TrailLocalStatusValues {
  static const String notDownloaded = 'notDownloaded';
  static const String downloading = 'downloading';
  static const String downloaded = 'downloaded';
  static const String updateAvailable = 'updateAvailable';
  static const String fallback = notDownloaded;
  static const List<String> values = [notDownloaded, downloading, downloaded, updateAvailable];
  static TrailLocalStatus fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Entree du catalogue combinant donnees distantes et locales.
class CatalogEntry {
  const CatalogEntry({
    required this.trailId,
    required this.dataVersion,
    required this.fileSize,
    required this.status,
    required this.lastUpdated,
    required this.localStatus,
    this.localVersion,
  });

  final String trailId;
  final int dataVersion;
  final int fileSize;
  final String status;
  final String lastUpdated;
  final TrailLocalStatus localStatus;
  final int? localVersion;
}

/// Etat global du catalogue.
class CatalogState {
  const CatalogState({
    required this.entries,
    required this.isOffline,
  });

  /// Liste combinee des sentiers (distants + statut local)
  final List<CatalogEntry> entries;

  /// Indique si l'appareil est hors ligne
  final bool isOffline;

  CatalogState copyWith({
    List<CatalogEntry>? entries,
    bool? isOffline,
  }) {
    return CatalogState(
      entries: entries ?? this.entries,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// --- Notifier principal du catalogue ---

/// Notifier qui gere la liste combinee sentiers distants + locaux.
///
/// Fusionne le manifeste distant (ManifestService) avec les
/// metadonnees locales (TrailManifestsDao) pour determiner le
/// statut de telechargement de chaque sentier.
class CatalogNotifier extends AsyncNotifier<CatalogState> {
  late ManifestService _manifestService;
  late TrailManifestsDao _manifestsDao;
  late TrailMetaDao _trailMetaDao;
  late ConnectivityMonitor _connectivity;

  /// URL du manifeste distant
  static const defaultManifestUrl =
      'https://storage.googleapis.com/moteur-gr/manifest.json';

  @override
  Future<CatalogState> build() async {
    _manifestService = ref.read(manifestServiceProvider);
    final db = ref.read(databaseProvider);
    _manifestsDao = TrailManifestsDao(db);
    _trailMetaDao = TrailMetaDao(db);
    _connectivity = ref.read(connectivityMonitorProvider);

    return _loadCatalog();
  }

  /// Charge le catalogue : fetch distant + merge local.
  Future<CatalogState> _loadCatalog() async {
    final connectivityStatus = await _connectivity.checkStatus();
    final isOffline = connectivityStatus == ConnectivityStatusValues.offline;

    if (isOffline) {
      // Hors ligne : afficher uniquement les sentiers deja telecharges
      final localManifests = await _manifestsDao.getAll();
      final entries = localManifests
          .where((m) => m.localVersion != null)
          .map((m) => CatalogEntry(
                trailId: m.trailId,
                dataVersion: m.dataVersion,
                fileSize: m.fileSize,
                status: m.status,
                lastUpdated: m.lastUpdated,
                localStatus: TrailLocalStatusValues.downloaded,
                localVersion: m.localVersion,
              ))
          .toList();

      return CatalogState(entries: entries, isOffline: true);
    }

    // En ligne : fetch le manifeste distant
    final manifest = await _manifestService.fetchManifest(defaultManifestUrl);
    if (manifest == null) {
      _log.w('[CatalogNotifier] Manifeste indisponible');
      // Fallback sur les donnees locales
      final localManifests = await _manifestsDao.getAll();
      final entries = localManifests
          .map(_buildEntryFromLocal)
          .toList();
      return CatalogState(entries: entries, isOffline: false);
    }

    // Sauvegarder le manifeste distant en base
    for (final entry in manifest.trails) {
      await _manifestService.saveLocalManifest(entry);
    }

    // Construire la liste combinee
    final entries = <CatalogEntry>[];
    for (final remote in manifest.trails) {
      if (remote.status != 'active') continue;

      final local = await _manifestsDao.getByTrailId(remote.trailId);
      final localVersion = local?.localVersion;

      TrailLocalStatus localStatus;
      if (localVersion == null) {
        localStatus = TrailLocalStatusValues.notDownloaded;
      } else if (remote.dataVersion > localVersion) {
        localStatus = TrailLocalStatusValues.updateAvailable;
      } else {
        localStatus = TrailLocalStatusValues.downloaded;
      }

      entries.add(CatalogEntry(
        trailId: remote.trailId,
        dataVersion: remote.dataVersion,
        fileSize: remote.fileSize,
        status: remote.status,
        lastUpdated: remote.lastUpdated,
        localStatus: localStatus,
        localVersion: localVersion,
      ));
    }

    return CatalogState(entries: entries, isOffline: false);
  }

  /// Construit une CatalogEntry depuis une entree locale uniquement.
  CatalogEntry _buildEntryFromLocal(TrailManifest local) {
    final localStatus = local.localVersion != null
        ? (local.dataVersion > local.localVersion!
            ? TrailLocalStatusValues.updateAvailable
            : TrailLocalStatusValues.downloaded)
        : TrailLocalStatusValues.notDownloaded;

    return CatalogEntry(
      trailId: local.trailId,
      dataVersion: local.dataVersion,
      fileSize: local.fileSize,
      status: local.status,
      lastUpdated: local.lastUpdated,
      localStatus: localStatus,
      localVersion: local.localVersion,
    );
  }

  /// Rafraichit le catalogue (pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadCatalog());
  }

  /// Lance le telechargement d'un sentier.
  ///
  /// Met a jour le statut en 'downloading' immediatement,
  /// puis ecoute le stream de progression du TrailDownloadService.
  Future<void> downloadTrail(String trailId) async {
    _updateEntryStatus(trailId, TrailLocalStatusValues.downloading);

    final downloadService = ref.read(trailDownloadServiceProvider);
    final manifestEntry = await _manifestsDao.getByTrailId(trailId);
    if (manifestEntry == null) {
      _log.e('[CatalogNotifier] Pas de manifeste pour $trailId');
      _updateEntryStatus(trailId, TrailLocalStatusValues.notDownloaded);
      return;
    }

    final dataUrl = manifestEntry.filePath;

    await for (final progress
        in downloadService.downloadTrail(trailId, dataUrl)) {
      // Mettre a jour le stream de progression
      ref.read(downloadProgressProvider(trailId).notifier).setProgress(progress);

      if (progress.status == DownloadStatusValues.completed) {
        // Marquer la version locale comme telechargee
        await _manifestsDao.insertOrReplace(
          TrailManifestsCompanion(
            trailId: Value(manifestEntry.trailId),
            dataVersion: Value(manifestEntry.dataVersion),
            hash: Value(manifestEntry.hash),
            filePath: Value(manifestEntry.filePath),
            fileSize: Value(manifestEntry.fileSize),
            status: Value(manifestEntry.status),
            lastUpdated: Value(manifestEntry.lastUpdated),
            localVersion: Value(manifestEntry.dataVersion),
          ),
        );
        _updateEntryStatus(trailId, TrailLocalStatusValues.downloaded);
      } else if (progress.status == DownloadStatusValues.error) {
        _updateEntryStatus(trailId, TrailLocalStatusValues.notDownloaded);
      }
    }
  }

  /// Supprime les donnees locales d'un sentier.
  Future<void> deleteTrailData(String trailId) async {
    await _trailMetaDao.deleteById(trailId);

    // Remettre localVersion a null dans le manifeste
    final manifestEntry = await _manifestsDao.getByTrailId(trailId);
    if (manifestEntry != null) {
      await _manifestsDao.insertOrReplace(
        TrailManifestsCompanion(
          trailId: Value(manifestEntry.trailId),
          dataVersion: Value(manifestEntry.dataVersion),
          hash: Value(manifestEntry.hash),
          filePath: Value(manifestEntry.filePath),
          fileSize: Value(manifestEntry.fileSize),
          status: Value(manifestEntry.status),
          lastUpdated: Value(manifestEntry.lastUpdated),
          localVersion: const Value(null),
        ),
      );
    }

    _updateEntryStatus(trailId, TrailLocalStatusValues.notDownloaded);
  }

  /// Met a jour le statut d'une entree dans l'etat courant.
  void _updateEntryStatus(String trailId, TrailLocalStatus newStatus) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.entries.map((e) {
      if (e.trailId == trailId) {
        return CatalogEntry(
          trailId: e.trailId,
          dataVersion: e.dataVersion,
          fileSize: e.fileSize,
          status: e.status,
          lastUpdated: e.lastUpdated,
          localStatus: newStatus,
          localVersion: newStatus == TrailLocalStatusValues.downloaded
              ? e.dataVersion
              : e.localVersion,
        );
      }
      return e;
    }).toList();

    state = AsyncData(current.copyWith(entries: updated));
  }
}

/// Provider principal du catalogue.
final catalogStateProvider =
    AsyncNotifierProvider<CatalogNotifier, CatalogState>(CatalogNotifier.new);

// --- Provider de progression de telechargement ---

/// Notifier simple pour la progression d'un telechargement en cours.
class DownloadProgressNotifier
    extends FamilyAsyncNotifier<DownloadProgress?, String> {
  @override
  Future<DownloadProgress?> build(String arg) async => null;

  /// Met a jour la progression.
  void setProgress(DownloadProgress progress) {
    state = AsyncData(progress);
  }

  /// Remet a null (telechargement termine ou annule).
  void clear() {
    state = const AsyncData(null);
  }
}

/// Provider de progression par trailId.
final downloadProgressProvider = AsyncNotifierProvider.family<
    DownloadProgressNotifier, DownloadProgress?, String>(
  DownloadProgressNotifier.new,
);
