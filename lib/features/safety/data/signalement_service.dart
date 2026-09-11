import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/data/daos/report_local_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/error/error_handler.dart';

/// Types de signalement terrain (F6C-02) + statut de POINT D'EAU (StepWays L6/I1).
///
/// Les 3 types `water*` portent le CROWDSOURCING du point d'eau (spec
/// enrich-signalement : « eau disponible / debit faible / a sec »). Ils
/// REUTILISENT la meme file offline-first que les signalements terrain
/// ([SignalementService], table `report_local`) : on ACTIVE l'existant, on ne
/// cree pas de boite neuve (I2). Les anciens types (`obstacle`/`eau_a_sec`/
/// `danger`) restent valides (parite GR20, aucune regression).
abstract final class SignalementType {
  static const String obstacle = 'obstacle';
  static const String eauASec = 'eau_a_sec';
  static const String danger = 'danger';

  /// Statut point d'eau : eau disponible (crowdsourcing, I1).
  static const String waterAvailable = 'water_available';

  /// Statut point d'eau : debit faible (crowdsourcing, I1).
  static const String waterLow = 'water_low';

  /// Statut point d'eau : a sec (crowdsourcing, I1).
  static const String waterDry = 'water_dry';

  /// Les 3 statuts de point d'eau, du plus favorable au moins favorable.
  static const List<String> waterStatuses = [
    waterAvailable,
    waterLow,
    waterDry,
  ];

  static const List<String> values = [
    obstacle,
    eauASec,
    danger,
    waterAvailable,
    waterLow,
    waterDry,
  ];

  /// Vrai si [type] est un statut de point d'eau (crowdsourcing).
  static bool isWaterStatus(String type) => waterStatuses.contains(type);
}

/// Etat partage d'un point d'eau (crowdsourcing offline-first, I1).
///
/// Agrege les signalements locaux (cache `report_local`) d'un point d'eau
/// donne : le DERNIER statut signale ([lastStatus], `null` si jamais signale)
/// et le NOMBRE de signalements ([reportCount]). Offline-first : calcule depuis
/// le cache local (dernier signalement fait foi), la visibilite inter-utilisateurs
/// arrive APRES synchronisation (latence assumee, comme les autres signalements).
class WaterSourceStatus {
  const WaterSourceStatus({
    required this.lastStatus,
    required this.reportCount,
    this.lastReportedAt,
  });

  /// Etat « jamais signale » (aucun crowdsourcing pour ce point d'eau).
  const WaterSourceStatus.none()
      : lastStatus = null,
        reportCount = 0,
        lastReportedAt = null;

  /// Dernier statut signale (`water_available`/`water_low`/`water_dry`), ou
  /// `null` si aucun signalement.
  final String? lastStatus;

  /// Nombre de signalements de statut pour ce point d'eau.
  final int reportCount;

  /// Horodatage du dernier signalement (UTC), ou `null` si aucun.
  final DateTime? lastReportedAt;

  /// Vrai si au moins un signalement existe pour ce point d'eau.
  bool get hasReports => reportCount > 0;
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

  // --- Point d'eau partage (crowdsourcing offline-first, I1) ---------------

  /// Cle stable d'un point d'eau pour regrouper ses signalements de statut.
  ///
  /// Derivee de l'identite du POI (sentier + etape + nom) : deux appareils qui
  /// signalent LE MEME point d'eau produisent la meme cle, donc le compteur et
  /// le dernier statut s'agregent correctement (crowdsourcing). Stockee dans le
  /// `payload` JSON du signalement (la table reste generique, aucune migration).
  static String waterSourceKey({
    required String trailId,
    required int stageNumber,
    required String poiName,
  }) =>
      '$trailId#$stageNumber#${poiName.trim().toLowerCase()}';

  /// Signale le STATUT d'un point d'eau (crowdsourcing, I1) — offline-first.
  ///
  /// ACTIVE la vraie persistance partagee demandee par la spec : ecrit EN LOCAL
  /// d'abord (meme file que les signalements terrain), avec la position du POI et
  /// un `payload` JSON portant l'identite du point d'eau + le statut. La
  /// synchronisation differee ([trySync]) le partagera au retour du reseau.
  ///
  /// [status] DOIT etre l'un de [SignalementType.waterStatuses].
  Future<int> reportWaterStatus({
    required String trailId,
    required int stageNumber,
    required String poiName,
    required String status,
    required double latitude,
    required double longitude,
    DateTime? now,
  }) async {
    if (!SignalementType.isWaterStatus(status)) {
      final err = ArgumentError.value(
        status,
        'status',
        'Statut de point d\'eau inconnu',
      );
      ErrorHandler.log(err, context: 'SignalementService.reportWaterStatus');
      throw err;
    }
    final payload = jsonEncode(<String, dynamic>{
      'kind': 'water_source',
      'key': waterSourceKey(
        trailId: trailId,
        stageNumber: stageNumber,
        poiName: poiName,
      ),
      'trailId': trailId,
      'stageNumber': stageNumber,
      'poiName': poiName,
    });
    return createLocal(
      type: status,
      latitude: latitude,
      longitude: longitude,
      payload: payload,
      now: now,
    );
  }

  /// Etat partage d'un point d'eau : dernier statut + compteur (I1).
  ///
  /// Lit le cache local (offline-first) et agrege les signalements de statut du
  /// point d'eau identifie par ([trailId], [stageNumber], [poiName]). Le DERNIER
  /// signalement (le plus recent) fait foi pour [WaterSourceStatus.lastStatus].
  Future<WaterSourceStatus> waterStatusFor({
    required String trailId,
    required int stageNumber,
    required String poiName,
  }) async {
    final key = waterSourceKey(
      trailId: trailId,
      stageNumber: stageNumber,
      poiName: poiName,
    );
    try {
      final rows = await _dao.allReports(); // deja tries: recents d'abord
      final matches = rows
          .where((r) =>
              SignalementType.isWaterStatus(r.type) &&
              _payloadKey(r.payload) == key)
          .toList(growable: false);
      if (matches.isEmpty) return const WaterSourceStatus.none();
      final last = matches.first; // allReports() renvoie le plus recent d'abord
      return WaterSourceStatus(
        lastStatus: last.type,
        reportCount: matches.length,
        lastReportedAt: last.createdAt,
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'SignalementService.waterStatusFor');
      return const WaterSourceStatus.none();
    }
  }

  /// Extrait la cle point d'eau d'un `payload` JSON, ou `null` si absente/illisible.
  String? _payloadKey(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded['kind'] == 'water_source') {
        final key = decoded['key'];
        return key is String ? key : null;
      }
    } on FormatException {
      // payload non-JSON (anciens signalements) : pas une cle point d'eau.
      return null;
    }
    return null;
  }
}
