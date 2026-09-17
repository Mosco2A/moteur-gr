import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import '../domain/itinerary_calculator.dart';
import '../domain/models/feasibility_profile.dart';
import '../domain/models/itinerary_config.dart';
import '../domain/models/itinerary_day.dart';
import '../../trail/domain/models/trail_feasibility_params.dart';
import 'gps_providers.dart';
import 'stage_providers.dart';
import '../../trail/providers/trail_providers.dart';

/// Configuration d'itineraire modifiable par l'utilisateur.
///
/// Valeurs par defaut raisonnables pour un randonneur moyen.
/// Modifiable via ref.read(itineraryConfigProvider.notifier).state = ...
final itineraryConfigProvider = StateProvider<ItineraryConfig>(
  (ref) => ItineraryConfig(
    maxKmPerDay: 20.0,
    maxHoursPerDay: 8.0,
    startDate: DateTime.now(),
    difficultyLevel: 'moderate',
  ),
);

/// Profil de faisabilite par defaut (solo, intermediaire).
///
/// Overridable pour supporter le mode groupe.
final feasibilityProfileProvider = StateProvider<FeasibilityProfile>(
  (ref) => const FeasibilityProfile(
    fitnessLevel: 'intermediate',
    experience: 'experienced',
    maxKmPerDay: 25.0,
    maxHoursPerDay: 10.0,
  ),
);

/// Provider de l'itineraire calcule.
///
/// Charge les etapes depuis stagesProvider, recupere les
/// TrailFeasibilityParams depuis trailDataProvider, puis
/// passe le tout a ItineraryCalculator.calculate().
/// Utilise select() sur stagesProvider pour ne rebuilder
/// que si la liste change.
final itineraryProvider = FutureProvider<List<ItineraryDay>>((ref) async {
  // Charger les etapes du sentier actif
  final stages = await ref.watch(stagesProvider.future);
  if (stages.isEmpty) return [];

  // Recuperer la config utilisateur (select pour precision)
  final config = ref.watch(itineraryConfigProvider.select((c) => c));

  // Recuperer le profil de faisabilite
  final profile = ref.watch(feasibilityProfileProvider.select((p) => p));

  // Charger les parametres de faisabilite du sentier
  final trailParams = _buildTrailFeasibilityParams(ref);

  // Trier les etapes par numero (sens de reference, ordre croissant).
  final sorted = List<StageModel>.of(stages)
    ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

  // Retour Chris #12b (LOT 2) : l'itineraire suit le SENS DE MARCHE choisi
  // ([selectedDirectionProvider]). Le sens de reference (ordre croissant) = 1er
  // code de `TrailConfig.directions` (fourni par le sentier, jamais devine).
  // Quand l'utilisateur inverse le sens, on inverse l'ORDRE des etapes AVANT le
  // calcul des jours : le calculateur regroupe alors la sequence inversee
  // (Jour 1 = ancienne derniere etape). Direction-aware, sans nombre en dur.
  final directions = ref.watch(trailConfigProvider.select((c) => c.directions));
  final forward = directions.isNotEmpty ? directions.first : null;
  final selected = ref.watch(selectedDirectionProvider);
  final reversed = forward != null && selected != null && selected != forward;
  final ordered = reversed ? sorted.reversed.toList() : sorted;

  // Calculer l'itineraire
  return ItineraryCalculator.calculate(ordered, config, profile, trailParams);
});

/// Construit les TrailFeasibilityParams depuis le trailDataProvider.
///
/// Retourne des parametres neutres si aucun n'est configure
/// pour le sentier actif. Ajuste altitudeFactor si le sentier
/// a un denivele total eleve.
TrailFeasibilityParams _buildTrailFeasibilityParams(Ref ref) {
  final dataProvider = ref.watch(trailDataProvider);
  final trailConfig = dataProvider.getTrailConfig();

  // Parametres neutres par defaut -- penalite altitude si D+ > 10 000 m
  return TrailFeasibilityParams(
    altitudeFactor: trailConfig.totalElevationGain > 10000 ? 1.5 : 1.0,
    technicalFactor: 1.0,
    heatFactor: 1.0,
    snowFactor: 1.0,
  );
}
