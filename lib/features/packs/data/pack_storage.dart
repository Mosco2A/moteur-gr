import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../core/error/error_handler.dart';

/// Stockage local des packs telecharges (F8B-02, offline-first R3).
///
/// Abstraction du systeme de fichiers : en prod, [FilePackStorage] ecrit sous le
/// repertoire applicatif (path_provider) ; en test, un fake en memoire simule le
/// stockage. Les services de lecture (carte mbtiles, WaypointService, town
/// guides) liront ces fichiers 100 % OFFLINE une fois le pack telecharge.
///
/// Les fichiers d'un pack sont ranges sous un sous-repertoire par `packId`, ce
/// qui permet une suppression atomique pour liberer l'espace.
abstract interface class PackStorage {
  /// Ecrit [bytes] pour la reference [ref] du pack [packId]. Retourne le chemin
  /// local absolu du fichier ecrit.
  Future<String> save(String packId, String ref, Uint8List bytes);

  /// Vrai si la reference [ref] du pack [packId] est presente en local.
  Future<bool> exists(String packId, String ref);

  /// Lit les octets stockes pour [ref] du pack [packId] (null si absent).
  Future<Uint8List?> read(String packId, String ref);

  /// Octets totaux occupes par le pack [packId] en local (0 si absent).
  Future<int> packSizeBytes(String packId);

  /// Vrai si le pack [packId] a au moins un fichier stocke.
  Future<bool> packExists(String packId);

  /// Supprime tout le pack [packId] (libere l'espace). Retourne le nombre
  /// d'octets liberes. Idempotent : 0 si le pack n'existait pas.
  Future<int> deletePack(String packId);
}

/// Implementation [PackStorage] sur le systeme de fichiers (path_provider).
///
/// Racine : `<applicationDocuments>/packs/<packId>/<ref aplati>`. Les `/` d'une
/// reference sont aplatis en `_` pour rester dans le sous-repertoire du pack.
class FilePackStorage implements PackStorage {
  FilePackStorage({Future<Directory> Function()? baseDirProvider})
      : _baseDirProvider =
            baseDirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDirProvider;

  Future<Directory> _packDir(String packId) async {
    final base = await _baseDirProvider();
    final dir = Directory('${base.path}/packs/$packId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Aplatit une reference (`a/b.json` -> `a_b.json`) pour un nom de fichier sur.
  String _flatten(String ref) => ref.replaceAll(RegExp(r'[\\/]+'), '_');

  Future<File> _fileFor(String packId, String ref) async {
    final dir = await _packDir(packId);
    return File('${dir.path}/${_flatten(ref)}');
  }

  @override
  Future<String> save(String packId, String ref, Uint8List bytes) async {
    try {
      final file = await _fileFor(packId, ref);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on FileSystemException catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'FilePackStorage.save');
      rethrow;
    }
  }

  @override
  Future<bool> exists(String packId, String ref) async {
    final file = await _fileFor(packId, ref);
    return file.exists();
  }

  @override
  Future<Uint8List?> read(String packId, String ref) async {
    final file = await _fileFor(packId, ref);
    if (!await file.exists()) return null;
    try {
      return await file.readAsBytes();
    } on FileSystemException catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'FilePackStorage.read');
      rethrow;
    }
  }

  @override
  Future<int> packSizeBytes(String packId) async {
    final base = await _baseDirProvider();
    final dir = Directory('${base.path}/packs/$packId');
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  @override
  Future<bool> packExists(String packId) async {
    final base = await _baseDirProvider();
    final dir = Directory('${base.path}/packs/$packId');
    if (!await dir.exists()) return false;
    final entries = await dir.list().toList();
    return entries.whereType<File>().isNotEmpty;
  }

  @override
  Future<int> deletePack(String packId) async {
    final base = await _baseDirProvider();
    final dir = Directory('${base.path}/packs/$packId');
    if (!await dir.exists()) return 0;
    try {
      final freed = await packSizeBytes(packId);
      await dir.delete(recursive: true);
      return freed;
    } on FileSystemException catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'FilePackStorage.deletePack');
      rethrow;
    }
  }
}
