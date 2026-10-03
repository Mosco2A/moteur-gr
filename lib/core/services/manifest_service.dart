/// Confrontation du manifeste distant aux versions locales : c'est elle qui
/// decide quels sentiers ont quelque chose a mettre a jour.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../data/database.dart' hide TrailManifest;
import '../data/daos/trail_manifests_dao.dart';
import '../models/trail_manifest.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'package:drift/drift.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Service de gestion du manifeste des sentiers.
///
/// Telecharge le manifeste distant, le parse, compare avec
/// les versions locales et identifie les sentiers a mettre a jour.
class ManifestService {
  ManifestService({
    required this.dao,
    required this.connectivityMonitor,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final TrailManifestsDao dao;
  final ConnectivityMonitor connectivityMonitor;
  final http.Client _httpClient;

  /// Telecharge le manifeste depuis l'URL distante.
  ///
  /// Retourne null si hors ligne ou en cas d'erreur HTTP.
  Future<TrailManifest?> fetchManifest(String url) async {
    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      _log.d('[ManifestService] Hors ligne — fetch annule');
      return null;
    }

    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return parseManifest(response.body);
      }
      _log.w('[ManifestService] HTTP ${response.statusCode} pour $url');
      return null;
    } catch (e) {
      _log.e('[ManifestService] Erreur fetch: $e');
      return null;
    }
  }

  /// Parse une chaine JSON en TrailManifest.
  TrailManifest parseManifest(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return TrailManifest.fromJson(json);
  }

  /// Compare le manifeste distant avec la base locale.
  ///
  /// Retourne la liste des entrees necessitant une mise a jour
  /// (nouvelle version, nouveau sentier, ou jamais telecharge).
  Future<List<TrailManifestEntry>> checkForUpdates(TrailManifest remote) async {
    final needsUpdateList = <TrailManifestEntry>[];

    for (final entry in remote.trails) {
      final needs = await dao.needsUpdate(entry.trailId);
      if (needs) {
        needsUpdateList.add(entry);
      }
    }

    return needsUpdateList;
  }

  /// Sauvegarde une entree du manifeste en base locale.
  ///
  /// Met a jour dataVersion, hash, etc. depuis l'entree distante.
  /// Ne touche PAS a localVersion (qui est mis a jour apres
  /// le telechargement effectif du fichier de donnees).
  ///
  /// CONSERVE AUSSI LA FICHE D AFFICHAGE (tache 605), et c est ce qui fait
  /// tenir la couche 2 de l ordre des sources. Sans cette ligne, le dernier
  /// catalogue distant recu serait perdu au premier redemarrage hors ligne :
  /// un sentier que le binaire ne connait pas disparaitrait de l ecran du
  /// randonneur des qu il perd le reseau.
  ///
  /// Une entree SANS fiche n EFFACE PAS la fiche deja connue : `Value.absent()`
  /// exclut la colonne du `UPDATE` (`insertOnConflictUpdate`). Une republication
  /// de simple versionnement ne fait donc pas regresser la description.
  ///
  /// CONSERVE AUSSI LE DESCRIPTEUR DES CARTES HORS LIGNE (tache 622), et c est ce
  /// qui rend la descente des tuiles possible depuis un catalogue affiche hors
  /// ligne. Le geste « telecharger » lit la LIGNE LOCALE, jamais la reponse reseau :
  /// sans ces trois colonnes, il faudrait relire le manifeste au moment du geste,
  /// donc ouvrir un second chemin de resolution de l adresse.
  ///
  /// LES TROIS CHAMPS SUIVENT LA MEME REGLE QUE LA FICHE — MAIS ENSEMBLE. Une entree
  /// qui ne declare AUCUNE tuile n effface pas celles deja connues (`Value.absent()`)
  /// : une republication de simple versionnement ne doit pas faire disparaitre la
  /// carte d un sentier. En revanche, des qu une entree declare un descripteur
  /// COMPLET, les trois colonnes sont reecrites d un bloc — une adresse neuve avec
  /// une ancienne empreinte serait une descente qui echoue a tous les coups.
  Future<void> saveLocalManifest(TrailManifestEntry entry) async {
    final fiche = entry.fiche;
    final tuiles = entry.aDesTuilesPubliees;
    if (!tuiles && entry.tilesPath != null) {
      _log.w(
        '[ManifestService] ${entry.trailId} : descripteur de cartes INCOMPLET '
        '(chemin=${entry.tilesPath}, taille=${entry.tilesSize}, '
        'empreinte=${entry.tilesHash == null ? "absente" : "presente"}) — ignore. '
        'Les trois vont ensemble : sans taille on ne peut pas annoncer le poids, '
        'sans empreinte on ne peut pas verifier une carte de plusieurs centaines '
        'de megaoctets.',
      );
    }
    await dao.insertOrReplace(
      TrailManifestsCompanion(
        trailId: Value(entry.trailId),
        dataVersion: Value(entry.dataVersion),
        hash: Value(entry.hash),
        filePath: Value(entry.filePath),
        fileSize: Value(entry.fileSize),
        status: Value(entry.status),
        lastUpdated: Value(entry.lastUpdated),
        ficheJson: fiche == null
            ? const Value.absent()
            : Value(jsonEncode(fiche.toJson())),
        tilesPath: tuiles ? Value(entry.tilesPath) : const Value.absent(),
        tilesSize: tuiles ? Value(entry.tilesSize) : const Value.absent(),
        tilesHash: tuiles ? Value(entry.tilesHash) : const Value.absent(),
      ),
    );
  }

  /// Relit une fiche d affichage conservee en base.
  ///
  /// Rend `null` sur une colonne vide comme sur un JSON illisible : une fiche
  /// corrompue ne doit PAS faire disparaitre le catalogue, elle doit seulement
  /// faire retomber ce sentier sur sa version compilee (ordre des sources).
  static TrailManifestSheet? ficheDepuisJson(String? brut) {
    if (brut == null || brut.isEmpty) return null;
    try {
      return TrailManifestSheet.fromJson(
        jsonDecode(brut) as Map<String, dynamic>,
      );
    } catch (e) {
      _log.w('[ManifestService] Fiche locale illisible, ignoree: $e');
      return null;
    }
  }
}

/// Provider Riverpod pour le service de manifeste.
///
/// Injecte la base de donnees et le moniteur de connectivite.
final manifestServiceProvider = Provider<ManifestService>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  return ManifestService(
    dao: TrailManifestsDao(db),
    connectivityMonitor: connectivity,
  );
});
