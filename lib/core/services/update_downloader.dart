/// Telechargement en arriere-plan d'une mise a jour de sentier, et notification
/// quand elle est prete a etre posee.
library;

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../i18n/translations.g.dart';
import '../config/trail_data_source.dart';
import '../data/daos/trail_manifests_dao.dart';
import '../models/niveau_de_telechargement.dart';
import '../models/trail_manifest.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'delta_update_service.dart';
import 'manifest_service.dart';
import 'update_checker.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// ID de base pour les notifications de MAJ prete.
const _updateReadyNotifBaseId = 6000;

/// Canal de notification pour les MAJ pretes.
const updateReadyChannel = 'update_ready';
const updateReadyChannelDesc = 'Notifications de mise a jour prete';

/// Resultat de la synchronisation d un sentier — MESURE, pas prevu.
class UpdateDownloadResult {
  const UpdateDownloadResult({
    required this.trailId,
    required this.success,
    this.tablesUpdated = const [],
    this.tablesSkipped = const [],
    this.error,
    this.niveau,
    this.enregistrementsRetenus = 0,
    this.enregistrementsEcartesHorsNiveau = 0,
  });

  /// Identifiant du sentier mis a jour.
  final String trailId;

  /// True si la synchronisation a abouti.
  final bool success;

  /// Familles de donnees effectivement REECRITES (bilan reel).
  final List<String> tablesUpdated;

  /// Familles intactes : rien de plus recent que la revision locale.
  final List<String> tablesSkipped;

  /// Message d erreur si echec.
  final String? error;

  /// JUSQU OU LE SENTIER EST DESCENDU apres cette passe (tache 616).
  final NiveauDeTelechargement? niveau;

  /// Enregistrements retenus et poses. C est le compte que le test affirme.
  final int enregistrementsRetenus;

  /// Enregistrements descendus puis ECARTES parce que hors du niveau demande.
  ///
  /// Sur un sentier seulement prepare, ce compte est celui des points de trace que
  /// le transport par fichier entier fait descendre pour rien. Il est REMONTE
  /// jusqu ici au lieu de finir dans un journal : c est ainsi qu on prouve qu un
  /// niveau ne pose pas plus que son perimetre, et qu on chiffre ce que le
  /// transport actuel coute encore.
  final int enregistrementsEcartesHorsNiveau;
}

/// Callback pour executer une tache en arriere-plan.
///
/// Abstraction du background work manager pour permettre
/// l injection en test sans dependance directe a workmanager.
typedef BackgroundTaskRunner =
    Future<void> Function(String taskName, Future<void> Function() task);

/// Runner par defaut : execute la tache directement (foreground).
Future<void> _defaultTaskRunner(
  String taskName,
  Future<void> Function() task,
) async {
  await task();
}

/// TACHE 604 — IL Y AVAIT ICI UNE ADRESSE EN DUR, ET ELLE ETAIT MORTE.
///
/// `const kDefaultTrailDataBaseUrl = 'https://storage.googleapis.com/moteur-gr'`
/// pointait sur un espace de stockage qui n a JAMAIS existe (404 sur la racine
/// comme sur l objet), et `catalog_provider.dart` en portait une SECONDE copie,
/// tout aussi morte. Deux copies d une meme information fausse.
///
/// La constante disparait : [UpdateDownloader.dataBaseUrl] devient un
/// REMPLACEMENT OPTIONNEL. Quand il est absent — le cas normal — chaque URL est
/// resolue par [TrailDataSource], seul endroit du moteur qui sait ou vivent les
/// donnees, et surchargeable au build.

