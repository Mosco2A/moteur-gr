import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_slice.dart';

/// LOT 671-06 (4) — LA TRANCHE DE TRACE, CAS LIMITE PAR CAS LIMITE.
///
/// Un trace volontairement GROSSIER (un point tous les 1 000 m, comme les
/// sentiers du depot) : c'est la que l'interpolation des bornes compte.
void main() {
  const metersPerDegree = 111194.93;

  /// Quatre points sur le meridien 9° E, un tous les 1 000 m, altitudes
  /// 500, 600, 550, 700.
  final track = [
    for (final (i, alt) in [(0, 500.0), (1, 600.0), (2, 550.0), (3, 700.0)])
      TrackPoint(
        lat: 42.0 + i * 1000 / metersPerDegree,
        lng: 9.0,
        altitude: alt,
        distanceFromStart: i * 1000.0,
      ),
  ];

  double lengthOf(List<TrackPoint> slice) {
    var m = 0.0;
    for (var i = 1; i < slice.length; i++) {
      m += GeoUtils.haversineDistance(
        slice[i - 1].lat,
        slice[i - 1].lng,
        slice[i].lat,
        slice[i].lng,
      );
    }
    return m;
  }

  group('671-06 (4) — la tranche de trace', () {
    test('DEUX BORNES AU MILIEU DE SEGMENTS : la tranche mesure 1 950 m au '
        'metre pres, bornes interpolees comprises', () {
      final slice = TrackSlice.between(
        trackPoints: track,
        fromM: 250,
        toM: 2200,
      );

      // Borne interpolee, les deux points du trace entre les bornes, borne
      // interpolee : sans les bornes, la tranche vaudrait 1 000 m.
      expect(slice, hasLength(4));
      expect(slice.first.distanceFromStart, 250);
      expect(slice.first.altitude, closeTo(525, 1e-9));
      expect(slice[1], track[1]);
      expect(slice[2], track[2]);
      expect(slice.last.distanceFromStart, 2200);
      expect(slice.last.altitude, closeTo(580, 1e-9));
      expect(lengthOf(slice), closeTo(1950, 1));
    });

    test('BORNES EGALES : tranche de longueur nulle, aucune erreur', () {
      final slice = TrackSlice.between(
        trackPoints: track,
        fromM: 1500,
        toM: 1500,
      );

      expect(slice, hasLength(2));
      expect(slice.first, slice.last);
      expect(lengthOf(slice), 0);
    });

    test('BORNE DE FIN AVANT LA BORNE DE DEPART : REFUSEE, comme '
        'TrackProjector.project refuse un trace trop court', () {
      expect(
        () => TrackSlice.between(trackPoints: track, fromM: 2200, toM: 250),
        throwsArgumentError,
      );
      expect(
        () =>
            TrackSlice.between(trackPoints: track, fromM: double.nan, toM: 250),
        throwsArgumentError,
      );
    });

    test('BORNES AU-DELA DU TRACE : bornees a ses extremites', () {
      final slice = TrackSlice.between(
        trackPoints: track,
        fromM: -400,
        toM: 9000,
      );

      expect(slice.first.distanceFromStart, 0);
      expect(slice.last.distanceFromStart, 3000);
      expect(lengthOf(slice), closeTo(3000, 1));
    });

    test('TRACE DE MOINS DE DEUX POINTS : REFUSE', () {
      expect(
        () => TrackSlice.between(
          trackPoints: track.sublist(0, 1),
          fromM: 0,
          toM: 10,
        ),
        throwsArgumentError,
      );
    });

    test('POINTS DUPLIQUES : enjambes sans division par zero', () {
      final withDuplicates = [
        track[0],
        track[1],
        track[1],
        track[1],
        track[2],
        track[3],
      ];
      final slice = TrackSlice.between(
        trackPoints: withDuplicates,
        fromM: 500,
        toM: 1500,
      );

      for (final p in slice) {
        expect(p.lat.isFinite && p.altitude.isFinite, isTrue);
      }
      expect(slice.first.altitude, closeTo(550, 1e-9));
      expect(slice.last.altitude, closeTo(575, 1e-9));
      expect(lengthOf(slice), closeTo(1000, 1));
    });
  });
}
