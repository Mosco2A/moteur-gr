import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../core/data/daos/kudos_feed_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/error/error_handler.dart';

/// Resultat d'un push distant d'un kudo : l'id distant (idempotent), ou erreur.
class KudoPushResult {
  const KudoPushResult.success() : ok = true, error = null;
  const KudoPushResult.failure(this.error) : ok = false;

  final bool ok;
  final String? error;
}

/// Puits distant abstrait — pousse un kudo vers Firestore (collection kudos).
///
/// La cle distante est l'id IDEMPOTENT [docId] = hash(fromUidHash +
/// targetActivityId) : re-pousser le meme kudo n'en cree PAS un second
/// (F7B-03 impose doc id = hash). Decouple le service du SDK Firestore pour la
/// testabilite (fake en test, implementation Firestore en F7B reel).
abstract interface class KudoRemoteSink {
  Future<KudoPushResult> push({
    required String docId,
    required String fromUidHash,
    required String targetActivityId,
  });
}

/// Service de kudos OFFLINE-FIRST et IDEMPOTENT (F7B-02, Phase 7).
///
/// - Ajout : ecrit le kudo EN LOCAL d'abord (kudos_local F7B-01,
///   `syncState=pending`) — fonctionne 100 % HORS-LIGNE. Un seul kudo par
///   (fromUidHash, targetActivityId) cote cache (garde-fou hasKudoLocal).
/// - Synchronisation : au retour reseau, depile les `pending` et les POUSSE
///   vers Firestore avec une cle IDEMPOTENTE [remoteDocId] = hash(from+target)
///   (F7B-03 : doc id = hash -> pas de doublon a la re-sync, X6).
/// - Echec : retry BORNE (max [maxAttempts]), jamais de boucle infinie (X6).
/// - Compteur : lu depuis le cache local, reconcilie a la sync.
///
/// Respecte le flag `deferSync` (zone blanche, F6A-04) : fournir
/// `shouldDeferSync=true` a [trySync] pour ne RIEN tenter en zone blanche (R2,
/// aucune ecriture live en montagne).
///
/// ZERO catch silencieux — toute erreur est loggee via [ErrorHandler].
class KudosService {
  KudosService({
    required AppDatabase database,
    required KudoRemoteSink remoteSink,
  })  : _dao = KudosFeedDao(database),
        _remoteSink = remoteSink;

  final KudosFeedDao _dao;
  final KudoRemoteSink _remoteSink;

  /// Nombre maximal de tentatives de synchronisation par kudo (X6).
  static const int maxAttempts = 5;

  /// Construit la cle distante IDEMPOTENTE d'un kudo (= doc id Firestore).
  ///
  /// hash(fromUidHash + ':' + targetActivityId) en SHA-256 : deterministe,
  /// donc re-pousser le meme kudo ecrit le MEME document (pas de doublon).
  static String remoteDocId(String fromUidHash, String targetActivityId) {
    final bytes = utf8.encode('$fromUidHash:$targetActivityId');
    return sha256.convert(bytes).toString();
  }

  /// Ajoute un kudo EN LOCAL (hors-ligne). Retourne l'id local, ou `null` si un
  /// kudo identique existe deja en cache (idempotence cote client).
  ///
  /// Ne tente AUCUN acces reseau : la synchronisation est differee a [trySync].
  /// [fromUidHash] DOIT etre l'UID HACHE (#85383). [now] injectable (tests).
  Future<int?> giveKudo({
    required String fromUidHash,
    required String targetActivityId,
    DateTime? now,
  }) async {
    try {
      if (await _dao.hasKudoLocal(fromUidHash, targetActivityId)) {
        // Idempotence : pas de second kudo du meme auteur sur la meme activite.
        return null;
      }
      return await _dao.addKudoLocal(
        KudosLocalCompanion(
          targetActivityId: Value(targetActivityId),
          fromUidHash: Value(fromUidHash),
          createdAt: Value((now ?? DateTime.now()).toUtc()),
        ),
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'KudosService.giveKudo');
      rethrow;
    }
  }

  /// Tente de synchroniser les kudos en attente vers Firestore.
  ///
  /// Ne fait RIEN si [shouldDeferSync] (zone blanche, F6A-04). Pour chaque
  /// `pending` : pousse avec la cle idempotente, marque `synced` en cas de
  /// succes ; sinon incremente `attempts` et stocke l'erreur. Un kudo ayant
  /// atteint [maxAttempts] n'est plus retente (X6). Retourne le nombre
  /// synchronise avec succes.
  Future<int> trySync({bool shouldDeferSync = false}) async {
    if (shouldDeferSync) return 0;
    var synced = 0;
    try {
      final pending = await _dao.pendingKudos();
      for (final kudo in pending) {
        if (kudo.attempts >= maxAttempts) {
          continue; // plafond atteint : on ne retente plus (X6)
        }
        final result = await _remoteSink.push(
          docId: remoteDocId(kudo.fromUidHash, kudo.targetActivityId),
          fromUidHash: kudo.fromUidHash,
          targetActivityId: kudo.targetActivityId,
        );
        if (result.ok) {
          await _dao.markKudoSynced(kudo.id);
          synced++;
        } else {
          await _dao.markKudoFailed(kudo.id, result.error ?? 'push echoue');
          if (kudo.attempts + 1 < maxAttempts) {
            await _dao.requeueKudo(kudo.id);
          }
        }
      }
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'KudosService.trySync');
    }
    return synced;
  }

  /// Compteur de kudos d'une activite, lu depuis le cache local (offline).
  Future<int> kudosCount(String targetActivityId) =>
      _dao.kudosCountForActivity(targetActivityId);
}
