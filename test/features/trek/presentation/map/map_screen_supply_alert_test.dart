import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/supply_alert_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Correctif L6-1 — LE MONTAGE de l'alerte ravitaillement sur la carte.
///
/// La REGLE de declenchement est testee a part (supply_alert_provider_test).
/// Ici on ne verifie que ce que ce correctif a reellement ajoute : la
/// minuterie, la fermeture a la main, et le rearmement au changement d'etape.
void main() {
  final mockTrackPoints = [
    const TrackPoint(lat: 45.77, lng: 2.96, altitude: 1465,
        distanceFromStart: 0),
    const TrackPoint(lat: 45.78, lng: 2.97, altitude: 1500,
        distanceFromStart: 1200),
  ];

  final mockStages = [
    const StageModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Puy de Dome',
      distanceKm: 12.0,
      elevationGainM: 450,
      elevationLossM: 200,
      startLat: 45.77,
      startLng: 2.96,
      endLat: 45.79,
      endLng: 2.98,
    ),
  ];

  TrekSession recordingSession() => TrekSession(
        id: 'sess-supply-1',
        trailId: 'test-trail',
        startedAt: DateTime.utc(2026, 6, 15, 8),
        status: 'active',
      );

  /// Alerte pilotee par le test (permet de changer d etape en cours de route).
  final alerteProvider = StateProvider<SupplyGapAlert?>(
    (ref) => const SupplyGapAlert(stageNumber: 3, gap: 6),
  );

  Widget harness({required TrackingSessionStatus status}) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        gpxTrackProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockTrackPoints)),
        gpxTrackProvider('default')
            .overrideWith((ref) => Future.value(mockTrackPoints)),
        stagesProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockStages)),
        stagesProvider('default')
            .overrideWith((ref) => Future.value(mockStages)),
        gpsPermissionProvider.overrideWith(
            (ref) => Future.value(GpsPermissionStateValues.denied)),
        trekSessionManagerProvider.overrideWith(
          () => _FixedStatusNotifier(
            TrackingSessionState(
              status: status,
              session: status == TrackingSessionStatus.recording ||
                      status == TrackingSessionStatus.paused
                  ? recordingSession()
                  : null,
            ),
          ),
        ),
        currentStageIdProvider.overrideWith((ref) => const Stream.empty()),
        // L alerte elle-meme est pilotee par le test.
        supplyGapAlertProvider.overrideWith((ref) => ref.watch(alerteProvider)),
      ],
      child: const MaterialApp(home: MapScreen(trailId: 'test-trail')),
    );
  }

  /// Conteneur Riverpod de l ecran monte (pour piloter l alerte en cours de
  /// test, comme le ferait un changement d etape reel).
  ProviderContainer conteneur(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MapScreen)));

  String texteAlerte(int gap) => t.shop.gapLong(n: gap);

  group('Alerte ravitaillement sur la carte (L6-1)', () {
    testWidgets('visible pendant un trek, libelle TRADUIT et nombre injecte',
        (tester) async {
      await tester.pumpWidget(
          harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(texteAlerte(6)), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('AUCUNE alerte hors trek', (tester) async {
      await tester.pumpWidget(
          harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(texteAlerte(6)), findsNothing);
    });

    testWidgets('s efface SEULE au bout d une minute', (tester) async {
      await tester.pumpWidget(
          harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(texteAlerte(6)), findsOneWidget);

      // Toujours la a 59 s : la minuterie ne coupe pas la lecture trop tot.
      await tester.pump(const Duration(seconds: 59));
      expect(find.text(texteAlerte(6)), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text(texteAlerte(6)), findsNothing);
    });

    testWidgets('se ferme a la demande et RESTE fermee', (tester) async {
      await tester.pumpWidget(
          harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip(t.map.supplyDismiss));
      await tester.pump();
      expect(find.text(texteAlerte(6)), findsNothing);

      // Le temps passe : rien ne la fait revenir sur la meme etape.
      await tester.pump(const Duration(seconds: 120));
      expect(find.text(texteAlerte(6)), findsNothing);
    });

    testWidgets('se REARME au changement d etape, meme apres fermeture',
        (tester) async {
      await tester.pumpWidget(
          harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip(t.map.supplyDismiss));
      await tester.pump();
      expect(find.text(texteAlerte(6)), findsNothing);

      // Nouvelle etape = nouvelle decision de ravitaillement.
      conteneur(tester).read(alerteProvider.notifier).state =
          const SupplyGapAlert(stageNumber: 4, gap: 5);
      await tester.pump();
      expect(find.text(texteAlerte(5)), findsOneWidget);
    });

    testWidgets('disparait des que l ecart n est plus alarmant',
        (tester) async {
      await tester.pumpWidget(
          harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(texteAlerte(6)), findsOneWidget);

      conteneur(tester).read(alerteProvider.notifier).state = null;
      await tester.pump();
      expect(find.text(texteAlerte(6)), findsNothing);
    });
  });
}

/// Notifier de session fige sur un statut (meme harnais que les autres tests
/// de la carte).
class _FixedStatusNotifier extends TrekSessionManagerNotifier {
  _FixedStatusNotifier(this._initial);

  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
