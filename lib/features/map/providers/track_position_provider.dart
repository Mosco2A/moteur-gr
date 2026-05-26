import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/geo/stage_detector.dart';
import '../../../core/geo/track_projection.dart';
import '../../../core/models/stage.dart';
import '../../trail/providers/stages_provider.dart';
import 'gpx_track_provider.dart';
import 'location_provider.dart';

/// Position de l'utilisateur sur le tracé avec toutes les infos calculées.
///
/// Combine la projection GPS sur le tracé, la détection d'étape,
/// et les distances pour l'affichage temps réel.
class TrackPositionState {
  const TrackPositionState({
    required this.userLat,
    required this.userLng,
    required this.projectedLat,
    required this.projectedLng,
    required this.distanceToTrackM,
    required this.distanceFromStartM,
    required this.distanceRemainingM,
    required this.trackIndex,
    required this.stageDetection,
    required this.isOffTrack,
  });

  /// Position GPS brute de l'utilisateur
  final double userLat;
  final double userLng;

  /// Position projetée sur le tracé
  final double projectedLat;
  final double projectedLng;

  /// Distance perpendiculaire au tracé en mètres
  final double distanceToTrackM;

  /// Distance parcourue depuis le début en mètres
  final double distanceFromStartM;

  /// Distance restante jusqu'à la fin en mètres
  final double distanceRemainingM;

  /// Index du segment courant sur le tracé
  final int trackIndex;

  /// Détection de l'étape courante
  final StageDetection stageDetection;

  /// Vrai si l'utilisateur est à plus de 100m du tracé
  final bool isOffTrack;

  /// Distance restante en kilomètres, arrondie à 1 décimale
  double get distanceRemainingKm =>
      (distanceRemainingM / 100).round() / 10;

  /// Pourcentage de progression sur le tracé (0.0 à 1.0)
  double get progressRatio {
    final total = distanceFromStartM + distanceRemainingM;
    if (total <= 0) return 0.0;
    return distanceFromStartM / total;
  }
}

/// Seuil en mètres au-delà duquel l'utilisateur est considéré hors tracé.
const double _offTrackThresholdM = 100.0;

/// Provider de la dernière projection connue (pour l'optimisation fenêtrée).
final _lastTrackIndexProvider = StateProvider<int?>((ref) => null);

/// Provider principal : combine position GPS + tracé + étapes.
///
/// Calcule la projection en temps réel et expose un [TrackPositionState]
/// complet pour l'UI (carte + barre de progression).
final trackPositionProvider =
    Provider<AsyncValue<TrackPositionState>>((ref) {
  final positionAsync = ref.watch(locationProvider);

  return positionAsync.when(
    data: (position) => _computeProjection(ref, position),
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

/// Calcule la projection à partir d'une position GPS reçue.
AsyncValue<TrackPositionState> _computeProjection(
  Ref ref,
  Position position,
) {
  // Récupérer le trailId depuis la config
  final trailId = ref.watch(
    gpxTrackProvider('default').select((_) => 'default'),
  );

  // Récupérer le tracé GPX
  final trackAsync = ref.watch(gpxTrackProvider(trailId));
  final stagesAsync = ref.watch(stagesProvider(trailId));

  return trackAsync.when(
    data: (trackPoints) {
      if (trackPoints.length < 2) {
        return AsyncError(
          StateError('Tracé trop court pour la projection'),
          StackTrace.current,
        );
      }

      final lastIndex = ref.read(_lastTrackIndexProvider);

      // Projeter la position sur le tracé
      final projection = TrackProjector.project(
        userLat: position.latitude,
        userLng: position.longitude,
        trackPoints: trackPoints,
        lastKnownIndex: lastIndex,
      );

      // Mémoriser l'index pour l'optimisation fenêtrée
      ref.read(_lastTrackIndexProvider.notifier).state =
          projection.trackIndexPosition;

      // Détecter l'étape courante
      final stages = stagesAsync.valueOrNull ?? <StageModel>[];
      final detection = StageDetector.detect(
        projectedLat: projection.projectedLat,
        projectedLng: projection.projectedLng,
        stages: stages,
      );

      final state = TrackPositionState(
        userLat: position.latitude,
        userLng: position.longitude,
        projectedLat: projection.projectedLat,
        projectedLng: projection.projectedLng,
        distanceToTrackM: projection.distanceToTrackM,
        distanceFromStartM: projection.distanceFromStartM,
        distanceRemainingM: projection.distanceRemainingM,
        trackIndex: projection.trackIndexPosition,
        stageDetection: detection,
        isOffTrack: projection.distanceToTrackM > _offTrackThresholdM,
      );

      return AsyncData(state);
    },
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
}
