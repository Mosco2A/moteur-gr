import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../error/error_handler.dart';

/// Service de lecture de la frequence cardiaque via une ceinture BLE standard
/// (F6F-02, Phase 6) — GATT Heart Rate Service, EN FLUTTER PUR (aucune app
/// montre).
///
/// Interop multi-marques (Polar / Wahoo / Garmin HRM...) via le profil
/// Bluetooth SIG standard :
/// - Heart Rate Service : UUID 0x180D ([heartRateServiceUuid]).
/// - Heart Rate Measurement characteristic : UUID 0x2A37
///   ([heartRateMeasurementUuid]), notifiee.
///
/// La FC est une donnee de SANTE (art. 9 RGPD) : ce service ne fait que LIRE
/// apres consentement explicite gere au niveau UX (design Securite D4).
///
/// Permissions a declarer :
/// - Android 12+ : `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (AndroidManifest).
/// - iOS : `NSBluetoothAlwaysUsageDescription` (Info.plist).
///
/// ZERO catch silencieux — toute erreur est loggee via [ErrorHandler].
class HeartRateBleService {
  HeartRateBleService();

  /// Heart Rate Service (GATT) — UUID court 0x180D.
  static final Guid heartRateServiceUuid = Guid('0000180d-0000-1000-8000-00805f9b34fb');

  /// Heart Rate Measurement characteristic — UUID court 0x2A37.
  static final Guid heartRateMeasurementUuid =
      Guid('00002a37-0000-1000-8000-00805f9b34fb');

  StreamSubscription<List<int>>? _measurementSub;
  BluetoothDevice? _device;

  /// Decode une trame Heart Rate Measurement (0x2A37) en BPM.
  ///
  /// Format Bluetooth SIG : l'octet 0 porte les flags. Le bit 0 indique le
  /// format de la valeur de FC :
  /// - 0 -> UINT8 : la FC est dans l'octet 1.
  /// - 1 -> UINT16 (little-endian) : la FC est dans les octets 1 (LSB) et 2
  ///        (MSB).
  ///
  /// Retourne null si la trame est trop courte / invalide. Fonction PURE
  /// (sans effet de bord) — directement testable.
  static int? parseHeartRate(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final flags = bytes[0];
    final is16Bit = (flags & 0x01) == 0x01;
    if (is16Bit) {
      if (bytes.length < 3) return null;
      // Little-endian : LSB en [1], MSB en [2].
      return bytes[1] | (bytes[2] << 8);
    }
    if (bytes.length < 2) return null;
    return bytes[1];
  }

  /// Scanne les peripheriques exposant le Heart Rate Service (0x180D).
  ///
  /// Emet la liste des resultats de scan filtres sur le service HR.
  Stream<List<ScanResult>> scanForHeartRateBelts({
    Duration timeout = const Duration(seconds: 15),
  }) {
    try {
      // Filtre cote plateforme sur le service HR pour limiter le bruit/conso.
      FlutterBluePlus.startScan(
        withServices: [heartRateServiceUuid],
        timeout: timeout,
      );
      return FlutterBluePlus.scanResults;
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st,
          context: 'HeartRateBleService.scanForHeartRateBelts');
      rethrow;
    }
  }

  /// Arrete le scan en cours.
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'HeartRateBleService.stopScan');
      rethrow;
    }
  }

  /// Se connecte a une [device] (ceinture), souscrit a la characteristic
  /// Heart Rate Measurement (0x2A37) et expose un flux de BPM decode.
  ///
  /// Gere la reconnexion via [BluetoothDevice.connect] (autoConnect) cote
  /// plateforme. ZERO catch silencieux.
  Future<Stream<int>> connectAndListen(BluetoothDevice device) async {
    try {
      _device = device;
      await device.connect();
      final services = await device.discoverServices();
      final hrService = services.firstWhere(
        (s) => s.serviceUuid == heartRateServiceUuid,
        orElse: () => throw StateError(
          'Service Heart Rate (0x180D) absent du peripherique',
        ),
      );
      final measurement = hrService.characteristics.firstWhere(
        (c) => c.characteristicUuid == heartRateMeasurementUuid,
        orElse: () => throw StateError(
          'Characteristic Heart Rate Measurement (0x2A37) absente',
        ),
      );

      final controller = StreamController<int>();
      await measurement.setNotifyValue(true);
      _measurementSub = measurement.lastValueStream.listen(
        (value) {
          final bpm = parseHeartRate(value);
          if (bpm != null && !controller.isClosed) {
            controller.add(bpm);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          ErrorHandler.log(error,
              stackTrace: stackTrace,
              context: 'HeartRateBleService.connectAndListen');
          if (!controller.isClosed) controller.addError(error, stackTrace);
        },
      );
      controller.onCancel = () async {
        await _measurementSub?.cancel();
      };
      return controller.stream;
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'HeartRateBleService.connectAndListen');
      rethrow;
    }
  }

  /// Deconnecte la ceinture et libere les ressources.
  Future<void> disconnect() async {
    try {
      await _measurementSub?.cancel();
      _measurementSub = null;
      await _device?.disconnect();
      _device = null;
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'HeartRateBleService.disconnect');
      rethrow;
    }
  }
}
