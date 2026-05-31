import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_progress.freezed.dart';
part 'download_progress.g.dart';

/// Statut du telechargement d'un sentier.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef DownloadStatus = String;

/// Valeurs connues pour DownloadStatus avec fallback generique.
abstract class DownloadStatusValues {
  static const String pending = 'pending';
  static const String downloading = 'downloading';
  static const String paused = 'paused';
  static const String completed = 'completed';
  static const String error = 'error';
  static const String fallback = pending;
  static const List<String> values = [pending, downloading, paused, completed, error];
  static DownloadStatus fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Progression du telechargement d'un sentier.
///
/// Emis via un Stream pendant le telechargement pour
/// permettre a l'UI d'afficher la barre de progression.
@freezed
abstract class DownloadProgress with _$DownloadProgress {
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