/// Service de synchronisation des donnees sentier en arriere-plan (E4.11c).
///
/// Orchestre le pipeline : detection d ecart de revision -> telechargement ->
/// pose atomique -> notification. Seuls les enregistrements plus recents que la
/// revision locale sont ecrits (cf. `RevisionDeDonnee`). Le travail tourne en
/// arriere-plan via [BackgroundTaskRunner]. L URL est construite depuis
/// [dataBaseUrl] + filePath du manifeste (aucune marque en dur).
///
/// Dependances : E4.11b (UpdateChecker), E4.3 (manifest), E4.4a (download).
class UpdateDownloader {
  UpdateDownloader({
    required this.updateChecker,
    required this.deltaUpdateService,
    required this.manifestService,
    required this.dao,
    required this.connectivityMonitor,
    this.dataBaseUrl,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    BackgroundTaskRunner? backgroundRunner,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
       _backgroundRunner = backgroundRunner ?? _defaultTaskRunner;

  final UpdateChecker updateChecker;
  final DeltaUpdateService deltaUpdateService;
  final ManifestService manifestService;

  /// Manifestes locaux — POUR LE MARQUEUR DE COMPLETUDE, et il etait mort.
  ///
  /// Ce champ etait injecte par [updateDownloaderProvider] et UTILISE NULLE PART
  /// dans cette classe (mesure de la tache 605, confirmant Athena). Il avait ete
  /// prevu pour ecrire `localVersion` apres une mise a jour reussie — l ecriture
  /// n a jamais existe, et comme `TrailManifestsDao.needsUpdate` s en sert pour
  /// decider s il faut telecharger, CHAQUE ouverture retelechargeait tout.
  /// L ecriture se fait desormais dans la transaction du
  /// `DeltaUpdateService.appliquerRevisions` (`inscrireRevision`), pour qu un
  /// repere de revision ne puisse pas survivre a un retour arriere des donnees.
  final TrailManifestsDao dao;

  final ConnectivityMonitor connectivityMonitor;

  /// REMPLACEMENT optionnel de la base d URL des fichiers de donnees.
  ///
  /// `null` — le cas normal — signifie « demande a [TrailDataSource] », qui
  /// resout depuis l espace de stockage Firebase du projet. Une valeur non nulle
  /// sert a servir les donnees depuis un autre hebergeur (tests, recette, futur
  /// miroir) sans reconstruire le moteur.
  final String? dataBaseUrl;

  /// URL des donnees de [cheminManifeste], remplacement honore s il existe.
  String urlDonnees(String cheminManifeste) => dataBaseUrl == null
      ? TrailDataSource.urlDonneesSentier(cheminManifeste)
      : '$dataBaseUrl/$cheminManifeste';

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final BackgroundTaskRunner _backgroundRunner;

  /// Telecharge les deltas pour tous les sentiers ayant une MAJ.
  ///
  /// Pipeline :
  /// 1. [UpdateChecker.checkAllForUpdates] detecte les sentiers en retard.
  /// 2. Pour chacun, recupere la liste distante.
  /// 3. [DeltaUpdateService.checkForUpdates] mesure l ecart de revision.
  /// 4. Telecharge, puis pose UNIQUEMENT ce qui est plus recent, en une
  ///    transaction.
  /// 5. Notifie l utilisateur quand c est pret.
  ///
  /// Retourne la liste des resultats (un par sentier traite).
  ///
  /// [niveauParSentier] DIT A QUEL NIVEAU RESYNCHRONISER CHAQUE SENTIER (tache
  /// 616), et c est la garde qui empeche la cadence de trahir la demande du 28/09
  /// 11:27. Un sentier absent de cette table descend au niveau
  /// [NiveauDeTelechargement.regarder], c est-a-dire RIEN.
  ///
  /// LE REPLI LE PLUS BAS EST LE SEUL HONNETE, ET C EST L INVERSE DU REFLEXE. Ne
  /// pas savoir jusqu ou un sentier est descendu ne doit jamais se traduire par
  /// « descends tout » : ce serait faire arriver la trace, ses 10 000 points et les
  /// tuiles sur un sentier seulement prepare, toutes les quatre heures, sans que le
  /// randonneur l ait demande. `DeltaUpdateService.synchroniser` releve de toute
  /// facon le niveau au plus haut des deux (demande / deja descendu), donc ce repli
  /// ne peut pas DEGRADER un sentier deja complet — il peut seulement s abstenir.
  Future<List<UpdateDownloadResult>> downloadAllUpdates({
    required String manifestUrl,
    Map<String, NiveauDeTelechargement> niveauParSentier = const {},
  }) async {
    final results = <UpdateDownloadResult>[];

    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      _log.d('[UpdateDownloader] Hors ligne, telechargement annule');
      return results;
    }

    final updates = await updateChecker.checkAllForUpdates();
    if (updates.isEmpty) {
      _log.d('[UpdateDownloader] Aucune MAJ a telecharger');
      return results;
    }

    final remoteManifest = await manifestService.fetchManifest(manifestUrl);
    if (remoteManifest == null) {
      _log.e('[UpdateDownloader] Impossible de recuperer le manifeste');
      return results;
    }

    for (final update in updates) {
      final result = await _downloadDelta(
        trailId: update.trailId,
        remoteManifest: remoteManifest,
        niveau:
            niveauParSentier[update.trailId] ?? NiveauDeTelechargement.regarder,
      );
      results.add(result);
    }

    final successCount = results.where((r) => r.success).length;
    if (successCount > 0) {
      await _notifyUpdateReady(successCount);
    }

    return results;
  }

  /// Synchronise un seul sentier, AU NIVEAU DEMANDE.
  ///
  /// Ne reecrit que les enregistrements plus recents que la revision locale, et
  /// seulement dans les familles que [niveau] porte. Le niveau est OBLIGATOIRE
  /// ici — c est un appel nomme, pour un sentier nomme : l appelant sait ce qu il
  /// veut, il le dit.
  Future<UpdateDownloadResult> downloadSingleUpdate({
    required String trailId,
    required String manifestUrl,
    required NiveauDeTelechargement niveau,
  }) async {
    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      return UpdateDownloadResult(
        trailId: trailId,
        success: false,
        error: 'offline',
      );
    }

    final remoteManifest = await manifestService.fetchManifest(manifestUrl);
    if (remoteManifest == null) {
      return UpdateDownloadResult(
        trailId: trailId,
        success: false,
        error: 'manifest_unavailable',
      );
    }

    return _downloadDelta(
      trailId: trailId,
      remoteManifest: remoteManifest,
      niveau: niveau,
    );
  }

