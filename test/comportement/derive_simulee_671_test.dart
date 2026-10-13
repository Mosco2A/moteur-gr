import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';
import 'package:moteur_gr/features/trek/data/calibration_du_pas.dart';
import 'package:moteur_gr/features/trek/data/estime_de_fond.dart';
import 'package:moteur_gr/features/trek/data/measure_recorder.dart';
import 'package:moteur_gr/features/trek/data/podometre_preferences.dart';
import 'package:moteur_gr/features/trek/data/trace_de_fond.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LOT 671-03 — LA MESURE DE DERIVE SIMULEE. C'EST LE CHIFFRE D'ACCEPTATION
/// DU LOT : ELLE REMPLACE LA MARCHE DE DEUX HEURES QUE PERSONNE NE FERA.
///
/// LE BANC. Un trace CONNU fabrique ici (une portion droite de 2 500 m, un
/// virage serre en epingle de 15 m de rayon, une portion de retour de 2 500 m
/// qui porte deux points dupliques), une FAUSSE HORLOGE qui avance de 3
/// minutes entre deux releves, un FAUX FLUX DE PAS engendre a partir d'une
/// longueur de pas VRAIE choisie ici alors que le code croit a la longueur
/// CALIBREE du point de calibration (lot 671-02), et un FAUX FOURNISSEUR DE
/// POSITION qui rend la position REELLEMENT atteinte sur le trace — calculee
/// ici par interpolation sur le grand cercle, independamment du code. Aucun
/// capteur, aucun temps reel, aucune mise en sommeil.
///
/// LA MESURE. A chaque releve, l'erreur est la distance LE LONG DU TRACE entre
/// le dernier point estime et le releve reel projete ; c'est le CHAMP 8 du
/// journal, lu ici dans le fichier que le vrai enregistreur ecrit : le test et
/// le journal mesurent LA MEME CHOSE. L'erreur par kilometre est cette erreur
/// divisee par la distance parcourue dans l'intervalle.
///
/// LE SEUIL : SOUS 30 METRES PAR KILOMETRE. LA DERIVE PAR KILOMETRE EST
/// L'ERREUR RELATIVE DE LA LONGUEUR DE PAS, exprimee en metres par kilometre :
/// 3 % valent 30 m/km. Les erreurs de longueur de pas publiees vont de 1 a 7 %,
/// l'erreur de distance moyenne mesuree vaut 2,6 % plus ou moins 1,3 %.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Le seuil d'acceptation, en metres par kilometre (3 % de pas).
  const kDriftThresholdMetersPerKm = 30.0;

  /// LA MARGE DE LA MACHINERIE : ce que l'interpolation, la projection, le
  /// trace reduit et le comptage entier des pas ont le droit d'ajouter a
  /// l'erreur de la longueur de pas. Quelques metres par kilometre au plus.
  const kMachineryMarginMetersPerKm = 2.0;

  /// L'erreur de longueur de pas MOYENNE publiee (2,6 %), le cas courant.
  const kInjectedStrideError = 0.026;

  /// La longueur de pas VRAIE du banc : 0,80 m, soit exactement 250 pas pour
  /// les 200 m d'un intervalle de 3 minutes a 4 km/h.
  const trueStride = 0.80;

  final track = _benchTrack();
  final total = track.last.distanceFromStart;

  test(
    'le banc : un trace connu au metre, droit, en epingle, avec doublons',
    () {
      // ignore: avoid_print
      print(
        'BANC trace : ${track.length} points, longueur totale '
        '${total.toStringAsFixed(1)} m',
      );
      expect(total, closeTo(5047.1, 0.5));
      final duplicates = [
        for (var i = 1; i < track.length; i++)
          if (track[i].distanceFromStart == track[i - 1].distanceFromStart) i,
      ];
      expect(duplicates, hasLength(2));
    },
  );

  test(
    '(i) LA MACHINERIE N AJOUTE RIEN A L ERREUR DE LA LONGUEUR DE PAS : '
    '3 % injectes valent 30 m/km, a la marge de la machinerie pres',
    () async {
      final r = await _runBench(track, trueStride, trueStride * 1.03);
      final perKm = r.perKm;
      final margin = perKm.map((v) => (v - 30).abs()).reduce(math.max);
      // ignore: avoid_print
      print(
        'DERIVE (i) 3 % injectes : moyenne ${_mean(perKm).toStringAsFixed(2)} '
        'm/km, ecart max a 30 : ${margin.toStringAsFixed(3)} m/km',
      );
      expect(perKm, hasLength(20));
      expect(margin, lessThan(kMachineryMarginMetersPerKm));
    },
  );

  test('a l erreur moyenne publiee (2,6 %), la derive est SOUS LE SEUIL de '
      '$kDriftThresholdMetersPerKm m/km a chaque releve', () async {
    final r = await _runBench(
      track,
      trueStride,
      trueStride * (1 + kInjectedStrideError),
    );
    final worst = r.perKm.reduce(math.max);
    // ignore: avoid_print
    print(
      'DERIVE ${(kInjectedStrideError * 100).toStringAsFixed(1)} % injectes : '
      'max ${worst.toStringAsFixed(2)} m/km',
    );
    expect(
      worst,
      lessThan(kDriftThresholdMetersPerKm),
      reason:
          'la derive mesuree vaut ${worst.toStringAsFixed(1)} m/km, au-dessus '
          'du seuil de $kDriftThresholdMetersPerKm m/km',
    );
  });

  test('(ii) LA DERIVE NE S ACCUMULE PAS : vingt releves, une heure de '
      'marche, l erreur reste celle d UN intervalle', () async {
    final r = await _runBench(track, trueStride, trueStride * 1.03);
    final worst = r.driftMeters.reduce(math.max);
    // Une accumulation naive : une seule estime depuis le depart, sans aucun
    // recalage, sur la meme heure.
    final walked = r.walkedMeters;
    final naive = walked * 1.03 - walked;
    // ignore: avoid_print
    print(
      'DERIVE (ii) sur ${r.driftMeters.length} releves '
      '(${walked.toStringAsFixed(0)} m) : erreur instantanee max '
      '${worst.toStringAsFixed(2)} m ; accumulation naive '
      '${naive.toStringAsFixed(1)} m',
    );
    expect(r.driftMeters, hasLength(20));
    expect(worst, lessThan(200 * 0.03 + 0.5));
    expect(naive, greaterThan(15 * worst));
  });

  test('(iii) LA CALIBRATION CONVERGE : de 0,75 m par defaut vers une vraie '
      'longueur de 0,85 m, la derive passe sous le seuil', () async {
    final r = await _runBench(track, 0.85, null, calibrate: true);
    final firstUnder = r.perKm.indexWhere(
      (v) => v < kDriftThresholdMetersPerKm,
    );
    // ignore: avoid_print
    print(
      'DERIVE (iii) calibration : premier intervalle '
      '${r.perKm.first.toStringAsFixed(1)} m/km, puis '
      '${r.perKm.skip(1).take(3).map((v) => v.toStringAsFixed(1)).join(' / ')}'
      ' m/km ; sous le seuil a partir du releve ${firstUnder + 1}',
    );
    expect(r.perKm.first, greaterThan(100));
    expect(firstUnder, greaterThan(0));
    expect(
      r.perKm.skip(firstUnder).every((v) => v < kDriftThresholdMetersPerKm),
      isTrue,
    );
  });

  test(
    'LE CAS DEFAVORABLE, SANS MAQUILLAGE : 7 % de pas valent 70 m/km, '
    'AU-DESSUS du seuil — c est pour cela que la calibration existe',
    () async {
      final r = await _runBench(track, trueStride, trueStride * 1.07);
      final mean = _mean(r.perKm);
      // ignore: avoid_print
      print(
        'DERIVE 7 % injectes : ${mean.toStringAsFixed(2)} m/km (NON CONFORME)',
      );
      expect(mean, closeTo(70, kMachineryMarginMetersPerKm));
      expect(mean, greaterThan(kDriftThresholdMetersPerKm));
    },
  );

  test('LE TABLEAU : erreur de longueur de pas injectee, derive mesuree, '
      'verdict face au seuil', () async {
    final rows = <String>[];
    for (final injected in [0.01, 0.026, 0.03, 0.07, 0.13]) {
      final r = await _runBench(track, trueStride, trueStride * (1 + injected));
      final mean = _mean(r.perKm);
      final worst = r.perKm.reduce(math.max);
      final verdict = worst < kDriftThresholdMetersPerKm
          ? 'sous le seuil'
          : (worst - kDriftThresholdMetersPerKm).abs() < 1
          ? 'AU SEUIL'
          : 'AU-DESSUS';
      rows.add(
        '${(injected * 100).toStringAsFixed(1)} % | '
        '${mean.toStringAsFixed(2)} m/km (max ${worst.toStringAsFixed(2)}) | '
        '$verdict',
      );
      expect(
        mean,
        closeTo(injected * 1000, kMachineryMarginMetersPerKm),
        reason: 'la machinerie ajoute a l erreur injectee',
      );
    }
    // ignore: avoid_print
    print('TABLEAU DE DERIVE :\n${rows.join('\n')}');
  });

  test('le journal du banc : des lignes estime a neuf champs et une '
      'precision vide, des releves au champ 8 rempli d une decimale', () async {
    final r = await _runBench(track, trueStride, trueStride * 1.03);
    final releves = r.lines.where((l) => l.split(';')[2] == 'releve').toList();
    final estimes = r.lines.where((l) => l.split(';')[2] == 'estime').toList();
    // ignore: avoid_print
    print(
      'JOURNAL DU BANC (dix lignes reelles) :\n'
      '${releves.skip(1).take(10).join('\n')}\n'
      'et trois lignes estime :\n${estimes.take(3).join('\n')}',
    );
    expect(estimes, isNotEmpty);
    for (final l in estimes) {
      final f = l.split(';');
      expect(f, hasLength(kMeasureEventFieldCount));
      expect(f[6], kMeasureNoValue, reason: 'un point calcule sans precision');
      expect(f[7], kMeasureNoValue);
    }
    expect(releves.first.split(';')[7], kMeasureNoValue);
    for (final l in releves.skip(1)) {
      expect(l.split(';')[7], matches(RegExp(r'^\d+\.\d$')));
    }
    for (final l in r.lines) {
      expect(
        () => MeasureEvent.fromWord(l.split(';')[2]),
        returnsNormally,
        reason: 'aucun mot hors du vocabulaire ferme',
      );
    }
  });
}

