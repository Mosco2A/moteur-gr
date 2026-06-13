import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:moteur_gr/core/services/health_reader_service.dart';

/// Construit un HealthDataPoint numerique de test.
HealthDataPoint _point(HealthDataType type, double value, HealthDataUnit unit) {
  final now = DateTime(2026, 6, 12, 10);
  return HealthDataPoint(
    uuid: 'uuid-${type.name}-$value',
    value: NumericHealthValue(numericValue: value),
    type: type,
    unit: unit,
    dateFrom: now,
    dateTo: now.add(const Duration(minutes: 1)),
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'device-1',
    sourceId: 'src-1',
    sourceName: 'Apple Watch',
  );
}

void main() {
  group('HealthReaderService.aggregate (mapping pur)', () {
    test('somme les pas', () {
      final snap = HealthReaderService.aggregate([
        _point(HealthDataType.STEPS, 1000, HealthDataUnit.COUNT),
        _point(HealthDataType.STEPS, 500, HealthDataUnit.COUNT),
      ]);
      expect(snap.authorized, isTrue);
      expect(snap.steps, 1500);
    });

    test('moyenne la frequence cardiaque', () {
      final snap = HealthReaderService.aggregate([
        _point(HealthDataType.HEART_RATE, 120, HealthDataUnit.BEATS_PER_MINUTE),
        _point(HealthDataType.HEART_RATE, 140, HealthDataUnit.BEATS_PER_MINUTE),
      ]);
      expect(snap.avgHeartRate, closeTo(130, 0.001));
    });

    test('somme distance et calories', () {
      final snap = HealthReaderService.aggregate([
        _point(HealthDataType.DISTANCE_DELTA, 800, HealthDataUnit.METER),
        _point(HealthDataType.DISTANCE_DELTA, 200, HealthDataUnit.METER),
        _point(
            HealthDataType.ACTIVE_ENERGY_BURNED, 50, HealthDataUnit.KILOCALORIE),
      ]);
      expect(snap.distanceMeters, 1000);
      expect(snap.activeCalories, 50);
    });

    test('aucune mesure FC -> avgHeartRate null', () {
      final snap = HealthReaderService.aggregate([
        _point(HealthDataType.STEPS, 10, HealthDataUnit.COUNT),
      ]);
      expect(snap.avgHeartRate, isNull);
    });

    test('liste vide -> snapshot autorise mais a zero', () {
      final snap = HealthReaderService.aggregate([]);
      expect(snap.authorized, isTrue);
      expect(snap.steps, 0);
      expect(snap.distanceMeters, 0);
      expect(snap.avgHeartRate, isNull);
    });

    test('types non geres ignores sans erreur', () {
      final snap = HealthReaderService.aggregate([
        _point(HealthDataType.HEIGHT, 1.8, HealthDataUnit.METER),
        _point(HealthDataType.STEPS, 42, HealthDataUnit.COUNT),
      ]);
      expect(snap.steps, 42);
    });
  });

  group('HealthSnapshot.notAuthorized', () {
    test('etat non autorise expose authorized=false', () {
      const snap = HealthSnapshot.notAuthorized();
      expect(snap.authorized, isFalse);
      expect(snap.steps, 0);
      expect(snap.avgHeartRate, isNull);
    });
  });
}
