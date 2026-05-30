import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../features/trail/providers/stages_provider.dart';
import '../domain/planning_calculator.dart';
import '../models/day_plan.dart';

/// Notifier pour la duree selectionnee par l'utilisateur (en jours).
///
/// Initialise avec la valeur par defaut de la configuration du sentier.
/// Mis a jour quand l'utilisateur change la duree dans le selecteur.
class SelectedDurationNotifier extends Notifier<int> {
  @override
  int build() {
    return ref.watch(trailConfigProvider.select((c) => c.defaultDuration));
  }

  void set(int duration) => state = duration;
}

final selectedDurationProvider =
    NotifierProvider<SelectedDurationNotifier, int>(
        SelectedDurationNotifier.new);

/// Provider du planning calcule.
///
/// Combine les etapes du sentier (stagesProvider) et la duree
/// choisie (selectedDurationProvider) pour recalculer le planning
/// via PlanningCalculator a chaque changement.
final planningProvider =
    FutureProvider.family<List<DayPlan>, String>((ref, trailId) async {
  final stages = await ref.watch(stagesProvider(trailId).future);
  final duration = ref.watch(selectedDurationProvider);

  return PlanningCalculator.distribute(stages, duration);
});