double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

/// Ce que rend une heure de marche au banc.
typedef _BenchRun = ({
  List<double> driftMeters,
  List<double> perKm,
  double walkedMeters,
  List<String> lines,
});

/// Le trace du banc : 2 500 m plein nord tous les 20 m, une epingle de 15 m
/// de rayon (12 points), 2 500 m plein sud a 30 m a l'est, avec un doublon au
/// milieu et un doublon en fin.
List<TrackPoint> _benchTrack() {
  const m = 111195.0;
  const lat0 = 42.0;
  const lng0 = 9.0;
  final mPerLng = m * math.cos(lat0 * math.pi / 180);
  final coords = <(double, double)>[];
  for (var i = 0; i <= 125; i++) {
    coords.add((lat0 + i * 20 / m, lng0));
  }
  for (var k = 1; k < 12; k++) {
    final a = math.pi - k * math.pi / 12;
    coords.add((
      lat0 + (2500 + 15 * math.sin(a)) / m,
      lng0 + (15 + 15 * math.cos(a)) / mPerLng,
    ));
  }
  for (var i = 0; i <= 125; i++) {
    final p = (lat0 + (2500 - i * 20) / m, lng0 + 30 / mPerLng);
    coords.add(p);
    if (i == 60 || i == 125) coords.add(p);
  }
  final points = <TrackPoint>[];
  var cumulated = 0.0;
  for (var i = 0; i < coords.length; i++) {
    if (i > 0) {
      cumulated += GeoUtils.haversineDistance(
        coords[i - 1].$1,
        coords[i - 1].$2,
        coords[i].$1,
        coords[i].$2,
      );
    }
    points.add(
      TrackPoint(
        lat: coords[i].$1,
        lng: coords[i].$2,
        altitude: 1000,
        distanceFromStart: cumulated,
      ),
    );
  }
  return points;
}

