import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/engine/trail_engine.dart';
import '../data/arrival_detection_service.dart';
import '../data/gps_service.dart';
import '../data/stage_detection_service.dart';
import '../domain/models/stage.dart';
import '../domain/trek_completion.dart';
import 'stage_providers.dart';
import 'tracking_providers.dart';

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

/// Sens de marche choisi pour le trek (code ⊂ `TrailConfig.directions`).
///
/// Par defaut = **premier sens declare par le sentier** (sens « officiel » du
/// JSON, ordre croissant des etapes ; p. ex. `'NS'` ou `'EW'`). Le choix du
/// parcours (entier/moitie) + sens se fait a la preparation
/// (E00 §2.4, PT-E00-3) : ce provider est le point d'ecriture de ce choix
/// (`ref.read(selectedDirectionProvider.notifier).state = 'SN'`). Un sentier
/// mono-sens n'a qu'un code : aucun choix impose.
final selectedDirectionProvider = StateProvider<String?>((ref) => null);

/// Plan de marche courant : sequence d'etapes **dans le sens de marche** +
/// direction + perimetre (entier/partiel). Source unique, direction-aware, de
/// la « premiere » / « derniere » etape du trek — sans nombre d'etapes en dur.
///
/// Modelise le couple (direction, parcours) de facon generique. Construit
/// depuis les etapes du sentier actif ([domainStagesProvider]) et le sens choisi
/// ([selectedDirectionProvider], defaut = 1er sens du sentier). Le sens
/// « croissant » de reference (`forwardDirectionCode`) = premier code de
/// `TrailConfig.directions` (fourni par le sentier, jamais devine). Retourne
/// null tant qu'aucune etape n'est chargee.
///
/// NOTE : par defaut le parcours couvre le **sentier entier**. La restriction a
/// un sous-ensemble (demi-parcours, section) se fera via l'ecran de preparation
/// (parcours §2.4) en surchargeant ce provider — le moteur de fin de trek est
/// deja pret a la recevoir (TrekPlan.stageIds).
final currentTrekPlanProvider = Provider<TrekPlan?>((ref) {
  final stages = ref.watch(domainStagesProvider);
  if (stages.isEmpty) return null;

  final config = ref.watch(trailConfigProvider);
  final directions = config.directions;
  // Sens de reference (ordre croissant des etapes) = 1er sens du sentier.
  final forward = directions.isNotEmpty ? directions.first : 'NS';
  final selected = ref.watch(selectedDirectionProvider) ?? forward;

  return TrekPlan.fromStages(
    stages,
    direction: selected,
    forwardDirectionCode: forward,
  );
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
/// Pipeline : positionStream + domainStages + plan -> arrivalDetection ->
/// ArrivalEvent. Emet quand le randonneur atteint la fin d'une etape (stageEnd)
/// ou la **vraie derniere etape du parcours dans le sens de marche** (trailEnd,
/// direction-aware via [currentTrekPlanProvider]). Aucune arrivee a l'etape de
/// depart (garde anti-felicitations prematurees). Guard anti-doublon integre.
final arrivalEventsProvider = StreamProvider<ArrivalEvent>((ref) {
  final arrivalService = ref.watch(arrivalDetectionServiceProvider);
  final gpsService = ref.watch(gpsServiceProvider);
  final stages = ref.watch(domainStagesProvider);
  final plan = ref.watch(currentTrekPlanProvider);

  if (stages.isEmpty) return const Stream.empty();

  final positionStream = gpsService.getPositionStream();
  return arrivalService.arrivalEvents(positionStream, stages, plan: plan);
});

/// Felicitations de fin de trek pour le parcours courant — complet vs partiel.
///
/// Derive du plan de marche ([currentTrekPlanProvider]) : parcours entier =>
/// felicitations completes, sous-ensemble => felicitations de parcours partiel.
/// Null tant qu'aucun plan (pas d'etapes). Le libelle i18n final reste a la
/// charge de l'UI (aucune chaine ici).
final trekCongratulationsProvider = Provider<TrekCongratulations?>((ref) {
  final plan = ref.watch(currentTrekPlanProvider);
  if (plan == null) return null;
  return TrekCongratulations.forPlan(plan);
});

/// Pont **detection d'arrivee finale -> completion de session**.
///
/// Ecoute [arrivalEventsProvider] et, sur un evenement `trailEnd` (vraie
/// derniere etape du parcours dans le sens de marche, direction-aware),
/// finalise la session via `TrekSessionManagerNotifier.completeOnArrival()` :
/// la completion du trek est declenchee UNIQUEMENT a la derniere etape reelle.
///
/// Les evenements `stageEnd` ne terminent PAS le trek : l'avancement d'etape
/// reste pilote par ailleurs (la detection propose, cf. E13 RM-3). Ce provider
/// doit etre **observe** (ex. `ref.listen`/`ref.watch` au montage de l'ecran de
/// trek) pour etre actif.
final arrivalCompletionListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<ArrivalEvent>>(arrivalEventsProvider, (prev, next) {
    final event = next.valueOrNull;
    if (event == null) return;
    if (event.type != 'trailEnd') return;
    // Fin reelle du trek atteinte -> completer la session.
    ref.read(trekSessionManagerProvider.notifier).completeOnArrival();
  });
});
