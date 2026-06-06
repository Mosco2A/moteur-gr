import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/firebase/firebase_service.dart';
import '../../../core/network/connectivity_monitor.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Mode de synchronisation du groupe.
/// Utilise String pour extensibilite (#81752) — la valeur est
/// serialisee vers Firestore (champ syncMode).
typedef GroupSyncMode = String;

/// Valeurs connues pour GroupSyncMode avec fallback generique.
abstract class GroupSyncModeValues {
  /// Batch toutes les heures — eco batterie sentier.
  static const String hourly = 'hourly';

  /// Push uniquement au refuge (wifi detecte).
  static const String refuge = 'refuge';

  static const String fallback = hourly;
  static const List<String> values = [hourly, refuge];

  static GroupSyncMode fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Position en attente de synchronisation.
class PendingGroupPosition {
  const PendingGroupPosition({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.stageId,
  });

  final double lat;
  final double lng;
  final DateTime timestamp;
  final String? stageId;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
        if (stageId != null) 'stageId': stageId,
      };
}

/// Service de synchronisation groupe eco-batterie (E4.12b).
///
/// Deux modes de fonctionnement :
/// - [GroupSyncModeValues.hourly] : accumule les positions et envoie
///   un batch toutes les heures. Economise la batterie sur le sentier.
/// - [GroupSyncModeValues.refuge] : n envoie les positions que lorsque
///   le wifi est detecte (arrivee au refuge). Zero consommation reseau
///   mobile.
///
/// Dans les deux modes, un rattrapage automatique est declenche
/// au retour du reseau apres une periode hors connexion.
///
/// E4.12b — Dependances: E4.12a (page web suivi), E4.11 (FollowService).
class GroupSyncService {
  GroupSyncService({
    required this.firebaseService,
    required this.connectivityMonitor,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  })  : _firestore = firestore,
        _connectivity = connectivity ?? Connectivity();

  final FirebaseService firebaseService;
  final ConnectivityMonitor connectivityMonitor;
  FirebaseFirestore? _firestore;
  final Connectivity _connectivity;

  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// Buffer de positions en attente d envoi.
  final List<PendingGroupPosition> _buffer = [];

  /// Expose le buffer en lecture seule (pour les tests).
  List<PendingGroupPosition> get pendingPositions => List.unmodifiable(_buffer);

  Timer? _hourlyTimer;
  StreamSubscription<ConnectivityStatus>? _connectivitySub;

  String? _sessionId;
  GroupSyncMode _mode = GroupSyncModeValues.hourly;
  bool _isRunning = false;
  bool _wasOffline = false;

  /// Indique si le service est actif.
  bool get isRunning => _isRunning;

  /// Mode courant.
  GroupSyncMode get mode => _mode;

  /// Demarre la synchronisation pour une session de suivi.
  ///
  /// [sessionId] : identifiant de la session follow_sessions.
  /// [mode] : mode de synchronisation (hourly par defaut,
  /// valeur inconnue -> fallback hourly).
  void start({
    required String sessionId,
    GroupSyncMode mode = GroupSyncModeValues.hourly,
  }) {
    if (_isRunning) stop();

    _sessionId = sessionId;
    _mode = GroupSyncModeValues.fromString(mode);

    if (!firebaseService.isAvailable) {
      _log.d('[GroupSync] Firebase non disponible, service inactif');
      return;
    }

    _isRunning = true;
    if (_mode == GroupSyncModeValues.hourly) {
      _hourlyTimer = Timer.periodic(
        const Duration(hours: 1),
        (_) => _flushBuffer(),
      );
      _log.i('[GroupSync] Demarre mode horaire (batch 1h)');
    } else {
      _log.i('[GroupSync] Demarre mode refuge (push wifi seulement)');
    }

    // Ecoute connectivite pour rattrapage + detection wifi refuge
    _connectivitySub = connectivityMonitor.onStatusChange.listen(
      _onConnectivityChange,
    );
  }

  /// Arrete le service et vide le buffer.
  void stop() {
    _hourlyTimer?.cancel();
    _hourlyTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _isRunning = false;
    _wasOffline = false;
    _buffer.clear();
    _log.d('[GroupSync] Arrete');
  }

  /// Enregistre une position dans le buffer.
  ///
  /// La position sera envoyee au prochain flush (horaire ou wifi).
  void recordPosition({
    required double lat,
    required double lng,
    String? stageId,
  }) {
    _buffer.add(PendingGroupPosition(
      lat: lat,
      lng: lng,
      timestamp: DateTime.now(),
      stageId: stageId,
    ));
  }

  /// Force un envoi immediat du buffer (ex: fermeture app).
  Future<void> forceFlush() async => _flushBuffer();

  /// Envoie le batch de positions vers Firestore.
  ///
  /// Toutes les positions accumulees sont envoyees dans un
  /// WriteBatch Firestore pour economiser les appels reseau.
  Future<void> _flushBuffer() async {
    if (_buffer.isEmpty || _sessionId == null) return;
    if (!firebaseService.isAvailable) return;

    final positions = List<PendingGroupPosition>.from(_buffer);
    _buffer.clear();

    try {
      final batch = firestore.batch();

      for (final pos in positions) {
        final docRef = firestore
            .collection('follow_sessions')
            .doc(_sessionId)
            .collection('positions')
            .doc();
        batch.set(docRef, {
          'lat': pos.lat,
          'lng': pos.lng,
          'stageId': pos.stageId,
          'timestamp': FieldValue.serverTimestamp(),
          'batchedAt': pos.timestamp.toIso8601String(),
          'syncMode': _mode,
        });
      }

      await batch.commit();
      _log.i('[GroupSync] Batch envoye: ${positions.length} position(s)');
    } catch (e) {
      // Remettre les positions dans le buffer pour le prochain essai
      _buffer.insertAll(0, positions);
      _log.e('[GroupSync] Erreur flush: $e');
    }
  }

  /// Callback connectivite : rattrapage retour reseau + push wifi refuge.
  void _onConnectivityChange(ConnectivityStatus status) {
    if (status == ConnectivityStatusValues.offline) {
      _wasOffline = true;
      _log.d('[GroupSync] Passage offline');
      return;
    }

    // Retour online
    if (_wasOffline && _buffer.isNotEmpty) {
      _wasOffline = false;
      _log.i('[GroupSync] Retour online, rattrapage ${_buffer.length} pos');
      _flushBuffer();
      return;
    }
    _wasOffline = false;

    // Mode refuge : push seulement si wifi detecte
    if (_mode == GroupSyncModeValues.refuge && _buffer.isNotEmpty) {
      _checkWifiAndFlush();
    }
  }

  /// Verifie si le reseau actuel est wifi et flush si c est le cas.
  Future<void> _checkWifiAndFlush() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.wifi) {
        _log.i('[GroupSync] Wifi refuge detecte, push positions');
        await _flushBuffer();
      }
    } catch (e) {
      _log.d('[GroupSync] Erreur check wifi: $e');
    }
  }

  /// Libere les ressources.
  void dispose() {
    stop();
  }
}

/// Provider Riverpod pour le [GroupSyncService].
final groupSyncServiceProvider = Provider<GroupSyncService>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final service = GroupSyncService(
    firebaseService: firebase,
    connectivityMonitor: connectivity,
  );
  ref.onDispose(service.dispose);
  return service;
});