/// La position REELLEMENT atteinte a [d] m du depart, calculee ICI, sans le
/// code teste : recherche lineaire du segment, puis point intermediaire sur
/// le grand cercle.
({double lat, double lng}) _truePosition(List<TrackPoint> track, double d) {
  var i = 0;
  while (i < track.length - 2 && track[i + 1].distanceFromStart <= d) {
    i++;
  }
  final a = track[i];
  final b = track[i + 1];
  final len = b.distanceFromStart - a.distanceFromStart;
  final f = len <= 0 ? 0.0 : ((d - a.distanceFromStart) / len).clamp(0.0, 1.0);
  double rad(double x) => x * math.pi / 180;
  final p1 = rad(a.lat), l1 = rad(a.lng), p2 = rad(b.lat), l2 = rad(b.lng);
  final delta = len / 6371000.0;
  if (delta == 0) return (lat: a.lat, lng: a.lng);
  final s = math.sin(delta);
  final ka = math.sin((1 - f) * delta) / s;
  final kb = math.sin(f * delta) / s;
  final x = ka * math.cos(p1) * math.cos(l1) + kb * math.cos(p2) * math.cos(l2);
  final y = ka * math.cos(p1) * math.sin(l1) + kb * math.cos(p2) * math.sin(l2);
  final z = ka * math.sin(p1) + kb * math.sin(p2);
  return (
    lat: math.atan2(z, math.sqrt(x * x + y * y)) * 180 / math.pi,
    lng: math.atan2(y, x) * 180 / math.pi,
  );
}

