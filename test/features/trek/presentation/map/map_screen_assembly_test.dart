import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/map/controls/map_controls.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/stage_markers_layer.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/trace_layer.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/user_position_layer.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';
import 'package:moteur_gr/features/trek/providers/trail_providers.dart';

/// Donnees mock pour les tests.

/// Points de trace fictifs.
final _mockTrackPoints = [
  const TrackPoint(lat: 42.1, lng: 9.1, altitude: 1200, distanceFromStart: 0),
  const TrackPoint(lat: 42.15, lng: 9.12, altitude: 1350, distanceFromStart: 1500),
  const TrackPoint(lat: 42.2, lng: 9.15, altitude: 1500, distanceFromStart: 3000),
  const TrackPoint(lat: 42.25, lng: 9.18, altitude: 1200, distanceFromStart: 4500),
  const TrackPoint(lat: 42.3, lng: 9.2, altitude: 1000, distanceFromStart: 6000),
];

/// Etapes fictives (3 etapes).
final _mockStages = [
  Stage(
    id: 'test-trail-1',
    nameFr: 'Etape 1',
    nameEn: 'Stage 1',
    distance: 12.5,
    elevationGain: 700,
    elevationLoss: 500,
    estimatedDurationMinutes: 270,
    orderIndex: 0,
    startLat: 42.05,
    startLng: 9.03,
    endLat: 42.1,
    endLng: 9.06,
  ),
  Stage(
    id: 'test-trail-2',
    nameFr: 'Etape 2',
    nameEn: 'Stage 2',
    distance: 15.0,
    elevationGain: 800,
    elevationLoss: 700,
    estimatedDurationMinutes: 330,
    orderIndex: 1,
    startLat: 42.1,
    startLng: 9.06,
    endLat: 42.15,
    endLng: 9.09,
  ),
  Stage(
    id: 'test-trail-3',
    nameFr: 'Etape 3',
    nameEn: 'Stage 3',
    distance: 17.5,
    elevationGain: 900,
    elevationLoss: 900,
    estimatedDurationMinutes: 390,
    orderIndex: 2,
    startLat: 42.15,
    startLng: 9.09,
    endLat: 42.2,
    endLng: 9.12,
  ),
];

/// Test d'integration du MapScreen assemble (E2.3f).
///
/// Verifie que le MapScreen complet avec donnees mock
/// affiche tous les layers : TileLayer, TraceLayer,
/// StageMarkersLayer, UserPositionLayer, et MapControls.
void main() {
  group('MapScreen assemblage complet (E2.3f)', () {
    testWidgets('affiche loading pendant le chargement',
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
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      await tester.pump();
      expect(find.text('Volcans Trail'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('affiche erreur quand le chargement echoue',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => Future<List<TrackPoint>>.error(
                Exception('GPX introuvable'),
              ),
            ),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Impossible de charger le trace'), findsOneWidget);
    });

    testWidgets('MapScreen complet avec donnees mock — tous layers presents',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => Future.value(_mockTrackPoints),
            ),
            trekStagesProvider.overrideWith(
              (ref) => Future.value(_mockStages),
            ),
            locationProvider.overrideWith((ref) {
              final controller = StreamController<Position>();
              ref.onDispose(controller.close);
              controller.add(Position(
                latitude: 42.18,
                longitude: 9.14,
                timestamp: DateTime.now(),
                accuracy: 15.0,
                altitude: 1400.0,
                altitudeAccuracy: 10.0,
                heading: 0.0,
                headingAccuracy: 0.0,
                speed: 0.0,
                speedAccuracy: 0.0,
              ));
              return controller.stream;
            }),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Titre
      expect(find.text('Volcans Trail'), findsOneWidget);

      // FlutterMap present
      expect(find.byType(FlutterMap), findsOneWidget);

      // Tous les layers assembles
      expect(find.byType(TraceLayer), findsOneWidget);
      expect(find.byType(StageMarkersLayer), findsOneWidget);
      expect(find.byType(UserPositionLayer), findsOneWidget);

      // MapControls overlay
      expect(find.byType(MapControls), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);

      // Marqueurs des 3 etapes
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
