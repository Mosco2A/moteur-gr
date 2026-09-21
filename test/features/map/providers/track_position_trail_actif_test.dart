import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// REGRESSION — la projection lit le sentier ACTIF, jamais un identifiant
/// ecrit en dur (correctif L6-2 suite, 21/09/2026).
///
/// Le calcul de projection demandait la trace du sentier « default ». Or
/// [gpxTrackProvider] refuse tout identifiant different de celui de la config
/// active : il levait donc une erreur a CHAQUE appel. Consequence sur
/// l'appareil : [trackPositionProvider] restait en erreur en permanence, et
/// tout ce qui en depend disparaissait de la carte — barre d'etape, distance
/// restante, progression, etape detectee, alerte ravitaillement (L6-1), ligne
/// de chiffres mesures (L6-2).
///
/// Le defaut etait INVISIBLE EN TEST parce que les suites d'ecran
/// surchargeaient `gpxTrackProvider('default')` — elles nourrissaient le
/// mauvais identifiant au lieu de constater qu'il etait mauvais. Ce test-ci
/// ne surcharge QUE le sentier actif : si quelqu'un remet un identifiant en
/// dur, il tombe.
void main() {
  final trace = <TrackPoint>[
    const TrackPoint(lat: 42.0156, lng: 9.4039, altitude: 5,
        distanceFromStart: 0),
    const TrackPoint(lat: 42.0100, lng: 9.3900, altitude: 45,
        distanceFromStart: 1300),
    const TrackPoint(lat: 42.0020, lng: 9.3780, altitude: 120,
        distanceFromStart: 2600),
  ];

  final etapes = <StageModel>[
    const StageModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Premiere etape',
      distanceKm: 12,
      elevationGainM: 400,
      elevationLossM: 100,
      startLat: 42.0156,
      startLng: 9.4039,
      endLat: 42.0020,
      endLng: 9.3780,
    ),
  ];

  Position position() => Position(
        latitude: 42.0150,
        longitude: 9.4030,
        timestamp: DateTime.utc(2026, 6, 15, 9),
        accuracy: 5,
        altitude: 12,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 0,
        speed: 1.1,
        speedAccuracy: 0.5,
      );

  test('la projection aboutit avec la SEULE trace du sentier actif', () async {
    final container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        // Rien d'autre : pas de `gpxTrackProvider('default')` de complaisance.
        gpxTrackProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(trace)),
        stagesProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(etapes)),
        locationProvider.overrideWith((ref) => Stream.value(position())),
      ],
    );
    addTearDown(container.dispose);

    // Garde la projection vivante pendant que ses sources se resolvent.
    final abonnement = container.listen<AsyncValue<TrackPositionState>>(
      trackPositionProvider,
      (_, __) {},
    );
    addTearDown(abonnement.close);

    await container.read(gpxTrackProvider(testTrailConfig.id).future);
    await container.read(stagesProvider(testTrailConfig.id).future);
    // Laisse la premiere position traverser le flux.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final projection = container.read(trackPositionProvider);
    expect(
      projection.hasError,
      isFalse,
      reason: 'une erreur ici = barre d etape absente sur l appareil',
    );
    final state = projection.value;
    expect(state, isNotNull);
    // Le randonneur est sur le trace : quelques dizaines de metres au plus.
    expect(state!.isOffTrack, isFalse);
    expect(state.distanceRemainingM, greaterThan(0));
    // Et l etape est detectee (il est a la borne de depart de l etape 1).
    expect(state.stageDetection.stageNumber, 1);
  });
}
