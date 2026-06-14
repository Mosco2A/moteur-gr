import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/error/error_handler.dart';
import '../domain/pack_download_progress.dart';
import '../domain/pack_manifest.dart';
import 'pack_storage.dart';

/// Erreur d'integrite d'un pack telecharge (F8B-02).
///
/// Levee quand le checksum calcule sur les fichiers stockes ne correspond PAS au
/// checksum attendu du manifeste. JAMAIS avalee silencieusement : le service la
/// loggue (ErrorHandler) et la transforme en evenement de progression `error`.
class PackIntegrityException implements Exception {
  const PackIntegrityException({
    required this.packId,
    required this.expected,
    required this.actual,
  });

  final String packId;
  final String expected;
  final String actual;

  @override
  String toString() =>
      'PackIntegrityException(pack: $packId, attendu: $expected, calcule: $actual)';
}

/// Erreur de telechargement d'un fichier apres epuisement des tentatives.
class PackDownloadException implements Exception {
  const PackDownloadException({required this.ref, required this.cause});

  final String ref;
  final Object cause;

  @override
  String toString() => 'PackDownloadException(ref: $ref, cause: $cause)';
}

/// Source distante des fichiers d'un pack (F8B-02).
///
/// Decouple [PackDownloadService] du transport reel (HTTP/Firebase Storage) pour
/// la testabilite : en prod, l'implementation telecharge depuis une zone
/// couverte AVANT le depart (R3) ; en test, un fake renvoie des octets et peut
/// simuler des echecs transitoires (pour valider le retry borne).
abstract interface class PackFileSource {
  /// Recupere les octets de la reference [ref]. Doit lever en cas d'echec
  /// (jamais renvoyer null) — le service gere le retry borne et le logging.
  Future<Uint8List> fetch(String ref);
}

/// Service de pre-telechargement des packs sentier (F8B-02, Phase 8 P8-B).
///
/// Rapatrie un [PackManifest] COMPLET (cartes mbtiles + gpx + poi + town guides
/// + snapshot waypoints) AVANT le depart depuis une zone couverte (R3), VERIFIE
/// l'integrite (checksum), STOCKE en local ([PackStorage], lisible 100 %
/// offline), publie la PROGRESSION (`Stream<PackDownloadProgress>`), gere la
/// REPRISE sur echec (retry borne [maxAttempts] par fichier) et la SUPPRESSION
/// pour liberer l'espace.
///
/// REPRISE : un fichier deja present en local n'est PAS retelecharge (un appel
/// ulterieur reprend la ou il s'etait arrete). Le retry borne par fichier
/// (X6, max [maxAttempts]) evite toute boucle infinie : au-dela, le pack echoue
/// proprement (statut `error`) sans planter l'app.
///
/// INTEGRITE : si le manifeste porte un [PackManifest.checksum], le service
/// recalcule un SHA-256 deterministe sur le contenu stocke et REFUSE le pack en
/// cas d'ecart (purge partielle + statut `error`). Sans checksum (avant backend,
/// #84627), il verifie au minimum que tous les fichiers sont presents.
///
/// ZERO catch silencieux : toute erreur est loggee (ErrorHandler) ET remontee
/// dans le flux de progression.
class PackDownloadService {
  PackDownloadService({
    required PackFileSource fileSource,
    required PackStorage storage,
  })  : _fileSource = fileSource,
        _storage = storage;

  final PackFileSource _fileSource;
  final PackStorage _storage;

  /// Nombre maximal de tentatives par fichier (X6, reprise sur echec bornee).
  static const int maxAttempts = 5;

