import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';
import 'package:moteur_gr/features/trek/data/trace_de_fond.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LOT 671-03 — LE TRACE REDUIT PASSE A L'ISOLATE DE FOND, ET CE QU'IL PESE.
///
/// La voie choisie (l'isolate de fond estime) transporte le trace par les
/// preferences partagees. Ce fichier MESURE ce que ca pese pour le sentier
/// reel du depot et pour un trace dense, et prouve la lecture tolerante.
void main() {
  List<TrackPoint> realTrail() {
    final gpx = File(
      'assets/data/mare_a_mare_centre/track.gpx',
    ).readAsStringSync();
    return GpxParser.parse(gpx).allTrackPoints;
  }

  /// 25 km vers le nord, un point tous les 10 m : un GPX de terrain dense.
  List<TrackPoint> denseTrail() {
    const step = 10.0;
    const dLat = step / 111195.0;
    return [
      for (var i = 0; i <= 2500; i++)
        TrackPoint(
          lat: 42.0 + i * dLat,
          lng: 9.123456,
          altitude: 500 + (i % 300).toDouble(),
          distanceFromStart: i * step,
        ),
    ];
  }

  group('le poids du trace reduit, MESURE', () {
    test('le sentier reel du depot (Mare a Mare Centre)', () {
      final points = realTrail();
      final bytes = utf8
          .encode(
            encodeBackgroundTrace((
              trailId: 'mare-a-mare-centre',
              points: points,
              direction: WalkDirection.increasing,
            )),
          )
          .length;
      // ignore: avoid_print
      print(
        'POIDS MESURE trace reduit Mare a Mare Centre : ${points.length} '
        'points, $bytes octets, '
        '${(bytes / points.length).toStringAsFixed(1)} octets par point, '
        '${(points.last.distanceFromStart / 1000).toStringAsFixed(1)} km',
      );
      // TACHE 761 — LE SENTIER REEL EST DEVENU UN TRACE DENSE. Il comptait 53
      // points pour 4 282 octets ; il en compte 3 590, releves dans
      // OpenStreetMap, pour 124 824 octets (34,8 octets par point). Les 4 ko
      // d avant n etaient pas un budget, c etait la taille d un croquis : un
      // point tous les 1,1 km ne pouvait rien peser. Le budget retenu est donc
      // celui qui etait DEJA justifie plus bas pour un trace dense de terrain,
      // 200 ko, et le sentier reel y entre avec 60 % de marge.
      expect(points.length, 3590);
      expect(bytes, lessThan(200 * 1024));
    });

    test('un trace dense de 25 km a un point tous les 10 m', () {
      final points = denseTrail();
      final bytes = utf8
          .encode(
            encodeBackgroundTrace((
              trailId: 'dense',
              points: points,
              direction: WalkDirection.increasing,
            )),
          )
          .length;
      // ignore: avoid_print
      print(
        'POIDS MESURE trace dense 25 km : ${points.length} points, '
        '$bytes octets (${(bytes / 1024).toStringAsFixed(1)} ko)',
      );
      expect(bytes, lessThan(200 * 1024));
    });
  });

  group('l aller-retour du trace par le canal', () {
    test('le trace se relit tel qu il a ete ecrit, au decimetre', () {
      final points = realTrail();
      final decoded = decodeBackgroundTrace(
        encodeBackgroundTrace((
          trailId: 'mare-a-mare-centre',
          points: points,
          direction: WalkDirection.decreasing,
        )),
      )!;
      expect(decoded.trailId, 'mare-a-mare-centre');
      expect(decoded.direction, WalkDirection.decreasing);
      expect(decoded.points, hasLength(points.length));
      for (var i = 0; i < points.length; i++) {
        final a = points[i];
        final b = decoded.points[i];
        expect(
          GeoUtils.haversineDistance(a.lat, a.lng, b.lat, b.lng),
          lessThan(0.2),
        );
        expect(
          (a.distanceFromStart - b.distanceFromStart).abs(),
          lessThan(0.06),
        );
      }
    });

    test('lecture tolerante : absent, illisible ou trop court rend nul, '
        'sans lever', () {
      expect(decodeBackgroundTrace(null), isNull);
      expect(decodeBackgroundTrace(''), isNull);
      expect(decodeBackgroundTrace('{pas du json'), isNull);
      expect(decodeBackgroundTrace('{"points":[[1,2,3,0]]}'), isNull);
      final noDirection = decodeBackgroundTrace(
        '{"points":[[42,9,0,0],[42.001,9,0,111.2]]}',
      )!;
      expect(noDirection.direction, WalkDirection.increasing);
      expect(noDirection.trailId, '');
    });

    test('la publication ecrit le canal, et ne reecrit pas un trace '
        'inchange', () async {
      SharedPreferences.setMockInitialValues({});
      final trace = (
        trailId: 't',
        points: denseTrail().take(3).toList(),
        direction: WalkDirection.increasing,
      );
      await publishBackgroundTrace(trace);
      final prefs = await SharedPreferences.getInstance();
      final first = prefs.getString(kPrefsBgTrace);
      expect(decodeBackgroundTrace(first)!.points, hasLength(3));
      await publishBackgroundTrace(trace);
      expect(identical(prefs.getString(kPrefsBgTrace), first), isTrue);
    });
  });
}
