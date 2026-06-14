import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/data/daos/waypoints_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/error/error_handler.dart';

/// Types de waypoint communautaire (F8A-02, modele FarOut R1).
abstract final class WaypointType {
  static const String eau = 'eau';
  static const String ravitaillement = 'ravitaillement';
  static const String danger = 'danger';
  static const String camp = 'camp';
  static const String connectivite = 'connectivite';
  static const String jonction = 'jonction';

  static const List<String> values = [
    eau,
    ravitaillement,
    danger,
    camp,
    connectivite,
    jonction,
  ];
}

/// Source d'un waypoint (F8A-01).
abstract final class WaypointSource {
  static const String officiel = 'officiel';
  static const String communaute = 'communaute';
}

/// Resultat d'un push distant : succes (id distant idempotent) ou erreur.
///
/// Mirroir des resultats [SignalementService]/[KudosService] : on ne lance
/// JAMAIS d'exception silencieuse, le service decide du requeue/abandon.
class WaypointPushResult {
  const WaypointPushResult.success([this.remoteId])
      : ok = true,
        error = null;
  const WaypointPushResult.failure(this.error)
      : ok = false,
        remoteId = null;

  final bool ok;
  final String? remoteId;
  final String? error;
}

/// Lot de donnees distantes recuperees a la synchronisation (pull).
///
/// Le service les fusionne dans le cache local par `lastUpdatedAt`
/// (last-write-wins). Decouple du SDK Firestore pour la testabilite.
class WaypointRemotePull {
  const WaypointRemotePull({
    this.waypoints = const [],
    this.comments = const [],
  });

  /// Waypoints distants a fusionner dans le cache (officiels ou communaute).
  final List<WaypointData> waypoints;

  /// Commentaires distants a fusionner dans le cache (deja moderes serveur).
  final List<WaypointCommentData> comments;
}

/// Puits distant abstrait des waypoints communautaires (push + pull).
///
/// Decouple [WaypointService] du SDK Firestore pour la testabilite : en prod,
/// l'implementation ecrit/lit la collection `waypoints` / `waypoint_comments`
/// (regles F8A-03) ; en test, un fake simule succes/echec et donnees distantes.
/// Tant que Firebase n'est pas connecte (avant Phase 4, #84627), un sink NO-OP
/// conserve les contributions en file locale.
abstract interface class WaypointRemoteSink {
  /// Pousse un waypoint communautaire. [docId] est idempotent (= id local).
  Future<WaypointPushResult> pushWaypoint(WaypointData waypoint);

  /// Pousse un commentaire de condition. [docId] est idempotent.
  Future<WaypointPushResult> pushComment(WaypointCommentData comment);

  /// Recupere les donnees distantes mises a jour depuis [since] pour un sentier.
  ///
  /// [since] est `null` au premier pull. Le service fusionne le resultat par
  /// `lastUpdatedAt` (last-write-wins). Renvoie un lot vide hors-ligne.
  Future<WaypointRemotePull> pull({
    required String trailId,
    DateTime? since,
  });
}

/// Vue lisible d'un waypoint avec sa fraicheur (F8A-02).
class WaypointView {
  const WaypointView({
    required this.id,
    required this.trailId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.titre,
    required this.lastUpdatedAt,
    required this.source,
  });

  factory WaypointView.fromData(WaypointData d) => WaypointView(
        id: d.id,
        trailId: d.trailId,
        type: d.type,
        latitude: d.latitude,
        longitude: d.longitude,
        titre: d.titre,
        lastUpdatedAt: d.lastUpdatedAt,
        source: d.source,
      );

  final String id;
  final String trailId;
  final String type;
  final double latitude;
  final double longitude;
  final String titre;
  final DateTime lastUpdatedAt;
  final String source;

  /// Vrai si ce waypoint provient d'une contribution communautaire.
  bool get isCommunity => source == WaypointSource.communaute;

