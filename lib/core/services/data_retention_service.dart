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
//      TOUTES les donnees personnelles locales (tables Drift utilisateur, fiche
//      randonneur, caches, cles SharedPreferences, consentements) ET emet une
//      demande de suppression cote serveur (suppression des documents lies a
//      l'UID hache). L'app etant anonyme-by-design (UID hache SHA-256, zero PII
//      directe #85383), l'effacement est simple — mais il doit etre COMPLET et
//      TRACABLE.
//
//      TACHE 561 (LOT J) — CE QUI A CHANGE, ET POURQUOI. Cet en-tete annoncait
//      deja un effacement complet alors qu'il ne l'etait pas : la liste des
//      tables etait RECOPIEE A LA MAIN (seize sur trente-six) et la fiche
//      randonneur n'y figurait pas — age, taille et poids, que l'application
//      declare elle-meme au randonneur comme des donnees de sante (art. 9), en
//      cinq langues. Cote SharedPreferences, seules les quatre cles de
//      consentement partaient : cinquante-cinq autres restaient, dont le
//      pseudo, les reservations et le tampon de points GPS bruts.
//      Les deux listes sont desormais DERIVEES (schema Drift / store de prefs)
//      et ne portent plus que des EXCEPTIONS nommees et justifiees. Une table
//      ou une cle nouvelle est donc effacee par defaut, jamais oubliee.
//
//      TACHE 562 (LOT K) — LE TROISIEME ETAGE. Deux etages ne suffisaient pas :
//      le KEYSTORE DE L'OS portait le code de reconnexion (qui ouvre le coffre
//      du randonneur sur un autre telephone) et la cle du coffre chiffre, tous
//      deux hors de portee de l'effacement. Meme inversion que pour les tables
//      et les prefs, voir [SecureKeystoreEraser].
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

import '../../features/feasibility/data/hiker_profile_repository.dart';
import '../data/database.dart';
import 'consent_service.dart';
import 'secure_keystore_eraser.dart';

/// CLE DU MARQUEUR D'EFFACEMENT LOCAL (tache 565, LOT N, N2).
///
/// Porte la DATE, en ISO-8601, du dernier effacement art. 17 joue sur cet
/// appareil. Ce n'est pas un residu de donnee personnelle : c'est la trace
/// MINIMALE qu'un droit a ete exerce — sans elle, aucune garde ne peut savoir
/// qu'une restauration s'appreterait a defaire cet effacement (voir
/// [RestoreService]). Une date plutot qu'un simple drapeau, pour qu'on puisse
/// toujours dire QUAND.
///
/// ELLE N'EST DANS AUCUNE LISTE D'EXCEPTION, ET C'EST VOULU : un effacement
/// suivant la balaye comme les autres cles, puis la reecrit a la fin. Le
/// resultat est identique et la classification des cles reste intacte (les
/// cles conservees sont des reglages d'affichage, rien d'autre).
const String kLocalErasureMarkerPrefsKey = 'privacy.localErasureAt';

/// Signature d'une verification « ce telephone a-t-il exerce son droit a
/// l'effacement ? », injectable pour les tests.
typedef LocalErasureCheck = Future<bool> Function();

/// Lecture REELLE du marqueur d'effacement local ([kLocalErasureMarkerPrefsKey]).
///
/// C'est l'implementation branchee par defaut dans les services qui pourraient
/// faire REVENIR de la donnee effacee. Elle relit les prefs a CHAQUE appel,
/// comme [consentFromLocalStore] et pour la meme raison : la reponse ne doit pas
/// dependre d'une instance mise en cache au demarrage.
///
/// FERMEE PAR DEFAUT, ET DANS CE SENS-CI : si l'etat est illisible, la fonction
/// retourne `true` — « on considere qu'il y a eu effacement », donc REFUS. Le
/// doute se tranche du cote de la personne, jamais du cote de la donnee : rendre
/// des donnees a quelqu'un qui a peut-etre demande leur effacement est la faute
/// la plus grave des deux.
Future<bool> localErasureFromStore() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kLocalErasureMarkerPrefsKey) != null;
  } catch (_) {
    return true;
  }
}

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
    this.prefsKeysDeleted = 0,
    this.tablesWiped = 0,
    this.secureKeysDeleted = 0,
  });

  /// Nombre total de lignes locales (toutes tables utilisateur) supprimees.
  final int localRowsDeleted;

  /// Vrai si les consentements ont ete effaces.
  final bool consentsCleared;

  /// Vrai si la demande de suppression serveur a ete emise avec succes.
  final bool serverDeletionRequested;

  /// Nombre de cles SharedPreferences personnelles supprimees (consentements
  /// compris). La retention de la SEULE base Drift laissait 55 cles derriere
  /// elle (tache 561, J1) : ce compte rend l'etage prefs verifiable.
  final int prefsKeysDeleted;

  /// Nombre de tables Drift videes (derive du schema, pas d'une liste ecrite
  /// a la main).
  final int tablesWiped;

  /// Nombre de cles effacees du KEYSTORE DE L'OS (tache 562, K2). Ce troisieme
  /// etage de stockage n'etait pas touche : le code de reconnexion, qui ouvre le
  /// coffre du randonneur sur un autre telephone, survivait a l'effacement.
  final int secureKeysDeleted;
}

