import 'dart:math';

import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';

/// LOT 671-04 — DES TRACES FABRIQUES AU METRE, POUR LES TESTS.
///
/// Les sommets sont donnes en metres sur un plan local (x vers l'est, y vers
/// le nord), autour de 42 degres nord (la Corse du sentier de reference) ;
/// chaque cote est decoupe en points tous les [pas] metres, et chaque point
/// porte sa distance cumulee calculee comme le fait le lecteur de GPX
/// (Haversine de point en point). Aucun capteur, aucune donnee reelle.
const double latitudeDOrigine = 42.0;

/// Longitude du point (0, 0) du plan local.
const double longitudeDOrigine = 9.0;

const double _metresParDegre = 111320.0;

/// Le point du plan local ([x], [y]) en degres.
({double lat, double lng}) versDegres(double x, double y) => (
  lat: latitudeDOrigine + y / _metresParDegre,
  lng:
      longitudeDOrigine +
      x / (_metresParDegre * cos(latitudeDOrigine * pi / 180)),
);

/// Un trace qui passe par [sommets], un point tous les [pas] metres au plus.
List<TrackPoint> traceDesSommets(
  List<(double, double)> sommets, {
  double pas = 10,
}) => traceDesPoints(decouper(sommets, pas: pas));

/// Les points du plan qui passent par [sommets], un tous les [pas] metres au
/// plus : on peut y inserer des doublons avant d'en faire un trace.
List<(double, double)> decouper(
  List<(double, double)> sommets, {
  double pas = 10,
}) {
  final plan = <(double, double)>[sommets.first];
  for (var i = 1; i < sommets.length; i++) {
    final (x0, y0) = sommets[i - 1];
    final (x1, y1) = sommets[i];
    final longueur = sqrt(pow(x1 - x0, 2) + pow(y1 - y0, 2));
    final n = max(1, (longueur / pas).ceil());
    for (var k = 1; k <= n; k++) {
      plan.add((x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n));
    }
  }
  return plan;
}

/// Un trace qui passe EXACTEMENT par [plan], sans decoupage : un point du
/// plan repete est un doublon du GPX.
List<TrackPoint> traceDesPoints(List<(double, double)> plan) {
  final points = <TrackPoint>[];
  var cumul = 0.0;
  for (final (x, y) in plan) {
    final p = versDegres(x, y);
    if (points.isNotEmpty) {
      final prec = points.last;
      cumul += GeoUtils.haversineDistance(prec.lat, prec.lng, p.lat, p.lng);
    }
    points.add(
      TrackPoint(lat: p.lat, lng: p.lng, altitude: 0, distanceFromStart: cumul),
    );
  }
  return points;
}

/// Le sommet atteint depuis ([x], [y]) en marchant [metres] au cap [cap]
/// (degres, 0 = nord, 90 = est).
(double, double) auCap(double x, double y, double cap, double metres) =>
    (x + metres * sin(cap * pi / 180), y + metres * cos(cap * pi / 180));

/// UN LACET DE [epingles] EPINGLES separees de [entre] metres sur le trace :
/// des branches alternees aux caps 60 et 300 degres (un virage de 120 degres
/// a chaque epingle), qui montent vers le nord. Rend les sommets, a partir de
/// ([x], [y]), branche d'arrivee comprise.
List<(double, double)> lacet(
  double x,
  double y, {
  int epingles = 5,
  double entre = 80,
}) {
  final sommets = <(double, double)>[];
  var courant = (x, y);
  for (var k = 0; k <= epingles; k++) {
    final cap = k.isEven ? 60.0 : 300.0;
    courant = auCap(courant.$1, courant.$2, cap, entre);
    sommets.add(courant);
  }
  return sommets;
}
