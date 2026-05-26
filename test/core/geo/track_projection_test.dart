import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';

void main() {
  /// Trace fictif horizontal (ouest -> est) le long du 45e parallele
  final straightTrack = List.generate(
    100,
    (i) => TrackPoint(
      lat: 45.0,
      lng: 3.0 + i * 0.001,
      altitude: 500.0,
      distanceFromStart: i * 78.7, // ~78.7m par segment a cette latitude
    ),
  );

  group('TrackProjector', () {
    test('projection sur segment droit retourne position correcte', () {
      // Point juste au nord du milieu du trace
      final result = TrackProjector.project(
        userLat: 45.001,
        userLng: 3.050,
        trackPoints: straightTrack,
      );

      // La projection doit etre sur le trace (lat ~ 45.0)
      expect(result.projectedLat, closeTo(45.0, 0.001));
      // La longitude projetee doit etre proche de 3.050
      expect(result.projectedLng, closeTo(3.050, 0.002));
    });

    test('distance au trace correcte pour un point decale', () {
      // Point a environ 111m au nord du trace (0.001 degre lat)
      final result = TrackProjector.project(
        userLat: 45.001,
        userLng: 3.050,
        trackPoints: straightTrack,
      );

      // Distance perpendiculaire ~ 111m (0.001 degre lat)
      expect(result.distanceToTrackM, closeTo(111, 20));
    });

    test('point hors trace a grande distance', () {
      // Point a 1 km au nord du trace
      final result = TrackProjector.project(
        userLat: 45.009,
        userLng: 3.050,
        trackPoints: straightTrack,
      );

      // Distance ~ 1000m
      expect(result.distanceToTrackM, closeTo(1000, 50));
    });

    test('distance restante decroit quand on avance', () {
      final resultStart = TrackProjector.project(
        userLat: 45.0,
        userLng: 3.010,
        trackPoints: straightTrack,
      );

      final resultEnd = TrackProjector.project(
        userLat: 45.0,
        userLng: 3.080,
        trackPoints: straightTrack,
      );

      expect(resultStart.distanceRemainingM,
          greaterThan(resultEnd.distanceRemainingM));
      expect(resultStart.distanceFromStartM,
          lessThan(resultEnd.distanceFromStartM));
    });

    test('optimisation fenetre avec lastKnownIndex', () {
      // Premier appel sans index
      final result1 = TrackProjector.project(
        userLat: 45.0,
        userLng: 3.050,
        trackPoints: straightTrack,
      );

      // Deuxieme appel avec index connu — meme resultat
      final result2 = TrackProjector.project(
        userLat: 45.0,
        userLng: 3.050,
        trackPoints: straightTrack,
        lastKnownIndex: result1.trackIndexPosition,
      );

      expect(result2.projectedLng, closeTo(result1.projectedLng, 0.001));
      expect(result2.trackIndexPosition, result1.trackIndexPosition);
    });

    test('leve ArgumentError si moins de 2 points', () {
      final shortTrack = [
        const TrackPoint(
          lat: 45.0,
          lng: 3.0,
          altitude: 500,
          distanceFromStart: 0,
        ),
      ];

      expect(
        () => TrackProjector.project(
          userLat: 45.0,
          userLng: 3.0,
          trackPoints: shortTrack,
        ),
        throwsArgumentError,
      );
    });

    test('trackIndexPosition est coherent avec la longitude', () {
      // Point au debut du trace
      final resultDebut = TrackProjector.project(
        userLat: 45.0,
        userLng: 3.005,
        trackPoints: straightTrack,
      );

      // Point vers la fin du trace
      final resultFin = TrackProjector.project(
        userLat: 45.0,
        userLng: 3.090,
        trackPoints: straightTrack,
      );

      expect(resultDebut.trackIndexPosition,
          lessThan(resultFin.trackIndexPosition));
    });
  });
}
