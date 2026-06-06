import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/features/group/services/group_sync_service.dart';

/// Tests du GroupSyncService (E4.12b) — batch 1h + push refuge wifi.
/// Fixtures neutres (coordonnees alpines fictives).
void main() {
  late GroupSyncService svc;
  late ConnectivityMonitor monitor;

  setUp(() {
    monitor = ConnectivityMonitor();
    svc = GroupSyncService(
      firebaseService: FirebaseService.testOnly(isAvailable: false),
      connectivityMonitor: monitor,
    );
  });

  tearDown(() => svc.dispose());

  group('mode hourly', () {
    test('batch accumule les positions et ne demarre pas sans Firebase', () {
      // Firebase indisponible => start n active pas le service
      svc.start(sessionId: 'sess-001', mode: GroupSyncModeValues.hourly);
      expect(svc.isRunning, isFalse);

      // recordPosition fonctionne quand meme (buffer local)
      svc.recordPosition(lat: 45.83, lng: 6.86, stageId: 'e1');
      svc.recordPosition(lat: 45.84, lng: 6.87);
      svc.recordPosition(lat: 45.85, lng: 6.88, stageId: 'e2');

      expect(svc.pendingPositions.length, 3);
      expect(svc.pendingPositions[0].lat, 45.83);
      expect(svc.pendingPositions[0].stageId, 'e1');
      expect(svc.pendingPositions[2].stageId, 'e2');
      expect(svc.mode, GroupSyncModeValues.hourly);

      // forceFlush ne crash pas meme sans Firebase
      expectLater(svc.forceFlush(), completes);
    });

    test('stop vide le buffer et reset le service', () {
      svc.recordPosition(lat: 45.83, lng: 6.86);
      svc.recordPosition(lat: 45.84, lng: 6.87);
      expect(svc.pendingPositions.length, 2);

      svc.stop();
      expect(svc.pendingPositions, isEmpty);
      expect(svc.isRunning, isFalse);
    });

    test('mode inconnu retombe sur hourly (String extensible)', () {
      svc.start(sessionId: 'sess-003', mode: 'mode-futur');
      expect(svc.mode, GroupSyncModeValues.hourly);
    });
  });

  group('mode refuge', () {
    test('push seulement au wifi — buffer intact sans wifi', () {
      // Firebase indisponible => start n active pas
      svc.start(sessionId: 'sess-002', mode: GroupSyncModeValues.refuge);
      expect(svc.isRunning, isFalse);
      expect(svc.mode, GroupSyncModeValues.refuge);

      // Buffer accumule les positions meme sans service actif
      svc.recordPosition(lat: 45.90, lng: 6.90, stageId: 'refuge-01');
      svc.recordPosition(lat: 45.91, lng: 6.91);

      expect(svc.pendingPositions.length, 2);
      expect(svc.pendingPositions[0].stageId, 'refuge-01');

      // Le buffer reste intact car pas de wifi pour flush
      // (Firebase indisponible, donc meme forceFlush ne vide pas)
      svc.forceFlush();
      expect(svc.pendingPositions.length, 2);
    });

    test('PendingGroupPosition toJson contient les champs attendus', () {
      final pos = PendingGroupPosition(
        lat: 45.83,
        lng: 6.86,
        timestamp: DateTime(2026, 6, 1, 12, 0),
        stageId: 'e3',
      );

      final json = pos.toJson();
      expect(json['lat'], 45.83);
      expect(json['lng'], 6.86);
      expect(json['stageId'], 'e3');
      expect(json['timestamp'], contains('2026-06-01'));
    });
  });
}
