import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/debug/emulator_detector.dart';
import 'package:moteur_gr/core/debug/gps_simulator.dart';
import 'package:moteur_gr/core/geo/track_point.dart';

void main() {
  group('EmulatorDetector', () {
    test('detecte un fingerprint emulateur Android (generic/sdk)', () {
      expect(
        EmulatorDetector.detect(fingerprint: 'generic/sdk/generic'),
        isTrue,
      );
      expect(
        EmulatorDetector.detect(fingerprint: 'google/sdk_gphone_x86'),
        isTrue,
      );
      expect(
        EmulatorDetector.detect(
          fingerprint: 'Android/sdk_gphone64_x86_64/emulator64',
        ),
        isTrue,
      );
      expect(EmulatorDetector.detect(fingerprint: 'goldfish'), isTrue);
      expect(EmulatorDetector.detect(fingerprint: 'ranchu'), isTrue);
    });

    test('ne detecte pas un device physique', () {
      expect(
        EmulatorDetector.detect(fingerprint: 'samsung/a52sxq/a52sxq'),
        isFalse,
      );
      expect(
        EmulatorDetector.detect(fingerprint: 'google/raven/raven'),
        isFalse,
      );
      expect(
        EmulatorDetector.detect(fingerprint: 'OnePlus/OnePlus9/OnePlus9'),
        isFalse,
      );
    });
  });

  group('GpsSimulator', () {
    test('emet des positions depuis une liste de points', () async {
      final testPoints = List.generate(
        5,
        (i) => TrackPoint(
          lat: 42.0 + i * 0.01,
          lng: 9.0 + i * 0.01,
          altitude: 1000.0 + i * 100,
          distanceFromStart: i * 500.0,
        ),
      );

      final simulator = GpsSimulator.fromPoints(testPoints);
      expect(simulator.pointCount, equals(5));
      expect(simulator.isRunning, isFalse);

      final received = <TrackPoint>[];
      final subscription = simulator.positionStream.listen(received.add);

      simulator.start(speed: SimulationSpeed.x100);
      expect(simulator.isRunning, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(received.length, equals(5));
      expect(received.first.lat, closeTo(42.0, 0.001));
      expect(received.first.lng, closeTo(9.0, 0.001));
      expect(received.last.lat, closeTo(42.04, 0.001));
      expect(simulator.isRunning, isFalse);

      await subscription.cancel();
      simulator.dispose();
    });

    test('stop arrete la simulation en cours', () async {
      final testPoints = List.generate(
        20,
        (i) => TrackPoint(
          lat: 42.0 + i * 0.001,
          lng: 9.0 + i * 0.001,
          altitude: 1000.0,
          distanceFromStart: i * 100.0,
        ),
      );

      final simulator = GpsSimulator.fromPoints(testPoints);
      final received = <TrackPoint>[];
      final subscription = simulator.positionStream.listen(received.add);

      simulator.start(speed: SimulationSpeed.x10);
      expect(simulator.isRunning, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 350));
      simulator.stop();

      expect(simulator.isRunning, isFalse);
      expect(received.length, greaterThan(0));
      expect(received.length, lessThan(20));

      await subscription.cancel();
      simulator.dispose();
    });
  });
}
