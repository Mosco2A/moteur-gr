import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_progress.freezed.dart';
part 'download_progress.g.dart';

/// Statut du telechargement d'un sentier.
enum DownloadStatus {
  /// En attente de demarrage
  pending,

  /// Telechargement en cours
  downloading,

  /// Mis en pause (coupure reseau, etc.)
  paused,

  /// Telechargement termine avec succes
  completed,

  /// Erreur lors du telechargement
  error,
}

/// Progression du telechargement d'un sentier.
///
/// Emis via un Stream pendant le telechargement pour
/// permettre a l'UI d'afficher la barre de progression.
@freezed
class DownloadProgress with _$DownloadProgress {
  const factory DownloadProgress({
    /// Identifiant du sentier en cours de telechargement
    required String trailId,

    /// Statut courant du telechargement
    required DownloadStatus status,

    /// Nombre d'octets telecharges
    required int bytesDownloaded,

    /// Taille totale en octets (0 si inconnue)
    required int totalBytes,

    /// Etape courante du pipeline ('downloading', 'trail_meta', 'stages', etc.)
    required String currentStep,

    /// Message d'erreur en cas de probleme (nullable)
    String? error,
  }) = _DownloadProgress;

  /// Deserialisation depuis JSON
  factory DownloadProgress.fromJson(Map<String, dynamic> json) =>
      _$DownloadProgressFromJson(json);
}
