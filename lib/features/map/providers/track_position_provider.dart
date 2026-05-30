import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/geo/stage_detector.dart';
import '../../../core/geo/track_projection.dart';
import '../../../core/models/stage.dart';
import '../../trail/providers/stages_provider.dart';
import 'gpx_track_provider.dart';
import 'location_provider.dart';

/// Position de l'utilisateur sur le trace avec toutes les infos calculees.
///
/// Combine la projection GPS sur le trace, la detection d'etape,
/// et les distances pour l'affichage temps reel.
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

  /// Position projetee sur le trace
  final double projectedLat;
  final double projectedLng;

  /// Distance perpendiculaire au trace en metres
  final double distanceToTrackM;

  /// Distance parcourue depuis le debut en metres
  final double distanceFromStartM;

  /// Distance restante jusqu'a la fin en metres
  final double distanceRemainingM;

  /// Index du segment courant sur le trace
  final int trackIndex;

  /// Detection de l'etape courante
  final StageDetection stageDetection;

  /// Vrai si l'utilisateur est a plus de 100m du trace
  final bool isOffTrack;

  /// Distance restante en kilometres, arrondie a 1 decimale
  double get distanceRemainingKm =>
      (distanceRemainingM / 100).round() / 10;

  /// Pourcentage de progression sur le trace (0.0 a 1.0)
  double get progressRatio {
    final total = distanceFromStartM + distanceRemainingM;
    if (total <= 0) return 0.0;
    return distanceFromStartM / total;
  }
}

/// Seuil en metres au-dela duquel l'utilisateur est considere hors trace.
const double _offTrackThresholdM = 100.0;

/// Notifier pour le dernier index de projection connu (optimisation fenetree).
class _LastTrackIndexNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? index) => state = index;
}

final _lastTrackIndexProvider =
    NotifierProvider<_LastTrackIndexNotifier, int?>(
        _LastTrackIndexNotifier.new);

/// Provider principal : combine position GPS + trace + etapes.
///
/// Calcule la projection en temps reel et expose un [TrackPositionState]
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

/// Calcule la projection a partir d'une position GPS recue.
AsyncValue<TrackPositionState> _computeProjection(
  Ref ref,
  Position position,
) {
  // Recuperer le trailId depuis la config
  final trailId = ref.watch(
    gpxTrackProvider('default').select((_) => 'default'),
  );

  // Recuperer le trace GPX
  final trackAsync = ref.watch(gpxTrackProvider(trailId));
  final stagesAsync = ref.watch(stagesProvider(trailId));

  return trackAsync.when(
    data: (trackPoints) {
      if (trackPoints.length < 2) {
        return AsyncError(
          StateError('Trace trop court pour la projection'),
          StackTrace.current,
        );
      }

      final lastIndex = ref.read(_lastTrackIndexProvider);

      // Projeter la position sur le trace
      final projection = TrackProjector.project(
        userLat: position.latitude,
        userLng: position.longitude,
        trackPoints: trackPoints,
        lastKnownIndex: lastIndex,
      );

      // Memoriser l'index pour l'optimisation fenetree
      ref.read(_lastTrackIndexProvider.notifier).set(
          projection.trackIndexPosition);

      // Detecter l'etape courante
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
