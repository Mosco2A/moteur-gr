import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../firebase/firebase_service.dart';
import '../network/connectivity_monitor.dart';
import 'cloud_sync_service.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Service de synchronisation automatique en arriere-plan (E4.16).
///
/// Lance un timer periodique (30 min par defaut) qui synchronise
/// les donnees utilisateur vers Firestore : progression etapes,
/// sessions trek, preferences. L identifiant utilisateur est
/// l ID ANONYMISE (E4.15) — aucune PII ne transite (#81775).
///
/// Conditions pour sync :
/// - Firebase disponible
/// - Utilisateur connecte (userId non null)
/// - Connectivite reseau (online)
///
/// Le timer est auto-gere : start/stop/dispose.
/// Si la sync echoue, elle sera retentee au prochain tick.
class BackgroundSyncService {
  BackgroundSyncService({
    required this.cloudSyncService,
    required this.connectivityMonitor,
    required this.firebaseService,
    this.intervalMinutes = 30,
  });

  final CloudSyncService cloudSyncService;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;

  /// Intervalle entre deux syncs automatiques (defaut 30 min).
  final int intervalMinutes;

  Timer? _timer;
  bool _isRunning = false;
  String? _userId;
  String? _activeTrailId;
  DateTime? _lastSyncTime;

  /// Indique si le service est actif.
  bool get isRunning => _isRunning;

  /// Derniere sync reussie (null si jamais).
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Demarre la sync automatique pour un utilisateur.
  ///
  /// Si deja en cours, redemarre avec les nouveaux parametres.
  /// Ne demarre pas si Firebase est indisponible.
  void start({
    required String userId,
    String? trailId,
  }) {
    if (_isRunning) {
      stop();
    }

    if (!firebaseService.isAvailable) {
      _log.d('[BackgroundSync] Firebase indisponible, sync inactive');
      return;
    }

    _userId = userId;
    _activeTrailId = trailId;
    _isRunning = true;

    _timer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _onTick(),
    );

    _log.d('[BackgroundSync] Demarre (intervalle=${intervalMinutes}min)');
  }

  /// Arrete la sync automatique.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _log.d('[BackgroundSync] Arrete');
  }

  /// Met a jour le sentier actif (changement de trek).
  void setActiveTrail(String trailId) {
    _activeTrailId = trailId;
  }

  /// Callback du timer periodique.
  Future<void> _onTick() async {
    if (_userId == null) return;

    // Verifier la connectivite avant de tenter
    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.offline) {
      _log.d('[BackgroundSync] Hors ligne, tick ignore');
      return;
    }

    if (_activeTrailId == null) {
      _log.d('[BackgroundSync] Pas de sentier actif, tick ignore');
      return;
    }

    _log.d('[BackgroundSync] Tick sync $_userId / $_activeTrailId');

    final result = await cloudSyncService.syncUserData(
      _userId!,
      _activeTrailId!,
    );

    if (result.status == CloudSyncStatusValues.success) {
      _lastSyncTime = result.syncedAt;
      _log.d('[BackgroundSync] Sync OK: ${result.itemsSynced} items');
    } else if (result.status == CloudSyncStatusValues.error) {
      _log.e('[BackgroundSync] Sync echouee: ${result.error}');
    }
  }

  /// Force une sync immediate (hors timer).
  Future<CloudSyncResult> syncNow() async {
    if (_userId == null || _activeTrailId == null) {
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

    final result = await cloudSyncService.syncUserData(
      _userId!,
      _activeTrailId!,
    );

    if (result.status == CloudSyncStatusValues.success) {
      _lastSyncTime = result.syncedAt;
    }

    return result;
  }

  /// Libere les ressources.
  void dispose() {
    stop();
    _userId = null;
    _activeTrailId = null;
  }
}

/// Provider Riverpod pour le service de sync background.
final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  final cloudSync = ref.watch(cloudSyncServiceProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  final service = BackgroundSyncService(
    cloudSyncService: cloudSync,
    connectivityMonitor: connectivity,
    firebaseService: firebase,
  );
  ref.onDispose(service.dispose);
  return service;
});
