// D4B-02 — Service de RETENTION et de DROIT A L'EFFACEMENT (design D4 CORDO
// #86166, angle mort AM-2 + RGPD art 17).
//
// Deux responsabilites complementaires :
//
//   1. RETENTION (limitation de la conservation, art 5.1.e RGPD) : chaque
//      categorie de donnee locale a une DUREE DE CONSERVATION documentee
//      ([RetentionPolicy]). [purgeExpired] supprime les donnees locales qui
//      ont depasse leur duree (caches expires, contributions deja
//      synchronisees et trop anciennes, file de synchro terminee). Ces durees
//      sont la SOURCE DE VERITE reprise par le registre des traitements
//      (D4D-01).
//
//   2. DROIT A L'EFFACEMENT (art 17 RGPD) : [deleteAccountData] efface
//      TOUTES les donnees personnelles locales (tables Drift utilisateur,
//      caches, consentements) ET emet une demande de suppression cote serveur
//      (suppression des documents lies a l'UID hache). L'app etant
//      anonyme-by-design (UID hache SHA-256, zero PII directe #85383),
//      l'effacement est simple — mais il doit etre COMPLET et TRACABLE.
//
// Aucun catch silencieux : une erreur de purge ou de suppression remonte
// (une suppression RGPD qui echoue en silence serait une non-conformite).
//
// Testabilite : l'horloge ([_now]) et l'appel serveur ([_serverDeletion])
// sont injectables. La purge et l'effacement local s'executent sur une vraie
// [AppDatabase] (in-memory en test).

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import 'consent_service.dart';

/// Categorie de donnee soumise a une duree de conservation (retention).
///
/// Chaque categorie porte sa propre duree, documentee et reprise dans le
/// registre des traitements (D4D-01).
enum RetentionCategory {
  /// Caches cartographiques / meteo : donnees recalculables, courte duree.
  cartoCache,

  /// Contributions deja synchronisees vers le serveur (signalements, efforts,
  /// kudos, commentaires) : la copie locale n'a plus a etre conservee
  /// longtemps une fois la synchro confirmee.
  syncedContributions,

  /// File de synchronisation terminee (actions deja jouees).
  completedSyncQueue,
}

/// Politique de retention : duree de conservation par categorie.
///
/// Valeurs documentees = SOURCE DE VERITE pour le registre des traitements
/// (D4D-01). Modifier une duree ici doit etre repercute dans la doc RGPD.
/// Les durees sont volontairement conservatrices (minimisation : on garde le
/// moins longtemps possible ce qui n'est plus utile).
class RetentionPolicy {
  const RetentionPolicy({
    this.cartoCache = const Duration(days: 7),
    this.syncedContributions = const Duration(days: 30),
    this.completedSyncQueue = const Duration(days: 7),
  });

  /// Caches carto/meteo : 7 jours (recalculables, on ne conserve pas plus).
  final Duration cartoCache;

  /// Contributions synchronisees : 30 jours apres synchro, la copie locale
  /// est purgee (la donnee de reference vit cote serveur).
  final Duration syncedContributions;

  /// File de synchro terminee : 7 jours (trace operationnelle courte).
  final Duration completedSyncQueue;

  /// Duree de conservation pour une categorie donnee.
  Duration durationFor(RetentionCategory category) {
    switch (category) {
      case RetentionCategory.cartoCache:
        return cartoCache;
      case RetentionCategory.syncedContributions:
        return syncedContributions;
      case RetentionCategory.completedSyncQueue:
        return completedSyncQueue;
    }
  }
}

/// Resultat d'une purge de retention (compte par categorie, pour tracabilite).
class PurgeReport {
  const PurgeReport({
    required this.expiredWeatherCache,
    required this.oldSyncQueue,
    required this.syncedReports,
    required this.syncedEfforts,
    required this.syncedKudos,
    required this.syncedComments,
  });

  /// Entrees de cache meteo expirees supprimees.
  final int expiredWeatherCache;

  /// Actions de la file de synchro terminees et anciennes supprimees.
  final int oldSyncQueue;

  /// Signalements synchronises et anciens supprimes.
  final int syncedReports;

  /// Efforts de segment synchronises et anciens supprimes.
  final int syncedEfforts;

  /// Kudos synchronises et anciens supprimes.
  final int syncedKudos;

