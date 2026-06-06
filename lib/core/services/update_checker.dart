import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../data/daos/trail_manifests_dao.dart';
import '../firebase/firebase_service.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Resultat de la detection de mise a jour pour un sentier.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.trailId,
    required this.hasUpdate,
    this.localVersion = 0,
    this.remoteVersion = 0,
  });

  /// Identifiant du sentier verifie.
  final String trailId;

  /// True si une nouvelle version est disponible.
  final bool hasUpdate;

  /// Version actuellement telechargee en local.
  final int localVersion;

  /// Version disponible sur Firebase.
  final int remoteVersion;
}

/// Service de detection des mises a jour de sentiers (E4.11b).
///
/// Compare la version du manifeste local (Drift) avec la version
/// distante (Firestore trails/{trailId}.data_version).
/// Complementaire de DeltaUpdateService : celui-ci detecte au niveau
/// Firestore (source temps reel), DeltaUpdateService calcule ensuite
/// le delta de tables a partir du manifeste.
///
/// Dependances : E4.3 (manifest model), E4.4b (Drift storage).
class UpdateChecker {
  UpdateChecker({
    required this.dao,
    required this.connectivityMonitor,
    required this.firebaseService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final TrailManifestsDao dao;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;
  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init pour les tests).
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// Verifie si un sentier a une mise a jour disponible.
  Future<UpdateCheckResult> checkForUpdate(String trailId) async {
    if (!firebaseService.isAvailable) {
      _log.d('[UpdateChecker] Firebase non disponible, check ignore');
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }

    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      _log.d('[UpdateChecker] Hors ligne, check ignore');
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }

    try {
      final doc = await firestore.collection('trails').doc(trailId).get();

      if (!doc.exists || doc.data() == null) {
        _log.d('[UpdateChecker] Aucun document distant pour $trailId');
        return UpdateCheckResult(trailId: trailId, hasUpdate: false);
      }

      final remoteData = doc.data()!;
      final remoteVersion = remoteData['data_version'] as int? ?? 0;

      final localEntry = await dao.getByTrailId(trailId);
      final localVersion = localEntry?.localVersion ?? 0;

      final hasUpdate = remoteVersion > localVersion;

      if (hasUpdate) {
        _log.d(
          '[UpdateChecker] MAJ disponible $trailId: '
          'v$localVersion -> v$remoteVersion',
        );
      }

      return UpdateCheckResult(
        trailId: trailId,
        hasUpdate: hasUpdate,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
      );
    } catch (e) {
      _log.e('[UpdateChecker] Erreur check $trailId: $e');
      return UpdateCheckResult(trailId: trailId, hasUpdate: false);
    }
  }

  /// Verifie les mises a jour pour tous les sentiers connus localement.
  Future<List<UpdateCheckResult>> checkAllForUpdates() async {
    if (!firebaseService.isAvailable) {
      return [];
    }

    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      return [];
    }

    final localEntries = await dao.getAll();
    final results = <UpdateCheckResult>[];

    for (final entry in localEntries) {
      final result = await checkForUpdate(entry.trailId);
      if (result.hasUpdate) {
        results.add(result);
      }
    }

    if (results.isNotEmpty) {
      _log.d('[UpdateChecker] ${results.length} MAJ disponible(s)');
    }

    return results;
  }
}

/// Provider Riverpod pour le service de detection de MAJ.
final updateCheckerProvider = Provider<UpdateChecker>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return UpdateChecker(
    dao: TrailManifestsDao(db),
    connectivityMonitor: connectivity,
    firebaseService: firebase,
  );
});
