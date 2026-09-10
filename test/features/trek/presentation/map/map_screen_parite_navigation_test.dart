import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/widgets/stage_progress_bar.dart';
import 'package:moteur_gr/features/safety/presentation/sos_button.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// PARITE GR20 (#99460) — l'onglet Carte StepWays clone l'ecran Navigation GR20.
///
/// Verifie la presence des elements ajoutes (au niveau GR20, hors peau) :
///   * bouton SOS (visible pendant un trek, masque hors trek) ;
///   * bouton Calques (toggle des couches) ;
///   * couche POI ;
///   * barre d'etape active pendant un trek ;
/// et le fix de navigation : le retour depuis la carte ne plante pas.
void main() {
  final mockTrackPoints = [
    const TrackPoint(lat: 45.77, lng: 2.96, altitude: 1465, distanceFromStart: 0),
    const TrackPoint(
        lat: 45.78, lng: 2.97, altitude: 1500, distanceFromStart: 1200),
    const TrackPoint(
        lat: 45.79, lng: 2.98, altitude: 1600, distanceFromStart: 2400),
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

  final mockPois = [
    const PoiModel(
      id: 1,
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Source du col',
      type: 'water',
      lat: 45.775,
      lng: 2.965,
    ),
  ];

  Position fakePosition() => Position(
        latitude: 45.775,
        longitude: 2.965,
        timestamp: DateTime.utc(2026, 6, 15, 9),
        accuracy: 5,
        altitude: 1480,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 0,
        speed: 1.2,
        speedAccuracy: 0.5,
      );

  TrekSession recordingSession() => TrekSession(
        id: 'sess-parite-1',
        trailId: 'test-trail',
        startedAt: DateTime.utc(2026, 6, 15, 8),
        status: 'active',
      );

  /// Harnais MapScreen avec surcharge du statut de session.
  Widget harness({
    required TrackingSessionStatus status,
    bool withGps = false,
  }) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        // Trace du sentier courant ET trace 'default' (lu par la projection).
        gpxTrackProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockTrackPoints)),
        gpxTrackProvider('default')
            .overrideWith((ref) => Future.value(mockTrackPoints)),
        stagesProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockStages)),
        stagesProvider('default')
            .overrideWith((ref) => Future.value(mockStages)),
        poisProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockPois)),
        // GPS : soit refuse (pas de position), soit une position fixe.
        if (withGps)
          locationProvider.overrideWith((ref) => Stream.value(fakePosition()))
        else
          gpsPermissionProvider.overrideWith(
              (ref) => Future.value(GpsPermissionStateValues.denied)),
        // Session de tracking figee au statut demande.
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
        // Neutralise le flux d'etape (evite le vrai GPS via le mount).
        currentStageIdProvider.overrideWith((ref) => const Stream.empty()),
      ],
      child: const MaterialApp(home: MapScreen(trailId: 'test-trail')),
    );
  }

  group('MapScreen parite GR20 — elements presents', () {
    testWidgets('bouton Calques present (toggle des couches)', (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));

      // FAB des calques (heroTag mapLayers -> icone layers).
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('SOS overlay masque hors trek', (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));

      // OVERLAY SOS ([SosButton], colonne bas-gauche) : se rend en
      // SizedBox.shrink hors trek -> son sous-arbre ne porte AUCUNE icone SOS.
      expect(find.byType(SosButton), findsOneWidget); // widget monte
      expect(
        find.descendant(
          of: find.byType(SosButton),
          matching: find.byIcon(Icons.emergency),
        ),
        findsNothing,
        reason: 'overlay SOS invisible hors trek (parite SosButton)',
      );

      // ⚠ ARBITRAGE §4 (StepWays LOT 3, Ph5) : la BARRE contextuelle de la carte
      // porte desormais une action SOS (Étape/Journal/SOS) INDEPENDANTE de
      // l'overlay -> elle est presente meme hors trek. C'est le point de gout que
      // Chris tranchera (garder overlay + barre, ou fusionner). On documente ici
      // qu'a l'ecran il y a bien l'icone SOS de la barre (et une seule), pas celle
      // de l'overlay.
      expect(find.byIcon(Icons.emergency), findsOneWidget);
    });

    testWidgets('SOS overlay visible pendant un trek (+ SOS de barre §4)',
        (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));

      // OVERLAY SOS ([SosButton]) : visible en trek (icone + texte « SOS »).
      expect(
        find.descendant(
          of: find.byType(SosButton),
          matching: find.byIcon(Icons.emergency),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SosButton),
          matching: find.text('SOS'),
        ),
        findsOneWidget,
      );

      // ⚠ ARBITRAGE §4 : la barre contextuelle ajoute un 2e point SOS -> au TOTAL
      // deux icones SOS a l'ecran en trek (overlay + barre). Attendu tant que
      // Chris n'a pas tranche le gout (non bloquant).
      expect(find.byIcon(Icons.emergency), findsNWidgets(2));
      expect(find.text('SOS'), findsNWidgets(2));
    });

    testWidgets('barre d etape active affichee pendant un trek avec fix GPS',
        (tester) async {
      await tester.pumpWidget(
        harness(status: TrackingSessionStatus.recording, withGps: true),
      );
      // Laisse le stream GPS + la projection se resoudre.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(StageProgressBar), findsOneWidget);
    });

    testWidgets('barre d etape masquee hors trek', (tester) async {
      await tester.pumpWidget(
        harness(status: TrackingSessionStatus.idle, withGps: true),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(StageProgressBar), findsNothing);
    });
  });

  group('MapScreen parite GR20 — navigation retour', () {
    testWidgets('retour depuis la carte (racine de branche) ne plante pas',
        (tester) async {
      // Router minimal : /home + /map (comme l'onglet Carte du shell). On entre
      // par /map (racine de branche, pile vide) : le bouton retour ne doit PAS
      // tenter de depiler une pile vide (crash) mais revenir a /home.
      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('HOME-SCREEN')),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(trailId: 'test-trail'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id)
                .overrideWith((ref) => Future.value(mockTrackPoints)),
            gpsPermissionProvider.overrideWith(
                (ref) => Future.value(GpsPermissionStateValues.denied)),
            trekSessionManagerProvider.overrideWith(
              () => _FixedStatusNotifier(
                const TrackingSessionState(status: TrackingSessionStatus.idle),
              ),
            ),
            currentStageIdProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Le bouton retour est present.
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      // Tap retour : aucune exception, on arrive sur /home.
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('HOME-SCREEN'), findsOneWidget);
    });
  });
}

/// Notifier de test : fige un [TrackingSessionState] donne (statut de session).
class _FixedStatusNotifier extends TrekSessionManagerNotifier {
  _FixedStatusNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