  /// Telecharge le pack decrit par [manifest] et publie la progression.
  ///
  /// Sequence : pour chaque reference de [PackManifest.allRefs] (sautee si deja
  /// presente — reprise), [PackFileSource.fetch] avec retry borne, puis stockage
  /// local ; ensuite VERIFICATION d'integrite ; enfin statut `completed`.
  /// N'emet JAMAIS d'exception : les erreurs deviennent un evenement `error`.
  Stream<PackDownloadProgress> downloadPack(PackManifest manifest) async* {
    final packId = manifest.packId;
    final refs = manifest.allRefs;
    final total = refs.length;

    yield PackDownloadProgress(
      packId: packId,
      status: PackDownloadStatus.pending,
      filesDone: 0,
      filesTotal: total,
    );

    var done = 0;
    for (final ref in refs) {
      // REPRISE : ne pas retelecharger un fichier deja stocke.
      if (await _storage.exists(packId, ref)) {
        done++;
        yield PackDownloadProgress(
          packId: packId,
          status: PackDownloadStatus.downloading,
          filesDone: done,
          filesTotal: total,
        );
        continue;
      }

      Object? lastError;
      var stored = false;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        yield PackDownloadProgress(
          packId: packId,
          status: PackDownloadStatus.downloading,
          filesDone: done,
          filesTotal: total,
          attempt: attempt,
        );
        try {
          final bytes = await _fileSource.fetch(ref);
          await _storage.save(packId, ref, bytes);
          stored = true;
          break;
        } on Exception catch (e, st) {
          lastError = e;
          ErrorHandler.log(
            e,
            stackTrace: st,
            context: 'PackDownloadService.downloadPack($packId/$ref) '
                'tentative $attempt/$maxAttempts',
          );
          // On retente tant que le plafond n'est pas atteint (X6).
        }
      }

      if (!stored) {
        // Plafond de tentatives atteint : echec propre, purge partielle.
        final failure = PackDownloadException(
          ref: ref,
          cause: lastError ?? 'inconnu',
        );
        ErrorHandler.log(failure,
            context: 'PackDownloadService.downloadPack($packId) abandon');
        await _safeDelete(packId);
        yield PackDownloadProgress(
          packId: packId,
          status: PackDownloadStatus.error,
          filesDone: done,
          filesTotal: total,
          error: failure.toString(),
        );
        return;
      }

      done++;
      yield PackDownloadProgress(
        packId: packId,
        status: PackDownloadStatus.downloading,
        filesDone: done,
        filesTotal: total,
      );
    }

    // --- VERIFICATION D'INTEGRITE ---
    yield PackDownloadProgress(
      packId: packId,
      status: PackDownloadStatus.verifying,
      filesDone: done,
      filesTotal: total,
    );
    try {
      await _verifyIntegrity(manifest);
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'PackDownloadService.verifyIntegrity');
      // Integrite KO : purge pour ne pas laisser un pack corrompu lisible.
      await _safeDelete(packId);
      yield PackDownloadProgress(
        packId: packId,
        status: PackDownloadStatus.error,
        filesDone: done,
        filesTotal: total,
        error: e.toString(),
      );
      return;
    }

    yield PackDownloadProgress(
      packId: packId,
      status: PackDownloadStatus.completed,
      filesDone: total,
      filesTotal: total,
    );
  }

  /// Verifie l'integrite du pack stocke contre [manifest].
  ///
  /// 1. tous les fichiers du manifeste DOIVENT etre presents en local ;
  /// 2. si [PackManifest.checksum] est fourni, le SHA-256 deterministe calcule
  ///    sur le contenu stocke doit correspondre — sinon [PackIntegrityException].
  Future<void> _verifyIntegrity(PackManifest manifest) async {
    final packId = manifest.packId;

    // 1. Presence de tous les fichiers.
    for (final ref in manifest.allRefs) {
      if (!await _storage.exists(packId, ref)) {
        throw PackIntegrityException(
          packId: packId,
          expected: 'fichier present: $ref',
          actual: 'fichier manquant',
        );
      }
    }

    // 2. Checksum (si fourni par le manifeste).
    final expected = manifest.checksum;
    if (expected == null) return; // pas de checksum -> presence suffit (P2-P3)

    final actual = await _computeChecksum(manifest);
    if (actual != expected) {
      throw PackIntegrityException(
        packId: packId,
        expected: expected,
        actual: actual,
      );
    }
  }

  /// SHA-256 DETERMINISTE du contenu stocke : concatene les octets des fichiers
  /// dans l'ordre stable de [PackManifest.allRefs], prefixes de la reference,
  /// pour un hash reproductible cote publication et cote client.
  Future<String> _computeChecksum(PackManifest manifest) async {
    final packId = manifest.packId;
    final builder = BytesBuilder(copy: false);
    for (final ref in manifest.allRefs) {
      builder.add(utf8.encode('$ref:'));
      final bytes = await _storage.read(packId, ref);
      if (bytes != null) builder.add(bytes);
    }
    final digest = sha256.convert(builder.takeBytes());
    return 'sha256:$digest';
  }

  /// Supprime un pack telecharge pour liberer l'espace (gestion de l'espace).
  ///
  /// Retourne le nombre d'octets liberes. Idempotent.
  Future<int> deletePack(String packId) => _storage.deletePack(packId);

  /// Vrai si le pack [packId] est present en local (telecharge).
  Future<bool> isDownloaded(String packId) => _storage.packExists(packId);

  /// Taille locale du pack [packId] en octets (0 si absent).
  Future<int> downloadedSizeBytes(String packId) =>
      _storage.packSizeBytes(packId);

  // Suppression defensive : ne JAMAIS masquer une erreur de purge (logging).
  Future<void> _safeDelete(String packId) async {
    try {
      await _storage.deletePack(packId);
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'PackDownloadService._safeDelete($packId)');
    }
  }
}
