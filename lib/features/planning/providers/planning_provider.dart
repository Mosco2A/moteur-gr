import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../features/trail/providers/stages_provider.dart';
import '../domain/planning_calculator.dart';
import '../models/day_plan.dart';

/// Provider de la durée sélectionnée par l'utilisateur (en jours).
///
/// Initialisé avec la valeur par défaut de la configuration du sentier.
/// Mis à jour quand l'utilisateur change la durée dans le sélecteur.
final selectedDurationProvider = StateProvider<int>((ref) {
  final config = ref.watch(trailConfigProvider);
  return config.defaultDuration;
});

/// Provider du planning calculé.
///
/// Combine les étapes du sentier (stagesProvider) et la durée
/// choisie (selectedDurationProvider) pour recalculer le planning
/// via PlanningCalculator à chaque changement.
final planningProvider =
    FutureProvider.family<List<DayPlan>, String>((ref, trailId) async {
  final stages = await ref.watch(stagesProvider(trailId).future);
  final duration = ref.watch(selectedDurationProvider);

  return PlanningCalculator.distribute(stages, duration);
});
