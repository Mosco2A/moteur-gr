import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/heart_rate_ble_service.dart';

void main() {
  group('HeartRateBleService.parseHeartRate (decode GATT 0x2A37, pure)', () {
    test('format 8 bits : flags=0x00, FC dans l octet 1', () {
      // flags bit0=0 -> UINT8. FC = 72.
      expect(HeartRateBleService.parseHeartRate([0x00, 72]), 72);
    });

    test('format 8 bits : autre valeur', () {
      expect(HeartRateBleService.parseHeartRate([0x00, 130]), 130);
    });

    test('format 16 bits : flags=0x01, FC little-endian sur 2 octets', () {
      // flags bit0=1 -> UINT16. FC = 300 = 0x012C -> LSB 0x2C, MSB 0x01.
      expect(HeartRateBleService.parseHeartRate([0x01, 0x2C, 0x01]), 300);
    });

    test('format 16 bits : valeur <256 encodee sur 2 octets', () {
      // FC = 80 = 0x0050 -> LSB 0x50, MSB 0x00.
      expect(HeartRateBleService.parseHeartRate([0x01, 0x50, 0x00]), 80);
    });

    test('flags avec d autres bits positionnes mais bit0=0 -> 8 bits', () {
      // flags=0x16 (capteur contact + energie depensee) bit0=0 -> UINT8.
      expect(HeartRateBleService.parseHeartRate([0x16, 65]), 65);
    });

    test('flags avec bit0=1 et autres bits -> 16 bits', () {
      // flags=0x1F, bit0=1 -> UINT16. FC = 0x00C8 = 200.
      expect(HeartRateBleService.parseHeartRate([0x1F, 0xC8, 0x00]), 200);
    });

    test('trame vide -> null', () {
      expect(HeartRateBleService.parseHeartRate([]), isNull);
    });

    test('trame 8 bits trop courte (flags seul) -> null', () {
      expect(HeartRateBleService.parseHeartRate([0x00]), isNull);
    });

    test('trame 16 bits trop courte (1 octet de FC) -> null', () {
      expect(HeartRateBleService.parseHeartRate([0x01, 0x2C]), isNull);
    });
  });

  group('HeartRateBleService — constantes GATT', () {
    test('UUID Heart Rate Service = 0x180D', () {
      expect(
        HeartRateBleService.heartRateServiceUuid.str.toLowerCase(),
        contains('180d'),
      );
    });

    test('UUID Heart Rate Measurement = 0x2A37', () {
      expect(
        HeartRateBleService.heartRateMeasurementUuid.str.toLowerCase(),
        contains('2a37'),
      );
    });
  });
}
