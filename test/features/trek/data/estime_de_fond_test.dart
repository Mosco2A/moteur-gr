import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/features/trek/data/estime_de_fond.dart';
import 'package:moteur_gr/features/trek/data/trace_de_fond.dart';

/// LOT 671-03 — L'ESTIME LE LONG DU TRACE, TEL QUE L'ISOLATE DE FOND LE MENE.
///
/// Recalage aux releves, avance aux pas depuis le DERNIER releve, sens de la
/// marche par les deux derniers releves, suspension hors du trace avec les
/// seuils de la carte, regle de retenue des 12 m, plafond de distance. Aucun
/// capteur : tout est donne.
void main() {
  const metersPerDegree = 111195.0;

  /// 5 km plein nord le long de 9 E, un point tous les 10 m.
  final points = [
    for (var i = 0; i <= 500; i++)
      TrackPoint(
        lat: 42.0 + i * 10 / metersPerDegree,
        lng: 9.0,
        altitude: 100,
        distanceFromStart: i * 10.0,
      ),
  ];
  BackgroundTrace traceOf({WalkDirection d = WalkDirection.increasing}) =>
      (trailId: 't', points: points, direction: d);

  /// Le point du trace a [m] metres du depart, decale de [eastM] vers l'est.
  ({double lat, double lng}) at(double m, {double eastM = 0}) => (
    lat: 42.0 + m / metersPerDegree,
    lng: 9.0 + eastM / (metersPerDegree * 0.7431),
  );

  Position position(({double lat, double lng}) p) => Position(
    latitude: p.lat,
    longitude: p.lng,
    timestamp: DateTime.utc(2026, 10, 7),
    accuracy: 5,
    altitude: 100,
    altitudeAccuracy: 3,
    heading: 0,
    headingAccuracy: 0,
    speed: 1.1,
    speedAccuracy: 0.5,
  );

  group('TrackDeadReckoning', () {
    test('le premier releve n a aucun estime avant lui : ecart nul', () {
      final r = TrackDeadReckoning(traceOf());
      final p = at(1000);
      expect(
        r.recalibrate(latitude: p.lat, longitude: p.lng, steps: 0),
        isNull,
      );
    });

    test('l estime part du DERNIER RELEVE, de (pas depuis lui) x longueur', () {
      final r = TrackDeadReckoning(traceOf());
      final p = at(1000);
      r.recalibrate(latitude: p.lat, longitude: p.lng, steps: 100);
      final e = r.advance(steps: 400, strideMeters: 0.75)!;
      expect(e.distanceFromStartM, closeTo(1225, 0.5));
      expect(r.estimatedSinceFixMeters, closeTo(225, 0.5));
      // Un releve reel a 1 240 m : l'ecart est de 15 m, le long du trace.
      final q = at(1240);
      final drift = r.recalibrate(
        latitude: q.lat,
        longitude: q.lng,
        steps: 400,
      );
      expect(drift, closeTo(15, 0.5));
      // Et l'estime suivant repart du releve, pas de l'estime.
      expect(
        r.advance(steps: 400, strideMeters: 0.75)!.distanceFromStartM,
        closeTo(1240, 0.5),
      );
    });

    test('sans pas connus au releve, l estime n a pas de rail', () {
      final r = TrackDeadReckoning(traceOf());
      final p = at(1000);
      r.recalibrate(latitude: p.lat, longitude: p.lng, steps: null);
      expect(r.advance(steps: 50, strideMeters: 0.75), isNull);
      r.recalibrate(latitude: p.lat, longitude: p.lng, steps: 50);
      expect(r.advance(steps: null, strideMeters: 0.75), isNull);
    });

    test('deux releves decroissants retournent le sens : l estime recule '
        'sur le trace', () {
      final r = TrackDeadReckoning(traceOf());
      final a = at(3000);
      final b = at(2700);
      r.recalibrate(latitude: a.lat, longitude: a.lng, steps: 0);
      r.recalibrate(latitude: b.lat, longitude: b.lng, steps: 400);
      expect(r.direction, WalkDirection.decreasing);
      expect(
        r.advance(steps: 800, strideMeters: 0.75)!.distanceFromStartM,
        closeTo(2400, 0.5),
      );
    });

    test('avant le deuxieme releve, le sens est celui que le trek connait', () {
      final r = TrackDeadReckoning(traceOf(d: WalkDirection.decreasing));
      final a = at(3000);
      r.recalibrate(latitude: a.lat, longitude: a.lng, steps: 0);
      expect(
        r.advance(steps: 400, strideMeters: 0.75)!.distanceFromStartM,
        closeTo(2700, 0.5),
      );
    });

    test('HORS DU TRACE, PAS D ESTIME : un releve a 300 m suspend l avance, '
        'un releve revenu sous le seuil de retour la reprend', () {
      final r = TrackDeadReckoning(traceOf());
      final off = at(1000, eastM: 300);
      r.recalibrate(latitude: off.lat, longitude: off.lng, steps: 0);
      expect(r.isOffTrack, isTrue);
      expect(r.advance(steps: 400, strideMeters: 0.75), isNull);
      // Dans la zone morte (65 m) : toujours suspendu.
      final dead = at(1100, eastM: 65);
      r.recalibrate(latitude: dead.lat, longitude: dead.lng, steps: 400);
      expect(r.isOffTrack, isTrue);
      final back = at(1200, eastM: 10);
      r.recalibrate(latitude: back.lat, longitude: back.lng, steps: 500);
      expect(r.isOffTrack, isFalse);
      expect(
        r.advance(steps: 600, strideMeters: 0.75)!.distanceFromStartM,
        closeTo(1275, 0.5),
      );
    });

    test('la regle de retenue des 12 m vaut pour l estime : le releve est la '
        'reference, puis le dernier estime retenu', () {
      final r = TrackDeadReckoning(traceOf());
      final p = at(1000);
      r.recalibrate(latitude: p.lat, longitude: p.lng, steps: 0);
      final near = r.advance(steps: 10, strideMeters: 0.75)!; // 7,5 m
      expect(r.keep(near, 12), isFalse);
      final far = r.advance(steps: 20, strideMeters: 0.75)!; // 15 m
      expect(r.keep(far, 12), isTrue);
      final next = r.advance(steps: 30, strideMeters: 0.75)!; // 7,5 m de plus
      expect(r.keep(next, 12), isFalse);
    });
  });

  group('BackgroundEstimate', () {
    BackgroundEstimate estimateOn(
      String? raw, {
      String trailId = 't',
      void Function()? requestFix,
    }) => BackgroundEstimate(
      readTrace: () async => raw,
      trailId: () => trailId,
      keepDistanceMeters: () => 12,
      requestFix: requestFix,
    );
    final raw = encodeBackgroundTrace(traceOf());

    test('en profil carte, l estime est sans objet : aucun ecart, aucun '
        'point', () async {
      final e = estimateOn(raw);
      expect(await e.onFix(position(at(1000)), 0, PositionProfile.map), isNull);
      expect(e.onSteps(400, 0.75, PositionProfile.map), isNull);
      expect(e.reckoning, isNull);
    });

    test('en profil batterie d abord, l estime avance et l ecart se mesure '
        'au releve suivant', () async {
      final e = estimateOn(raw);
      const p = PositionProfile.batteryFirst;
      expect(await e.onFix(position(at(1000)), 0, p), isNull);
      final kept = e.onSteps(266, 0.75, p)!;
      expect(kept.distanceFromStartM, closeTo(1199.5, 0.5));
      expect(await e.onFix(position(at(1200)), 266, p), closeTo(0.5, 0.5));
    });

    test(
      'un trace d un autre sentier, ou pas de trace : pas de rail',
      () async {
        final other = estimateOn(raw, trailId: 'autre');
        await other.onFix(position(at(1000)), 0, PositionProfile.batteryFirst);
        expect(other.reckoning, isNull);
        final none = estimateOn(null);
        await none.onFix(position(at(1000)), 0, PositionProfile.lowBattery);
        expect(none.reckoning, isNull);
        expect(none.onSteps(10, 0.75, PositionProfile.lowBattery), isNull);
      },
    );

    test(
      'LE PLAFOND DE DISTANCE : un releve est demande, une seule fois, '
      'quand l estime a avance de $kEstimateDistanceCeilingMeters m',
      () async {
        var requests = 0;
        final e = estimateOn(raw, requestFix: () => requests++);
        const p = PositionProfile.lowBattery;
        await e.onFix(position(at(500)), 0, p);
        e.onSteps(600, 0.75, p); // 450 m
        expect(requests, 0);
        e.onSteps(667, 0.75, p); // 500,25 m
        e.onSteps(700, 0.75, p);
        expect(requests, 1);
        await e.onFix(position(at(1025)), 700, p);
        e.onSteps(1400, 0.75, p); // 525 m apres le nouveau releve
        expect(requests, 2);
      },
    );
  });
}
