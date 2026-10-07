import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/features/map/providers/current_position_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';
import 'package:moteur_gr/features/trek/data/position_controller.dart';

/// LOT 671-03 — LA POSITION COURANTE : le releve en profil carte, l'estime le
/// long du trace entre deux releves en profils de tir.
void main() {
  Position fix(double lat, DateTime at) => Position(
    latitude: lat,
    longitude: 9,
    timestamp: at,
    accuracy: 6,
    altitude: 300,
    altitudeAccuracy: 3,
    heading: 0,
    headingAccuracy: 0,
    speed: 1,
    speedAccuracy: 0.5,
  );

  BgTrackPoint estimate(double lat, DateTime at) => BgTrackPoint(
    id: 'e',
    sessionId: 's',
    trailId: 't',
    latitude: lat,
    longitude: 9,
    altitude: 420,
    accuracy: 0,
    speed: 0,
    timestamp: at,
    source: TrackPointSource.estimated,
    trackDistanceM: 1234,
  );

  Future<
    (
      ProviderContainer,
      StreamController<Position>,
      StreamController<BgTrackPoint>,
    )
  >
  bench(PositionProfile profile) async {
    final real = StreamController<Position>.broadcast();
    final estimated = StreamController<BgTrackPoint>.broadcast();
    final controller = PositionController();
    await controller.setProfile(profile);
    final c = ProviderContainer(
      overrides: [
        positionControllerProvider.overrideWithValue(controller),
        locationProvider.overrideWith((ref) => real.stream),
        estimatedTrackPointsProvider.overrideWithValue(estimated.stream),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await real.close();
      await estimated.close();
    });
    final sub = c.listen(currentPositionProvider, (_, _) {});
    addTearDown(sub.close);
    return (c, real, estimated);
  }

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  final t0 = DateTime(2026, 10, 7, 9);

  test('un releve est une position mesuree, avec sa precision', () async {
    final (c, real, _) = await bench(PositionProfile.map);
    real.add(fix(42.1, t0));
    await settle();
    final p = c.read(currentPositionProvider).value!;
    expect(p.isEstimated, isFalse);
    expect(p.latitude, 42.1);
    expect(p.accuracy, 6);
    expect(p.trackDistanceM, isNull);
  });

  test('en profil batterie basse, un estime devient la position courante, '
      'sans precision, avec sa distance sur le trace', () async {
    final (c, real, estimated) = await bench(PositionProfile.lowBattery);
    real.add(fix(42.1, t0));
    await settle();
    estimated.add(estimate(42.11, t0.add(const Duration(minutes: 1))));
    await settle();
    final p = c.read(currentPositionProvider).value!;
    expect(p.isEstimated, isTrue);
    expect(p.latitude, 42.11);
    expect(p.altitude, 420);
    expect(p.accuracy, isNull);
    expect(p.trackDistanceM, 1234);
  });

  test('un estime calcule avant le dernier releve est perime : le releve '
      'reste la position courante', () async {
    final (c, real, estimated) = await bench(PositionProfile.batteryFirst);
    real.add(fix(42.1, t0));
    await settle();
    estimated.add(estimate(42.09, t0.subtract(const Duration(seconds: 30))));
    await settle();
    expect(c.read(currentPositionProvider).value!.isEstimated, isFalse);
  });
}
