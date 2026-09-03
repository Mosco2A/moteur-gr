import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/trek/data/arrival_detection_service.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/domain/trek_completion.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// PARITE GR20, LOT 2 (2.B, #99433) — le pont d'arrivee est VIVANT dans l'ecran
/// terrain (MapScreen).
///
/// Prouve qu'une fois l'ecran carte monte AVEC un trek en cours, une arrivee
/// simulee (trailEnd apres avoir marche toutes les etapes) declenche la porte du
/// finisher — alors qu'au LOT 1 le listener n'etait observe par AUCUN ecran
/// (chaine INERTE). Le cas « hors trek » (idle) est couvert au niveau unitaire
/// (le mount ne s'abonne que si la session est recording/paused).
void main() {
  final mockTrackPoints = [
    const TrackPoint(lat: 45.77, lng: 2.96, altitude: 1465, distanceFromStart: 0),
    const TrackPoint(
        lat: 45.79, lng: 2.98, altitude: 1600, distanceFromStart: 2400),
  ];

  const plan = TrekPlan(
    orderedStageIds: ['1', '2', '3'],
    direction: 'NS',
    isFullTrail: true,
  );

  TrekSession recordingSession() => TrekSession(
        id: 'sess-map-1',
        trailId: 'test-trail',
        startedAt: DateTime.utc(2026, 6, 15, 8),
        status: 'active',
      );

  Widget harness(
    StreamController<ArrivalEvent> ctrl, {
    required _GateNotifier notifier,
  }) {
    return ProviderScope(
      overrides: [
        // DB in-memory isolee : la persistance best-effort du finisher ecrit ici
        // sans effet de bord (le focus du test = le pont d'arrivee monte).
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase.memory());
          ref.onDispose(db.close);
          return db;
        }),
        trailConfigProvider.overrideWithValue(testTrailConfig),
        gpxTrackProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockTrackPoints)),
        // GPS non accorde -> pas de couche position (rendu neutre).
        gpsPermissionProvider
            .overrideWith((ref) => Future.value(GpsPermissionStateValues.denied)),
        // Plan + flux d'arrivee pilotables (pas de vrai GPS).
        currentTrekPlanProvider.overrideWithValue(plan),
        arrivalEventsProvider.overrideWith((ref) => ctrl.stream),
        // currentStageIdProvider est aussi monte par l'ecran : on le neutralise.
        currentStageIdProvider.overrideWith((ref) => const Stream.empty()),
        trekSessionManagerProvider.overrideWith(() => notifier),
      ],
      child: const MaterialApp(home: MapScreen(trailId: 'test-trail')),
    );
  }

  ArrivalEvent evt(String stageId, {required bool isFinal}) => ArrivalEvent(
        type: isFinal ? 'trailEnd' : 'stageEnd',
        stageId: stageId,
        timestamp: DateTime.now(),
      );

  testWidgets(
      'trek en cours : arrivee simulee (parcours complet) -> finisher declenche',
      (tester) async {
    final ctrl = StreamController<ArrivalEvent>();
    final notifier = _GateNotifier(TrackingSessionState(
      status: TrackingSessionStatus.recording,
      session: recordingSession(),
    ));
    addTearDown(() => ctrl.close());

    await tester.pumpWidget(harness(ctrl, notifier: notifier));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Le listener est monte (trek actif) : on simule la marche complete.
    ctrl.add(evt('1', isFinal: false));
    ctrl.add(evt('2', isFinal: false));
    ctrl.add(evt('3', isFinal: true)); // derniere etape reelle
    await tester.pump(const Duration(milliseconds: 50));

    final session = notifier.state.session;
    expect(session?.completedStages, containsAll(<String>['1', '2', '3']),
        reason: 'Chaque arrivee marque l etape via le pont monte par l ecran.');
    expect(notifier.stopCallCount, 1,
        reason: 'Parcours complet marche -> la porte du finisher s ouvre.');
    expect(notifier.fullyWalkedAtStop, isTrue);
  });
}

/// Notifier de test : garde la vraie logique de gate (recordStageCompleted /
/// completeOnArrival) et neutralise stop (services lourds). Instrumente stop.
class _GateNotifier extends TrekSessionManagerNotifier {
  _GateNotifier(this._initial);
  final TrackingSessionState _initial;

  int stopCallCount = 0;
  bool? fullyWalkedAtStop;

  @override
  TrackingSessionState build() => _initial;

  @override
  Future<void> stop() async {
    stopCallCount++;
    fullyWalkedAtStop = state.session?.parcoursFullyWalked;
    state = state.copyWith(status: TrackingSessionStatus.stopped);
  }
}