  /// Anciennete de la donnee depuis [lastUpdatedAt] jusqu'a [now].
  ///
  /// Sert a exposer la FRAICHEUR ("mis a jour il y a X", R3). La mise en forme
  /// texte/i18n est portee par l'UI (F8A-04) : ici on expose la Duration brute.
  Duration freshness({DateTime? now}) =>
      (now ?? DateTime.now()).toUtc().difference(lastUpdatedAt.toUtc());
}

/// Service des waypoints communautaires OFFLINE-FIRST (F8A-02, Phase 8 P8-A).
///
/// Modele FarOut (R1) : waypoints filtrables + 100 % OFFLINE apres telechargement
/// du pack, contributions de condition (ex « source a sec ») en file de sync
/// differee. Aligne sur [SignalementService]/[KudosService] (memes garanties).
///
/// - LECTURE : 100 % depuis le CACHE LOCAL (Drift F8A-01), aucun acces reseau
///   a la lecture — fonctionne hors-ligne complet (R1/R3).
/// - CONTRIBUTION : ajout d'un waypoint communautaire ou d'un commentaire de
///   condition ecrit EN LOCAL d'abord (`pending`) — fonctionne 100 % HORS-LIGNE.
/// - SYNC DIFFEREE : au retour reseau ([trySync]), POUSSE les contributions
///   `pending`, puis PULL les donnees distantes et met a jour le cache par
///   `lastUpdatedAt` (last-write-wins).
/// - FRAICHEUR : [WaypointView.freshness] expose l'anciennete (« maj il y a X »).
/// - ZONE BLANCHE : respecte le flag `deferSync` (F6A-04) — fournir
///   `shouldDeferSync=true` pour ne RIEN tenter en montagne.
/// - RETRY BORNE : max [maxAttempts] tentatives par commentaire (X6), suivi en
///   memoire de service (la table waypoint_comment F8A-01 n'a pas de colonne
///   `attempts` ; un commentaire ayant atteint le plafond reste `failed` et
///   n'est plus requeue — jamais de boucle infinie).
///
/// AUCUNE promesse de temps reel : la visibilite par les autres trekkeurs
/// intervient APRES synchronisation des deux cotes (latence assumee A2-6).
///
/// ZERO catch silencieux — toute erreur est loggee via [ErrorHandler].
class WaypointService {
  WaypointService({
    required AppDatabase database,
    required WaypointRemoteSink remoteSink,
  })  : _dao = WaypointsDao(database),
        _remoteSink = remoteSink;

  final WaypointsDao _dao;
  final WaypointRemoteSink _remoteSink;

  /// Nombre maximal de tentatives de synchronisation par commentaire (X6).
  static const int maxAttempts = 5;

  /// Suivi EN MEMOIRE du nombre d'echecs de sync par id de commentaire.
  ///
  /// La table waypoint_comment (F8A-01) ne porte pas de colonne `attempts` ; on
  /// borne donc le retry au niveau service. Le service etant un singleton
  /// (provider Riverpod), ce compteur vit le temps de la session. Un commentaire
  /// ayant atteint [maxAttempts] reste `failed` et n'est plus requeue.
  final Map<int, int> _failedAttempts = <int, int>{};

  /// Horloge de fraicheur courante (UTC), pour la derniere sync reussie.
  DateTime? _lastSyncAt;

  /// Date de la derniere synchronisation reussie (null si jamais sync).
  DateTime? get lastSyncAt => _lastSyncAt;

  // ---------------------------------------------------------------------------
  // LECTURE — 100 % cache local, offline complet (R1/R3)
  // ---------------------------------------------------------------------------

  /// Waypoints d'un sentier (cache local), en [WaypointView] avec fraicheur.
  Future<List<WaypointView>> waypointsForTrail(String trailId) async {
    final rows = await _dao.waypointsForTrail(trailId);
    return rows.map(WaypointView.fromData).toList(growable: false);
  }

