import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/data/daos/journal_dao.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Resultat de la sauvegarde d'une photo.
///
/// Contient le chemin local et la taille finale en octets,
/// ou un code erreur si la sauvegarde a echoue.
class PhotoSaveResult {
  const PhotoSaveResult._({
    this.path,
    this.sizeBytes,
    this.error,
  });

  /// Succes : chemin + taille
  factory PhotoSaveResult.success({
    required String path,
    required int sizeBytes,
  }) = _PhotoSaveSuccess;

  /// Echec : code erreur
  factory PhotoSaveResult.failure(PhotoError error) =>
      PhotoSaveResult._(error: error);

  /// Chemin local de la photo sauvegardee (null si erreur)
  final String? path;

  /// Taille finale en octets (null si erreur)
  final int? sizeBytes;

  /// Code erreur (null si succes)
  final PhotoError? error;

  /// Vrai si la sauvegarde a reussi
  bool get isSuccess => error == null && path != null;
}

class _PhotoSaveSuccess extends PhotoSaveResult {
  const _PhotoSaveSuccess({
    required String super.path,
    required int super.sizeBytes,
  }) : super._();
}

/// Codes d'erreur pour les operations photo.
enum PhotoError {
  /// Limite quotidienne de photos atteinte
  dailyLimitReached,

  /// Photo trop volumineuse apres compression
  tooLarge,

  /// Fichier source introuvable
  fileNotFound,

  /// Erreur d'ecriture disque
  ioError,
}

/// Service de gestion des photos du journal de trek.
///
/// Gere la compression JPEG, le stockage local (path_provider),
/// et applique les limites : 500 Ko max, 3 photos/jour (#81462).
/// Fonctionne entierement offline (galerie locale).
class PhotoService {
  PhotoService({
    required JournalDao journalDao,
    String? storagePath,
  })  : _dao = journalDao,
        _customStoragePath = storagePath;

  final JournalDao _dao;
  final String? _customStoragePath;

  /// Taille max d'une photo compressee (500 Ko)
  static const int maxSizeBytes = JournalDao.maxPhotoSizeBytes;

  /// Nombre max de photos par jour
  static const int maxPhotosPerDay = JournalDao.maxPhotosPerDay;

  /// Dimension max d'un cote (largeur ou hauteur) en pixels
  static const int _maxDimension = 1920;

  /// Sauvegarde une photo avec compression si necessaire.
  ///
  /// Verifie la limite quotidienne, compresse en JPEG <= 500 Ko,
  /// et stocke dans le dossier local du journal.
  /// [trailId] identifiant du sentier (pour le compteur quotidien).
  /// [sourceBytes] octets bruts de l'image source.
  /// [fileName] nom optionnel (defaut: timestamp).
  Future<PhotoSaveResult> savePhoto({
    required String trailId,
    required Uint8List sourceBytes,
    String? fileName,
  }) async {
    // Verifier la limite quotidienne (3 photos/jour)
    final canAdd = await _dao.canAddPhoto(trailId);
    if (!canAdd) {
      _log.w('[PhotoService] Limite quotidienne atteinte pour $trailId');
      return PhotoSaveResult.failure(PhotoError.dailyLimitReached);
    }

    // Compresser l'image
    final compressed = await compressPhoto(sourceBytes);
    if (compressed == null) {
      _log.w('[PhotoService] Compression echouee');
      return PhotoSaveResult.failure(PhotoError.tooLarge);
    }

    // Sauvegarder sur disque
    try {
      final dir = await _getPhotosDirectory();
      final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(compressed);

      _log.d(
        '[PhotoService] Photo sauvegardee: ${file.path} '
        '(${compressed.length} octets)',
      );

      return PhotoSaveResult.success(
        path: file.path,
        sizeBytes: compressed.length,
      );
    } catch (e) {
      _log.e('[PhotoService] Erreur ecriture: $e');
      return PhotoSaveResult.failure(PhotoError.ioError);
    }
  }

