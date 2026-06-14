import 'package:freezed_annotation/freezed_annotation.dart';

part 'pack_download_progress.freezed.dart';

/// Statut du telechargement d'un pack (F8B-02).
///
/// String extensible (cf. [DownloadStatus] des sentiers) : une valeur inconnue
/// retombe sur [fallback] sans planter.
abstract final class PackDownloadStatus {
  /// En file d'attente, rien n'a encore demarre.
  static const String pending = 'pending';

  /// Telechargement des fichiers en cours.
  static const String downloading = 'downloading';

  /// Verification d'integrite (checksum/taille) en cours.
  static const String verifying = 'verifying';

  /// Pack telecharge, verifie et stocke en local (lisible offline).
  static const String completed = 'completed';

  /// Echec (reseau, integrite, stockage) — voir [PackDownloadProgress.error].
  static const String error = 'error';

  /// Valeur de repli pour un statut inconnu.
  static const String fallback = pending;

  /// Tous les statuts connus.
  static const List<String> values = [
    pending,
    downloading,
    verifying,
    completed,
    error,
  ];

  /// Normalise [value] vers un statut connu, ou [fallback] sinon.
  static String fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Progression du telechargement d'un pack sentier (F8B-02).
///
/// Emise via un `Stream<PackDownloadProgress>` pendant le pre-telechargement
/// (R3) pour piloter la barre de progression du store (F8B-03). La progression
/// est exprimee en NOMBRE DE FICHIERS du manifeste (et non en octets) : le
/// catalogue fictif P2-P3 (#84627) ne fournit pas encore de tailles binaires
/// fiables, mais [PackManifest.allRefs] donne un decompte deterministe.
@freezed
abstract class PackDownloadProgress with _$PackDownloadProgress {
  const PackDownloadProgress._();

  const factory PackDownloadProgress({
    /// Identifiant du pack en cours de telechargement.
    required String packId,

    /// Statut courant ([PackDownloadStatus]).
    required String status,

    /// Nombre de fichiers deja recuperes et stockes.
    required int filesDone,

    /// Nombre total de fichiers a recuperer (= [PackManifest.allRefs].length).
    required int filesTotal,

    /// Numero de tentative courante (1..maxAttempts) pour le fichier en cours.
    @Default(1) int attempt,

    /// Message d'erreur en cas d'echec (null si tout va bien).
    String? error,
  }) = _PackDownloadProgress;

  /// Fraction de progression dans [0.0, 1.0] (0 si total inconnu).
  double get fraction => filesTotal == 0 ? 0 : filesDone / filesTotal;

  /// Vrai si le pack est entierement telecharge, verifie et stocke.
  bool get isCompleted => status == PackDownloadStatus.completed;

  /// Vrai si le telechargement a echoue.
  bool get isError => status == PackDownloadStatus.error;
}
