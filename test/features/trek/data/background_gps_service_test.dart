import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';

/// Tests unitaires de la capture GPS de fond FIABILISEE (re-portage socle).
///
/// Couvre les fonctions PURES, testables SANS device : filtre de distance,
/// keep-alive, garde anti-churn, libelle de notification, et le round-trip de
/// serialisation du handshake / tampon de drain. La capture reelle (isolate de
/// fond, foreground service, permissions OEM) exige une validation terrain.
void main() {
  group('bgShouldKeepPosition (filtre de distance)', () {
    test('tout premier point (aucun retenu) -> retenu', () {
      expect(
        bgShouldKeepPosition(
          lastKeptLat: null,
          lastKeptLon: null,
          newLat: 42.0,
          newLon: 9.0,
        ),
        isTrue,
      );
    });

    test('deplacement franc (> seuil) -> retenu', () {
      // ~157 m plus au nord (0.001 deg de latitude ~= 111 m ; 0.0015 ~= 167 m).
      expect(
        bgShouldKeepPosition(
          lastKeptLat: 42.0,
          lastKeptLon: 9.0,
          newLat: 42.0015,
          newLon: 9.0,
        ),
        isTrue,
      );
    });

    test('sur-place (< seuil 12 m par defaut) -> jete', () {
      // ~1.1 m plus au nord (0.00001 deg ~= 1.11 m), sous le seuil de 12 m.
      expect(
        bgShouldKeepPosition(
          lastKeptLat: 42.0,
          lastKeptLon: 9.0,
          newLat: 42.00001,
          newLon: 9.0,
        ),
        isFalse,
      );
    });

    test('seuil personnalise respecte (threshold=5 m)', () {
      // ~3.3 m (0.00003 deg) : jete a 5 m mais retenu si le seuil descend a 2 m.
      expect(
        bgShouldKeepPosition(
          lastKeptLat: 42.0,
          lastKeptLon: 9.0,
          newLat: 42.00003,
          newLon: 9.0,
          threshold: 5,
        ),
        isFalse,
      );
      expect(
        bgShouldKeepPosition(
          lastKeptLat: 42.0,
          lastKeptLon: 9.0,
          newLat: 42.00003,
          newLon: 9.0,
          threshold: 2,
        ),
        isTrue,
      );
    });
  });

  group('bgIsKeepAliveDue (sonde de vie)', () {
    final now = DateTime(2026, 7, 10, 12, 0, 0);

    test('aucun point encore retenu -> du', () {
      expect(bgIsKeepAliveDue(null, now), isTrue);
    });

    test('dernier point recent (< 5 min) -> pas du', () {
      final last = now.subtract(const Duration(minutes: 2));
      expect(bgIsKeepAliveDue(last, now), isFalse);
    });

    test('dernier point ancien (>= 5 min) -> du', () {
      final last = now.subtract(const Duration(minutes: 5));
      expect(bgIsKeepAliveDue(last, now), isTrue);
    });

    test('seuil personnalise (threshold=1 min)', () {
      final last = now.subtract(const Duration(seconds: 90));
      expect(
        bgIsKeepAliveDue(last, now, threshold: const Duration(minutes: 1)),
        isTrue,
      );
    });
  });

  group('bgShouldSubscribe (garde anti-churn)', () {
    test('pas encore abonne -> s-abonner', () {
      expect(bgShouldSubscribe(hasSubscription: false), isTrue);
    });

    test('deja abonne -> NE PAS re-abonner', () {
      expect(bgShouldSubscribe(hasSubscription: true), isFalse);
    });
  });

  group('bgNotificationContent (libelle notif)', () {
    test('aucun fix encore -> en attente', () {
      expect(bgNotificationContent(0, null), '0 pts · en attente');
    });

    test('avec compteur et dernier fix -> N pts + heure', () {
      final at = DateTime(2026, 7, 10, 8, 5, 3);
      expect(bgNotificationContent(42, at), '42 pts · dernier 08:05:03');
    });

    test('heure zero-paddee', () {
      final at = DateTime(2026, 7, 10, 9, 7, 1);
      expect(bgNotificationContent(1, at), '1 pts · dernier 09:07:01');
    });
  });

  group('serialisation handshake / tampon de drain', () {
    test('bgEncodePoint produit toutes les cles attendues', () {
      final ts = DateTime(2026, 7, 10, 12, 30, 15);
      final map = bgEncodePoint(
        id: 'p1',
        sessionId: 's1',
        trailId: 't1',
        latitude: 42.5,
        longitude: 9.1,
        altitude: 1200.0,
        accuracy: 4.2,
        speed: 1.3,
        timestamp: ts,
      );
      expect(map['id'], 'p1');
      expect(map['sessionId'], 's1');
      expect(map['trailId'], 't1');
      expect(map['latitude'], 42.5);
      expect(map['longitude'], 9.1);
      expect(map['altitude'], 1200.0);
      expect(map['accuracy'], 4.2);
      expect(map['speed'], 1.3);
      expect(map['timestamp'], ts.toIso8601String());
    });

    test('BgTrackPoint round-trip toJson/fromJson', () {
      final ts = DateTime(2026, 7, 10, 6, 45, 0);
      final original = BgTrackPoint(
        id: 'abc',
        sessionId: 'sess',
        trailId: 'trail',
        latitude: 41.9,
        longitude: 8.7,
        altitude: 900.5,
        accuracy: 6.0,
        speed: 0.8,
        timestamp: ts,
      );
      final restored = BgTrackPoint.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.sessionId, original.sessionId);
      expect(restored.trailId, original.trailId);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.altitude, original.altitude);
      expect(restored.accuracy, original.accuracy);
      expect(restored.speed, original.speed);
      expect(restored.timestamp, original.timestamp);
    });

    test('BgTrackPoint.fromJson tolere un JSON incomplet (defauts surs)', () {
      final p = BgTrackPoint.fromJson(const <String, dynamic>{'id': 'x'});
      expect(p.id, 'x');
      expect(p.sessionId, '');
      expect(p.trailId, '');
      expect(p.latitude, 0);
      expect(p.longitude, 0);
    });
  });

  group('constantes du socle', () {
    test('seuil batterie basse conserve (partage battery controller)', () {
      expect(kLowBatteryThreshold, 20);
    });

    test('filtre de distance par defaut = 12 m', () {
      expect(kBgMinKeepDistanceMeters, 12.0);
    });

    test('keep-alive par defaut = 5 min', () {
      expect(kBgKeepAliveThreshold, const Duration(minutes: 5));
    });

    test('canal foreground generique (aucun sentier en dur)', () {
      expect(kForegroundChannelId, isNot(contains('gr20')));
      expect(kForegroundChannelId, isNot(contains('corse')));
      expect(kForegroundNotificationId, 9001);
    });
  });
}