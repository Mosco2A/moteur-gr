import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';

/// Tests integration du MapScreen assemble (Phase 2 E2.3f).
///
/// Verifie l assemblage complet : tous layers presents avec donnees mock.
void main() {
  // Points de test fictifs (Auvergne)
  final mockTrackPoints = [
    const TrackPoint(lat: 45.77, lng: 2.96, altitude: 1465, distanceFromStart: 0),
    const TrackPoint(lat: 45.78, lng: 2.97, altitude: 1500, distanceFromStart: 1200),
    const TrackPoint(lat: 45.79, lng: 2.98, altitude: 1600, distanceFromStart: 2400),
  ];

  // Etapes de test fictives
  final mockStages = [
    const StageModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Puy de Dome',
      distanceKm: 12.0,
      elevationGainM: 450,
      elevationLossM: 200,
      startLat: 45.77, startLng: 2.96,
      endLat: 45.78, endLng: 2.97,
    ),
    const StageModel(
      trailId: 'test-trail',
      stageNumber: 2,
      name: 'Puy de Sancy',
      distanceKm: 15.0,
      elevationGainM: 600,
      elevationLossM: 350,
      startLat: 45.78, startLng: 2.97,
      endLat: 45.79, endLng: 2.98,
    ),
  ];

  group('MapScreen E2.3f assemblage', () {
    testWidgets('affiche loading puis structure complete',
        (tester) async {
      final completer = Completer<List<TrackPoint>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: MapScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Volcans Trail'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('affiche ErrorView quand le chargement echoue',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => Future<List<TrackPoint>>.error(
                Exception('Fichier GPX introuvable'),
              ),
            ),
          ],
          child: const MaterialApp(
            home: MapScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Impossible de charger le trace'), findsOneWidget);
      expect(find.text('Reessayer'), findsOneWidget);
    });

    testWidgets('affiche ErrorView quand le GPX est vide', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => Future.value(<TrackPoint>[]),
            ),
          ],
          child: const MaterialApp(
            home: MapScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Aucun trace disponible'), findsOneWidget);
    });

    testWidgets('MapScreen est un StatelessWidget', (tester) async {
      const screen = MapScreen(trailId: 'test-trail');
      expect(screen, isA<StatelessWidget>());
    });

    testWidgets('assemblage complet -- tous layers avec donnees mock',
        (tester) async {
      // Ce test verifie que MapScreen se construit sans erreur
      // avec stagesProvider et locationProvider overrides.
      // FlutterMap ne rend pas les tuiles en test, mais les layers
      // doivent etre instancies sans crash.

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => Future.value(mockTrackPoints),
            ),
            stagesProvider(testTrailConfig.id).overrideWith(
              (ref) => Future.value(mockStages),
            ),
            // GPS non accorde en test -> position null (SizedBox.shrink)
            gpsPermissionProvider.overrideWith(
              (ref) => Future.value(GpsPermissionStateValues.denied),
            ),
          ],
          child: const MaterialApp(
            home: MapScreen(trailId: 'test-trail'),
          ),
        ),
      );

      // Pump pour le FutureProvider
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Le titre doit etre present
      expect(find.text('Volcans Trail'), findsOneWidget);

      // Pas de loading ni erreur (donnees fournies)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
