import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/stage_detector.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';

void main() {
  group('TrackPositionState', () {
    test('distanceRemainingKm convertit correctement', () {
      const state = TrackPositionState(
        userLat: 45.0,
        userLng: 3.0,
        projectedLat: 45.0,
        projectedLng: 3.0,
        distanceToTrackM: 5.0,
        distanceFromStartM: 5000.0,
        distanceRemainingM: 15000.0,
        trackIndex: 10,
        stageDetection: (
          stageNumber: 1,
          event: StageDetectionEvent.between,
        ),
        isOffTrack: false,
      );

      // 15000m = 15.0 km
      expect(state.distanceRemainingKm, 15.0);
    });

    test('progressRatio calcule le bon pourcentage', () {
      const state = TrackPositionState(
        userLat: 45.0,
        userLng: 3.0,
        projectedLat: 45.0,
        projectedLng: 3.0,
        distanceToTrackM: 5.0,
        distanceFromStartM: 5000.0,
        distanceRemainingM: 15000.0,
        trackIndex: 10,
        stageDetection: (
          stageNumber: 1,
          event: StageDetectionEvent.between,
        ),
        isOffTrack: false,
      );

      // 5000 / (5000 + 15000) = 0.25
      expect(state.progressRatio, closeTo(0.25, 0.01));
    });

    test('isOffTrack est vrai quand distance > 100m', () {
      const stateOnTrack = TrackPositionState(
        userLat: 45.0,
        userLng: 3.0,
        projectedLat: 45.0,
        projectedLng: 3.0,
        distanceToTrackM: 50.0,
        distanceFromStartM: 1000.0,
        distanceRemainingM: 9000.0,
        trackIndex: 5,
        stageDetection: (
          stageNumber: 1,
          event: StageDetectionEvent.between,
        ),
        isOffTrack: false,
      );

      const stateOffTrack = TrackPositionState(
        userLat: 45.001,
        userLng: 3.0,
        projectedLat: 45.0,
        projectedLng: 3.0,
        distanceToTrackM: 150.0,
        distanceFromStartM: 1000.0,
        distanceRemainingM: 9000.0,
        trackIndex: 5,
        stageDetection: (
          stageNumber: 1,
          event: StageDetectionEvent.between,
        ),
        isOffTrack: true,
      );

      expect(stateOnTrack.isOffTrack, false);
      expect(stateOffTrack.isOffTrack, true);
    });
  });

  group('TrackProjector integration avec TrackPositionState', () {
    final track = List.generate(
      50,
      (i) => TrackPoint(
        lat: 45.0,
        lng: 3.0 + i * 0.001,
        altitude: 500.0,
        distanceFromStart: i * 78.7,
      ),
    );

    test('projection mock GPS retourne des valeurs coherentes', () {
      final projection = TrackProjector.project(
        userLat: 45.0005,
        userLng: 3.025,
        trackPoints: track,
      );

      expect(projection.projectedLat, closeTo(45.0, 0.001));
      expect(projection.distanceToTrackM, greaterThan(0));
      expect(projection.distanceFromStartM, greaterThan(0));
      expect(projection.distanceRemainingM, greaterThan(0));
    });

    test('projection point sur le trace a distance quasi nulle', () {
      final projection = TrackProjector.project(
        userLat: 45.0,
        userLng: 3.025,
        trackPoints: track,
      );

      // Sur le trace exactement -> distance ~ 0
      expect(projection.distanceToTrackM, lessThan(5));
    });
  });
}
