import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/config/trail_data_source.dart';
import '../../../core/data/daos/trail_manifests_dao.dart';
import '../../../core/data/daos/trail_meta_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/models/download_progress.dart';
import '../../../core/data/revision_de_donnee.dart';
import '../../treks/providers/entitlements_provider.dart';
import '../domain/etat_du_sentier.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/manifest_service.dart';
import '../../../core/services/trail_download_service.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

// --- Modeles internes au catalogue ---

/// Statut local d'un sentier dans le catalogue.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef TrailLocalStatus = String;

/// Valeurs connues pour TrailLocalStatus avec fallback generique.
abstract class TrailLocalStatusValues {
  static const String notDownloaded = 'notDownloaded';
  static const String downloading = 'downloading';
  static const String downloaded = 'downloaded';
  static const String updateAvailable = 'updateAvailable';
  static const String fallback = notDownloaded;
  static const List<String> values = [notDownloaded, downloading, downloaded, updateAvailable];
  static TrailLocalStatus fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Entree du catalogue combinant donnees distantes et locales.
class CatalogEntry {
  const CatalogEntry({
    required this.trailId,
    required this.dataVersion,
    required this.fileSize,
    required this.status,
    required this.lastUpdated,
    required this.localStatus,
    this.localVersion,
  });

  final String trailId;
  final int dataVersion;
  final int fileSize;
  final String status;
  final String lastUpdated;
  final TrailLocalStatus localStatus;
  final int? localVersion;
}

/// POURQUOI LA LISTE DES SENTIERS N A PAS PU ETRE RAFRAICHIE (tache 604).
///
/// CE QUI ETAIT CASSE, ET C EST LE POINT LE PLUS GRAVE DU LOT. Quand le
/// manifeste distant echouait, `_loadCatalog()` retombait sur la base locale et
/// rendait `CatalogState(entries: [...], isOffline: false)`. A l installation la
/// base locale est VIDE : l ecran recevait donc une liste vide, avec
/// `isOffline: false`, et AUCUNE trace de l echec. Un catalogue vide et un
/// catalogue qui n a pas pu se charger produisaient exactement le meme etat —
/// l utilisateur voyait un ecran vide sans un mot, et personne, ni lui ni un
/// journal, ne pouvait distinguer « il n y a rien » de « je n ai pas pu
/// regarder ».
///
/// La cause est desormais NOMMEE et portee par l etat, sur le meme principe que
/// [FirebaseIndisponible] (tache 596) : un echec silencieux est un echec
/// indiagnosticable.
enum CatalogEchec {
  /// Hors ligne : la liste distante n a pas ete demandee. Ce n est PAS une
  /// panne — les sentiers deja telecharges restent accessibles.
  horsLigne,

  /// En ligne, mais le manifeste distant n a pas pu etre recupere (404, panne
  /// serveur, espace de stockage non provisionne, reseau capricieux). Anomalie :
  /// l ecran doit le DIRE et proposer de reessayer.
  manifesteInjoignable,
}

/// Etat global du catalogue.
class CatalogState {
  const CatalogState({
    required this.entries,
    required this.isOffline,
    this.echec,
  });

  /// Liste combinee des sentiers (distants + statut local)
  final List<CatalogEntry> entries;

  /// Indique si l'appareil est hors ligne
  final bool isOffline;

  /// Pourquoi la liste distante manque, ou `null` si elle a bien ete lue.
  ///
  /// Non nul AVEC des entrees = les sentiers deja telecharges sont la, mais la
  /// liste n est pas a jour (hors ligne assume, cf. [CatalogEchec.horsLigne]).
  final CatalogEchec? echec;

  /// Vrai quand l ecran n a RIEN a montrer ET que la cause est un echec.
  ///
  /// C est exactement le cas qui produisait un ecran vide muet. L ecran doit
  /// afficher un message et un bouton « reessayer » ([CatalogNotifier.refresh]),
  /// jamais une liste vide sans explication.
  bool get doitExpliquerAuLieuDeRienMontrer =>
      entries.isEmpty && echec != null;

