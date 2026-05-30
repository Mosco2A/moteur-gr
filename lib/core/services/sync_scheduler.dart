import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:logger/logger.dart";

import "../firebase/firebase_service.dart";
import "../models/sync_config.dart";
import "../network/connectivity_monitor.dart";
import "cloud_sync_service.dart";

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

/// Scheduler de synchronisation cloud periodique.
///
/// Gere un timer periodique (batchIntervalMinutes) pour la sync batch,
/// et ecoute le ConnectivityMonitor pour le rattrapage au retour reseau.
class SyncScheduler {
  SyncScheduler({
    required this.cloudSyncService,
    required this.connectivityMonitor,
    required this.firebaseService,
  });

  final CloudSyncService cloudSyncService;
  final ConnectivityMonitor connectivityMonitor;
  final FirebaseService firebaseService;

  Timer? _batchTimer;
  StreamSubscription<ConnectivityStatus>? _connectivitySub;
  bool _isRunning = false;
  bool _wasOffline = false;
  String? _userId;
  String? _trailId;
  SyncConfig _config = const SyncConfig();

  /// Indique si le scheduler est actif
  bool get isRunning => _isRunning;

  /// Demarre le scheduler pour un utilisateur et un sentier.
  void start({
    required String userId,
    required String trailId,
    SyncConfig config = const SyncConfig(),
  }) {
    if (_isRunning) {
      _log.d("[SyncScheduler] Deja en cours, arret avant redemarrage");
      stop();
    }

    // Si Firebase non disponible, ne pas demarrer
    if (!firebaseService.isAvailable) {
      _log.d("[SyncScheduler] Firebase non disponible, scheduler inactif");
      return;
    }

    _userId = userId;
    _trailId = trailId;
    _config = config;
    _isRunning = true;

    // Timer periodique pour le batch sync
    _batchTimer = Timer.periodic(
      Duration(minutes: config.batchIntervalMinutes),
      (_) => _onBatchTick(),
    );

    // Ecoute des changements de connectivite
    _connectivitySub = connectivityMonitor.onStatusChange.listen(
      _onConnectivityChange,
    );

    _log.d("[SyncScheduler] Demarre (batch=${config.batchIntervalMinutes}min)");
  }

  /// Arrete le scheduler.
  void stop() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _isRunning = false;
    _wasOffline = false;
    _log.d("[SyncScheduler] Arrete");
  }

  /// Callback du timer batch periodique.
  Future<void> _onBatchTick() async {
    if (_userId == null || _trailId == null) return;

    _log.d("[SyncScheduler] Tick batch sync");
    await cloudSyncService.pushBatchHourly(_userId!, _trailId!);

    // Tenter la sync immediate si connecte
    final status = await connectivityMonitor.checkStatus();
    if (status == ConnectivityStatusValues.online) {
      await cloudSyncService.syncUserData(
        _userId!, _trailId!,
        config: _config,
      );
    }
  }

  /// Callback lors d un changement de connectivite.
  void _onConnectivityChange(ConnectivityStatus status) {
    if (status == ConnectivityStatusValues.offline) {
      _wasOffline = true;
      _log.d("[SyncScheduler] Passage offline");
      return;
    }

    // Retour online
    if (_wasOffline && _config.syncOnReconnect && _userId != null) {
      _wasOffline = false;
      _log.d("[SyncScheduler] Retour online, rattrapage");
      cloudSyncService.catchUpOnReconnect(
        _userId!,
        config: _config,
      );
    }
  }
}

/// Provider Riverpod pour le scheduler de sync.
final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final cloudSync = ref.watch(cloudSyncServiceProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return SyncScheduler(
    cloudSyncService: cloudSync,
    connectivityMonitor: connectivity,
    firebaseService: firebase,
  );
});
