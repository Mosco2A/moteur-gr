import 'package:freezed_annotation/freezed_annotation.dart';

part 'trail_manifest.freezed.dart';
part 'trail_manifest.g.dart';

/// Manifeste des sentiers disponibles cote serveur.
///
/// Contient la version du schema et la liste des sentiers
/// avec leurs metadonnees de versionnement (hash, taille, etc.)
/// Utilise pour detecter les mises a jour a telecharger.
@freezed
class TrailManifest with _$TrailManifest {
  const factory TrailManifest({
    /// Version du schema du manifeste
    required int schemaVersion,

    /// Liste des sentiers declares dans le manifeste
    required List<TrailManifestEntry> trails,
  }) = _TrailManifest;

  /// Deserialisation depuis JSON
  factory TrailManifest.fromJson(Map<String, dynamic> json) =>
      _$TrailManifestFromJson(json);
}

/// Entree individuelle du manifeste pour un sentier.
///
/// Represente un sentier avec sa version, son hash d'integrite
/// et les informations de fichier associees.
@freezed
class TrailManifestEntry with _$TrailManifestEntry {
  const factory TrailManifestEntry({
    /// Identifiant unique du sentier (ex: 'gr20', 'mare_a_mare')
    required String trailId,

    /// Version des donnees (incremente a chaque publication serveur)
    required int dataVersion,

    /// Hash SHA-256 du fichier de donnees
    required String hash,

    /// Chemin relatif du fichier de donnees sur le serveur
    required String filePath,

    /// Taille du fichier en octets
    required int fileSize,

    /// Statut du sentier ('active', 'draft', 'archived')
    required String status,

    /// Date de derniere mise a jour (ISO 8601)
    required String lastUpdated,
  }) = _TrailManifestEntry;

  /// Deserialisation depuis JSON
  factory TrailManifestEntry.fromJson(Map<String, dynamic> json) =>
      _$TrailManifestEntryFromJson(json);
}