  CatalogState copyWith({
    List<CatalogEntry>? entries,
    bool? isOffline,
    CatalogEchec? echec,
    bool effacerEchec = false,
  }) {
    return CatalogState(
      entries: entries ?? this.entries,
      isOffline: isOffline ?? this.isOffline,
      echec: effacerEchec ? null : (echec ?? this.echec),
    );
  }
}

// --- Notifier principal du catalogue ---

/// Notifier qui gere la liste combinee sentiers distants + locaux.
///
/// Fusionne le manifeste distant (ManifestService) avec les
/// metadonnees locales (TrailManifestsDao) pour determiner le
/// statut de telechargement de chaque sentier.
class CatalogNotifier extends AsyncNotifier<CatalogState> {
  late ManifestService _manifestService;
  late TrailManifestsDao _manifestsDao;
  late TrailMetaDao _trailMetaDao;
  late ConnectivityMonitor _connectivity;

  /// URL du manifeste distant.
  ///
  /// TACHE 604 — C ETAIT `storage.googleapis.com/moteur-gr/manifest.json`, EN
  /// DUR, et cet espace de stockage n a jamais existe : 404 sur la racine comme
  /// sur l objet. `update_downloader.dart` en portait une seconde copie, aussi
  /// morte. Les deux lisent maintenant [TrailDataSource], seul endroit du moteur
  /// qui sait ou vivent les donnees, et surchargeable au build.
  static String get defaultManifestUrl => TrailDataSource.urlManifeste;

  @override
  Future<CatalogState> build() async {
    _manifestService = ref.read(manifestServiceProvider);
    final db = ref.read(databaseProvider);
    _manifestsDao = TrailManifestsDao(db);
    _trailMetaDao = TrailMetaDao(db);
    _connectivity = ref.read(connectivityMonitorProvider);

    return _loadCatalog();
  }

  /// Charge le catalogue : fetch distant + merge local.
  Future<CatalogState> _loadCatalog() async {
    final connectivityStatus = await _connectivity.checkStatus();
    final isOffline = connectivityStatus == ConnectivityStatusValues.offline;

    if (isOffline) {
      // Hors ligne : afficher uniquement les sentiers deja telecharges
      final localManifests = await _manifestsDao.getAll();
      final entries = localManifests
          .where((m) => m.localVersion != null)
          .map((m) => CatalogEntry(
                trailId: m.trailId,
                dataVersion: m.dataVersion,
                fileSize: m.fileSize,
                status: m.status,
                lastUpdated: m.lastUpdated,
                localStatus: TrailLocalStatusValues.downloaded,
                localVersion: m.localVersion,
              ))
          .toList();

      // HORS LIGNE : NON NEGOCIABLE. Les sentiers deja telecharges restent
      // accessibles au randonneur sans reseau — c est la raison d etre du
      // produit. La cause est nommee pour que l ecran puisse dire « liste non
      // rafraichie » au lieu de laisser croire que le catalogue est vide.
      return CatalogState(
        entries: entries,
        isOffline: true,
        echec: CatalogEchec.horsLigne,
      );
    }

    // En ligne : fetch le manifeste distant
    final manifest = await _manifestService.fetchManifest(defaultManifestUrl);
    if (manifest == null) {
      // L ECHEC EST DIT, PAS AVALE (tache 604). Avant, on rendait ici les
      // entrees locales avec `isOffline: false` et rien d autre : a
      // l installation la base locale est vide, donc l ecran recevait une liste
      // vide SANS AUCUNE EXPLICATION, indistinguable d un catalogue
      // legitimement vide. On garde le repli sur le local — ce qui est deja
      // telecharge doit rester visible — mais on NOMME la cause.
      _log.w(
        '[CatalogNotifier] Manifeste distant injoignable ($defaultManifestUrl) '
        '— repli sur les sentiers deja telecharges. La liste n est PAS a jour.',
      );
      final localManifests = await _manifestsDao.getAll();
      final entries = localManifests.map(_buildEntryFromLocal).toList();
      return CatalogState(
        entries: entries,
        isOffline: false,
        echec: CatalogEchec.manifesteInjoignable,
      );
    }

    // Sauvegarder le manifeste distant en base
    for (final entry in manifest.trails) {
      await _manifestService.saveLocalManifest(entry);
    }

    // Construire la liste combinee
    final entries = <CatalogEntry>[];
    for (final remote in manifest.trails) {
      if (remote.status != 'active') continue;

      final local = await _manifestsDao.getByTrailId(remote.trailId);
      final localVersion = local?.localVersion;

      TrailLocalStatus localStatus;
      if (localVersion == null) {
        localStatus = TrailLocalStatusValues.notDownloaded;
      } else if (remote.dataVersion > localVersion) {
        localStatus = TrailLocalStatusValues.updateAvailable;
      } else {
        localStatus = TrailLocalStatusValues.downloaded;
      }

      entries.add(CatalogEntry(
        trailId: remote.trailId,
        dataVersion: remote.dataVersion,
        fileSize: remote.fileSize,
        status: remote.status,
        lastUpdated: remote.lastUpdated,
        localStatus: localStatus,
        localVersion: localVersion,
      ));
    }

    return CatalogState(entries: entries, isOffline: false);
  }

