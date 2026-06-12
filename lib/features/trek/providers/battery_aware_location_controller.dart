import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/error/error_handler.dart';
import '../data/background_gps_service.dart' show kLowBatteryThreshold;
import '../data/gps_service.dart';

/// Etat de pilotage GPS/batterie (F6A-04).
@immutable
class BatteryLocationState {
  const BatteryLocationState({
    required this.mode,
    required this.deferSync,
    required this.batteryPct,
    required this.isForeground,
  });

  /// Regime GPS courant impose par la strategie batterie.
  final GpsAccuracyMode mode;

  /// Vrai si la synchronisation reseau doit etre DIFFEREE (zone blanche) :
  /// coupe le polling Firestore, les writes vont en file locale (F6C).
  final bool deferSync;

  /// Niveau de batterie en pourcentage (0-100).
  final int batteryPct;

  /// Vrai si l'app est au premier plan, ecran allume.
  final bool isForeground;

  BatteryLocationState copyWith({
    GpsAccuracyMode? mode,
    bool? deferSync,
    int? batteryPct,
    bool? isForeground,
  }) {
    return BatteryLocationState(
      mode: mode ?? this.mode,
      deferSync: deferSync ?? this.deferSync,
      batteryPct: batteryPct ?? this.batteryPct,
      isForeground: isForeground ?? this.isForeground,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BatteryLocationState &&
      other.mode == mode &&
      other.deferSync == deferSync &&
      other.batteryPct == batteryPct &&
      other.isForeground == isForeground;

  @override
  int get hashCode => Object.hash(mode, deferSync, batteryPct, isForeground);
}

/// Controller batterie-aware (F6A-04) : combine 3 signaux — cycle de vie
/// (foreground/background), niveau de batterie et connectivite — pour piloter
/// la strategie GPS et de synchronisation, dans l'optique d'economiser la
/// batterie (audits A1-2, A1-4d).
///
/// Strategie :
/// - foreground + ecran on -> regime GPS adaptatif normal (high/walking/
///   balanced gere par [GpsService.classifyMovement] / F6A-03).
/// - background ou ecran off -> on FORCE le regime walking/balanced (jamais
///   high) pour economiser la batterie.
/// - connectivite absente (zone blanche) -> [BatteryLocationState.deferSync] =
///   true : coupe le polling Firestore (writes en file locale, F6C), sync
///   uniquement au retour du reseau. En mauvais signal, la radio cellulaire
///   coute plus que le GPS (A1-2).
///
/// Une telemetrie zero-PII est emise a chaque changement de regime
/// ([AnalyticsService.logGpsRegime]) pour mesurer la conso terrain (BAT-2).
///
/// ZERO catch silencieux — les erreurs sont loggees via [ErrorHandler].
class BatteryAwareLocationController extends Notifier<BatteryLocationState>
    with WidgetsBindingObserver {
  BatteryAwareLocationController({
    Battery? battery,
    Connectivity? connectivity,
    AnalyticsService? analytics,
  })  : _battery = battery,
        _connectivity = connectivity,
        _analyticsOverride = analytics;

  final Battery? _battery;
  final Connectivity? _connectivity;
  final AnalyticsService? _analyticsOverride;

  late final Battery _batteryInstance = _battery ?? Battery();
  late final Connectivity _connectivityInstance =
      _connectivity ?? Connectivity();

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  StreamSubscription<BatteryState>? _batterySub;
  bool _observerAttached = false;

  AnalyticsService get _analytics =>
      _analyticsOverride ?? ref.read(analyticsServiceProvider);

  @override
  BatteryLocationState build() {
    ref.onDispose(_disposeController);
    return const BatteryLocationState(
      mode: GpsAccuracyMode.walking,
      deferSync: false,
      batteryPct: 100,
      isForeground: true,
    );
  }

  /// Demarre l'observation des 3 signaux. A appeler une fois la navigation
  /// active. Idempotent.
  Future<void> start() async {
    if (_observerAttached) return;
    try {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;

      // Niveau initial de batterie + connectivite.
      await _refreshBattery();
      final connectivity = await _connectivityInstance.checkConnectivity();
      _applyConnectivity(connectivity);

      _connectivitySub = _connectivityInstance.onConnectivityChanged
          .listen(_applyConnectivity, onError: _onSignalError);
      _batterySub = _batteryInstance.onBatteryStateChanged.listen(
        (_) => _refreshBattery(),
        onError: _onSignalError,
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'BatteryAwareLocationController.start');
      rethrow;
    }
  }

  /// Notifie un changement de mouvement detecte (regime GPS issu de F6A-03).
  /// En foreground/ecran on, ce regime est applique tel quel ; en background,
  /// il est plafonne a walking (jamais high).
  void onMovementRegime(GpsAccuracyMode detected) {
    final effective = state.isForeground ? detected : _capForBackground(detected);
    _updateState(state.copyWith(mode: effective));
  }

  /// Plafonne un regime en background : high -> walking, le reste inchange.
  GpsAccuracyMode _capForBackground(GpsAccuracyMode detected) {
    return detected == GpsAccuracyMode.moving
        ? GpsAccuracyMode.walking
        : detected;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `state` (le parametre) = etat du cycle de vie ; `this.state` = etat du
    // Notifier. On nomme le parametre 'state' pour respecter la signature de
    // la methode surchargee (lint avoid_renaming_method_parameters).
    final current = this.state;
    switch (state) {
      case AppLifecycleState.resumed:
        _updateState(current.copyWith(isForeground: true));
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Background / ecran off -> forcer walking (jamais high).
        _updateState(current.copyWith(
          isForeground: false,
          mode: _capForBackground(current.mode),
        ));
    }
  }

  Future<void> _refreshBattery() async {
    try {
      final level = await _batteryInstance.batteryLevel;
      var next = state.copyWith(batteryPct: level);
      // Batterie basse (<20%, seuil partage avec background_gps_service) :
      // ne jamais rester en high, plafonner a walking.
      if (level < kLowBatteryThreshold) {
        next = next.copyWith(mode: _capForBackground(next.mode));
      }
      _updateState(next);
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st,
          context: 'BatteryAwareLocationController._refreshBattery');
    }
  }

  void _applyConnectivity(ConnectivityResult result) {
    final offline = result == ConnectivityResult.none;
    _updateState(state.copyWith(deferSync: offline));
  }

  void _onSignalError(Object error, StackTrace stackTrace) {
    ErrorHandler.log(error,
        stackTrace: stackTrace,
        context: 'BatteryAwareLocationController.signal');
  }

  /// Applique le nouvel etat et emet la telemetrie SI le regime, le defer ou
  /// le palier de batterie a change (pas a chaque tick).
  void _updateState(BatteryLocationState next) {
    final prev = state;
    if (prev == next) return;
    state = next;
    final regimeChanged = prev.mode != next.mode;
    final deferChanged = prev.deferSync != next.deferSync;
    final bucketChanged = (prev.batteryPct ~/ 10) != (next.batteryPct ~/ 10);
    if (regimeChanged || deferChanged || bucketChanged) {
      unawaited(_emitTelemetry(next));
    }
  }

  Future<void> _emitTelemetry(BatteryLocationState s) async {
    try {
      await _analytics.logGpsRegime(
        regime: s.mode.name,
        batteryPct: s.batteryPct,
        deferSync: s.deferSync,
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st,
          context: 'BatteryAwareLocationController._emitTelemetry');
    }
  }

  void _disposeController() {
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
    _connectivitySub?.cancel();
    _batterySub?.cancel();
  }
}

/// Provider du controller batterie-aware (F6A-04).
final batteryAwareLocationControllerProvider =
    NotifierProvider<BatteryAwareLocationController, BatteryLocationState>(
  BatteryAwareLocationController.new,
);
