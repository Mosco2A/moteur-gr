import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/progress_dao.dart';
import '../../../core/data/daos/session_track_points_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/tracking_engine.dart';
import '../models/tracking_status.dart';

/// Etat immutable du tracking expose a l UI.
class TrackingState {
  const TrackingState({
    this.status = TrackingStatusValues.idle,
    this.distanceM = 0.0,
    this.elevationGainM = 0,
    this.durationSec = 0,
    this.speedKmh = 0.0,
  });

  final TrackingStatus status;
  final double distanceM;
  final int elevationGainM;
  final int durationSec;
  final double speedKmh;

  TrackingState copyWith({
    TrackingStatus? status,
    double? distanceM,
    int? elevationGainM,
    int? durationSec,
    double? speedKmh,
  }) {
    return TrackingState(
      status: status ?? this.status,
      distanceM: distanceM ?? this.distanceM,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      durationSec: durationSec ?? this.durationSec,
      speedKmh: speedKmh ?? this.speedKmh,
    );
  }
}

/// Notifier du tracking GPS.
class TrackingNotifier extends Notifier<TrackingState> {
  final TrackingEngine _engine = TrackingEngine();
  StreamSubscription<Position>? _locationSub;
  Timer? _ticker;
  String _trailId = '';

  /// L3-1 — identifiant du segment de trace en cours (une valeur par
  /// [start]), pour que deux randonnees successives ne se melangent pas.
  String? _sessionId;

  /// L3-1 — depart de la randonnee en cours, origine de la numerotation
  /// des jours de marche (jour 1 = jour du depart).
  DateTime? _startedAt;

  @override
  TrackingState build() {
    ref.onDispose(() {
      _locationSub?.cancel();
      _ticker?.cancel();
    });
    return const TrackingState();
  }

  /// Demarre le tracking GPS.
  void start(String trailId) {
    if (state.status == TrackingStatusValues.recording) {
      return;
    }
    _trailId = trailId;
    _engine.reset();
    // L3-1 : le trace de la randonnee PRECEDENTE n'est PLUS efface. Chaque
    // session ouvre son propre segment (identifie par [_sessionId]) et les
    // jours de marche sont numerotes a partir de [_startedAt]. Effacer ici
    // rendait impossible de relire le jour 3 apres avoir marche le jour 5.
    final traceDao = ref.read(databaseProvider).sessionTrackPointsDao;
    _startedAt = DateTime.now();
    _sessionId = 'local-${_startedAt!.millisecondsSinceEpoch}';
    state = state.copyWith(
      status: TrackingStatusValues.recording,
      distanceM: 0.0,
      elevationGainM: 0,
      durationSec: 0,
      speedKmh: 0.0,
    );
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (_engine.isPaused) {
        return;
      }
      _engine.addPosition(
        position.latitude,
        position.longitude,
        position.altitude,
      );
      // F3 : persistence au fil de l'eau du trace de session
      // (lu par le recap diplome) — robuste a un arret brutal.
      // L3-1 : chaque point porte sa session et son jour de marche.
      final now = DateTime.now();
      unawaited(traceDao.insertPoint(
        trailId: trailId,
        lat: position.latitude,
        lng: position.longitude,
        altitude: position.altitude,
        recordedAt: now,
        sessionId: _sessionId,
        dayIndex: _startedAt == null
            ? null
            : SessionTrackPointsDao.dayIndexFor(_startedAt!, now),
      ));
      _updateState();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == TrackingStatusValues.recording) {
        _updateState();
      }
    });
  }

  /// Met en pause le tracking.
  void pause() {
    if (state.status != TrackingStatusValues.recording) {
      return;
    }
    _engine.pause();
    state = state.copyWith(status: TrackingStatusValues.paused);
  }

  /// Reprend le tracking apres une pause.
  void resume() {
    if (state.status != TrackingStatusValues.paused) {
      return;
    }
    _engine.resume();
    state = state.copyWith(status: TrackingStatusValues.recording);
  }

  /// Arrete le tracking et sauvegarde la progression.
  Future<void> stop() async {
    if (state.status != TrackingStatusValues.recording &&
        state.status != TrackingStatusValues.paused) {
      return;
    }
    _locationSub?.cancel();
    _locationSub = null;
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(status: TrackingStatusValues.stopped);
    await _saveProgress();
    _engine.reset();
    state = const TrackingState();
  }

  /// Sauvegarde la progression dans la DB Drift.
  Future<void> _saveProgress() async {
    if (_trailId.isEmpty) {
      return;
    }
    final db = ref.read(databaseProvider);
    final dao = ProgressDao(db);
    final existing = await dao.getByTrailId(_trailId);
    final prevDistKm = existing?.totalDistanceWalkedKm ?? 0.0;
    final prevElevM = existing?.totalElevationGainedM ?? 0;
    final prevTimeMin = existing?.totalTimeMinutes ?? 0;
    await dao.upsert(UserProgressEntriesCompanion(
      trailId: Value(_trailId),
      totalDistanceWalkedKm:
          Value(prevDistKm + _engine.distanceMeters / 1000),
      totalElevationGainedM:
          Value(prevElevM + _engine.elevationGainM.round()),
      totalTimeMinutes:
          Value(prevTimeMin + (_engine.durationSeconds / 60).round()),
      startedAt: Value(existing?.startedAt ?? DateTime.now()),
    ));
  }

  void _updateState() {
    state = state.copyWith(
      distanceM: _engine.distanceMeters,
      elevationGainM: _engine.elevationGainM.round(),
      durationSec: _engine.durationSeconds,
      speedKmh: _engine.averageSpeedKmh,
    );
  }
}

/// Provider du tracking GPS.
final trackingProvider =
    NotifierProvider<TrackingNotifier, TrackingState>(TrackingNotifier.new);