  /// Construit une CatalogEntry depuis une entree locale uniquement.
  CatalogEntry _buildEntryFromLocal(TrailManifest local) {
    final localStatus = local.localVersion != null
        ? (local.dataVersion > local.localVersion!
            ? TrailLocalStatusValues.updateAvailable
            : TrailLocalStatusValues.downloaded)
        : TrailLocalStatusValues.notDownloaded;

    return CatalogEntry(
      trailId: local.trailId,
      dataVersion: local.dataVersion,
      fileSize: local.fileSize,
      status: local.status,
      lastUpdated: local.lastUpdated,
      localStatus: localStatus,
      localVersion: local.localVersion,
    );
  }

  /// Rafraichit le catalogue (pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadCatalog());
  }

  /// Lance le telechargement d'un sentier.
  ///
  /// Met a jour le statut en 'downloading' immediatement,
  /// puis ecoute le stream de progression du TrailDownloadService.
  Future<void> downloadTrail(String trailId) async {
    _updateEntryStatus(trailId, TrailLocalStatusValues.downloading);

    final downloadService = ref.read(trailDownloadServiceProvider);
    final manifestEntry = await _manifestsDao.getByTrailId(trailId);
    if (manifestEntry == null) {
      _log.e('[CatalogNotifier] Pas de manifeste pour $trailId');
      _updateEntryStatus(trailId, TrailLocalStatusValues.notDownloaded);
      return;
    }

    final dataUrl = manifestEntry.filePath;

    await for (final progress
        in downloadService.downloadTrail(trailId, dataUrl)) {
      // Mettre a jour le stream de progression
      ref.read(downloadProgressProvider(trailId).notifier).setProgress(progress);

      if (progress.status == DownloadStatusValues.completed) {
        // LA COPIE EST COMPLETE : on le marque, et on marque AUSSI chaque
        // morceau (point 1 + point 2 de Christophe, 27/09 20:11).
        //
        // Ce chemin telecharge le fichier COMPLET du sentier : les sept morceaux
        // sont donc poses ensemble, et leurs versions locales valent la
        // publication. Sans ces lignes, la table des versions unitaires resterait
        // vide apres un premier telechargement et la mise a jour suivante
        // reprendrait TOUT — c est-a-dire le defaut que le versionnage unitaire
        // vient supprimer.
        await _manifestsDao.inscrireRevision(
          manifestEntry.trailId,
          manifestEntry.dataVersion,
        );
        _updateEntryStatus(trailId, TrailLocalStatusValues.downloaded);
      } else if (progress.status == DownloadStatusValues.error) {
        _updateEntryStatus(trailId, TrailLocalStatusValues.notDownloaded);
      }
    }
  }

