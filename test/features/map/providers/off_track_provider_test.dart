import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/off_track_provider.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';
import 'package:moteur_gr/features/notifications/providers/notification_provider.dart';

/// Espion du service de notifications : compte les show/cancel hors-trace sans
/// toucher au plugin natif. Suffisant pour valider le CABLAGE (transitions ->
/// notification), la logique fine de l'hysteresis etant couverte par le test du
/// detecteur.
class _SpyNotificationService extends NotificationService {
  int shows = 0;
  int cancels = 0;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> showOffTrackAlert({
    required String title,
    required String body,
  }) async {
    shows++;
    lastTitle = title;
    lastBody = body;
  }

  @override
  Future<void> cancelOffTrackAlert() async {
    cancels++;
  }
}

/// Trace de test rectiligne le long d'un meridien (lng constant), pas ~78 m.
/// S'ecarter en longitude = distance perpendiculaire quasi pure.
List<TrackPoint> _straightTrack() => List.generate(
      60,
      (i) => TrackPoint(
        lat: 42.0 + i * 0.0007,
        lng: 9.0,
        altitude: 500,
        distanceFromStart: i * 78.0,
      ),
    );

/// Position a [meters] metres a l'EST du trace (approx : 1 deg lng ~ 82.6 km a
/// 42 deg de latitude -> on decale la longitude pour obtenir l'ecart voulu).
Position _posOffsetEast(double meters) {
  const metersPerDegLng = 111320.0 * 0.743; // cos(42 deg) ~ 0.743
  final dLng = meters / metersPerDegLng;
  return Position(
    latitude: 42.021, // ~ milieu du trace
    longitude: 9.0 + dLng,
    timestamp: DateTime(2026, 1, 1),
    accuracy: 5,
    altitude: 500,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<Position> gps;
  late _SpyNotificationService spy;
  late ProviderContainer container;

  setUp(() {
    gps = StreamController<Position>.broadcast();
    spy = _SpyNotificationService();
    container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        // Trace pleine resolution prete (synchrone) pour l'id du sentier test.
        gpxTrackProvider(testTrailConfig.id)
            .overrideWith((ref) async => _straightTrack()),
        // Flux GPS controle par le test.
        offTrackGpsStreamProvider.overrideWithValue(gps.stream),
        notificationServiceProvider.overrideWithValue(spy),
      ],
    );
    addTearDown(() {
      container.dispose();
      gps.close();
    });
  });

  /// Attend que le FutureProvider du trace soit resolu (value != null),
  /// puis (re)lit offTrackProvider pour declencher startListening.
  Future<void> primeTrack() async {
    await container.read(gpxTrackProvider(testTrailConfig.id).future);
    container.read(offTrackProvider); // instancie le notifier + startListening
  }

  test('reglage offTrackAlerts ON par defaut', () {
    expect(
      container.read(notificationSettingsProvider).offTrackAlerts,
      isTrue,
    );
  });

  test('SORTIE puis RETOUR : 1 notification affichee, 1 levee', () async {
    // Le retour haptique n'existe pas en test : on avale l'appel plateforme.
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);

    await primeTrack();

    // Sur le trace (0 m) : aucune alerte.
    gps.add(_posOffsetEast(0));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(offTrackProvider).isOffTrack, isFalse);
    expect(spy.shows, 0);

    // Sortie franche (~120 m > 80) : UNE notification.
    gps.add(_posOffsetEast(120));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(offTrackProvider).isOffTrack, isTrue);
    expect(spy.shows, 1);
    expect(spy.lastTitle, isNotNull);

    // Toujours loin (~150 m) : pas de nouvelle notification (UNE seule).
    gps.add(_posOffsetEast(150));
    await Future<void>.delayed(Duration.zero);
    expect(spy.shows, 1);

    // Retour franc (~20 m < 50) : la notification se leve.
    gps.add(_posOffsetEast(20));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(offTrackProvider).isOffTrack, isFalse);
    expect(spy.cancels, 1);
  });

  test('alerte desactivee : aucune surveillance, aucune notification', () async {
    container.read(notificationSettingsProvider.notifier)
        .toggleOffTrackAlerts(false);
    await primeTrack();

    gps.add(_posOffsetEast(200)); // tres loin
    await Future<void>.delayed(Duration.zero);

    expect(container.read(offTrackProvider).isOffTrack, isFalse);
    expect(spy.shows, 0);
  });

  test('libelles de notification injectables (i18n) via le provider messages',
      () async {
    container.read(offTrackMessagesProvider.notifier).setMessages(
          OffTrackMessages(
            notifTitle: 'TITRE-TEST',
            notifBody: (m) => 'CORPS-TEST $m',
          ),
        );
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);

    await primeTrack();
    gps.add(_posOffsetEast(120));
    await Future<void>.delayed(Duration.zero);

    expect(spy.lastTitle, 'TITRE-TEST');
    expect(spy.lastBody, startsWith('CORPS-TEST'));
  });
}