/// Signature de l'effacement de la FICHE RANDONNEUR (donnee de sante, art. 9).
///
/// Injectable pour les tests ; par defaut branchee sur
/// `HikerProfileRepository.eraseAllPersonalData`, seule couche qui connaisse
/// les DEUX etages de stockage de cette fiche (prefs durables + miroir Drift).
typedef HikerFileEraser = Future<void> Function();

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
    HikerFileEraser? hikerFileEraser,
    SecureKeystoreErasure? secureKeystoreErasure,
    DateTime Function()? now,
  })  : _db = database,
        _prefs = prefs,
        _serverDeletion = serverDeletion,
        _policy = policy,
        _hikerFileEraser = hikerFileEraser ??
            HikerProfileRepository(db: database, prefs: prefs)
                .eraseAllPersonalData,
        _secureKeystoreErasure =
            secureKeystoreErasure ?? SecureKeystoreEraser().eraseAll,
        _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SharedPreferences _prefs;
  final ServerDeletionRequest? _serverDeletion;
  final RetentionPolicy _policy;
  final HikerFileEraser _hikerFileEraser;

  /// Effacement du keystore OS (tache 562, K2). JAMAIS nul : a defaut
  /// d'injection, il est branche sur le keystore REEL. Une etape d'effacement
  /// qu'on desactive en oubliant un parametre n'efface rien.
  final SecureKeystoreErasure _secureKeystoreErasure;
  final DateTime Function() _now;

  // ---------------------------------------------------------------------------
  // CLASSIFICATION DES TABLES — pourquoi elle est DERIVEE et non recopiee
  // ---------------------------------------------------------------------------
  //
  // Avant la tache 561, la liste des tables a vider etait ecrite a la main :
  // seize tables sur trente-six. Huit tables a donnee personnelle n'y etaient
  // pas, dont `hiker_profile` — l'age, la taille et le poids, que l'application
  // declare elle-meme comme des donnees de sante (art. 9) au randonneur. Le
  // defaut n'etait pas l'oubli d'une table : c'etait une liste recopiee, qu'on
  // oublie fatalement de tenir a jour.
  //
  // Le sens est donc INVERSE. On n'enumere plus ce qu'on efface : on enumere les
  // DEUX exceptions, et tout le reste du schema est efface. Consequence voulue :
  // une table ajoutee demain et oubliee par son auteur est EFFACEE, pas
  // conservee. Le defaut protege la personne, pas la donnee. Le test de
  // classification (`data_retention_classification_test.dart`) exige en plus
  // que chaque table du schema soit nommee dans une categorie.

  /// EXCEPTION 1 — tables de REFERENCE : contenu telecharge du sentier, aucune
  /// donnee personnelle. Les vider ferait perdre le sentier a un utilisateur qui
  /// demande l'effacement de SES donnees, sans rien proteger.
  static const Set<String> referenceTableNames = <String>{
    'stages',
    'pois',
    'segments',
    'waypoint',
    'trail_meta',
    'trail_itineraries',
    'trail_stages',
    'trail_accommodations',
    'trail_pois',
    'trail_gpx_tracks',
    'trail_gpx_points',
    'trail_manifests',
  };

  /// EXCEPTION 2 — donnees personnelles VOLONTAIREMENT conservees, chacune avec
  /// sa raison. Toute entree ici est une decision assumee, pas un oubli.
  ///
  ///   - `wallet_balance`   : solde d'etapes ACHETEES. L'effacer ferait perdre
  ///     au randonneur ce qu'il a paye ; la donnee est un miroir local du recu
  ///     du store, qui reste detenu par Google/Apple.
  ///   - `trek_entitlements`: droits d'acces par sentier, meme raison. Trace de
  ///     transaction (art 17.3.b/e : obligation comptable, defense de droits).
  ///   - `no_ads_state`     : periode sans-pub derivee d'un achat ou d'une
  ///     recompense ; l'effacer re-afficherait des pubs a un abonne.
  ///
  /// A ARBITRER PAR CHRIS : si l'effacement doit emporter l'etage monetaire,
  /// retirer les trois noms d'ici suffit — et le test de classification dira
  /// aussitot ce qui change.
  static const Set<String> retainedOnErasureTableNames = <String>{
    'wallet_balance',
    'trek_entitlements',
    'no_ads_state',
  };

  /// CLES SharedPreferences conservees par l'effacement : reglages d'affichage
  /// de l'appareil, sans rattachement a la personne. Meme inversion que pour les
  /// tables : la liste des cles a effacer est DERIVEE de `prefs.getKeys()` (le
  /// store reel), jamais recopiee — c'est la seule facon d'atteindre les cles
  /// construites dynamiquement par sentier (`departure_date_<trailId>`,
  /// `planning.retainedDuration.<trailId>`, `training_done_sessions_<trailId>`...)
  /// qu'aucune liste ecrite a la main ne peut enumerer.
  static const Set<String> preservedPrefsKeys = <String>{
    'settings_language',
    'settings_distance_unit',
    'settings_theme_mode',
    'settings_cache_enabled',
    'settings_cache_size_mb',
    'settings_skin',
    'settings_dominant_hand',
  };

  /// Cles de prefs conservees en plus des reglages : etage monetaire, meme
  /// arbitrage que [retainedOnErasureTableNames].
  ///
  /// `wallet.deliveredPurchaseIds` porte en outre une garantie d'IDEMPOTENCE :
  /// l'effacer exposerait a crediter deux fois un achat rejoue par le store.
  static const Set<String> retainedOnErasurePrefsKeys = <String>{
    'wallet.balanceSteps',
    'wallet.lifetimeEarned',
    'wallet.lifetimeSpent',
    'wallet.deliveredPurchaseIds',
    'monetization.purchasedTrails',
    'purchased_trail_ids',
  };

  /// Politique de retention appliquee (durees par categorie).
  RetentionPolicy get policy => _policy;

  /// Tables Drift effacees par le droit a l'effacement — DERIVEES du schema.
  ///
  /// `allTables` moins les deux exceptions. Une table ajoutee au schema sans
  /// etre classee tombe automatiquement ici (et sera donc effacee).
  List<TableInfo> get userTables => _db.allTables
      .where((t) =>
          !referenceTableNames.contains(t.actualTableName) &&
          !retainedOnErasureTableNames.contains(t.actualTableName))
      .toList(growable: false);

  /// Noms SQL des tables effacees (lecture, tracabilite et tests).
  List<String> get userTableNames =>
      userTables.map((t) => t.actualTableName).toList(growable: false);

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

    // 1. Cache meteo trop ANCIEN — au sens de la politique ecrite
    //    ([RetentionPolicy.cartoCache] : 7 jours), et non du TTL de
    //    re-telechargement (3 h).
    //
    //    TACHE 572 : ces deux durees etaient confondues. La purge appelait
    //    `clearExpired`, qui efface sur `expiresAt`, donc TROIS HEURES apres le
    //    releve — pendant que la politique de ce fichier documente sept JOURS
    //    pour les caches carto/meteo. Consequence sur le sentier : le randonneur
    //    telecharge sa meteo au refuge, marche, et trois heures plus tard
    //    l'application a efface le bulletin qu'il n'a plus aucun moyen de
    //    retelecharger. On purge desormais sur l'AGE du bulletin, avec la meme
    //    horloge que le reste de la purge (D4B-02).
    final expiredWeather = await _db.weatherCacheDao
        .clearFetchedBefore(now.subtract(_policy.cartoCache));

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
  ///   2. Effacement de la FICHE RANDONNEUR par la couche qui la possede
  ///      (donnee de sante art. 9, stockee sur DEUX etages).
  ///   3. Purge de toutes les tables Drift a donnee utilisateur, DERIVEE du
  ///      schema (voir [userTables]).
  ///   4. Purge des cles SharedPreferences personnelles, DERIVEE du store reel
  ///      (consentements compris).
  ///   5. Purge du KEYSTORE DE L'OS (tache 562, K2) : le code de reconnexion et
  ///      la cle du coffre chiffre y vivaient hors de portee de l'effacement.
  ///
  /// Retourne un [DeletionReport] (lignes, tables, cles, statut serveur).
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

    // 2. FICHE RANDONNEUR (art. 9) par sa propre couche : elle seule connait
    //    les deux etages. Vider le miroir Drift sans les prefs ne servirait a
    //    rien — le boot suivant le re-hydrate depuis les prefs.
    await _hikerFileEraser();

    // 3. Purge locale de toutes les tables a donnees utilisateur (derivee).
    final localRows = await _wipeAllUserTables();

    // 4. Purge des cles de prefs personnelles (dont les consentements : un
    //    consentement est un acte positif, il doit etre re-demande).
    final prefsKeysDeleted = await _wipeAllPersonalPrefs();

    // 5. KEYSTORE DE L'OS : le code de reconnexion ouvre le coffre du
    //    randonneur DEPUIS UN AUTRE TELEPHONE, et la cle du coffre dechiffre le
    //    backup de sa fiche sante. Les laisser en place apres un effacement,
    //    c'etait laisser la cle sur la porte.
    final secureKeysDeleted = await _secureKeystoreErasure();

    // 6. MARQUEUR D'EFFACEMENT LOCAL (tache 565, LOT N, N2), ECRIT EN DERNIER —
    //    apres la purge des prefs, sinon il serait emporte par son propre
    //    effacement. Il ne conserve rien de la personne : il dit seulement
    //    qu'un droit a ete exerce ici, et quand. Sans lui, une restauration
    //    depuis le miroir cloud (`RestoreService`) ramenerait tout ce qui vient
    //    d'etre efface, et la fusion « dernier ecrit gagne » ne pourrait pas
    //    s'y opposer : apres un effacement, le local est vide, donc le distant
    //    gagne toujours.
    await _prefs.setString(
      kLocalErasureMarkerPrefsKey,
      _now().toIso8601String(),
    );

    return DeletionReport(
      localRowsDeleted: localRows,
      consentsCleared: true,
      serverDeletionRequested: serverRequested,
      prefsKeysDeleted: prefsKeysDeleted,
      tablesWiped: userTables.length,
      secureKeysDeleted: secureKeysDeleted,
    );
  }

  /// Supprime toutes les lignes des tables Drift a donnees utilisateur.
  /// Retourne le nombre total de lignes supprimees.
  ///
  /// La liste n'est PLUS ecrite a la main : elle est derivee du schema
  /// ([userTables] = `allTables` moins [referenceTableNames] et
  /// [retainedOnErasureTableNames]). Couvre donc, sans avoir a les enumerer :
  /// contributions sociales, trace GPS de session, progression, journal,
  /// checklist, infos sante, fiche randonneur et randos passees, sessions de
  /// trek, nuitees choisies, suivi de groupe, demandes d'avis et caches.
  Future<int> _wipeAllUserTables() async {
    var total = 0;
    for (final table in userTables) {
      total += await _db.delete(table).go();
    }
    return total;
  }

  /// Supprime toutes les cles SharedPreferences personnelles. Retourne le
  /// nombre de cles supprimees.
  ///
  /// DERIVEE DU STORE REEL (`prefs.getKeys()`) moins [preservedPrefsKeys] et
  /// [retainedOnErasurePrefsKeys]. C'est la seule facon d'emporter les cles
  /// construites dynamiquement (une par sentier), qu'aucune liste recopiee ne
  /// peut connaitre — et la seule qui n'oublie pas une cle ajoutee demain.
  ///
  /// Les quatre cles de consentement tombent d'elles-memes (elles ne sont dans
  /// aucune exception) : un consentement est un acte positif, il doit etre
  /// re-demande apres un effacement. On les retire tout de meme nommement, pour
  /// que l'effacement du consentement ne depende pas d'une liste d'exceptions.
  Future<int> _wipeAllPersonalPrefs() async {
    var deleted = 0;
    // Copie defensive : on modifie le store en iterant.
    for (final key in _prefs.getKeys().toList(growable: false)) {
      if (preservedPrefsKeys.contains(key)) continue;
      if (retainedOnErasurePrefsKeys.contains(key)) continue;
      await _prefs.remove(key);
      deleted++;
    }
    for (final purpose in ConsentPurpose.values) {
      if (await _prefs.remove(purpose.storageKey)) deleted++;
    }
    return deleted;
  }
}
