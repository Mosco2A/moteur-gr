/// LE BANC DU LOT 671-06 : un trace connu, une fausse horloge, une marche a
/// 4 km/h, et des releves fabriques depuis le trace. Aucun capteur reel.
library;

import 'dart:io';
import 'dart:math';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/gpx_depuis_les_assets.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';

/// Metres par degre de latitude, au rayon de [GeoUtils.haversineDistance].
const double metersPerDegree = 6371000.0 * pi / 180;

/// La vitesse de marche du banc : 4 km/h, en metres par seconde.
const double walkSpeedMps = 4000 / 3600;

/// L'espacement des releves au pas du profil batterie d'abord : la distance
/// marchee a 4 km/h pendant [kBatteryFirstShotPeriod] (3 min, decision du
/// 06/10), soit 200 m.
final double batteryFirstSpacingM =
    walkSpeedMps * kBatteryFirstShotPeriod.inSeconds;

/// Le debut de la journee simulee.
final DateTime benchStart = DateTime.utc(2026, 7, 14, 7);

/// Un trace a partir de ses points, la distance cumulee recalculee par
/// [GeoUtils.haversineDistance] — celle du moteur.
List<TrackPoint> traceOf(List<({double lat, double lng, double alt})> pts) {
  final out = <TrackPoint>[];
  var cumul = 0.0;
  for (var i = 0; i < pts.length; i++) {
    if (i > 0) {
      cumul += GeoUtils.haversineDistance(
        pts[i - 1].lat,
        pts[i - 1].lng,
        pts[i].lat,
        pts[i].lng,
      );
    }
    out.add(
      TrackPoint(
        lat: pts[i].lat,
        lng: pts[i].lng,
        altitude: pts[i].alt,
        distanceFromStart: cumul,
      ),
    );
  }
  return out;
}

/// LE TRACE FABRIQUE DU BANC, dont la geometrie est connue au metre.
///
/// En metres locaux (x vers l'est, y vers le nord), depuis (42° N, 9° E),
/// avec un point a chaque RUPTURE de pente, comme les sentiers du depot :
/// - une MONTEE FRANCHE de 2 000 m en ligne droite, de 500 a 800 m
///   d'altitude (15 %), un point tous les 100 m ;
/// - une DESCENTE EN LACETS de 20 virages (75 m vers le nord, 60 m de
///   cote), de 800 a 550 m ;
/// - 2 500 m de BOSSES : 25 bosses de 8 m, un point tous les 50 m, en
///   ligne droite.
/// D+ vrai 500 m, D- vrai 450 m.
List<TrackPoint> fabricatedTrace() {
  final lngPerMeter = 1 / (metersPerDegree * cos(42 * pi / 180));
  ({double lat, double lng, double alt}) at(double x, double y, double alt) =>
      (lat: 42.0 + y / metersPerDegree, lng: 9.0 + x * lngPerMeter, alt: alt);
  return traceOf([
    for (var i = 0; i <= 20; i++) at(0, i * 100.0, 500 + i * 15.0),
    for (var k = 1; k <= 20; k++)
      at(k.isOdd ? 60 : 0, 2000 + k * 75.0, 800 - k * 12.5),
    for (var j = 1; j <= 50; j++)
      at(0, 3500 + j * 50.0, 550 + (j.isOdd ? 8 : 0)),
  ]);
}

/// Le meme trace, avec un point de plus tous les [stepM] metres entre ses
/// sommets : la MEME geometrie, au metre pres, d'autres points.
List<TrackPoint> densify(List<TrackPoint> trace, double stepM) => traceOf([
  for (var i = 1; i < trace.length; i++)
    for (
      var s = trace[i - 1].distanceFromStart;
      s < trace[i].distanceFromStart;
      s += stepM
    )
      _at(trace, s),
  _at(trace, trace.last.distanceFromStart),
]);

({double lat, double lng, double alt}) _at(List<TrackPoint> t, double s) {
  final p = TrackProjector.locate(trackPoints: t, distanceFromStartM: s);
  return (lat: p.lat, lng: p.lng, alt: p.altitude);
}

/// LE SENTIER DE REFERENCE DU DEPOT, lu comme une donnee : le trace du Mare a
/// Mare Centre (53 points, 72,9 km), celui du sentier de demonstration.
List<TrackPoint> referenceTrail() => GpxDepuisLesAssets.parseFromString(
  File('assets/data/mare_a_mare_centre/track.gpx').readAsStringSync(),
);

/// Les releves REELS d'une marche a 4 km/h le long de [trace], de son
/// depart a [untilM], un releve tous les [everyM] metres, poses SUR le trace
/// et dates par la fausse horloge.
List<SessionTrackPoint> walk(
  List<TrackPoint> trace, {
  required double everyM,
  required double untilM,
  String sessionId = 'banc',
}) {
  final out = <SessionTrackPoint>[];
  final n = (untilM / everyM).round();
  for (var i = 0; i <= n; i++) {
    final s = i * everyM;
    final p = TrackProjector.locate(trackPoints: trace, distanceFromStartM: s);
    out.add(
      SessionTrackPoint(
        id: i + 1,
        trailId: 'banc',
        sessionId: sessionId,
        lat: p.lat,
        lng: p.lng,
        altitude: p.altitude,
        recordedAt: benchStart.add(
          Duration(milliseconds: (s / walkSpeedMps * 1000).round()),
        ),
        source: 'gps',
      ),
    );
  }
  return out;
}

/// L'ecart relatif de [b] a [a], en pour cent ; zero si les deux sont nuls.
double gapPercent(num a, num b) =>
    a == 0 ? (b == 0 ? 0 : double.infinity) : (b - a).abs() / a.abs() * 100;

/// [gapPercent] lisible : « infini » quand la reference vaut zero et la
/// mesure non.
String gapText(num a, num b) {
  final g = gapPercent(a, b);
  return g.isInfinite
      ? 'infini (reference a zero)'
      : '${g.toStringAsFixed(2)} %';
}

/// La mediane d'une liste non vide.
double median(List<double> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}
