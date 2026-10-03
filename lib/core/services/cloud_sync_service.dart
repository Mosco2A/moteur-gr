/// Montee et descente du miroir de compte non nominatif, sous liste fermee des
/// documents que le coffre distant peut porter (tache 612).
library;

import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:drift/drift.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:logger/logger.dart";

import "../data/database.dart";
import "../data/daos/checklist_dao.dart";
import "../data/daos/progress_dao.dart";
import "../data/daos/sync_queue_dao.dart";
import "../data/daos/past_hikes_dao.dart";
import "../firebase/firebase_service.dart";
import "../models/sync_config.dart";
import "../network/connectivity_monitor.dart";
import "../providers/database_provider.dart";

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

// LA RAISON DE REFUS « CONSENTEMENT SANTE ABSENT » N EXISTE PLUS ICI, ET ELLE
// N A PLUS DE SENS (DEM du 30/09 12:33).
//
// Elle nommait le refus de la seule garde de consentement que ce service
// portait, devant la montee des randos passees. Christophe a detache les randos
// de la case sante : ce service n a donc plus AUCUN refus de consentement a
// nommer, et garder la constante — comme garder le champ `consentCheck` qui
// allait avec — laisserait croire qu une garde vit encore ici. Elle ne vit plus.
//
// LA GARDE ART. 9 N A PAS DISPARU DU DEPOT, elle a change de porte :
// `RestoreService.restoreHikerProfile` la tient toujours dans l autre sens (la
// morphologie que le telephone peut RECEVOIR), avec sa propre raison nommee
// `kRestoreErrorHealthConsentMissing`. Et la fiche medicale, elle, n a aucun
// chemin de sortie du tout (liste fermee de la tache 612).

/// Raison de refus : le document demande n'est PAS dans
/// [DocumentsDuCoffreDistant.autorises] (tache 612).
///
/// Porte par [CloudSyncResult.error] avec un statut `idle`, pour la meme raison
/// que ci-dessus : ce n'est pas une panne, c'est un refus, et il doit se
/// diagnostiquer avec son propre mot.
const String kSyncErrorDocumentNonAutorise = 'document_coffre_non_autorise';

/// LES SEULS DOCUMENTS QUE LE COFFRE DISTANT PEUT PORTER — LISTE FERMEE,
/// REFUS PAR DEFAUT (tache 612, decision de Christophe du 28/09 10:42).
///
/// DECISION, verbatim et en majuscules dans son message : « NON ON NE
/// TROUVERAIT RIEN !!! Les donnees medicales RESTENT sur le tel !!! ». Version
/// dure : pas de sauvegarde distante de la fiche medicale, meme chiffree, meme
/// avec consentement, meme pour le bien de la personne. Si on ouvrait nos
/// serveurs on ne trouverait RIEN, pas des octets illisibles, RIEN.
///
/// POURQUOI UNE LISTE FERMEE ET PAS UN INTERDIT NOMME. Interdire le mot
/// « health » n'aurait rien protege : le prochain document se serait appele
/// « sante », « medical » ou « fiche_v2 » et serait passe. Le transport
/// n'accepte donc QUE ce qui est nomme ici, et tout le reste est refuse sans
/// toucher au reseau. Ouvrir un nouveau chemin de sortie exige d'ecrire son nom
/// dans cette liste, donc de croiser la decision ci-dessus, et une invariante
/// (`test/comportement/fiche_medicale_locale_612_test.dart`) exige que la liste
/// ne porte JAMAIS de document de sante.
///
/// CE QUI RESTE AUTORISE, ET POURQUOI. [compte] porte le pseudonyme, l'avatar
/// et le solde d'etapes (`AccountVaultService`) : zero donnee de sante, zero
/// nominatif. C'est le coffre de reconnexion de la decision #99784, et il n'est
/// pas concerne par celle du 28/09 — les deux sujets sont distincts.
abstract final class DocumentsDuCoffreDistant {
  /// Profil (pseudonyme + avatar) et solde d'etapes. AUCUNE donnee de sante.
  static const String account = 'account';

  /// La liste fermee elle-meme. Tout ce qui n'y est pas est refuse.
  static const Set<String> autorises = {account};

