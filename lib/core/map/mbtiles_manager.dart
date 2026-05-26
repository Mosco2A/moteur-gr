import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Gestionnaire de fichiers MBTiles pour le mode offline.
///
/// Gere le telechargement, la suppression et la verification
/// des fichiers .mbtiles par sentier (trailId).
/// Les fichiers sont stockes dans : documents/mbtiles/{trailId}.mbtiles
class MBTilesManager {
  MBTilesManager({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// Sous-dossier de stockage des MBTiles dans le repertoire documents.
  static const _mbtilesDir = 'mbtiles';

  /// Retourne le repertoire de stockage des MBTiles.
  /// Cree le dossier s'il n'existe pas.
  Future<Directory> _getMbtilesDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final mbtilesDir = Directory('${documentsDir.path}/$_mbtilesDir');
    if (!await mbtilesDir.exists()) {
      await mbtilesDir.create(recursive: true);
    }
    return mbtilesDir;
  }

  /// Retourne le chemin local du fichier .mbtiles pour un sentier.
  Future<String> getMbtilesPath(String trailId) async {
    final dir = await _getMbtilesDirectory();
    return '${dir.path}/$trailId.mbtiles';
  }

  /// Telecharge un fichier .mbtiles depuis [url] et le sauvegarde
  /// localement pour le sentier [trailId].
  ///
  /// Ecrase le fichier existant le cas echeant.
  /// Lance une exception si le telechargement echoue.
  Future<void> downloadMbtiles(String url, String trailId) async {
    _log.d('[MBTilesManager] Telechargement MBTiles pour $trailId depuis $url');

    final response = await _httpClient.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw HttpException(
        'Echec telechargement MBTiles: HTTP ${response.statusCode}',
        uri: Uri.parse(url),
      );
    }

    final path = await getMbtilesPath(trailId);
    final file = File(path);
    await file.writeAsBytes(response.bodyBytes);

    _log.d('[MBTilesManager] MBTiles sauvegarde: $path '
        '(${response.bodyBytes.length} octets)');
  }

  /// Supprime le fichier .mbtiles local pour le sentier [trailId].
  ///
  /// Ne fait rien si le fichier n'existe pas.
  Future<void> deleteMbtiles(String trailId) async {
    final path = await getMbtilesPath(trailId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _log.d('[MBTilesManager] MBTiles supprime: $path');
    }
  }

  /// Verifie si un fichier .mbtiles existe localement pour le sentier.
  Future<bool> hasMbtiles(String trailId) async {
    final path = await getMbtilesPath(trailId);
    return File(path).exists();
  }

  /// Liste les identifiants de sentiers ayant un fichier .mbtiles local.
  ///
  /// Parcourt le dossier mbtiles et extrait les trailIds
  /// depuis les noms de fichier ({trailId}.mbtiles).
  Future<List<String>> listDownloaded() async {
    final dir = await _getMbtilesDirectory();
    if (!await dir.exists()) return [];

    final entities = await dir.list().toList();
    final trailIds = <String>[];

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.mbtiles')) {
        // Extraire le trailId du nom de fichier
        final fileName = entity.uri.pathSegments.last;
        final trailId = fileName.replaceAll('.mbtiles', '');
        trailIds.add(trailId);
      }
    }

    return trailIds;
  }
}

/// Provider singleton du gestionnaire MBTiles.
final mbtilesManagerProvider = Provider<MBTilesManager>((ref) {
  return MBTilesManager();
});