  /// Commentaires de waypoint synchronises et anciens supprimes.
  final int syncedComments;

  /// Total des lignes supprimees (toutes categories).
  int get total =>
      expiredWeatherCache +
      oldSyncQueue +
      syncedReports +
      syncedEfforts +
      syncedKudos +
      syncedComments;
}

/// Resultat d'un effacement de compte (art 17), pour tracabilite.
class DeletionReport {
  const DeletionReport({
    required this.localRowsDeleted,
    required this.consentsCleared,
    required this.serverDeletionRequested,
  });

  /// Nombre total de lignes locales (toutes tables utilisateur) supprimees.
  final int localRowsDeleted;

  /// Vrai si les consentements ont ete effaces.
  final bool consentsCleared;

  /// Vrai si la demande de suppression serveur a ete emise avec succes.
  final bool serverDeletionRequested;
}

/// Signature de l'appel de suppression cote serveur.
///
/// Recoit l'UID hache du compte a supprimer. L'implementation reelle
/// declenche la suppression des documents Firestore lies a cet UID (ou
/// appelle une Cloud Function de suppression). Injectable -> testable sans
/// reseau. Doit lever en cas d'echec (pas de suppression silencieusement
/// ratee).
typedef ServerDeletionRequest = Future<void> Function(String uidHash);

/// Service de retention + droit a l'effacement (D4B-02).
class DataRetentionService {
  DataRetentionService({
    required AppDatabase database,
    required SharedPreferences prefs,
    ServerDeletionRequest? serverDeletion,
    RetentionPolicy policy = const RetentionPolicy(),
    DateTime Function()? now,
  })  : _db = database,
        _prefs = prefs,
        _serverDeletion = serverDeletion,
        _policy = policy,
        _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SharedPreferences _prefs;
  final ServerDeletionRequest? _serverDeletion;
  final RetentionPolicy _policy;
  final DateTime Function() _now;

  /// Politique de retention appliquee (durees par categorie).
  RetentionPolicy get policy => _policy;

  // -------------------------------------------------------------------------
  // RETENTION — purge des donnees locales EXPIREES
  // -------------------------------------------------------------------------

  /// Purge toutes les donnees locales qui ont depasse leur duree de
  /// conservation. Idempotent (rejouer ne supprime rien de plus).
  ///
  /// Categories traitees :
  ///   - cache meteo expire ([WeatherCache.expiresAt] < maintenant) ;
  ///   - file de synchro terminee plus ancienne que [RetentionPolicy
  ///     .completedSyncQueue] ;
  ///   - signalements / efforts / kudos / commentaires DEJA SYNCHRONISES
  ///     (`syncState == 'synced'`) plus anciens que [RetentionPolicy
  ///     .syncedContributions]. Les contributions NON synchronisees ne sont
  ///     JAMAIS purgees (sinon perte de donnee non remontee).
  ///
  /// Retourne un [PurgeReport] (compte par categorie) a des fins de tracabilite.
  Future<PurgeReport> purgeExpired() async {
    final now = _now();
    final contribCutoff = now.subtract(_policy.syncedContributions);

    // 1. Cache meteo expire (reutilise la logique TTL existante du DAO).
    //    On passe la MEME horloge que le reste de la purge : sinon une entree
    //    encore valide (expiresAt > now) serait supprimee a tort (D4B-02).
    final expiredWeather = await _db.weatherCacheDao.clearExpired(now);

    // 2. File de synchro terminee et ancienne.
    final oldSync = await _db.syncQueueDao
        .cleanOldCompleted(_policy.completedSyncQueue.inDays);

    // 3. Signalements synchronises et anciens.
    final reports = await (_db.delete(_db.reportLocal)
          ..where((t) =>
              t.syncState.equals('synced') &
              t.createdAt.isSmallerThanValue(contribCutoff)))
        .go();

    // 4. Efforts de segment synchronises et anciens (date = startedAt).
    final efforts = await (_db.delete(_db.segmentEffortLocal)
          ..where((t) =>
              t.syncState.equals('synced') &
              t.startedAt.isSmallerThanValue(contribCutoff)))
        .go();

    // 5. Kudos synchronises et anciens.
    final kudos = await (_db.delete(_db.kudosLocal)
          ..where((t) =>
              t.syncState.equals('synced') &
              t.createdAt.isSmallerThanValue(contribCutoff)))
        .go();

    // 6. Commentaires de waypoint synchronises et anciens.
    final comments = await (_db.delete(_db.waypointComment)
          ..where((t) =>
              t.syncState.equals('synced') &
              t.createdAt.isSmallerThanValue(contribCutoff)))
        .go();

    return PurgeReport(
      expiredWeatherCache: expiredWeather,
      oldSyncQueue: oldSync,
      syncedReports: reports,
      syncedEfforts: efforts,
      syncedKudos: kudos,
      syncedComments: comments,
    );
  }

