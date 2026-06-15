import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pack_download_service.dart';
import '../data/pack_storage.dart';
import '../domain/pack_download_progress.dart';
import '../domain/pack_manifest.dart';

/// Provider du stockage local des packs (path_provider).
final packStorageProvider = Provider<PackStorage>((ref) => FilePackStorage());

/// Source de fichiers des packs (F8B-03).
///
/// Avant le backend (Phase 4, #84627), AUCUNE source reelle n'est connectee :
/// un sink NO-OP echoue PROPREMENT a chaque fetch pour que l'UI montre l'etat
/// reel (« telechargement indisponible ») sans planter. L'implementation HTTP /
/// Firebase Storage sera surchargee ici une fois le backend pret.
class UnavailablePackFileSource implements PackFileSource {
  const UnavailablePackFileSource();

  @override
  Future<Uint8List> fetch(String ref) async {
    throw Exception('source de pack non connectee (pre-Phase 4, #84627)');
  }
}

/// Provider de la source de fichiers des packs (surchargeable en test/prod).
final packFileSourceProvider = Provider<PackFileSource>(
  (ref) => const UnavailablePackFileSource(),
);

/// Provider du service de telechargement des packs (F8B-02).
final packDownloadServiceProvider = Provider<PackDownloadService>((ref) {
  return PackDownloadService(
    fileSource: ref.watch(packFileSourceProvider),
    storage: ref.watch(packStorageProvider),
  );
});

/// Etat de telechargement d'un pack vu par l'UI (F8B-03).
///
/// Combine le statut courant ([PackDownloadStatus]) et la progression. Sert au
/// store pour afficher non-telecharge / en cours / telecharge / erreur.
class PackDownloadState {
  const PackDownloadState({
    this.status = PackDownloadStatus.pending,
    this.filesDone = 0,
    this.filesTotal = 0,
    this.error,
    this.downloaded = false,
  });

  /// Etat initial : pas de telechargement en cours.
  const PackDownloadState.idle({this.downloaded = false})
      : status = PackDownloadStatus.pending,
        filesDone = 0,
        filesTotal = 0,
        error = null;

  final String status;
  final int filesDone;
  final int filesTotal;
  final String? error;

  /// Vrai si le pack est present en local (telecharge et verifie).
  final bool downloaded;

  /// Vrai si un telechargement est actuellement en cours.
  bool get isDownloading =>
      status == PackDownloadStatus.downloading ||
      status == PackDownloadStatus.verifying;

  /// Vrai si la derniere tentative a echoue.
  bool get isError => status == PackDownloadStatus.error;

  /// Fraction de progression [0..1] (0 si total inconnu).
  double get fraction => filesTotal == 0 ? 0 : filesDone / filesTotal;

  PackDownloadState copyWith({
    String? status,
    int? filesDone,
    int? filesTotal,
    String? error,
    bool? downloaded,
    bool clearError = false,
  }) {
    return PackDownloadState(
      status: status ?? this.status,
      filesDone: filesDone ?? this.filesDone,
      filesTotal: filesTotal ?? this.filesTotal,
      error: clearError ? null : (error ?? this.error),
      downloaded: downloaded ?? this.downloaded,
    );
  }
}

/// Controleur du telechargement/suppression d'UN pack (F8B-03).
///
/// Pilote [PackDownloadService.downloadPack] et reflete la progression dans un
/// [PackDownloadState] observe par l'UI (Riverpod 2.6, AUCUNE logique reseau
/// dans le widget). Gere aussi la suppression (gestion de l'espace, R2/R3).
class PackDownloadController extends StateNotifier<PackDownloadState> {
  PackDownloadController(this._service, this._packId)
      : super(const PackDownloadState.idle()) {
    _refreshDownloaded();
  }

  final PackDownloadService _service;
  final String _packId;
  StreamSubscription<PackDownloadProgress>? _sub;

  Future<void> _refreshDownloaded() async {
    final dl = await _service.isDownloaded(_packId);
    if (mounted) state = state.copyWith(downloaded: dl);
  }

  /// Lance (ou relance) le telechargement du pack decrit par [manifest].
  Future<void> download(PackManifest manifest) async {
    await _sub?.cancel();
    state = state.copyWith(
      status: PackDownloadStatus.downloading,
      filesDone: 0,
      filesTotal: manifest.allRefs.length,
      clearError: true,
    );
    _sub = _service.downloadPack(manifest).listen((p) {
      if (!mounted) return;
      state = state.copyWith(
        status: p.status,
        filesDone: p.filesDone,
        filesTotal: p.filesTotal,
        error: p.error,
        downloaded: p.isCompleted ? true : state.downloaded,
        clearError: p.error == null,
      );
    });
  }

  /// Supprime le pack telecharge (libere l'espace). Retourne les octets liberes.
  Future<int> delete() async {
    final freed = await _service.deletePack(_packId);
    if (mounted) {
      state = const PackDownloadState.idle(downloaded: false);
    }
    return freed;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Controleur de telechargement par pack (famille indexee par packId).
final packDownloadControllerProvider = StateNotifierProvider.family<
    PackDownloadController, PackDownloadState, String>((ref, packId) {
  return PackDownloadController(
    ref.watch(packDownloadServiceProvider),
    packId,
  );
});