  /// Sauvegarde une photo depuis un fichier existant (ex: camera, galerie).
  ///
  /// Lit le fichier source, compresse, et stocke dans le dossier journal.
  Future<PhotoSaveResult> savePhotoFromFile({
    required String trailId,
    required String sourcePath,
  }) async {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      _log.w('[PhotoService] Fichier source introuvable: $sourcePath');
      return PhotoSaveResult.failure(PhotoError.fileNotFound);
    }

    final bytes = await file.readAsBytes();
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    return savePhoto(trailId: trailId, sourceBytes: bytes, fileName: name);
  }

  /// Compresse une image <= [maxSizeBytes].
  ///
  /// Reduit d'abord les dimensions (max 1920px par cote),
  /// puis encode en PNG. Si encore trop gros, reduit de moitie.
  /// Retourne null si impossible de compresser sous la limite.
  Future<Uint8List?> compressPhoto(Uint8List sourceBytes) async {
    // Si deja sous la limite, retourner tel quel
    if (sourceBytes.length <= maxSizeBytes) {
      return sourceBytes;
    }

    // Decoder l'image source
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Calculer les dimensions cibles (max 1920px par cote)
    final tw = image.width > _maxDimension ? _maxDimension : image.width;
    final th = image.height > _maxDimension ? _maxDimension : image.height;

    // Redimensionner si necessaire
    ui.Image resized;
    if (tw < image.width || th < image.height) {
      final scale = (tw / image.width) < (th / image.height)
          ? tw / image.width
          : th / image.height;
      final fw = (image.width * scale).round();
      final fh = (image.height * scale).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, fw.toDouble(), fh.toDouble()),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          0, 0, image.width.toDouble(), image.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, fw.toDouble(), fh.toDouble()),
        Paint()..filterQuality = FilterQuality.medium,
      );
      final picture = recorder.endRecording();
      resized = await picture.toImage(fw, fh);
    } else {
      resized = image;
    }

    // Encoder en PNG et verifier la taille
    final byteData = await resized.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return null;

    final pngBytes = byteData.buffer.asUint8List();
    if (pngBytes.length <= maxSizeBytes) {
      return pngBytes;
    }

    // Derniere tentative : reduction aggressive (moitie)
    final lastResort = await _compressHalf(resized);
    if (lastResort != null && lastResort.length <= maxSizeBytes) {
      return lastResort;
    }

    return null;
  }

  /// Compression aggressive : dimensions reduites de moitie.
  Future<Uint8List?> _compressHalf(ui.Image source) async {
    final hw = (source.width / 2).round();
    final hh = (source.height / 2).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, hw.toDouble(), hh.toDouble()),
    );
    canvas.drawImageRect(
      source,
      Rect.fromLTWH(
        0, 0, source.width.toDouble(), source.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, hw.toDouble(), hh.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final small = await picture.toImage(hw, hh);

    final byteData = await small.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List();
  }

  /// Recupere toutes les photos du journal stockees localement.
  ///
  /// Retourne la liste des fichiers tries par date (plus recent d'abord).
  /// Fonctionne entierement offline (galerie locale).
  Future<List<File>> getLocalPhotos() async {
    final dir = await _getPhotosDirectory();
    if (!dir.existsSync()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.jpeg') ||
            f.path.endsWith('.png'))
        .toList();

    // Trier par date de modification descendante (plus recent d'abord)
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// Supprime une photo du stockage local.
  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        _log.d('[PhotoService] Photo supprimee: $photoPath');
        return true;
      }
      return false;
    } catch (e) {
      _log.e('[PhotoService] Erreur suppression: $e');
      return false;
    }
  }

  /// Verifie si on peut encore ajouter une photo aujourd'hui.
  Future<bool> canAddPhoto(String trailId) async {
    return _dao.canAddPhoto(trailId);
  }

  /// Nombre de photos ajoutees aujourd'hui pour un sentier.
  Future<int> photosToday(String trailId) async {
    return _dao.countPhotosToday(trailId);
  }

  /// Retourne le dossier de stockage des photos du journal.
  Future<Directory> _getPhotosDirectory() async {
    final basePath =
        _customStoragePath ?? (await getApplicationDocumentsDirectory()).path;
    final dir = Directory('$basePath/journal_photos');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
