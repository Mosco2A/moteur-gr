// Test miroir de `lib/features/trek/domain/longueur_de_pas.dart` (lot
// 671-02) : le decoupage de la marche en intervalles, et la forme stockee.
// Le garde-fou, la moyenne et la persistance sont prouves dans
// `test/comportement/longueur_de_pas_671_test.dart`.
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/longueur_de_pas.dart';

void main() {
  group('671-02 — le decoupage en intervalles', () {
    test('le premier point ne ferme aucun intervalle', () {
      final c = StrideCalibrator(StrideCalibration());
      expect(c.observe(distanceFromStartMeters: 0, steps: 0), isNull);
    });

    test('un intervalle trop court garde son point de depart et grandit '
        'jusqu a 50 m', () {
      final c = StrideCalibrator(StrideCalibration());
      c.observe(distanceFromStartMeters: 100, steps: 1000);
      final StrideOutcome? court = c.observe(
        distanceFromStartMeters: 130,
        steps: 1043,
      );
      expect(court?.rejection, StrideRejection.tooShort);
      final assez = c.observe(distanceFromStartMeters: 170, steps: 1100);
      expect(assez?.accepted, isTrue);
      expect(assez?.intervalMeters, closeTo(0.70, 1e-9));
      expect(c.calibration.meters, closeTo(0.70, 1e-9));
    });

    test('un arret (zero pas) repart du point courant', () {
      final c = StrideCalibrator(StrideCalibration());
      c.observe(distanceFromStartMeters: 0, steps: 500);
      final arret = c.observe(distanceFromStartMeters: 300, steps: 500);
      expect(arret?.rejection, StrideRejection.noSteps);
      final suite = c.observe(distanceFromStartMeters: 370, steps: 600);
      expect(suite?.intervalMeters, closeTo(0.70, 1e-9));
    });

    test('des pas inconnus oublient l intervalle en cours', () {
      final c = StrideCalibrator(StrideCalibration());
      c.observe(distanceFromStartMeters: 0, steps: 500);
      expect(c.observe(distanceFromStartMeters: 200, steps: null), isNull);
      expect(c.observe(distanceFromStartMeters: 400, steps: 900), isNull);
    });
  });

  group('671-02 — la forme stockee et la dispersion', () {
    test('aller-retour par la forme stockee, quatre decimales', () {
      final c = StrideCalibration([0.6812, 0.7]);
      expect(c.toStored(), ['0.6812', '0.7000']);
      expect(StrideCalibration.fromStored(c.toStored()).accepted, c.accepted);
    });

    test('la fenetre ne garde que les cinq dernieres longueurs', () {
      final c = StrideCalibration([0.5, 0.6, 0.7, 0.8, 0.9, 1.0]);
      expect(c.accepted, [0.6, 0.7, 0.8, 0.9, 1.0]);
    });

    test('la dispersion est nulle sous deux longueurs, et rapporte l ecart '
        'extreme a la moyenne au-dela', () {
      expect(StrideCalibration().spreadPercent, isNull);
      expect(StrideCalibration([0.7]).spreadPercent, isNull);
      expect(StrideCalibration([0.6, 0.8]).spreadPercent, closeTo(28.57, 0.01));
    });
  });
}
