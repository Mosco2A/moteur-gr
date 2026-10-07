/// LE TRACE PASSE A L'ISOLATE DE FOND (lot 671-03) : sous une forme reduite,
/// par le canal des preferences partagees, celui du profil GPS (lot 671-00) et
/// du podometre (lot 671-02).
///
/// POURQUOI L'ISOLATE DE FOND ESTIME, ET POURQUOI IL LUI FAUT LE TRACE. C'est
/// lui qui reste eveille ecran eteint, qui recoit les pas et qui ecrit le
/// journal de mesure : le champ 8 d'une ligne `releve` (l'ecart au dernier
/// estime) ne peut s'ecrire qu'au moment du releve, la ou il est pris. Or le
/// trace est charge cote interface (la base Drift n'est pas partageable entre
/// isolates). On le lui passe donc, reduit a ce dont l'avance a besoin : les
/// coordonnees, l'altitude et la distance cumulee de chaque point.
///
/// CE QUE CA PESE, MESURE PAR `trace_de_fond_test.dart` : 1 561 octets pour
/// le sentier reel du depot (Mare a Mare Centre, 53 points, 72,9 km), soit
/// 29,5 octets par point ; un trace dense de 25 km a un point tous les 10 m
/// (2 501 points) pese 86 203 octets (84,2 ko). Ecrit UNE fois par trace,
/// relu a chaque releve des profils batterie (toutes les 3 ou 15 minutes),
/// jamais a chaque pas. LE COUT A CONNAITRE : l'isolate de fond relit TOUT le
/// fichier des preferences a chaque point tamponne ; un trace de plusieurs
/// centaines de ko y alourdirait chaque relecture, et un fichier a part
/// deviendrait alors la meilleure place.
///
/// UN SEUL ECRIVAIN : l'interface, seule a connaitre le trace et le sens de la
/// marche. L'isolate de fond le relit et l'ignore s'il ne porte pas le sentier
/// qu'il suit.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/geo/trace_point.dart';
import '../../../core/geo/track_projection.dart';

/// La cle du trace reduit dans les preferences partagees.
const String kPrefsBgTrace = 'bg_gps_trace';

/// Le trace tel que l'isolate de fond le recoit : le sentier qu'il porte, ses
/// points, et le sens de la marche que le trek connait (le sens de repli de
/// l'estime avant son deuxieme releve).
typedef BackgroundTrace = ({
  String trailId,
  List<TrackPoint> points,
  WalkDirection direction,
});

/// La forme rangee : un objet JSON, un tableau `[lat, lng, alt, distance]`
/// par point, six decimales de degre (11 cm), un decimetre d'altitude et de
/// distance.
String encodeBackgroundTrace(BackgroundTrace trace) => jsonEncode({
  'trailId': trace.trailId,
  'direction': trace.direction.name,
  'points': [
    for (final p in trace.points)
      [
        _round(p.lat, 6),
        _round(p.lng, 6),
        _round(p.altitude, 1),
        _round(p.distanceFromStart, 1),
      ],
  ],
});

/// LECTURE TOLERANTE, sur le motif de `PositionProfile.fromStored` : une
/// valeur absente, illisible, ou un trace de moins de deux points rend nul, et
/// l'estime n'a alors pas de rail. Ne leve jamais.
BackgroundTrace? decodeBackgroundTrace(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final points = <TrackPoint>[
      for (final p in json['points'] as List<dynamic>)
        TrackPoint(
          lat: ((p as List<dynamic>)[0] as num).toDouble(),
          lng: (p[1] as num).toDouble(),
          altitude: (p[2] as num).toDouble(),
          distanceFromStart: (p[3] as num).toDouble(),
        ),
    ];
    if (points.length < 2) return null;
    return (
      trailId: json['trailId'] as String? ?? '',
      points: points,
      direction: json['direction'] == WalkDirection.decreasing.name
          ? WalkDirection.decreasing
          : WalkDirection.increasing,
    );
  } on Object {
    return null;
  }
}

/// Ecrit [trace] pour l'isolate de fond, s'il a change. Ne leve jamais : sans
/// trace, l'estime n'a pas de rail et le GPS continu reste la regle.
Future<void> publishBackgroundTrace(BackgroundTrace trace) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final encoded = encodeBackgroundTrace(trace);
    if (prefs.getString(kPrefsBgTrace) == encoded) return;
    await prefs.setString(kPrefsBgTrace, encoded);
  } on Object {
    // Une ecriture perdue : l'isolate de fond garde le trace precedent ou
    // n'estime pas. Le suivi GPS n'en depend pas.
  }
}

double _round(double value, int decimals) =>
    double.parse(value.toStringAsFixed(decimals));