  /// Lance le telechargement de toutes les MAJ en arriere-plan.
  ///
  /// Utilise [BackgroundTaskRunner] pour executer le pipeline
  /// sans bloquer l UI. Par defaut, execute en foreground.
  /// En production, injecter un runner workmanager.
  ///
  /// CETTE METHODE N ETAIT APPELEE PAR PERSONNE, ET C EST TOUT LE SECOND POINT DE
  /// LA TACHE 616. La tache 610 l avait signale : la mecanique existait depuis
  /// E4.11c, rien ne la reveillait. Elle est desormais le point d entree de
  /// [OrdonnanceurDeSynchronisation] — au retour du reseau, puis toutes les quatre
  /// heures — qui lui fournit le niveau de CHAQUE sentier telecharge.
  ///
  /// ELLE REND LES RESULTATS, ET LA LIMITE DE CE RETOUR EST DITE. Avec le runner
  /// par defaut (foreground) les bilans reviennent, ce qui permet de les MESURER
  /// — c est ce dont la tache 616 avait besoin pour compter les enregistrements
  /// descendus par niveau. Avec un runner qui delegue vraiment a un ordonnanceur
  /// systeme (workmanager), l appel rend la main AVANT que la tache ne tourne :
  /// la liste revient alors VIDE, et cela ne signifie pas « rien n a ete fait ».
  /// Le dire ici vaut mieux que de laisser un appelant futur conclure a un echec.
  Future<List<UpdateDownloadResult>> scheduleBackgroundDownload({
    required String manifestUrl,
    Map<String, NiveauDeTelechargement> niveauParSentier = const {},
  }) async {
    var resultats = const <UpdateDownloadResult>[];
    await _backgroundRunner('update_download', () async {
      resultats = await downloadAllUpdates(
        manifestUrl: manifestUrl,
        niveauParSentier: niveauParSentier,
      );
    });
    return resultats;
  }