  // -------------------------------------------------------------------------
  // DROIT A L'EFFACEMENT — art 17 RGPD
  // -------------------------------------------------------------------------

  /// Efface TOUTES les donnees personnelles du compte (RGPD art 17).
  ///
  /// Etapes (toutes obligatoires) :
  ///   1. Demande de suppression cote serveur (si [_serverDeletion] fourni et
  ///      [uidHash] non vide) — emise EN PREMIER : si elle echoue, on ne veut
  ///      pas avoir deja efface le local sans avoir prevenu le serveur. Une
  ///      erreur remonte (pas d'effacement partiel silencieux).
  ///   2. Purge de toutes les tables Drift contenant des donnees utilisateur
  ///      (contributions, caches, progression, sante, trace, journal...).
  ///   3. Effacement de tous les consentements locaux.
  ///
  /// Retourne un [DeletionReport] (nb de lignes locales supprimees, statut).
  ///
  /// [uidHash] : UID hache du compte (anonyme-by-design). Si vide/null, la
  /// suppression serveur est ignoree (compte purement local) mais l'effacement
  /// local est tout de meme realise.
  Future<DeletionReport> deleteAccountData({String? uidHash}) async {
    // 1. Demande de suppression serveur EN PREMIER (laisse remonter l'erreur).
    var serverRequested = false;
    final deletion = _serverDeletion;
    if (deletion != null && uidHash != null && uidHash.isNotEmpty) {
      await deletion(uidHash);
      serverRequested = true;
    }

    // 2. Purge locale COMPLETE de toutes les tables a donnees utilisateur.
    final localRows = await _wipeAllUserTables();

    // 3. Effacement de tous les consentements (acte positif a re-demander).
    final consentsCleared = await _clearAllConsents();

    return DeletionReport(
      localRowsDeleted: localRows,
      consentsCleared: consentsCleared,
      serverDeletionRequested: serverRequested,
    );
  }

  /// Supprime toutes les lignes des tables Drift contenant des donnees
  /// utilisateur. Retourne le nombre total de lignes supprimees.
  ///
  /// Couvre : contributions sociales (signalements, efforts, kudos, fil,
  /// waypoints + commentaires), trace GPS de session, progression, journal,
  /// checklist, infos sante, suivi de groupe, demandes d'avis, caches
  /// (meteo, file de synchro). NE touche PAS aux tables de REFERENCE
  /// (catalogue de sentiers TrailMeta/TrailStages/etc.) qui ne contiennent
  /// aucune donnee personnelle — seulement le contenu telecharge du sentier.
  Future<int> _wipeAllUserTables() async {
    var total = 0;
    // Liste explicite des tables a donnees utilisateur (revue ligne a ligne).
    final userTables = <TableInfo>[
      _db.reportLocal,
      _db.segmentEffortLocal,
      _db.kudosLocal,
      _db.activityFeedCache,
      _db.waypointComment,
      _db.sessionTrackPoints,
      _db.userProgressEntries,
      _db.journalEntries,
      _db.checklistItems,
      _db.healthInfoEntries,
      _db.followSessions,
      _db.followerSlots,
      _db.reviewRequests,
      _db.feedbackQueue,
      _db.weatherCache,
      _db.syncQueue,
    ];
    for (final table in userTables) {
      total += await _db.delete(table).go();
    }
    return total;
  }

  /// Efface tous les consentements stockes localement (une cle par finalite).
  ///
  /// Retourne vrai si l'operation s'est deroulee (meme si rien n'etait stocke).
  Future<bool> _clearAllConsents() async {
    for (final purpose in ConsentPurpose.values) {
      await _prefs.remove(purpose.storageKey);
    }
    return true;
  }
}
