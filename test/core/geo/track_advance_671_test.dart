import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';

/// LOT 671-03 — LA FONCTION PURE D'AVANCE SUR LE TRACE, CAS PAR CAS.
///
/// Elle fait avancer un point d'un nombre de metres le long d'un trace connu,
/// sans GPS. Chaque cas limite de la fiche E2 a son test : avance au-dela de
/// la fin, avance negative, avance nulle, trace trop court, segment de longueur
/// nulle (doublon au milieu ET en fin de trace).
void main() {
  /// Un trace dont chaque point porte sa distance cumulee, calculee comme le
  /// fait le lecteur de GPX : Haversine de point en point.
  List<TrackPoint> trackOf(List<(double, double, double)> coords) {
    final points = <TrackPoint>[];
    var cumulated = 0.0;
    for (var i = 0; i < coords.length; i++) {
      final (lat, lng, alt) = coords[i];
      if (i > 0) {
        final (pLat, pLng, _) = coords[i - 1];
        cumulated += GeoUtils.haversineDistance(pLat, pLng, lat, lng);
      }
      points.add(
        TrackPoint(
          lat: lat,
          lng: lng,
          altitude: alt,
          distanceFromStart: cumulated,
        ),
      );
    }
    return points;
  }

  // Quatre segments vers l'est sur le 45e parallele, ~78,7 m chacun.
  final straight = trackOf([
    for (var i = 0; i < 5; i++) (45.0, 3.0 + i * 0.001, 1000.0 + i * 10),
  ]);
  final total = straight.last.distanceFromStart;

  TrackAbscissa start(List<TrackPoint> track) =>
      TrackProjector.locate(trackPoints: track, distanceFromStartM: 0);

  group('l avance sur un trace droit', () {
    test('une avance au milieu d un segment rend la position interpolee, '
        'verifiee au metre', () {
      final r = TrackProjector.advance(
        trackPoints: straight,
        from: start(straight),
        meters: 40,
      );
      expect(r.segmentIndex, 0);
      expect(r.distanceFromStartM, closeTo(40, 1e-9));
      final fromStart = GeoUtils.haversineDistance(45.0, 3.0, r.lat, r.lng);
      expect(fromStart, closeTo(40, 1.0));
      expect(r.lat, closeTo(45.0, 1e-9));
    });

    test('une avance qui franchit plusieurs segments d un coup', () {
      final r = TrackProjector.advance(
        trackPoints: straight,
        from: start(straight),
        meters: 200,
      );
      expect(r.segmentIndex, 2);
      expect(r.distanceFromStartM, closeTo(200, 1e-9));
      expect(
        GeoUtils.haversineDistance(45.0, 3.0, r.lat, r.lng),
        closeTo(200, 1.0),
      );
    });

    test('une avance qui tombe exactement sur un point du trace', () {
      final r = TrackProjector.advance(
        trackPoints: straight,
        from: start(straight),
        meters: straight[2].distanceFromStart,
      );
      expect(r.segmentIndex, 2);
      expect(r.lat, closeTo(straight[2].lat, 1e-12));
      expect(r.lng, closeTo(straight[2].lng, 1e-12));
      expect(r.altitude, closeTo(straight[2].altitude, 1e-9));
    });

    test('une avance AU-DELA DE LA FIN est bornee a la fin : index du dernier '
        'segment, distance rendue egale a la longueur totale', () {
      final r = TrackProjector.advance(
        trackPoints: straight,
        from: start(straight),
        meters: total + 500,
      );
      final beyond = r.distanceFromStartM - total;
      expect(
        r.distanceFromStartM,
        lessThanOrEqualTo(total),
        reason:
            'le point est sorti du trace de ${beyond.toStringAsFixed(1)} m '
            'au-dela de sa fin',
      );
      expect(r.distanceFromStartM, closeTo(total, 1e-9));
      expect(r.segmentIndex, straight.length - 2);
      expect(r.lng, closeTo(straight.last.lng, 1e-12));
    });

    test('dans le sens decroissant, une avance au-dela du depart est bornee '
        'au depart, index du premier segment', () {
      final atEnd = TrackProjector.locate(
        trackPoints: straight,
        distanceFromStartM: total,
      );
      final r = TrackProjector.advance(
        trackPoints: straight,
        from: atEnd,
        meters: total + 100,
        direction: WalkDirection.decreasing,
      );
      expect(r.distanceFromStartM, 0);
      expect(r.segmentIndex, 0);
      expect(r.lng, closeTo(3.0, 1e-12));
    });

    test(
      'une avance NEGATIVE est refusee : un nombre de pas ne recule pas',
      () {
        expect(
          () => TrackProjector.advance(
            trackPoints: straight,
            from: start(straight),
            meters: -1,
          ),
          throwsArgumentError,
        );
      },
    );

    test('une avance NULLE rend le point tel quel, sans recalcul et sans '
        'changement d index', () {
      // Un index volontairement incoherent avec la distance : s'il etait
      // recalcule, il changerait. C'est la preuve qu'il ne l'est pas.
      const from = (
        lat: 1.0,
        lng: 2.0,
        altitude: 3.0,
        segmentIndex: 3,
        distanceFromStartM: 10.0,
      );
      final r = TrackProjector.advance(
        trackPoints: straight,
        from: from,
        meters: 0,
      );
      expect(r, from);
      expect(r.segmentIndex, 3);
    });

    test('un trace de moins de deux points est refuse, comme par la '
        'projection', () {
      final one = [straight.first];
      expect(
        () => TrackProjector.advance(
          trackPoints: one,
          from: start(straight),
          meters: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => TrackProjector.locate(trackPoints: one, distanceFromStartM: 0),
        throwsArgumentError,
      );
      expect(
        () => TrackProjector.locate(
          trackPoints: const <TrackPoint>[],
          distanceFromStartM: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('le segment de longueur nulle (doublon du GPX)', () {
    // Un doublon au MILIEU (points 2 et 3) ET un doublon en FIN (4 et 5).
    final duplicated = trackOf([
      (45.0, 3.000, 1000),
      (45.0, 3.001, 1010),
      (45.0, 3.002, 1020),
      (45.0, 3.002, 1020),
      (45.0, 3.003, 1030),
      (45.0, 3.003, 1030),
    ]);
    final length = duplicated.last.distanceFromStart;

    test('le doublon du milieu est enjambe, sans division par zero', () {
      for (var m = 0.0; m <= length; m += 7.3) {
        final r = TrackProjector.advance(
          trackPoints: duplicated,
          from: start(duplicated),
          meters: m,
        );
        expect(r.lat.isFinite && r.lng.isFinite, isTrue, reason: 'a $m m');
        expect(r.distanceFromStartM, closeTo(m, 1e-9));
      }
      final onDuplicate = TrackProjector.advance(
        trackPoints: duplicated,
        from: start(duplicated),
        meters: duplicated[2].distanceFromStart,
      );
      expect(onDuplicate.lng, closeTo(3.002, 1e-12));
      // La recherche prend le DERNIER segment qui commence a cette abscisse :
      // celui qui suit le doublon, de longueur non nulle.
      expect(onDuplicate.segmentIndex, 3);
    });

    test('le doublon de fin est enjambe : la fin du trace est atteinte sans '
        'boucle, sur le dernier segment', () {
      final r = TrackProjector.advance(
        trackPoints: duplicated,
        from: start(duplicated),
        meters: length + 50,
      );
      expect(r.distanceFromStartM, closeTo(length, 1e-9));
      expect(r.segmentIndex, duplicated.length - 2);
      expect(r.lng, closeTo(3.003, 1e-12));
      expect(r.altitude, 1030);
    });
  });

  group('le sens de la marche, sans aucun capteur de cap', () {
    test('deux releves croissants donnent le sens croissant', () {
      expect(
        TrackProjector.directionOf(
          previousM: 100,
          latestM: 300,
          fallback: WalkDirection.decreasing,
        ),
        WalkDirection.increasing,
      );
    });

    test('deux releves decroissants donnent le sens decroissant', () {
      expect(
        TrackProjector.directionOf(
          previousM: 300,
          latestM: 100,
          fallback: WalkDirection.increasing,
        ),
        WalkDirection.decreasing,
      );
    });

    test('avant le deuxieme releve, le sens de repli s applique', () {
      for (final fallback in WalkDirection.values) {
        expect(
          TrackProjector.directionOf(
            previousM: null,
            latestM: 300,
            fallback: fallback,
          ),
          fallback,
        );
      }
    });

    test('sous la zone morte de $kWalkDirectionDeadBandMeters m, le bruit '
        'd un releve a l arret ne retourne pas le sens', () {
      expect(
        TrackProjector.directionOf(
          previousM: 300,
          latestM: 300 - kWalkDirectionDeadBandMeters + 1,
          fallback: WalkDirection.increasing,
        ),
        WalkDirection.increasing,
      );
    });
  });
}