  /// Vrai si [docKey] peut etre transporte vers le coffre distant.
  static bool autorise(String docKey) => autorises.contains(docKey);
}

/// Statut d une operation de sync cloud.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef CloudSyncStatus = String;

/// Valeurs connues pour CloudSyncStatus avec fallback generique.
abstract class CloudSyncStatusValues {
  static const String idle = 'idle';
  static const String syncing = 'syncing';
  static const String success = 'success';
  static const String error = 'error';
  static const String fallback = idle;
  static const List<String> values = [idle, syncing, success, error];
  static CloudSyncStatus fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Resultat d une operation de synchronisation.
class CloudSyncResult {
  const CloudSyncResult({
    required this.status,
    required this.syncedAt,
    this.itemsSynced = 0,
    this.error,
  });

  final CloudSyncStatus status;
  final DateTime syncedAt;
  final int itemsSynced;
  final String? error;
}

/// CE QUE LE TELEPHONE ECRIT AU SERVEUR — ET LA LISTE S EST RETRECIE (tache
/// 635).
///
/// Strategie last-write-wins : chaque document porte un `updated_at`, le plus
/// recent gagne. POUR CE QUE CE SERVICE PORTE, LE TELEPHONE EST LA SOURCE DE
/// VERITE et le serveur en est la copie — c est l exact inverse du COMPTE, dont
/// les droits ne font que DESCENDRE (`descente_des_droits.dart`, tache 631).
///
/// CE QUI MONTE, ET C EST TOUT : la progression d un sentier
/// (`users/{uid}/trails/{trailId}/user_progress/current`), le sac
/// (`.../checklist_items/{id}`) et les randos passees
/// (`users/{uid}/past_hikes/{n}`, sous consentement art. 9).
///
/// CE QUI A ETE RETIRE DE LA MONTEE LE 29/09, ET POURQUOI. Decision de
/// Christophe, verbatim : « je veux que tout soit en base ... seul la copie sur
/// le tel », « Sauf les donnees persos ». Trois chemins de sortie de donnees
/// personnelles ont donc ete FERMES, pas seulement laisses inutilises :
///
///   1. LE JOURNAL (`journal_entries`). Du texte libre ecrit par le randonneur,
///      et le chemin des photos avec. C est le contenu le plus personnel de
///      l application ; il reste sur le telephone.
///   2. LA MORPHOLOGIE (`profile/hiker`) — age, taille, poids, sexe. Donnee de
///      sante au sens de l article 9, et une donnee personnelle au sens de
///      Christophe. Elle reste sur le telephone, comme la fiche medicale
///      (tache 612).
///   3. LE COMPTE (`syncWallet` : `wallet/current` + `entitlements/{trailId}`).
///      Retire pour une raison differente et plus forte : depuis la tache 631
///      les regles deployees repondent `allow write: if false` sur ces trois
///      chemins. La methode ne pouvait plus produire QUE des refus. La garder
///      aurait ete du code mort qui ment sur ce qu il sait faire.
///
/// Les trois sont verifies par `test/comportement/montee_en_base_635_test.dart`
/// et par `test/core/services/cloud_sync_wallet_test.dart`.
class CloudSyncService {
  CloudSyncService({
    required this.progressDao,
    required this.checklistDao,
    required this.syncQueueDao,
    required this.connectivityMonitor,
    required this.firebaseService,
    this.pastHikesDao,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final ProgressDao progressDao;
  final ChecklistDao checklistDao;
  final SyncQueueDao syncQueueDao;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;

  /// DAO des randos passees (miroir cloud ANONYME, LOT 4). Nullable pour
  /// retro-compat des instances/tests qui ne montent pas les randos.
  final PastHikesDao? pastHikesDao;

  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init pour les tests)
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// Synchronise toutes les donnees utilisateur pour un sentier.
  Future<CloudSyncResult> syncUserData(
    String userId,
    String trailId, {
    SyncConfig config = const SyncConfig(),
  }) async {
    // Si Firebase non disponible, graceful no-op
    if (!firebaseService.isAvailable) {
      _log.d("[CloudSync] Firebase non disponible, sync ignoree");
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    // Verifier la connectivite
    final connectivity = await connectivityMonitor.checkStatus();
    if (connectivity == ConnectivityStatusValues.offline) {
      _log.d("[CloudSync] Hors ligne, sync reportee");
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    _log.d("[CloudSync] Debut sync $userId / $trailId");
    int itemsSynced = 0;
    int retryCount = 0;

    while (retryCount <= config.maxRetries) {
      try {
        final basePath = firestore
            .collection("users")
            .doc(userId)
            .collection("trails")
            .doc(trailId);

        // --- 1. Sync progression utilisateur ---
        final progress = await progressDao.getByTrailId(trailId);
        if (progress != null) {
          final now = DateTime.now().toIso8601String();
          final progressData = {
            "trail_id": progress.trailId,
            "current_stage": progress.currentStage,
            "total_distance_walked_km": progress.totalDistanceWalkedKm,
            "total_elevation_gained_m": progress.totalElevationGainedM,
            "total_time_minutes": progress.totalTimeMinutes,
            "is_completed": progress.isCompleted,
            "started_at": progress.startedAt?.toIso8601String(),
            "completed_at": progress.completedAt?.toIso8601String(),
            "updated_at": now,
          };

          // Last-write-wins : ecriture conditionnelle si plus recent
          await _setWithLastWriteWins(
            basePath.collection("user_progress").doc("current"),
            progressData,
          );
          itemsSynced++;
        }

        // --- 2. LE JOURNAL NE MONTE PLUS (tache 635) ---
        //
        // Il montait ici : `journal_entries/entry_{id}`, avec le TEXTE LIBRE du
        // randonneur (`content`) et le chemin de ses photos (`photo_path`).
        // C est la donnee la plus personnelle que porte l application, et elle
        // partait sans que personne ne l ait decide — le bloc n avait de toute
        // facon aucun appelant, donc rien n est perdu pour qui que ce soit.
        //
        // Decision de Christophe du 29/09 : « Sauf les donnees persos ». Le
        // journal reste sur le telephone, comme la fiche medicale (tache 612).
        // Le `JournalDao` a ete retire de ce service avec le bloc : garder la
        // dependance aurait laisse croire qu il reste un chemin de sortie.

        // --- 3. Sync checklist items ---
        final checklistItems = await checklistDao.getByTrailId(trailId);
        for (final item in checklistItems) {
          final now = DateTime.now().toIso8601String();
          final itemData = {
            "item_id": item.itemId,
            "category": item.category,
            "is_checked": item.isChecked,
            "updated_at": item.updatedAt?.toIso8601String() ?? now,
          };

          await _setWithLastWriteWins(
            basePath.collection("checklist_items").doc("item_${item.itemId}"),
            itemData,
          );
          itemsSynced++;
        }

        // --- Marquer la sync dans la queue ---
        final now = DateTime.now().toIso8601String();
        await syncQueueDao.insertOrReplace(
          SyncQueueCompanion(
            trailId: Value(trailId),
            action: const Value("cloud_sync"),
            status: const Value("completed"),
            createdAt: Value(now),
            completedAt: Value(now),
          ),
        );

        _log.d("[CloudSync] Sync terminee: $itemsSynced items");
        return CloudSyncResult(
          status: CloudSyncStatusValues.success,
          syncedAt: DateTime.now(),
          itemsSynced: itemsSynced,
        );
      } catch (e) {
        retryCount++;
        _log.e("[CloudSync] Erreur sync (tentative $retryCount): $e");

        if (retryCount > config.maxRetries) {
          final now = DateTime.now().toIso8601String();
          await syncQueueDao.insertOrReplace(
            SyncQueueCompanion(
              trailId: Value(trailId),
              action: const Value("cloud_sync"),
              status: const Value("failed"),
              createdAt: Value(now),
              payload: Value(e.toString()),
            ),
          );

          return CloudSyncResult(
            status: CloudSyncStatusValues.error,
            syncedAt: DateTime.now(),
            error: e.toString(),
          );
        }

        // Attente exponentielle entre les retries
        await Future<void>.delayed(Duration(seconds: retryCount * 2));
      }
    }

    return CloudSyncResult(
      status: CloudSyncStatusValues.error,
      syncedAt: DateTime.now(),
      error: "Max retries atteint",
    );
  }

  /// Enqueue une sync batch horaire dans la sync_queue.
  Future<void> pushBatchHourly(String userId, String trailId) async {
    if (!firebaseService.isAvailable) return;

    final now = DateTime.now().toIso8601String();
    await syncQueueDao.insertOrReplace(
      SyncQueueCompanion(
        trailId: Value(trailId),
        action: const Value("cloud_sync_batch"),
        status: const Value("pending"),
        createdAt: Value(now),
        payload: Value(userId),
      ),
    );
    _log.d("[CloudSync] Batch sync enqueue pour $trailId");
  }

  /// Sync immediate a l arrivee dans un refuge.
  Future<CloudSyncResult> pushOnRefugeArrival(
    String userId,
    String trailId, {
    SyncConfig config = const SyncConfig(),
  }) async {
    if (!config.syncOnRefugeArrival) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }
    _log.d("[CloudSync] Arrivee refuge, sync immediate $trailId");
    return syncUserData(userId, trailId, config: config);
  }

  /// Rattrapage au retour de la connectivite.
  Future<CloudSyncResult> catchUpOnReconnect(
    String userId, {
    SyncConfig config = const SyncConfig(),
  }) async {
    if (!config.syncOnReconnect) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    if (!firebaseService.isAvailable) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    final pending = await syncQueueDao.getPending();
    final syncActions = pending
        .where(
          (a) => a.action == "cloud_sync_batch" || a.action == "cloud_sync",
        )
        .toList();

    if (syncActions.isEmpty) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    _log.d("[CloudSync] Rattrapage: ${syncActions.length} syncs pending");
    int totalSynced = 0;

    for (final action in syncActions) {
      final trailId = action.trailId;
      final uid = action.payload ?? userId;
      final result = await syncUserData(uid, trailId, config: config);
      if (result.status == CloudSyncStatusValues.success) {
        totalSynced += result.itemsSynced;
        // LA FILE SE VIDE, ET ELLE NE SE VIDAIT PAS (tache 635).
        //
        // DEFAUT MESURE : cette boucle relisait `getPending()` et ne marquait
        // JAMAIS l action traitee. `syncUserData` ajoute bien une ligne
        // `completed`, mais c est une LIGNE DE PLUS (`id` auto-incremente) —
        // l originale restait `pending` pour toujours. Consequence : chaque
        // retour de reseau rejouait tout l historique des attentes, et la file
        // grossissait sans fin. Une file de rattrapage qui ne se vide pas n est
        // pas un rattrapage, c est une fuite.
        await syncQueueDao.markCompleted(action.id);
      }
    }

    return CloudSyncResult(
      status: CloudSyncStatusValues.success,
      syncedAt: DateTime.now(),
      itemsSynced: totalSynced,
    );
  }

  // --- LE COMPTE NE MONTE PLUS DU TOUT — IL NE FAIT QUE DESCENDRE (tache 635)
  //
  // ICI VIVAIT `syncWallet`, qui ecrivait `users/{uid}/wallet/current` et
  // `users/{uid}/entitlements/{trailId}`, avec ses deux constructeurs de charge
  // utile. ELLE N ETAIT APPELEE DE NULLE PART — verifie dans tout `lib/` avant
  // et apres le lot 631 — et depuis ce lot elle ne POUVAIT plus rien ecrire :
  // `firestore.rules` repond `allow write: if false` sur wallet, entitlements
  // et subscription.
  //
  // C EST LA DECISION D ARCHITECTURE DE CHRISTOPHE DU 29/09 13:43, et elle
  // n est pas remise en cause ici : « je veux que tout soit en base ... seul la
  // copie sur le tel ». Le COMPTE fait foi AU SERVEUR ; le telephone le LIT
  // (`descente_des_droits.dart`) et ne l ecrit jamais — sinon n importe qui se
  // poserait `owned: true` sur un sentier payant.
  //
  // POURQUOI RETIRER PLUTOT QUE LAISSER DORMIR. Une methode dont chaque
  // ecriture est refusee par le serveur est du code mort QUI MENT : le premier
  // qui la rebranche croira monter un solde et ne recoltera que des refus
  // silencieux. `test/core/services/cloud_sync_wallet_test.dart` tient
  // desormais la garde : ce service n expose plus aucun chemin vers le compte.

  // --- LES RANDOS PASSEES MONTENT, LA MORPHOLOGIE NON (tache 635) -----------
  //
  // CE BLOC MONTAIT TROIS CHOSES ET N EN MONTE PLUS QU UNE. Il ecrivait
  // `users/{uid}/profile/hiker` (age, taille, poids, sexe, pays),
  // `users/{uid}/past_hikes/{n}` et, jusqu a la tache 570,
  // `users/{uid}/profile/experience_note`. Decision de Christophe du 29/09 :
  // « Sauf les donnees persos ». LA MORPHOLOGIE EST UNE DONNEE PERSONNELLE — et
  // une donnee de sante au sens de l article 9 — donc elle RESTE SUR LE
  // TELEPHONE, au meme titre que la fiche medicale (tache 612). Seules les
  // RANDOS PASSEES montent : des metriques d effort (jours, D+, distance,
  // temps moyen), sans trace, sans lieu, sans rien qui dise qui.
  //
  // LA GARDE ART. 9 A ETE RETIREE D ICI, ET C EST CHRISTOPHE QUI A TRANCHE
  // (DEM du 30/09 12:33). La tache 635 avait conserve le consentement
  // `healthData` devant cette montee, par prudence : une rando passee decrit
  // l effort physique d une personne. CONSEQUENCE MESUREE, et signalee dans le
  // rapport du lot : tant que la case n etait pas cochee, `past_hikes` restait
  // VIDE au serveur — Christophe ne voyait pas ses randos, et la prudence
  // produisait exactement le silence qu il reprochait a l application.
  //
  // SA DECISION : les randos passees montent COMME la progression et le sac,
  // sans dependre de la case. Ce sont des metriques d effort — jours, D+,
  // distance, temps moyen — sans trace, sans lieu, sans rien qui dise qui. LA
  // CASE RESTE, et elle garde ce qu elle a toujours garde : la fiche medicale,
  // qui n a AUCUN chemin de sortie (liste fermee de la tache 612, intacte), et
  // la morphologie, qui ne monte pas (tache 635). Demarrer une rando exige
  // toujours la fiche sante validee : cela ne change pas.
  //
  // DEUX IDENTIFIANTS, ET ILS NE SONT PAS LE MEME. C est le defaut que ce lot a
  // trouve en branchant : la version precedente passait UN SEUL identifiant, a
  // la fois comme chemin Firestore et comme cle de lecture locale. Or les
  // randos passees sont rangees en base sous une cle LOCALE (`kHikerLocalUserId`
  // = « local »), tandis que `firestore.rules` exige que le chemin soit
  // l identifiant d AUTHENTIFICATION. Avec un seul identifiant, soit la lecture
  // locale ne trouvait rien, soit l ecriture distante se faisait refuser — dans
  // les deux cas, zero rando au serveur, en silence.

  /// Payload ANONYME d'une rando passee (`users/{uid}/past_hikes/{n}`).
  ///
  /// Metriques d'effort uniquement (jours, D+, distance, temps) + timestamp.
  /// Aucun nominatif, aucun trace fin. Fonction pure.
  Map<String, dynamic> buildPastHikePayload(
    PastHikeEntry hike, {
    String? updatedAt,
  }) {
    return {
      "date": hike.date.toIso8601String(),
      "days": hike.days,
      "avg_walk_hours_per_day": hike.avgWalkHoursPerDay,
      "total_elevation_gain": hike.totalElevationGain,
      "total_distance_km": hike.totalDistanceKm,
      "updated_at": updatedAt ?? hike.updatedAt.toIso8601String(),
    };
  }

  /// Monte les randos passees sous `users/[uid]/past_hikes/hike_{n}`.
  ///
  /// [uid] = identifiant d AUTHENTIFICATION (le chemin Firestore).
  /// [identifiantLocal] = la cle sous laquelle les randos sont rangees dans la
  /// base du telephone (`kHikerLocalUserId` tant qu aucun compte n est lie).
  ///
  /// PAS DE GARDE DE CONSENTEMENT ICI (DEM du 30/09 12:33) : les randos passees
  /// montent comme la progression et le sac. Le commentaire au-dessus de ce
  /// bloc dit pourquoi, et ce que la case continue de garder.
  ///
  /// GRACEFUL NO-OP si Firebase indisponible, hors-ligne, ou DAO non injecte
  /// (retourne `idle` sans rien ecrire).
  Future<CloudSyncResult> syncPastHikes(
    String uid, {
    String identifiantLocal = "local",
  }) async {
    if (pastHikesDao == null) {
      _log.d("[CloudSync] DAO randos non injecte, montee ignoree");
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }
    if (!firebaseService.isAvailable) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }
    final connectivity = await connectivityMonitor.checkStatus();
    if (connectivity == ConnectivityStatusValues.offline) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }

    try {
      int itemsSynced = 0;
      final base = firestore.collection("users").doc(uid);

      final hikes = await pastHikesDao!.getByUserId(identifiantLocal);
      for (var i = 0; i < hikes.length; i++) {
        await _setWithLastWriteWins(
          base.collection("past_hikes").doc("hike_${i + 1}"),
          buildPastHikePayload(hikes[i]),
        );
        itemsSynced++;
      }

      _log.d("[CloudSync] Randos passees montees: $itemsSynced items");
      return CloudSyncResult(
        status: CloudSyncStatusValues.success,
        syncedAt: DateTime.now(),
        itemsSynced: itemsSynced,
      );
    } catch (e) {
      _log.e("[CloudSync] Erreur montee randos passees: $e");
      return CloudSyncResult(
        status: CloudSyncStatusValues.error,
        syncedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  // --- Miroir cloud du BACKUP CHIFFRE zero-knowledge (StepWays L7, gap C) ---
  //
  // Transport d'un BLOB DEJA CHIFFRE (enveloppe [VaultEnvelope], produit par
  // SecureVaultService) vers le miroir anonyme `users/{hash}/secure_backup/{k}`.
  // Le serveur ne voit QUE du chiffre : ni identite, ni contenu. La CLE reste
  // cote client (derivee du code de reconnexion) — jamais transmise. On ne
  // stocke pas de champ nominatif ; le doc ne contient que le blob + un
  // timestamp. [userId] = hash anonyme.
  //
  // Cette couche ne CHIFFRE ni ne DECHIFFRE : elle ne fait que STOCKER/LIRE le
  // ciphertext (separation nette ; la crypto est dans SecureVaultService).
  //
  // CE COMMENTAIRE DISAIT « ni identite, ni contenu (fiche sante art. 9) », ET
  // CETTE PARENTHESE EST MORTE LE 28/09 (tache 612). La fiche medicale ne
  // transite plus par ici, et elle ne PEUT plus : le transport n'accepte que
  // [DocumentsDuCoffreDistant.autorises]. Le chiffrement zero-knowledge etait un
  // bon argument, il ne l'est plus — Christophe a tranche que nos serveurs ne
  // devaient rien contenir du tout, pas meme de l'illisible.

  /// Depose le [encryptedBlob] (enveloppe chiffree serialisee) dans le miroir
  /// anonyme sous `users/{userId}/secure_backup/{docKey}`. GRACEFUL NO-OP si
  /// Firebase indisponible / hors-ligne. Retourne `success` si ecrit.
  ///
  /// REFUS PAR DEFAUT (tache 612) : si [docKey] n'est pas dans
  /// [DocumentsDuCoffreDistant.autorises], la methode refuse AVANT le reseau et
  /// avant toute lecture, avec la raison nommee
  /// [kSyncErrorDocumentNonAutorise]. Le refus est un `idle` porteur d'une
  /// raison, jamais une `error` : ce n'est pas une panne, c'est une decision, et
  /// la confondre avec un hors-ligne la rendrait indebuggable (meme forme que la
  /// garde article 9, tache 561).
  Future<CloudSyncResult> pushEncryptedBackup(
    String userId,
    String docKey,
    String encryptedBlob,
  ) async {
    // EN PREMIER, AVANT TOUT : avant la disponibilite Firebase, avant le
    // reseau, avant le blob. Un chemin de sortie de la fiche medicale ne doit
    // pas dependre de l'etat du telephone pour etre refuse.
    if (!DocumentsDuCoffreDistant.autorise(docKey)) {
      _log.w("[CloudSync] Document « $docKey » hors coffre autorise -> REFUS");
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
        error: kSyncErrorDocumentNonAutorise,
      );
    }
    if (!firebaseService.isAvailable) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }
    final connectivity = await connectivityMonitor.checkStatus();
    if (connectivity == ConnectivityStatusValues.offline) {
      return CloudSyncResult(
        status: CloudSyncStatusValues.idle,
        syncedAt: DateTime.now(),
      );
    }
    try {
      final now = DateTime.now().toIso8601String();
      await _setWithLastWriteWins(
        firestore
            .collection("users")
            .doc(userId)
            .collection("secure_backup")
            .doc(docKey),
        {"vault": encryptedBlob, "updated_at": now},
      );
      _log.d("[CloudSync] Backup chiffre pousse ($docKey)");
      return CloudSyncResult(
        status: CloudSyncStatusValues.success,
        syncedAt: DateTime.now(),
        itemsSynced: 1,
      );
    } catch (e) {
      _log.e("[CloudSync] Erreur push backup chiffre: $e");
      return CloudSyncResult(
        status: CloudSyncStatusValues.error,
        syncedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Lit le blob chiffre depose sous `users/{userId}/secure_backup/{docKey}`.
  /// Retourne le ciphertext serialise, ou `null` si absent/indisponible. Le
  /// dechiffrement (avec la cle cote client) est fait par l'appelant.
  ///
  /// REFUS PAR DEFAUT AUSSI DANS CE SENS (tache 612). Fermer la montee sans
  /// fermer la descente laisserait un chemin ouvert vers un document depose par
  /// une version anterieure de l'application : le telephone irait le chercher, et
  /// une fiche medicale redescendrait d'un serveur qui n'aurait jamais du
  /// l'avoir. Le refus est muet (`null`) parce que cette methode n'a pas de
  /// canal de raison ; il est journalise.
  Future<String?> pullEncryptedBackup(String userId, String docKey) async {
    if (!DocumentsDuCoffreDistant.autorise(docKey)) {
      _log.w("[CloudSync] Lecture « $docKey » hors coffre autorise -> REFUS");
      return null;
    }
    if (!firebaseService.isAvailable) return null;
    final connectivity = await connectivityMonitor.checkStatus();
    if (connectivity == ConnectivityStatusValues.offline) return null;
    try {
      final snap = await firestore
          .collection("users")
          .doc(userId)
          .collection("secure_backup")
          .doc(docKey)
          .get();
      if (!snap.exists) return null;
      return snap.data()?["vault"] as String?;
    } catch (e) {
      _log.e("[CloudSync] Erreur pull backup chiffre: $e");
      return null;
    }
  }

  /// Ecriture Firestore avec strategie last-write-wins.
  Future<void> _setWithLastWriteWins(
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> data,
  ) async {
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set(data);
      return;
    }

    final remoteUpdatedAt = snapshot.data()?["updated_at"] as String?;
    final localUpdatedAt = data["updated_at"] as String?;

    if (remoteUpdatedAt == null || localUpdatedAt == null) {
      await docRef.set(data);
      return;
    }

    // Last-write-wins : le plus recent gagne
    if (localUpdatedAt.compareTo(remoteUpdatedAt) >= 0) {
      await docRef.set(data);
    }
  }
}

/// Provider Riverpod pour le service de sync cloud.
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return CloudSyncService(
    progressDao: ProgressDao(db),
    checklistDao: ChecklistDao(db),
    syncQueueDao: SyncQueueDao(db),
    connectivityMonitor: connectivity,
    firebaseService: firebase,
    pastHikesDao: db.pastHikesDao,
  );
});