  /// LE GESTE « SUPPRIMER » — ET SON INTERDICTION SUR UN SENTIER ACHETE.
  ///
  /// Regle de Christophe du 27/09 20:41, prise telle quelle : « on peut aussi le
  /// supprimer sauf si on l a achete ». Le refus est RENDU, avec sa cause, pour
  /// que l ecran puisse le DIRE — un bouton indisponible sans explication est
  /// interdit.
  ///
  /// LE REFUS EST PORTE ICI, PAS SEULEMENT DANS L INTERFACE, et c est la
  /// difference entre une regle et une decoration : un bouton masque protege le
  /// randonneur qui regarde l ecran, une garde dans le notifier protege ses
  /// donnees quel que soit l appelant (raccourci, test, geste futur).
  ///
  /// CE QUI N EST PAS CONCERNE, ET IL FAUT LE DIRE POUR QU ON NE LE CONFONDE PAS
  /// AVEC UNE CONTRADICTION. Le modele economique (§6, #99412) prevoit qu un trek
  /// REALISE, donc termine, LIBERE ses grosses cartes hors ligne — gardees tant
  /// que le trek est EN COURS, retelechargeables s il refait le sentier. Ce sont
  /// deux objets differents a deux moments differents : l interdiction ci-dessous
  /// porte sur LES DONNEES DU SENTIER (etapes, points d interet, hebergements,
  /// trace) d un sentier achete ; la liberation porte sur LES TUILES DE CARTE d un
  /// trek deja fini. Aucune des deux ne touche a l objet de l autre.
  Future<RefusDeSuppression?> deleteTrailData(String trailId) async {
    final disponibilite = await disponibiliteDe(trailId);
    final refus = disponibilite.refusDeSuppression;
    if (refus != null) {
      _log.w(
        '[CatalogNotifier] Suppression de $trailId refusee : '
        '${refus == RefusDeSuppression.sentierAchete ? "sentier ACHETE — ses "
            "donnees ne peuvent pas etre effacees" : "rien a supprimer, le "
            "sentier n est pas sur le telephone"}.',
      );
      return refus;
    }

    await _trailMetaDao.deleteById(trailId);
    await _manifestsDao.oublierRevision(trailId);
    _updateEntryStatus(trailId, TrailLocalStatusValues.notDownloaded);
    return null;
  }

  /// L etat d un sentier et les gestes offerts (cf. [DisponibiliteDuSentier]).
  ///
  /// Les deux entrees sont lues a leur source respective et restent SEPAREES :
  /// la presence des donnees dans `trail_manifests.localVersion`, le droit dans
  /// les droits d achat. Telecharger n est pas acheter.
  Future<DisponibiliteDuSentier> disponibiliteDe(String trailId) async {
    final ligne = await _manifestsDao.getByTrailId(trailId);
    final revisionLocale = ligne?.localVersion;
    final possedes = await ref.read(ownedTrailIdsProvider.future);

    return DisponibiliteDuSentier(
      trailId: trailId,
      copieComplete: revisionLocale != null &&
          revisionLocale > RevisionDeDonnee.revisionInitiale &&
          (ligne == null || revisionLocale >= ligne.dataVersion),
      achete: possedes.contains(trailId),
    );
  }

  /// Met a jour le statut d'une entree dans l'etat courant.
  void _updateEntryStatus(String trailId, TrailLocalStatus newStatus) {
    final current = state.value;
    if (current == null) return;

    final updated = current.entries.map((e) {
      if (e.trailId == trailId) {
        return CatalogEntry(
          trailId: e.trailId,
          dataVersion: e.dataVersion,
          fileSize: e.fileSize,
          status: e.status,
          lastUpdated: e.lastUpdated,
          localStatus: newStatus,
          localVersion: newStatus == TrailLocalStatusValues.downloaded
              ? e.dataVersion
              : e.localVersion,
        );
      }
      return e;
    }).toList();

    state = AsyncData(current.copyWith(entries: updated));
  }
}

/// Provider principal du catalogue.
final catalogStateProvider =
    AsyncNotifierProvider<CatalogNotifier, CatalogState>(CatalogNotifier.new);

// --- Provider de progression de telechargement ---

/// Notifier simple pour la progression d'un telechargement en cours.
class DownloadProgressNotifier extends AsyncNotifier<DownloadProgress?> {
  // Riverpod 3 : FamilyAsyncNotifier retire (remplace par AsyncNotifier).
  // L'argument de famille (trailId) est recu par le constructeur ; il n'est pas
  // utilise ici mais conserve pour respecter la signature du tear-off .new
  // attendu par AsyncNotifierProvider.family. Aucun changement de logique.
  DownloadProgressNotifier(this._trailId);

  // ignore: unused_field
  final String _trailId;

  @override
  Future<DownloadProgress?> build() async => null;

  /// Met a jour la progression.
  void setProgress(DownloadProgress progress) {
    state = AsyncData(progress);
  }

  /// Remet a null (telechargement termine ou annule).
  void clear() {
    state = const AsyncData(null);
  }
}

/// Provider de progression par trailId.
final downloadProgressProvider = AsyncNotifierProvider.family<
    DownloadProgressNotifier, DownloadProgress?, String>(
  DownloadProgressNotifier.new,
);
