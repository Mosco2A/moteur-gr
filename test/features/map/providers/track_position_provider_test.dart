import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/stage_detector.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/tracking/domain/tracking_engine.dart';

void main() {
  group('TrackPositionState', () {
    test('distanceRemainingKm convertit correctement', () {
      const state = TrackPositionState(
        userLat: 45.0,
        userLng: 3.0,
        projectedLat: 45.0,
        projectedLng: 3.0,
        distanceToTrackM: 5.0,
        distanceFromStartM: 5000.0,
        distanceRemainingM: 15000.0,
        trackIndex: 10,
        stageDetection: (
          stageNumber: 1,
          event: StageDetectionEventValues.between,
        ),
        isOffTrack: false,
      );

      // 15000m = 15.0 km
      expect(state.distanceRemainingKm, 15.0);
    });

    test('progressRatio calcule le bon pourcentage', () {
      const state = TrackPositionState(
        userLat: 45.0,
        userLng: 3.0,
        projectedLat: 45.0,
        projectedLng: 3.0,
        distanceToTrackM: 5.0,
        distanceFromStartM: 5000.0,
        distanceRemainingM: 15000.0,
        trackIndex: 10,
        stageDetection: (
          stageNumber: 1,
          event: StageDetectionEventValues.between,
        ),
        isOffTrack: false,
      );

      // 5000 / (5000 + 15000) = 0.25
      expect(state.progressRatio, closeTo(0.25, 0.01));
    });

    test('isOffTrack est vrai quand distance > 100m', () {
      const stateOnTrack = TrackPositionState(
        userLat: 45.0,
        userLng: 3.0,
        projectedLat: 45.0,
        projectedLng: 3.0,
        distanceToTrackM: 50.0,
        distanceFromStartM: 1000.0,
        distanceRemainingM: 9000.0,
        trackIndex: 5,
        stageDetection: (
          stageNumber: 1,
          event: StageDetectionEventValues.between,
        ),
        isOffTrack: false,
      );

      const stateOffTrack = TrackPositionState(
        userLat: 45.001,
        userLng: 3.0,
        projectedLat: 45.0,
        projectedLng: 3.0,
        distanceToTrackM: 150.0,
        distanceFromStartM: 1000.0,
        distanceRemainingM: 9000.0,
        trackIndex: 5,
        stageDetection: (
          stageNumber: 1,
          event: StageDetectionEventValues.between,
        ),
        isOffTrack: true,
      );

      expect(stateOnTrack.isOffTrack, false);
      expect(stateOffTrack.isOffTrack, true);
    });
  });

  group('TrackProjector integration avec TrackPositionState', () {
    final track = List.generate(
      50,
      (i) => TrackPoint(
        lat: 45.0,
        lng: 3.0 + i * 0.001,
        altitude: 500.0,
        distanceFromStart: i * 78.7,
      ),
    );

    test('projection mock GPS retourne des valeurs coherentes', () {
      final projection = TrackProjector.project(
        userLat: 45.0005,
        userLng: 3.025,
        trackPoints: track,
      );

      expect(projection.projectedLat, closeTo(45.0, 0.001));
      expect(projection.distanceToTrackM, greaterThan(0));
      expect(projection.distanceFromStartM, greaterThan(0));
      expect(projection.distanceRemainingM, greaterThan(0));
    });

    test('projection point sur le trace a distance quasi nulle', () {
      final projection = TrackProjector.project(
        userLat: 45.0,
        userLng: 3.025,
        trackPoints: track,
      );

      // Sur le trace exactement -> distance ~ 0
      expect(projection.distanceToTrackM, lessThan(5));
    });
  });

  // ---------------------------------------------------------------------------
  // Coherence de progression : SOURCE PROJETEE (correctif build 117).
  //
  // La distance parcourue affichee (overlay, barre de progression, widget Home)
  // = projection sur le trace (`distanceFromStartM`), JAMAIS le cumul GPS brut
  // (`TrackingEngine.distanceMeters`). Un aller-retour ne doit PAS gonfler la
  // progression : la source projetee ne depend que de l'endroit ou l'on est sur
  // le trace, pas du chemin parcouru pour y arriver.
  // Spec: E10 RF-10 / AM-5 / RM-2 ; E13 RM-2 / AM-8.
  // ---------------------------------------------------------------------------
  group('Coherence progression projetee (aller-retour, source unique)', () {
    // Trace rectiligne d'~3,9 km (50 points espaces de ~78,7 m).
    final track = List.generate(
      50,
      (i) => TrackPoint(
        lat: 45.0,
        lng: 3.0 + i * 0.001,
        altitude: 500.0,
        distanceFromStart: i * 78.7,
      ),
    );

    double projectedCoveredM(double userLng) {
      return TrackProjector.project(
        userLat: 45.0,
        userLng: userLng,
        trackPoints: track,
      ).distanceFromStartM;
    }

    test('un aller-retour ne gonfle PAS la distance projetee', () {
      // On avance jusqu'au milieu du trace, puis on repart en arriere pour
      // revenir exactement au meme point. Le chemin GPS parcouru double, mais
      // la position projetee sur le trace est identique.
      const midLng = 3.025; // ~milieu du trace

      final coveredOutbound = projectedCoveredM(midLng); // a l'aller
      // ... l'utilisateur continue jusqu'a 3.030 puis fait demi-tour ...
      final coveredForward = projectedCoveredM(3.030);
      final coveredReturn = projectedCoveredM(midLng); // revenu au milieu

      // Au retour au meme point : distance projetee identique a l'aller.
      expect(coveredReturn, closeTo(coveredOutbound, 1.0));
      // Et strictement inferieure au point le plus avance atteint.
      expect(coveredReturn, lessThan(coveredForward));
    });

    test(
        'contraste : le cumul brut (TrackingEngine) gonfle sur un aller-retour, '
        'la source projetee non', () {
      // Meme aller-retour, alimente dans le moteur de cumul Haversine.
      final engine = TrackingEngine();
      // Aller : du debut (3.000) au milieu (3.025).
      engine.addPosition(45.0, 3.000, 500.0);
      engine.addPosition(45.0, 3.025, 500.0);
      final cumulAtMid = engine.distanceMeters;
      // On pousse jusqu'a 3.030 puis on REVIENT au milieu (3.025).
      engine.addPosition(45.0, 3.030, 500.0);
      engine.addPosition(45.0, 3.025, 500.0);
      final cumulAfterRoundTrip = engine.distanceMeters;

      // Le cumul brut a AUGMENTE alors qu'on est physiquement au meme endroit.
      expect(cumulAfterRoundTrip, greaterThan(cumulAtMid));

      // La source projetee, elle, est revenue a la meme valeur : c'est la
      // raison pour laquelle la progression affichee lit le projete, pas
      // le cumul.
      final projAtMid = projectedCoveredM(3.025);
      final projAfterRoundTrip = projectedCoveredM(3.025);
      expect(projAfterRoundTrip, closeTo(projAtMid, 1.0));

      // L'ecart (gonflement) est bien un ~aller-retour 3.025->3.030->3.025.
      final legM = GeoUtils.haversineDistance(45.0, 3.025, 45.0, 3.030);
      expect(
        cumulAfterRoundTrip - cumulAtMid,
        closeTo(legM * 2, legM * 0.1),
      );
    });

    test(
        'distanceFromStartM (source projetee unique) croit de facon monotone '
        'le long du trace', () {
      // Progression le long du trace -> valeurs strictement croissantes.
      final atStart = projectedCoveredM(3.005);
      final atQuarter = projectedCoveredM(3.012);
      final atMid = projectedCoveredM(3.025);
      final atEnd = projectedCoveredM(3.045);

      expect(atQuarter, greaterThan(atStart));
      expect(atMid, greaterThan(atQuarter));
      expect(atEnd, greaterThan(atMid));
    });
  });
}
