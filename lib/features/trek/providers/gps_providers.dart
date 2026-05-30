import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/arrival_detection_service.dart';
import '../data/gps_service.dart';
import '../data/stage_detection_service.dart';
import '../domain/models/stage.dart';
import 'stage_providers.dart';

// Re-export des providers de service deja definis dans leurs fichiers.
// Les utilisateurs de gps_providers.dart n'ont pas besoin d'importer
// chaque service individuellement.
export '../data/arrival_detection_service.dart'
    show arrivalDetectionServiceProvider;
export '../data/background_gps_service.dart' show backgroundGpsServiceProvider;
export '../data/gps_service.dart' show gpsServiceProvider;
export '../data/stage_detection_service.dart'
    show stageDetectionServiceProvider;

/// Stream de positions GPS depuis GpsService.
///
/// Fournit le stream brut de Position — point d'entree du pipeline.
/// Depend de gpsServiceProvider (select sur la reference, pas sur le stream).
final positionStreamProvider = StreamProvider<Position>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.getPositionStream();
});

/// Convertit les StageModel (core/DB) en Stage (domain trek).
///
/// Utilise select() sur stagesProvider pour ne rebuilder que si la liste change.
/// Retourne [] si le chargement n'est pas termine.
final domainStagesProvider = Provider<List<Stage>>((ref) {
  final stagesAsync = ref.watch(
    stagesProvider.select((async) => async.valueOrNull),
  );
  final stages = stagesAsync ?? [];

  return stages
      .map(
        (sm) => Stage(
          id: '${sm.stageNumber}',
          nameFr: sm.name,
          distance: sm.distanceKm,
          elevationGain: sm.elevationGainM,
          elevationLoss: sm.elevationLossM,
          orderIndex: sm.stageNumber,
          startLat: sm.startLat,
          startLng: sm.startLng,
          endLat: sm.endLat,
          endLng: sm.endLng,
          difficulty: sm.difficulty,
          descriptionFr: sm.description,
        ),
      )
      .toList();
});

/// Stream du stageId courant via StageDetectionService.
///
/// Pipeline : positionStream + domainStages -> stageDetection -> stageId.
/// select() sur domainStagesProvider pour eviter rebuilds inutiles.
/// Emet des valeurs distinctes uniquement (hysteresis integree au service).
final currentStageIdProvider = StreamProvider<String>((ref) {
  final detectionService = ref.watch(stageDetectionServiceProvider);
  final gpsService = ref.watch(gpsServiceProvider);
  final stages = ref.watch(domainStagesProvider);

  if (stages.isEmpty) return const Stream.empty();

  final positionStream = gpsService.getPositionStream();
  return detectionService.currentStageId(positionStream, stages);
});

/// Stream d'evenements d'arrivee via ArrivalDetectionService.
///
/// Pipeline : positionStream + domainStages -> arrivalDetection -> ArrivalEvent.
/// Emet quand le randonneur atteint la fin d'une etape (stageEnd)
/// ou la fin du sentier (trailEnd). Guard anti-doublon integre au service.
final arrivalEventsProvider = StreamProvider<ArrivalEvent>((ref) {
  final arrivalService = ref.watch(arrivalDetectionServiceProvider);
  final gpsService = ref.watch(gpsServiceProvider);
  final stages = ref.watch(domainStagesProvider);

  if (stages.isEmpty) return const Stream.empty();

  final positionStream = gpsService.getPositionStream();
  return arrivalService.arrivalEvents(positionStream, stages);
});
