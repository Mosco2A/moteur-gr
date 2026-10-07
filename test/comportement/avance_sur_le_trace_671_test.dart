import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/map/providers/current_position_provider.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/off_track_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';
import 'package:moteur_gr/features/notifications/providers/notification_provider.dart';
import 'package:moteur_gr/features/trail/trail_facade.dart' show stagesProvider;
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';
import 'package:moteur_gr/features/trek/data/position_controller.dart';
import 'package:moteur_gr/features/trek/data/repli_gps_continu.dart';
import 'package:moteur_gr/features/trek/providers/live_trek_stats_provider.dart';
import 'package:moteur_gr/features/trek/providers/measure_bench_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LOT 671-03 — LE RECALAGE SUR LE TRACE, PROUVE SANS AUCUN CAPTEUR REEL.
///
/// Faux robinet GPS (le vrai `PositionController`, branche sur un faux flux
/// et de faux tirs), fausse horloge des tirs, faux flux de points estimes,
/// faux trace, fausses preferences, base Drift en memoire. Personne ne
/// marchera avec un telephone : ce que ce lot affirme, il le prouve ici.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const metersPerDegree = 111195.0;
  final track = [
    for (var i = 0; i <= 300; i++)
      TrackPoint(
        lat: 42.0 + i * 10 / metersPerDegree,
        lng: 9.0,
        altitude: 100.0 + i,
        distanceFromStart: i * 10.0,
      ),
  ];

  var clock = DateTime(2026, 10, 7, 9);
  Position fixAt(double meters, {double eastM = 0}) {
    clock = clock.add(const Duration(minutes: 3));
    return Position(
      latitude: 42.0 + meters / metersPerDegree,
      longitude: 9.0 + eastM / (metersPerDegree * 0.7431),
      timestamp: clock,
      accuracy: 5,
      altitude: 100,
      altitudeAccuracy: 3,
      heading: 0,
      headingAccuracy: 0,
      speed: 1.1,
      speedAccuracy: 0.5,
    );
  }

  BgTrackPoint estimateAt(double meters) {
    clock = clock.add(const Duration(seconds: 20));
    return BgTrackPoint(
      id: 'e$meters',
      sessionId: 's',
      trailId: testTrailConfig.id,
      latitude: 42.0 + meters / metersPerDegree,
      longitude: 9.0,
      altitude: 100 + meters / 10,
      accuracy: 0,
      speed: 0,
      timestamp: clock,
      source: TrackPointSource.estimated,
      trackDistanceM: meters,
    );
  }

  /// Le banc d'un test : le vrai controleur GPS sur de faux tirs et un faux
  /// flux, la carte et le hors-trace branches dessus.
  late StreamController<Position> stream;
  late StreamController<BgTrackPoint> estimates;
  late List<(Duration, void Function())> timers;
  late Position nextShot;
  late PositionController controller;
  late _SpyNotifications spy;

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<ProviderContainer> bench(PositionProfile profile) async {
    stream = StreamController<Position>.broadcast();
    estimates = StreamController<BgTrackPoint>.broadcast();
    timers = [];
    spy = _SpyNotifications();
    controller = PositionController(
      positionStream: ({required locationSettings}) => stream.stream,
      currentPosition: ({required locationSettings}) async => nextShot,
      schedule: (d, run) {
        timers.add((d, run));
        return _NoTimer();
      },
    );
    await controller.setProfile(profile);
    final container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        gpxTrackProvider(testTrailConfig.id).overrideWith((ref) async => track),
        stagesProvider(testTrailConfig.id).overrideWith((ref) async => []),
        positionControllerProvider.overrideWithValue(controller),
        gpsPermissionProvider.overrideWith(
          (ref) async => GpsPermissionStateValues.granted,
        ),
        estimatedTrackPointsProvider.overrideWithValue(estimates.stream),
        notificationServiceProvider.overrideWithValue(spy),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await stream.close();
      await estimates.close();
    });
    await container.read(gpxTrackProvider(testTrailConfig.id).future);
    return container;
  }

  /// Le tir suivant du profil de tir : celui que la periode a arme.
  Future<void> nextPeriodicShot(Position fix) async {
    nextShot = fix;
    final armed = timers.lastWhere((t) => t.$1 > const Duration(minutes: 1));
    timers.remove(armed);
    armed.$2();
    await settle();
  }

  TrackPositionState? position(ProviderContainer c) =>
      c.read(trackPositionProvider).value;

  group('(3) le branchement en un seul point', () {
    test('EN PROFIL CARTE, la position courante est la position REELLE, au '
        'metre pres : un point estime qui passe est ignore', () async {
      final c = await bench(PositionProfile.map);
      final sub = c.listen(trackPositionProvider, (_, _) {});
      addTearDown(sub.close);
      await settle();
      final real = fixAt(1000);
      stream.add(real);
      await settle();
      estimates.add(estimateAt(1500));
      await settle();
      final current = c.read(currentPositionProvider).value!;
      expect(current.isEstimated, isFalse);
      expect(current.latitude, real.latitude);
      expect(current.longitude, real.longitude);
      expect(current.accuracy, real.accuracy);
      expect(position(c)!.distanceFromStartM, closeTo(1000, 0.5));
      expect(position(c)!.isEstimated, isFalse);
    });

    test('EN PROFIL BATTERIE D ABORD, entre deux releves la position est '
        'l ESTIME et elle AVANCE ; au releve suivant elle est REMISE a la '
        'position reelle projetee', () async {
      final c = await bench(PositionProfile.batteryFirst);
      nextShot = fixAt(1000);
      final sub = c.listen(trackPositionProvider, (_, _) {});
      addTearDown(sub.close);
      await settle();
      expect(position(c)!.distanceFromStartM, closeTo(1000, 0.5));

      for (final m in [1050.0, 1100.0, 1150.0]) {
        estimates.add(estimateAt(m));
        await settle();
        final p = position(c)!;
        expect(p.isEstimated, isTrue);
        expect(p.distanceFromStartM, closeTo(m, 1e-6));
        expect(p.distanceToTrackM, 0);
      }
      expect(c.read(stageDistanceCoveredProvider), closeTo(1150, 1e-6));

      await nextPeriodicShot(fixAt(1180));
      final p = position(c)!;
      expect(p.isEstimated, isFalse);
      expect(p.distanceFromStartM, closeTo(1180, 0.5));
      // Un estime calcule AVANT ce releve, arrive en retard, est perime.
      estimates.add(
        BgTrackPoint(
          id: 'perime',
          sessionId: 's',
          trailId: testTrailConfig.id,
          latitude: 42.01,
          longitude: 9.0,
          altitude: 100,
          accuracy: 0,
          speed: 0,
          timestamp: clock.subtract(const Duration(minutes: 1)),
          source: TrackPointSource.estimated,
          trackDistanceM: 1170,
        ),
      );
      await settle();
      expect(position(c)!.distanceFromStartM, closeTo(1180, 0.5));
    });

    test('les huit lecteurs de la projection ne lisent plus le flux GPS brut '
        'en direct', () {
      const readers = [
        'lib/features/map/map_facade.dart',
        'lib/features/map/providers/supply_alert_provider.dart',
        'lib/features/map/widgets/stage_poi_checklist.dart',
        'lib/features/trek/presentation/map/map_content.dart',
        'lib/features/trek/presentation/map/map_overlays.dart',
        'lib/features/trek/presentation/map/map_photo_button.dart',
        'lib/features/trek/providers/live_trek_stats_provider.dart',
        'lib/features/map/providers/track_position_provider.dart',
      ];
      final direct = RegExp(r'ref\.(watch|read|listen)\(\s*locationProvider');
      for (final f in readers) {
        final text = File(f).readAsStringSync();
        expect(text, contains('trackPositionProvider'), reason: f);
        expect(direct.hasMatch(text), isFalse, reason: '$f lit le GPS brut');
      }
    });
  });

  group('(5) le hors-trace ne lit que les releves reels', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    });

    test('UNE SORTIE DE SENTIER DE 300 M sur un releve reel declenche '
        'l alerte et fait passer le profil en carte ; le retour sous le '
        'seuil leve l alerte et rend le profil choisi', () async {
      final c = await bench(PositionProfile.batteryFirst);
      nextShot = fixAt(1000);
      final sub = c.listen(trackPositionProvider, (_, _) {});
      addTearDown(sub.close);
      await settle();
      c.read(offTrackProvider);
      await settle();
      estimates.add(estimateAt(1040));
      await settle();
      // Le releve suivant est a 300 m du sentier.
      await nextPeriodicShot(fixAt(1100, eastM: 300));
      // L'estime, lui, continuerait sur le trace, a zero metre.
      estimates.add(estimateAt(1140));
      await settle();

      expect(
        c.read(offTrackProvider).isOffTrack,
        isTrue,
        reason:
            'une sortie de sentier de 300 m n a RIEN declenche : le '
            'detecteur hors-trace ne lit pas les releves reels',
      );
      expect(spy.shows, 1, reason: 'une alerte, une seule');
      expect(position(c)!.isOffTrack, isTrue);

      final fallback = ContinuousGpsFallback(
        apply: c.read(positionProfileChannelProvider),
        chosen: PositionProfile.batteryFirst,
      );
      expect(
        await fallback.observe(
          offTrack: position(c)!.isOffTrack,
          trackLoaded: true,
          estimatePossible: true,
        ),
        ContinuousGpsReason.offTrack,
      );
      expect(controller.profile, PositionProfile.map);
      await settle();
      // Le GPS continu : le flux de la carte, celui du robinet unique.
      stream.add(fixAt(1100, eastM: 10));
      await settle();
      expect(c.read(offTrackProvider).isOffTrack, isFalse);
      expect(spy.cancels, 1);
      expect(position(c)!.isOffTrack, isFalse);
      await fallback.observe(offTrack: position(c)!.isOffTrack);
      expect(controller.profile, PositionProfile.batteryFirst);
    });

    test('une position ESTIMEE, a zero metre du trace par construction, ne '
        'declenche JAMAIS rien', () async {
      final c = await bench(PositionProfile.batteryFirst);
      nextShot = fixAt(1000);
      c.read(offTrackProvider);
      final sub = c.listen(trackPositionProvider, (_, _) {});
      addTearDown(sub.close);
      await settle();
      for (var m = 1010.0; m < 1500; m += 20) {
        estimates.add(estimateAt(m));
        await settle();
      }
      expect(c.read(offTrackProvider).isOffTrack, isFalse);
      expect(spy.shows, 0);
      expect(position(c)!.isOffTrack, isFalse);
    });

    test('il n existe plus que DEUX seuils hors-trace dans lib/ : le '
        'troisieme (100 m) a disparu', () {
      final threshold = RegExp(
        r'(const|final)\s+(double|int)?\s*_?[A-Za-z]*'
        r'([Oo]ffTrack|[Hh]orsTrace)[A-Za-z]*(Threshold|Seuil)[A-Za-z]*\s*=',
      );
      final found = <String>[];
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        for (final line in f.readAsLinesSync()) {
          if (threshold.hasMatch(line)) found.add('${f.path}: ${line.trim()}');
        }
      }
      expect(found, hasLength(2), reason: found.join('\n'));
      expect(found.join('\n'), contains('kOffTrackExitThresholdMeters = 80.0'));
      expect(
        found.join('\n'),
        contains('kOffTrackReturnThresholdMeters = 50.0'),
      );
    });
  });

  group('(6) les sorties de secours passent par le canal, sans flux', () {
    test('le canal change le profil du robinet unique et n ouvre aucun flux '
        'de positions', () async {
      final c = await bench(PositionProfile.batteryFirst);
      expect(controller.hasLiveSubscription, isFalse);
      await c.read(positionProfileChannelProvider)(PositionProfile.map);
      expect(controller.profile, PositionProfile.map);
      // Aucun abonne : aucun flux n'est ouvert par le changement de profil.
      expect(controller.hasLiveSubscription, isFalse);
    });

    test('les fichiers neufs du lot n ouvrent aucun flux et ne nomment aucune '
        'precision du greffon', () {
      const newFiles = [
        'lib/core/geo/track_projection.dart',
        'lib/features/map/providers/current_position_provider.dart',
        'lib/features/trek/data/estime_de_fond.dart',
        'lib/features/trek/data/repli_gps_continu.dart',
        'lib/features/trek/data/trace_de_fond.dart',
        'lib/features/trek/presentation/map/recalage_mount.dart',
      ];
      final forbidden = RegExp(
        r'getPositionStream|getCurrentPosition|LocationAccuracy|'
        r'gyroscope|Gyroscope|listenManual\(\s*positionStreamProvider',
      );
      for (final f in newFiles) {
        expect(
          forbidden.hasMatch(File(f).readAsStringSync()),
          isFalse,
          reason: f,
        );
      }
    });
  });

  group('(4) LES CHIFFRES DU JOUR NE BOUGENT PAS', () {
    test('la distance et le denivele du jour sont IDENTIQUES au metre pres '
        'avec et sans points estimes en base', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      Future<void> add(TrackPointSource s, double lat, double alt, int min) =>
          db.sessionTrackPointsDao.insertPoint(
            trailId: 'sentier-bleu',
            sessionId: 'sess',
            lat: lat,
            lng: 3.0,
            altitude: alt,
            recordedAt: DateTime.utc(2026, 6, 15, 8, min),
            source: s,
          );
      for (var i = 0; i <= 6; i++) {
        await add(TrackPointSource.gps, 45 + i * 0.002, 1000.0 + i * 40, i * 3);
      }
      final session = TrekSession(
        id: 'sess',
        trailId: 'sentier-bleu',
        startedAt: DateTime.utc(2026, 6, 15, 8),
        status: 'active',
      );
      Future<dynamic> stats() async {
        final c = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trekSessionManagerProvider.overrideWith(
              () => _FixedSession(
                TrackingSessionState(
                  status: TrackingSessionStatus.recording,
                  session: session,
                ),
              ),
            ),
          ],
        );
        addTearDown(c.dispose);
        return c.read(liveTrekStatsProvider.future);
      }

      final before = await stats();
      // Des points estimes qui, comptes, ajouteraient des kilometres et des
      // centaines de metres de denivele.
      for (var i = 0; i < 6; i++) {
        await add(
          TrackPointSource.estimated,
          45.5 + (i.isEven ? 0.05 : -0.05),
          i.isEven ? 3000 : 200,
          i * 3 + 1,
        );
      }
      final after = await stats();
      expect(after.distanceKm, before.distanceKm);
      expect(after.elevationGainM, before.elevationGainM);
      expect(after.elevationLossM, before.elevationLossM);
      expect(after.pointCount, before.pointCount);
      expect(after.duration, before.duration);
    });
  });

  group('(8) le tampon et le drain', () {
    test('un point estime traverse le tampon avec son origine et arrive en '
        'base avec elle ; un tampon de la version precedente se draine en '
        'releves reels', () async {
      final estimated = bgEncodePoint(
        id: 'e1',
        sessionId: 's',
        trailId: 't',
        latitude: 42.01,
        longitude: 9.0,
        altitude: 200,
        accuracy: 0,
        speed: 0,
        timestamp: DateTime.utc(2026, 10, 7, 9, 1),
        source: TrackPointSource.estimated,
        trackDistanceM: 1111.1,
      );
      // La forme d'un tampon ecrit par la version 671-02 : sans origine.
      final previous = Map<String, dynamic>.of(estimated)
        ..remove('source')
        ..remove('trackDistanceM')
        ..['id'] = 'ancien';
      SharedPreferences.setMockInitialValues({
        kPrefsBgPointsBuffer: [jsonEncode(estimated), jsonEncode(previous)],
      });
      final drained = await BackgroundGpsService().drainBackgroundPoints();
      expect(drained, hasLength(2));
      expect(drained[0].source, TrackPointSource.estimated);
      expect(drained[0].trackDistanceM, 1111.1);
      expect(drained[1].source, TrackPointSource.gps);
      expect(drained[1].trackDistanceM, isNull);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (final p in drained) {
        await db.sessionTrackPointsDao.insertPoint(
          trailId: p.trailId,
          lat: p.latitude,
          lng: p.longitude,
          altitude: p.altitude,
          source: p.source,
          recordedAt: p.timestamp,
          sessionId: p.sessionId,
        );
      }
      final all = await db.sessionTrackPointsDao.getBySessionId(
        's',
        read: TrackPointsRead.withEstimated,
      );
      expect(all.map((p) => p.source), ['estime', 'gps']);
      expect(
        await db.sessionTrackPointsDao.getBySessionId(
          's',
          read: TrackPointsRead.gpsOnly,
        ),
        hasLength(1),
      );
    });
  });
}

class _NoTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

class _SpyNotifications extends NotificationService {
  int shows = 0;
  int cancels = 0;

  @override
  Future<void> showOffTrackAlert({
    required String title,
    required String body,
  }) async => shows++;

  @override
  Future<void> cancelOffTrackAlert() async => cancels++;
}

class _FixedSession extends TrekSessionManagerNotifier {
  _FixedSession(this._initial);

  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
