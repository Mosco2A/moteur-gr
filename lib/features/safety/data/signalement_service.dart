import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/data/daos/report_local_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/error/error_handler.dart';

/// Types de signalement terrain (F6C-02).
abstract final class SignalementType {
  static const String obstacle = 'obstacle';
  static const String eauASec = 'eau_a_sec';
  static const String danger = 'danger';
  static const List<String> values = [obstacle, eauASec, danger];
}

/// Resultat d'un push distant : l'id Firestore attribue, ou une erreur.
class RemotePushResult {
  const RemotePushResult.success(this.remoteId)
      : ok = true,
        error = null;
  const RemotePushResult.failure(this.error)
      : ok = false,
        remoteId = null;

  final bool ok;
  final String? remoteId;
  final String? error;
}

/// Puits distant abstrait — pousse un signalement vers Firestore.
///
/// Decouple [SignalementService] du SDK Firestore pour la testabilite : en
/// prod, l'implementation ecrit dans la collection `trail_reports` (F6C-04) ;
/// en test, un fake simule succes/echec.
abstract interface class ReportRemoteSink {
  Future<RemotePushResult> push(ReportLocalData report);
}

/// Vue fusionnee d'un signalement (cache local + distant), pour la lecture.
class SignalementView {
  const SignalementView({
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.synced,
  });

  final String type;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool synced;
}

/// Service de signalement terrain OFFLINE-FIRST (F6C-02, F6.1).
///
/// - Création : écrit le signalement EN LOCAL d'abord (report_local F6C-01,
///   `syncState=pending`) — fonctionne 100 % HORS-LIGNE.
/// - Synchronisation : sur retour réseau, dépile les `pending` et les POUSSE
///   vers Firestore (collection `trail_reports`, F6C-04), marque `synced`.
/// - Échec : retry BORNÉ (max [maxAttempts]), jamais de boucle infinie (X6).
/// - Lecture : cache local d'abord, fusion par timestamp (last-write-wins).
///
/// AUCUNE promesse de temps réel : la visibilité par les autres trekkeurs
/// intervient APRÈS synchronisation des deux côtés (latence assumée A2-6).
/// La synchronisation respecte le flag `deferSync` (zone blanche, F6A-04) :
/// fournir `shouldDeferSync` à [trySync] pour ne pas tenter en zone blanche.
///
/// ZERO catch silencieux — toute erreur est loggée via [ErrorHandler].
class SignalementService {
  SignalementService({
    required AppDatabase database,
    required ReportRemoteSink remoteSink,
  })  : _dao = ReportLocalDao(database),
        _remoteSink = remoteSink;

  final ReportLocalDao _dao;
  final ReportRemoteSink _remoteSink;

  /// Nombre maximal de tentatives de synchronisation par signalement (X6).
  static const int maxAttempts = 5;

  /// Crée un signalement EN LOCAL (hors-ligne). Retourne l'id local.
  ///
  /// Ne tente AUCUN accès réseau : la synchronisation est différée à
  /// [trySync]. [now] est injectable pour les tests.
  Future<int> createLocal({
    required String type,
    required double latitude,
    required double longitude,
    String? payload,
    DateTime? now,
  }) async {
    if (!SignalementType.values.contains(type)) {
      final err = ArgumentError.value(type, 'type', 'Type de signalement inconnu');
      ErrorHandler.log(err, context: 'SignalementService.createLocal');
      throw err;
    }
    try {
      return await _dao.insertReport(
        ReportLocalCompanion.insert(
          type: type,
          latitude: latitude,
          longitude: longitude,
          createdAt: (now ?? DateTime.now()).toUtc(),
          payload: Value(payload),
        ),
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'SignalementService.createLocal');
      rethrow;
    }
  }

  /// Tente de synchroniser les signalements en attente vers Firestore.
  ///
  /// Ne fait RIEN si [shouldDeferSync] est vrai (zone blanche, F6A-04). Pour
  /// chaque `pending` : pousse, marque `synced` en cas de succès ; en cas
  /// d'échec incrémente `attempts` et stocke l'erreur. Un signalement ayant
  /// atteint [maxAttempts] n'est plus retenté (pas de boucle infinie).
  ///
  /// Retourne le nombre de signalements synchronisés avec succès.
  Future<int> trySync({bool shouldDeferSync = false}) async {
    if (shouldDeferSync) return 0;
    var synced = 0;
    try {
      final pending = await _dao.pendingReports();
      for (final report in pending) {
        if (report.attempts >= maxAttempts) {
          // Plafond atteint : on ne retente plus (évite la boucle infinie X6).
          continue;
        }
        final result = await _remoteSink.push(report);
        if (result.ok) {
          await _dao.markSynced(report.id, remoteId: result.remoteId);
          synced++;
        } else {
          await _dao.markFailed(report.id, result.error ?? 'push échoué');
          // markFailed passe en 'failed' : on le remet pending tant que le
          // plafond n'est pas atteint, pour une nouvelle tentative ultérieure.
          if (report.attempts + 1 < maxAttempts) {
            await _dao.requeue(report.id);
          }
        }
      }
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'SignalementService.trySync');
    }
    return synced;
  }

  /// Liste des signalements (cache local), récents d'abord. La fusion avec les
  /// reports distants (last-write-wins par timestamp) est portée par la couche
  /// de lecture appelante ; ici on expose le cache local source de vérité
  /// hors-ligne.
  Future<List<SignalementView>> localReports() async {
    final rows = await _dao.allReports();
    return rows
        .map((r) => SignalementView(
              type: r.type,
              latitude: r.latitude,
              longitude: r.longitude,
              createdAt: r.createdAt,
              synced: r.syncState == 'synced',
            ))
        .toList();
  }

  /// Nombre de signalements en attente de synchronisation.
  Future<int> pendingCount() => _dao.countPending();
}