class _NoTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

/// Une heure de marche a 4 km/h, vingt releves a 3 minutes, des paquets de
/// pas toutes les 10 secondes. [codeStride] est la longueur rangee au point
/// de calibration (nulle : la valeur de depart du lot 671-02) ; [calibrate]
/// fait tourner la calibration en marchant de l'interface a chaque releve.
Future<_BenchRun> _runBench(
  List<TrackPoint> track,
  double trueStride,
  double? codeStride, {
  bool calibrate = false,
}) async {
  SharedPreferences.setMockInitialValues({
    if (codeStride != null) kPrefsStrideWindow: [codeStride.toStringAsFixed(4)],
  });
  final dir = await Directory.systemTemp.createTemp('derive_671_');
  final journal = MeasureJournal(directory: () async => dir);
  var now = DateTime(2026, 10, 7, 9);
  final steps = StreamController<int>();
  final store = PodometerStore();
  final feed = StrideCalibrationFeed(store);
  final recorder = MeasureRecorder(
    journal: journal,
    readBattery: () async => 80,
    stepCounts: () => steps.stream,
    stepsAllowed: () async => true,
    podometer: store,
    sessionId: () => 'banc',
    estimate: BackgroundEstimate(
      readTrace: () async => encodeBackgroundTrace((
        trailId: 'banc',
        points: track,
        direction: WalkDirection.increasing,
      )),
      trailId: () => 'banc',
      keepDistanceMeters: () => 12,
    ),
    schedule: (_, _) => _NoTimer(),
    now: () => now,
  );
  Future<void> settle() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await journal.idle;
  }

  const raw0 = 10000;
  const speed = 4000 / 3600; // m/s
  int stepsAt(double d) => raw0 + (d / trueStride + 1e-9).floor();
  Future<void> fixAt(double d) async {
    final p = _truePosition(track, d);
    if (calibrate) await feed.observe(d);
    await recorder.received(
      Position(
        latitude: p.lat,
        longitude: p.lng,
        timestamp: now,
        accuracy: 4,
        altitude: 1000,
        altitudeAccuracy: 3,
        heading: 0,
        headingAccuracy: 0,
        speed: speed,
        speedAccuracy: 0.5,
      ),
      const Duration(seconds: 5),
    );
    await settle();
  }

  await recorder.started(PositionProfile.batteryFirst);
  steps.add(raw0);
  await settle();
  await fixAt(0);
  var t = 0;
  for (var k = 1; k <= 20; k++) {
    for (var tick = 1; tick <= 18; tick++) {
      t += 10;
      now = now.add(const Duration(seconds: 10));
      steps.add(stepsAt(t * speed));
      await settle();
    }
    await fixAt(t * speed);
  }
  await steps.close();
  final lines = (await (await journal.file()).readAsLines())
      .where((l) => l.isNotEmpty)
      .toList();
  await dir.delete(recursive: true);
  final drifts = [
    for (final l in lines)
      if (l.split(';')[2] == 'releve' && l.split(';')[7] != kMeasureNoValue)
        double.parse(l.split(';')[7]),
  ];
  const intervalMeters = 200.0;
  return (
    driftMeters: drifts,
    perKm: [for (final d in drifts) d / (intervalMeters / 1000)],
    walkedMeters: t * speed,
    lines: lines,
  );
}