  /// Synchronise un sentier : ce qui est plus recent que sa revision descend.
  ///
  /// LE RESULTAT EST MESURE, PLUS PREDIT (tache 605). [UpdateDownloadResult]
  /// annoncait `tablesUpdated` / `tablesSkipped` depuis la liste rendue par
  /// `DeltaUpdateService._inferChangedTables`, qui retournait les SEPT tables en
  /// dur : le rapport disait donc invariablement « 7 mises a jour, 0 ignorees »,
  /// quelle que soit la realite. Les deux listes viennent desormais du BILAN de ce
  /// qui a ete pose — une altitude corrigee rend « stages » et rien d autre.
  Future<UpdateDownloadResult> _downloadDelta({
    required String trailId,
    required TrailManifest remoteManifest,
    required NiveauDeTelechargement niveau,
  }) async {
    try {
      // NIVEAU « REGARDER » : ON N INTERROGE MEME PAS L ECART (tache 616). Il n y a
      // rien a poser, donc rien a comparer — et surtout aucune liste de donnees a
      // aller chercher. Sortir ici plutot que de laisser la source rendre un lot
      // vide evite un aller-retour reseau par sentier et par passe de cadence.
      if (niveau == NiveauDeTelechargement.regarder) {
        _log.d(
          '[UpdateDownloader] $trailId : niveau « regarder » — aucune donnee '
          'demandee.',
        );
        return UpdateDownloadResult(
          trailId: trailId,
          success: true,
          tablesSkipped: allTables,
          niveau: niveau,
        );
      }

      final ecart = await deltaUpdateService.checkForUpdates(
        trailId,
        remoteManifest: remoteManifest,
      );

      // « DEJA A JOUR » EST UNE REPONSE SUR LA DATE, PAS SUR LE NIVEAU — ET LE
      // PIEGE SE REFERMAIT ICI (tache 616). `checkForUpdates` ne compare que les
      // horodatages : un sentier copie au niveau « preparer » jusqu a l instant T,
      // dont le serveur est toujours a T, rend un ecart NUL. On sortait donc en
      // annoncant « deja a jour » et la demande de monter a « realiser » etait
      // perdue en silence — le randonneur partait sans trace. La question complete
      // est « suis-je a jour A CETTE DATE ET A CE NIVEAU ».
      final niveauDeja = await dao.niveauDe(trailId);
      final niveauCouvert = niveauDeja != null && niveauDeja.couvre(niveau);

      if (ecart == null && niveauCouvert) {
        _log.d(
          '[UpdateDownloader] $trailId deja a jour au niveau ${niveau.code}',
        );
        return UpdateDownloadResult(
          trailId: trailId,
          success: true,
          tablesSkipped: allTables,
          niveau: niveauDeja,
        );
      }

      final remoteEntry = remoteManifest.trails
          .where((t) => t.trailId == trailId)
          .firstOrNull;

      if (remoteEntry == null) {
        return UpdateDownloadResult(
          trailId: trailId,
          success: false,
          error: 'trail_missing_from_manifest',
        );
      }

      _log.d(
        '[UpdateDownloader] $trailId : '
        '${ecart == null
            ? "MONTEE DE NIVEAU"
            : ecart.premiereCopie
            ? "PREMIERE "
                  "COPIE"
            : "mise a jour"} '
        '${ecart?.fromVersion ?? "(date inchangee)"} -> '
        '${remoteEntry.dataVersion}, niveau ${niveauDeja?.code ?? "aucun"} -> '
        '${niveau.code}',
      );

      // UN SEUL CHEMIN pour la premiere copie, la mise a jour et la montee de
      // niveau : a la revision zero, tout est plus recent que la revision locale,
      // donc tout descend. La revision locale est passee telle qu elle vient d etre
      // lue, pour ne pas la relire entre-temps — sauf sur une montee de niveau sans
      // nouvelle publication, ou il n y a pas d ecart a lire et ou
      // `synchroniser` relit le repere lui-meme avant de repartir de l origine.
      final bilan = await deltaUpdateService.synchroniser(
        trailId,
        urlDonnees(remoteEntry.filePath),
        revisionCible: remoteEntry.dataVersion,
        // L empreinte vient de la liste DISTANTE, pas du cache local : c est
        // celle que le serveur annonce pour le fichier qu on va chercher.
        empreinteAttendue: remoteEntry.hash,
        niveau: niveau,
        revisionLocaleConnue: ecart?.fromVersion,
      );

      return UpdateDownloadResult(
        trailId: trailId,
        success: true,
        tablesUpdated: bilan.famillesTouchees,
        tablesSkipped: allTables
            .where((t) => !bilan.famillesTouchees.contains(t))
            .toList(),
        niveau: bilan.niveauAtteint,
        enregistrementsRetenus: bilan.retenus,
        enregistrementsEcartesHorsNiveau: bilan.ecartesHorsNiveau,
      );
    } catch (e) {
      _log.e('[UpdateDownloader] Erreur synchronisation $trailId: $e');
      return UpdateDownloadResult(
        trailId: trailId,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Notifie l utilisateur que la MAJ est prete (textes Slang).
  Future<void> _notifyUpdateReady(int count) async {
    try {
      final title = t.updates.readyTitle;
      final body = count == 1
          ? t.updates.readyBodyOne
          : t.updates.readyBodyMany(count: count);

      await _notificationsPlugin.show(
        _updateReadyNotifBaseId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            updateReadyChannel,
            updateReadyChannel,
            channelDescription: updateReadyChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
          ),
        ),
      );
      _log.d('[UpdateDownloader] Notification MAJ prete envoyee ($count)');
    } catch (e) {
      _log.e('[UpdateDownloader] Erreur notification: $e');
    }
  }

  /// Les sept familles de donnees d un sentier.
  ///
  /// UNE SEULE DEFINITION (tache 605) : cette liste etait la TROISIEME copie de
  /// la meme enumeration (avec `_insertionSteps` de l ancien
  /// `TrailDownloadService`, supprime en 606, et le retour en dur de
  /// `_inferChangedTables`). Trois copies d un ordre qui compte
  /// — c est l ordre des cles etrangeres — dont deux pouvaient deriver en
  /// silence. Elle delegue desormais a [MorceauxDeSentier.tous].
  static const allTables = MorceauxDeSentier.tous;
}

/// Provider Riverpod pour le service de telechargement delta background.
final updateDownloaderProvider = Provider<UpdateDownloader>((ref) {
  final db = ref.watch(databaseProvider);
  return UpdateDownloader(
    updateChecker: ref.watch(updateCheckerProvider),
    deltaUpdateService: ref.watch(deltaUpdateServiceProvider),
    manifestService: ref.watch(manifestServiceProvider),
    dao: TrailManifestsDao(db),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
  );
});