  /// Waypoints filtres par type (cache local) — Comment Filtering FarOut (R1).
  ///
  /// [type] doit appartenir a [WaypointType.values] ; un type inconnu renvoie
  /// une liste vide (la validation stricte est faite cote contribution).
  Future<List<WaypointView>> waypointsByType(String type) async {
    final rows = await _dao.waypointsByType(type);
    return rows.map(WaypointView.fromData).toList(growable: false);
  }

  /// Un waypoint par id (cache local), ou `null` s'il n'est pas en cache.
  Future<WaypointView?> waypointById(String id) async {
    final row = await _dao.waypointById(id);
    return row == null ? null : WaypointView.fromData(row);
  }

  /// Commentaires VISIBLES d'un waypoint (cache local, `removed` masque, DSA).
  ///
  /// Lecture offline-first : delegue au DAO F8A-01 [WaypointsDao.visibleComments].
  Future<List<WaypointCommentData>> visibleComments(String waypointId) {
    return _dao.visibleComments(waypointId);
  }

  // ---------------------------------------------------------------------------
  // CONTRIBUTION — ecriture locale d'abord, fonctionne 100 % hors-ligne
  // ---------------------------------------------------------------------------

  /// Contribue un waypoint communautaire EN LOCAL (hors-ligne).
  ///
  /// Stocke immediatement en cache avec `source='communaute'` ; la
  /// synchronisation est differee a [trySync]. Aucun acces reseau ici.
  /// [type] DOIT appartenir a [WaypointType.values]. [now] injectable (tests).
  Future<void> contributeWaypoint({
    required String id,
    required String trailId,
    required String type,
    required double latitude,
    required double longitude,
    required String titre,
    DateTime? now,
  }) async {
    if (!WaypointType.values.contains(type)) {
      final err =
          ArgumentError.value(type, 'type', 'Type de waypoint inconnu');
      ErrorHandler.log(err, context: 'WaypointService.contributeWaypoint');
      throw err;
    }
    try {
      await _dao.upsertWaypoints([
        WaypointCompanion.insert(
          id: id,
          trailId: trailId,
          type: type,
          latitude: latitude,
          longitude: longitude,
          titre: titre,
          lastUpdatedAt: (now ?? DateTime.now()).toUtc(),
          source: const Value(WaypointSource.communaute),
        ),
      ]);
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'WaypointService.contributeWaypoint');
      rethrow;
    }
  }

  /// Contribue un commentaire de condition EN LOCAL (hors-ligne). Retourne l'id
  /// local (file `pending`).
  ///
  /// Ex : « source a sec », « eau coule bien », « passage glissant ». La
  /// synchronisation est differee a [trySync]. [authorUidHash] DOIT etre l'UID
  /// HACHE (#85383). [now] injectable (tests).
  Future<int> contributeComment({
    required String waypointId,
    required String authorUidHash,
    required String texte,
    String? condition,
    DateTime? now,
  }) async {
    try {
      return await _dao.addCommentLocal(
        WaypointCommentCompanion(
          waypointId: Value(waypointId),
          authorUidHash: Value(authorUidHash),
          texte: Value(texte),
          condition: Value(condition),
          createdAt: Value((now ?? DateTime.now()).toUtc()),
          // moderationState defaut 'visible' (publication immediate, R5),
          // syncState defaut 'pending' (file de sync differee).
        ),
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'WaypointService.contributeComment');
      rethrow;
    }
  }

  /// Nombre de contributions (commentaires) en attente de synchronisation.
  Future<int> pendingCount() async => (await _dao.pendingComments()).length;

  // ---------------------------------------------------------------------------
  // SYNCHRONISATION DIFFEREE — au retour reseau, push puis pull/merge
  // ---------------------------------------------------------------------------

  /// Tente de synchroniser les contributions en attente puis de rapatrier les
  /// donnees distantes pour [trailId].
  ///
  /// Ne fait RIEN si [shouldDeferSync] (zone blanche, F6A-04). Sequence :
  /// 1. PUSH : depile les commentaires `pending`, pousse via [WaypointRemoteSink]
  ///    (retry borne a [maxAttempts] par commentaire, suivi en memoire X6) ;
  /// 2. PULL : recupere les waypoints/commentaires distants depuis [_lastSyncAt]
  ///    et met a jour le cache (merge par `lastUpdatedAt`, last-write-wins) ;
  /// 3. note l'horodatage de la sync reussie ([lastSyncAt]).
  ///
  /// Renvoie le nombre de contributions poussees avec succes. AUCUNE promesse
  /// de temps reel (latence assumee A2-6).
  Future<int> trySync({
    required String trailId,
    bool shouldDeferSync = false,
    DateTime? now,
  }) async {
    if (shouldDeferSync) return 0; // zone blanche : rien ne part (R3)
    var pushed = 0;
    try {
      pushed = await _pushPendingComments();
      await _pullAndMerge(trailId: trailId);
      _lastSyncAt = (now ?? DateTime.now()).toUtc();
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'WaypointService.trySync');
    }
    return pushed;
  }

  /// Depile et pousse les commentaires `pending`. Retourne le nombre synchronise.
  Future<int> _pushPendingComments() async {
    var synced = 0;
    final pending = await _dao.pendingComments();
    for (final comment in pending) {
      final attempts = _failedAttempts[comment.id] ?? 0;
      if (attempts >= maxAttempts) {
        // Plafond atteint : on ne retente plus (evite la boucle infinie X6).
        continue;
      }
      final result = await _remoteSink.pushComment(comment);
      if (result.ok) {
        await _dao.markCommentSynced(comment.id);
        _failedAttempts.remove(comment.id);
        synced++;
      } else {
        await _dao.markCommentFailed(comment.id);
        final next = attempts + 1;
        _failedAttempts[comment.id] = next;
        // Tant que le plafond n'est pas atteint, on remet en file pour re-tenter.
        if (next < maxAttempts) {
          await _dao.requeueComment(comment.id);
        }
      }
    }
    return synced;
  }

  /// Rapatrie les donnees distantes et fusionne le cache (last-write-wins).
  ///
  /// Un waypoint/commentaire distant n'ecrase le cache que s'il est PLUS RECENT
  /// (`lastUpdatedAt` / `createdAt`) — last-write-wins par horodatage (A2-6).
  Future<void> _pullAndMerge({required String trailId}) async {
    final pull = await _remoteSink.pull(trailId: trailId, since: _lastSyncAt);

    // --- Waypoints : merge par lastUpdatedAt ---
    final toUpsert = <WaypointCompanion>[];
    for (final remote in pull.waypoints) {
      final local = await _dao.waypointById(remote.id);
      if (local == null ||
          remote.lastUpdatedAt.isAfter(local.lastUpdatedAt)) {
        toUpsert.add(
          WaypointCompanion(
            id: Value(remote.id),
            trailId: Value(remote.trailId),
            type: Value(remote.type),
            latitude: Value(remote.latitude),
            longitude: Value(remote.longitude),
            titre: Value(remote.titre),
            lastUpdatedAt: Value(remote.lastUpdatedAt),
            source: Value(remote.source),
          ),
        );
      }
    }
    if (toUpsert.isNotEmpty) {
      await _dao.upsertWaypoints(toUpsert);
    }

    // --- Commentaires : reflet de la moderation serveur (DSA D4) ---
    // Le serveur est la source de verite de moderationState. On applique l'etat
    // distant sur les commentaires deja en cache (ex : un commentaire passe
    // 'removed' cote serveur doit etre masque localement). Le client n'est PAS
    // moderateur (R5) : il ne fait que refleter la decision serveur.
    for (final remote in pull.comments) {
      await _dao.setCommentModerationState(remote.id, remote.moderationState);
    }
  }
}
