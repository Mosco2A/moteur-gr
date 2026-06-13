import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:moteur_gr/core/services/sensor_fusion_service.dart';

void main() {
  group('SensorFusionService.pressureToAltitude (fonction pure)', () {
    test('pression de reference -> altitude relative ~0 m', () {
      final h = SensorFusionService.pressureToAltitude(1013.25, 1013.25);
      expect(h, closeTo(0, 0.001));
    });

    test('1013.25 hPa depuis le niveau mer -> ~0 m', () {
      final h = SensorFusionService.pressureToAltitude(
        1013.25,
        SensorFusionService.seaLevelPressureHPa,
      );
      expect(h, closeTo(0, 0.5));
    });

    test('~899 hPa depuis le niveau mer -> ~1000 m (+/-15 m)', () {
      // ~899 hPa correspond a ~1000 m en atmosphere standard.
      final h = SensorFusionService.pressureToAltitude(
        898.76,
        SensorFusionService.seaLevelPressureHPa,
      );
      expect(h, closeTo(1000, 15));
    });

    test('pression plus basse -> altitude plus haute (monotone)', () {
      final bas = SensorFusionService.pressureToAltitude(1013.25, 1013.25);
      final haut = SensorFusionService.pressureToAltitude(950.0, 1013.25);
      expect(haut, greaterThan(bas));
    });

    test('reference 950 hPa : meme pression -> 0 m (relatif a la reference)', () {
      final h = SensorFusionService.pressureToAltitude(950.0, 950.0);
      expect(h, closeTo(0, 0.001));
    });

    test('pression non physique (<=0) ne renvoie pas NaN/Infinity', () {
      final h = SensorFusionService.pressureToAltitude(0, 1013.25);
      expect(h.isFinite, isTrue);
    });
  });

  group('SensorFusionService.altitudeRelativeStream (barometre + calibration)',
      () {
    test('1er echantillon -> 0 m (origine), puis altitude relative', () async {
      final baro = StreamController<BarometerEvent>();
      final service = SensorFusionService(
        barometerStream: () => baro.stream,
      );

      final future = service.altitudeRelativeStream().take(2).toList();

      baro.add(BarometerEvent(1013.25, DateTime.now())); // reference -> 0 m
      baro.add(BarometerEvent(1000.0, DateTime.now())); // plus bas -> >0 m
      await baro.close();

      final values = await future;
      expect(values[0], closeTo(0, 0.001));
      expect(values[1], greaterThan(0));
    });

    test('recalibrate(GPS) translate l altitude relative sur l altitude GPS',
        () async {
      final baro = StreamController<BarometerEvent>();
      final service = SensorFusionService(
        barometerStream: () => baro.stream,
      );
      // Recalage AVANT toute donnee barometre : origine = 800 m (altitude GPS).
      service.recalibrate(800);

      final future = service.altitudeRelativeStream().first;
      baro.add(BarometerEvent(1013.25, DateTime.now()));
      await baro.close();

      final value = await future;
      // Reference barometre = 1013.25 -> relatif 0 m + offset 800 m = 800 m.
      expect(value, closeTo(800, 0.001));
    });

    test('barometre absent sous le timeout -> fallback altitude GPS', () async {
      final baro = StreamController<BarometerEvent>();
      final service = SensorFusionService(
        barometerStream: () => baro.stream,
        barometerProbeTimeout: const Duration(milliseconds: 30),
      );
      service.pushGpsAltitude(1234);

      final value = await service.altitudeRelativeStream().first;
      expect(value, closeTo(1234, 0.001));
      await baro.close();
    });
  });

  group('SensorFusionService.stepCountStream (podometre)', () {
    test('expose le nombre de pas cumule', () async {
      final steps = StreamController<int>();
      final service = SensorFusionService(
        stepCountStream: () => steps.stream,
      );

      final future = service.stepCountStream().take(2).toList();
      steps.add(10);
      steps.add(25);
      await steps.close();

      final values = await future;
      expect(values, equals([10, 25]));
    });
  });
}
