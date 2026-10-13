// Lot 671-02 : le montage de la calibration de la longueur de pas sur la
// carte (`StrideCalibrationMount`, dans `map_overlays.dart`) ne vit que
// pendant un trek qui enregistre, et il ne montre rien.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/trek/data/calibration_du_pas.dart';
import 'package:moteur_gr/features/trek/data/podometre_preferences.dart';
import 'package:moteur_gr/features/trek/domain/longueur_de_pas.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_overlays.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// Une calibration qui note ce qu'on lui donne.
class _Espion extends StrideCalibrationFeed {
  _Espion() : super(PodometerStore());

  final distances = <double>[];
  int remises = 0;

  @override
  Future<StrideOutcome?> observe(double distanceFromStartMeters) async {
    distances.add(distanceFromStartMeters);
    return null;
  }

  @override
  void reset() => remises++;
}

class _Trek extends TrekSessionManagerNotifier {
  _Trek(this.statut);
  final TrackingSessionStatus statut;

  @override
  TrackingSessionState build() => TrackingSessionState(status: statut);
}

class _Projection extends Notifier<AsyncValue<TrackPositionState>> {
  @override
  AsyncValue<TrackPositionState> build() => const AsyncLoading();

  void aller(double metres, {bool estime = false}) => state = AsyncData(
    TrackPositionState(
      userLat: 42,
      userLng: 9,
      projectedLat: 42,
      projectedLng: 9,
      distanceToTrackM: 3,
      distanceFromStartM: metres,
      distanceRemainingM: 10000 - metres,
      trackIndex: 1,
      stageDetection: (stageNumber: 1, event: 'between'),
      isOffTrack: false,
      isEstimated: estime,
    ),
  );
}

final _projection =
    NotifierProvider<_Projection, AsyncValue<TrackPositionState>>(
      _Projection.new,
    );

void main() {
  Future<(_Espion, ProviderContainer)> monter(
    WidgetTester tester,
    TrackingSessionStatus statut,
  ) async {
    final espion = _Espion();
    final conteneur = ProviderContainer(
      overrides: [
        strideCalibrationFeedProvider.overrideWithValue(espion),
        trekSessionManagerProvider.overrideWith(() => _Trek(statut)),
        trackPositionProvider.overrideWith((ref) => ref.watch(_projection)),
      ],
    );
    addTearDown(conteneur.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: conteneur,
        child: const MaterialApp(home: StrideCalibrationMount()),
      ),
    );
    return (espion, conteneur);
  }

  testWidgets('pendant un trek qui enregistre, chaque position projetee est '
      'offerte a la calibration ; rien n est montre', (tester) async {
    final (espion, conteneur) = await monter(
      tester,
      TrackingSessionStatus.recording,
    );
    conteneur.read(_projection.notifier).aller(120);
    await tester.pump();
    conteneur.read(_projection.notifier).aller(400);
    await tester.pump();
    expect(espion.distances, [120, 400]);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('lot 671-03 : un point ESTIME n est jamais offert a la '
      'calibration, qui mesurerait sa propre hypothese', (tester) async {
    final (espion, conteneur) = await monter(
      tester,
      TrackingSessionStatus.recording,
    );
    conteneur.read(_projection.notifier).aller(120);
    await tester.pump();
    conteneur.read(_projection.notifier).aller(200, estime: true);
    await tester.pump();
    conteneur.read(_projection.notifier).aller(300, estime: true);
    await tester.pump();
    conteneur.read(_projection.notifier).aller(400);
    await tester.pump();
    expect(espion.distances, [120, 400]);
  });

  testWidgets('en pause, rien n est offert et l intervalle est oublie', (
    tester,
  ) async {
    final (espion, conteneur) = await monter(
      tester,
      TrackingSessionStatus.paused,
    );
    conteneur.read(_projection.notifier).aller(120);
    await tester.pump();
    expect(espion.distances, isEmpty);
    expect(espion.remises, greaterThan(0));
  });
}
