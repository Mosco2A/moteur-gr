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

/// Bornes de duree (en jours) DERIVEES du nombre d'etapes du sentier.
///
/// Generique, jamais hardcode (pas de « 16 » en dur) : les bornes suivent le
/// nombre reel d'etapes charge pour le sentier courant, a la maniere de GR20
/// qui borne le curseur de duree selon le parcours.
///
/// Modele de duree = CIBLE (parite GR20) :
///  - `jours >= etapes` : une etape par jour, le surplus devient des jours de
///    repos (jusqu'a [maxDuration]) ;
///  - `jours < etapes`  : regroupement d'etapes (jusqu'a [minDuration]).
///
/// Bornes :
///  - min = moitie du nombre d'etapes (arrondi au superieur, plancher 1) :
///    borne basse raisonnable de regroupement (~2 etapes/jour au plus dense) ;
///  - max = nombre d'etapes + une marge de repos (~1/3 des etapes, plancher +1) :
///    laisse ajouter des jours de repos sans exploser la liste.
class DurationBounds {
  const DurationBounds({required this.min, required this.max});

  final int min;
  final int max;

  /// Calcule les bornes a partir du nombre d'etapes.
  factory DurationBounds.fromStageCount(int stageCount) {
    if (stageCount <= 0) return const DurationBounds(min: 1, max: 1);
    if (stageCount == 1) return const DurationBounds(min: 1, max: 1);
    final min = (stageCount / 2).ceil().clamp(1, stageCount);
    final restMargin = (stageCount / 3).round().clamp(1, stageCount);
    final max = stageCount + restMargin;
    return DurationBounds(min: min, max: max);
  }

  /// Liste discrete des durees proposees (min..max inclus), pour le selecteur.
  List<int> get options =>
      List<int>.generate(max - min + 1, (i) => min + i);

  /// Ramene une duree dans les bornes.
  int clampDuration(int duration) => duration.clamp(min, max);
}

/// Bornes de duree du sentier courant (derivees du nombre d'etapes charge).
///
/// Tant que les etapes ne sont pas chargees, se rabat sur les bornes de la
/// config du sentier ([TrailConfig.availableDurations]) pour rester coherent
/// avant l'arrivee des donnees.
final durationBoundsProvider =
    Provider.family<DurationBounds, String>((ref, trailId) {
  final stagesAsync = ref.watch(stagesProvider(trailId));
  return stagesAsync.maybeWhen(
    data: (stages) => DurationBounds.fromStageCount(stages.length),
    orElse: () {
      final config = ref.watch(trailConfigProvider);
      final durations = config.availableDurations;
      if (durations.isEmpty) {
        return DurationBounds(
            min: config.defaultDuration, max: config.defaultDuration);
      }
      return DurationBounds(
        min: durations.reduce((a, b) => a < b ? a : b),
        max: durations.reduce((a, b) => a > b ? a : b),
      );
    },
  );
});
