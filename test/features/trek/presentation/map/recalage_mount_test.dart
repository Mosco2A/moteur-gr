// Lot 671-03 : le montage du recalage sur la carte (`TrackRecalibrationMount`)
// publie le trace reduit pour l'isolate de fond et tient les trois sorties de
// secours vers le GPS continu, en disant UNE phrase de randonneur.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';
import 'package:moteur_gr/features/trek/data/podometre_permission_service.dart';
import 'package:moteur_gr/features/trek/data/position_controller.dart';
import 'package:moteur_gr/features/trek/data/trace_de_fond.dart';
import 'package:moteur_gr/features/trek/domain/accumulateur_de_pas.dart';
import 'package:moteur_gr/features/trek/domain/longueur_de_pas.dart';
import 'package:moteur_gr/features/trek/presentation/map/recalage_mount.dart';
import 'package:moteur_gr/features/trek/providers/measure_bench_provider.dart';
import 'package:moteur_gr/features/trek/providers/podometre_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Trek extends TrekSessionManagerNotifier {
  @override
  TrackingSessionState build() =>
      const TrackingSessionState(status: TrackingSessionStatus.recording);
}

class _Projection extends Notifier<AsyncValue<TrackPositionState>> {
  @override
  AsyncValue<TrackPositionState> build() => const AsyncLoading();

  void at(double meters, {required bool offTrack}) => state = AsyncData(
    TrackPositionState(
      userLat: 42,
      userLng: 9,
      projectedLat: 42,
      projectedLng: 9,
      distanceToTrackM: offTrack ? 300 : 3,
      distanceFromStartM: meters,
      distanceRemainingM: 3000 - meters,
      trackIndex: 1,
      stageDetection: (stageNumber: 1, event: 'between'),
      isOffTrack: offTrack,
    ),
  );
}

final _projection =
    NotifierProvider<_Projection, AsyncValue<TrackPositionState>>(
      _Projection.new,
    );

void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  final track = [
    for (var i = 0; i <= 30; i++)
      TrackPoint(
        lat: 42 + i * 0.001,
        lng: 9,
        altitude: 100,
        distanceFromStart: i * 111.2,
      ),
  ];

  Future<(List<PositionProfile>, ProviderContainer)> mount(
    WidgetTester tester, {
    EstimateReadiness readiness = EstimateReadiness.possible,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final applied = <PositionProfile>[];
    final controller = PositionController();
    await controller.setProfile(PositionProfile.batteryFirst);
    final container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        trekSessionManagerProvider.overrideWith(_Trek.new),
        trackPositionProvider.overrideWith((ref) => ref.watch(_projection)),
        gpxTrackProvider(testTrailConfig.id).overrideWith((ref) async => track),
        positionControllerProvider.overrideWithValue(controller),
        positionProfileChannelProvider.overrideWithValue(
          (p) async => applied.add(p),
        ),
        podometerProvider.overrideWith(
          (ref) async => PodometerState(
            steps: 0,
            stride: StrideCalibration(),
            access: PodometerAccess.granted,
            readiness: readiness,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: const MaterialApp(
            locale: Locale('fr'),
            home: Scaffold(body: TrackRecalibrationMount()),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    return (applied, container);
  }

  testWidgets('un releve hors du trace fait passer le profil en carte par le '
      'canal, et l ecran le dit en une phrase', (tester) async {
    final (applied, container) = await mount(tester);
    container.read(_projection.notifier).at(500, offTrack: false);
    await tester.pumpAndSettle();
    expect(applied, isEmpty);
    container.read(_projection.notifier).at(600, offTrack: true);
    await tester.pumpAndSettle();
    expect(applied, [PositionProfile.map]);
    final fr = AppLocale.fr.buildSync().tracking.stepCounting;
    expect(find.text(fr.continuousGps), findsOneWidget);
    container.read(_projection.notifier).at(700, offTrack: false);
    await tester.pumpAndSettle();
    expect(applied, [PositionProfile.map, PositionProfile.batteryFirst]);
  });

  testWidgets('un podometre refuse : la carte, et la phrase du lot 671-02 au '
      'meme endroit, sans en empiler une seconde', (tester) async {
    final (applied, container) = await mount(
      tester,
      readiness: EstimateReadiness.permissionRefused,
    );
    container.read(_projection.notifier).at(500, offTrack: false);
    await tester.pumpAndSettle();
    expect(applied, [PositionProfile.map]);
    final fr = AppLocale.fr.buildSync().tracking.stepCounting;
    expect(find.text(fr.whyGps), findsOneWidget);
    expect(find.text(fr.continuousGps), findsNothing);
  });

  testWidgets('le trace reduit est publie pour l isolate de fond, avec le '
      'sentier et le sens de la marche', (tester) async {
    final (_, container) = await mount(tester);
    container.read(_projection.notifier).at(500, offTrack: false);
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final prefs = await SharedPreferences.getInstance();
    final trace = decodeBackgroundTrace(prefs.getString(kPrefsBgTrace))!;
    expect(trace.trailId, testTrailConfig.id);
    expect(trace.points, hasLength(track.length));
  });

  testWidgets('le choix manuel de l ecran de mesure reste maitre', (
    tester,
  ) async {
    final (applied, container) = await mount(tester);
    container.read(_projection.notifier).at(600, offTrack: true);
    await tester.pumpAndSettle();
    expect(applied, [PositionProfile.map]);
    container
        .read(chosenPositionProfileProvider.notifier)
        .choose(PositionProfile.batteryFirst);
    for (var m = 610.0; m < 700; m += 10) {
      container.read(_projection.notifier).at(m, offTrack: true);
      await tester.pumpAndSettle();
    }
    expect(applied, [PositionProfile.map]);
  });
}
