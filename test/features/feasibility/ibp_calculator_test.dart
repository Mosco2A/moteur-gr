import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/ibp_calculator.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';

/// Construit une trace lineaire (meme longitude) de [n] points espaces de
/// [stepMeters] en latitude, avec un gain d'altitude [gainPerStep] par pas.
List<TrackPoint> _linearTrace({
  required int n,
  required double stepMeters,
  required double gainPerStep,
  double startAlt = 0,
}) {
  final dLat = stepMeters / 111320.0; // ~m par degre de latitude
  return List.generate(
    n,
    (i) => TrackPoint(
      lat: 45.0 + i * dLat,
      lng: 6.0,
      elevation: startAlt + i * gainPerStep,
    ),
  );
}

void main() {
  group('IbpCalculator — fonction pure', () {
    test('trace vide ou 1 point -> effort nul, niveau 1', () {
      expect(IbpCalculator.compute(const []).score, 0);
      expect(
        IbpCalculator.compute([
          const TrackPoint(lat: 45, lng: 6, elevation: 0),
        ]).effortLevel,
        1,
      );
    });

    test('distance et denivele coherents avec la trace', () {
      // 21 points, 50 m/pas => ~1000 m. +5 m/pas => +100 m D+.
      final trace = _linearTrace(n: 21, stepMeters: 50, gainPerStep: 5);
      final r = IbpCalculator.compute(trace);
      expect(r.distanceKm, closeTo(1.0, 0.05));
      expect(r.elevationGainM, closeTo(100, 5));
      expect(r.elevationLossM, 0);
    });

    test('une montee raide coute plus qu une montee douce (meme D+)', () {
      // Meme D+ (+200 m) mais concentre sur une distance courte (raide) vs
      // etale sur une distance longue (doux).
      final steep = _linearTrace(n: 11, stepMeters: 20, gainPerStep: 20); // 200m dist, +200m
      final gentle =
          _linearTrace(n: 41, stepMeters: 50, gainPerStep: 5); // 2000m dist, +200m
      final rSteep = IbpCalculator.compute(steep);
      final rGentle = IbpCalculator.compute(gentle);
      expect(rSteep.elevationGainM, closeTo(rGentle.elevationGainM, 5));
      expect(rSteep.score, greaterThan(rGentle.score),
          reason: 'la raideur majore l effort a D+ egal');
    });

    test('la descente coute moins que la montee (meme denivele)', () {
      final up = _linearTrace(n: 21, stepMeters: 50, gainPerStep: 10);
      final down = _linearTrace(
          n: 21, stepMeters: 50, gainPerStep: -10, startAlt: 200);
      final rUp = IbpCalculator.compute(up);
      final rDown = IbpCalculator.compute(down);
      expect(rUp.elevationGainM, closeTo(rDown.elevationLossM, 5));
      expect(rUp.score, greaterThan(rDown.score));
    });

    test('effort croit avec la distance sur du plat', () {
      final short = _linearTrace(n: 11, stepMeters: 50, gainPerStep: 0);
      final long = _linearTrace(n: 101, stepMeters: 50, gainPerStep: 0);
      expect(IbpCalculator.compute(long).score,
          greaterThan(IbpCalculator.compute(short).score));
    });

    test('niveau croit avec l effort (barème standard)', () {
      final easy = _linearTrace(n: 11, stepMeters: 50, gainPerStep: 0); // court plat
      final hard = _linearTrace(n: 201, stepMeters: 50, gainPerStep: 15); // long + raide
      final le = IbpCalculator.compute(easy).effortLevel;
      final lh = IbpCalculator.compute(hard).effortLevel;
      expect(le, lessThan(lh));
      expect(le, inInclusiveRange(1, 5));
      expect(lh, inInclusiveRange(1, 5));
    });
  });

  group('IbpBareme — barème externalise', () {
    test('mapping score -> niveau (bornes superieures)', () {
      const b = IbpBareme.standard; // [25, 50, 90, 130]
      expect(b.levelFor(0), 1);
      expect(b.levelFor(25), 1);
      expect(b.levelFor(26), 2);
      expect(b.levelFor(50), 2);
      expect(b.levelFor(90), 3);
      expect(b.levelFor(120), 4);
      expect(b.levelFor(200), 5);
    });

    test('JSON round-trip', () {
      const b = IbpBareme([10, 40, 80, 150]);
      final restored = IbpBareme.fromJson(b.toJson());
      expect(restored.thresholds, b.thresholds);
      expect(restored.levelFor(45), 3);
    });

    test('JSON invalide -> barème standard', () {
      expect(IbpBareme.fromJson(const {'thresholds': [1, 2]}).thresholds,
          IbpBareme.standard.thresholds);
      expect(IbpBareme.fromJson(const {}).thresholds,
          IbpBareme.standard.thresholds);
    });

    test('barème custom applique par compute', () {
      final trace = _linearTrace(n: 41, stepMeters: 50, gainPerStep: 5);
      final strict = IbpCalculator.compute(trace,
          bareme: const IbpBareme([1, 2, 3, 4]));
      // Barème tres bas -> tout devient niveau max.
      expect(strict.effortLevel, 5);
    });
  });
}
