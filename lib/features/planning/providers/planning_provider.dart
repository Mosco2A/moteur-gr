import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../features/trail/providers/stages_provider.dart';
import '../data/retained_plan_store.dart';
import '../domain/planning_calculator.dart';
import '../models/day_plan.dart';

/// Acces au stockage durable du decoupage retenu (surchargeable en test).
final retainedPlanStoreProvider =
    Provider<RetainedPlanStore>((ref) => const RetainedPlanStore());

/// DECOUPAGE RETENU par le randonneur pour le sentier courant — `null` tant
/// qu'il n'a rien choisi (correctif N2 / D2, mandat #100293).
///
/// C'est la DECISION, pas l'etat d'ecran : appliquer la reco de la faisabilite
/// ou bouger le curseur du Programme ecrit ici, et ce qui est ecrit ici
/// SURVIT au redemarrage (cf. [RetainedPlanStore]). Avant ce correctif, le
/// choix ne vivait qu'en memoire : choisir « 8 jours » ne laissait aucune
/// trace, ce qui rendait le bouton indistinguable d'un bouton mort.
///
/// Une valeur PAR SENTIER : changer de sentier recharge le plan de ce sentier.
class RetainedDurationNotifier extends Notifier<int?> {
  /// Sentier dont on porte le decoupage (re-lu a chaque bascule de sentier).
  String _trailId = '';

  @override
  int? build() {
    _trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    // Hydratation depuis le stockage durable. Asynchrone par nature : on rend
    // d'abord « aucun choix » (le sentier garde sa duree par defaut), puis on
    // pose la valeur retenue des qu'elle arrive. Meme patron que
    // `DownloadReminderNotifier` — `ref.mounted` protege du « Ref used after
    // dispose » si le provider est recycle pendant l'attente.
    _restore(_trailId);
    return null;
  }

  Future<void> _restore(String trailId) async {
    final days = await ref.read(retainedPlanStoreProvider).read(trailId);
    if (!ref.mounted || days == null) return;
    // Un changement de sentier pendant l'attente rendrait la valeur caduque.
    if (trailId != _trailId) return;
    state = days;
  }

  /// RETIENT [days] jours pour le sentier courant : effet immediat a l'ecran
  /// (le Programme, l'Itineraire et le Calendrier suivent) ET ecriture durable.
  Future<void> retain(int days) async {
    if (days <= 0) return;
    state = days;
    await ref.read(retainedPlanStoreProvider).write(_trailId, days);
  }

  /// Oublie le decoupage retenu : le sentier revient a sa duree par defaut.
  Future<void> forget() async {
    state = null;
    await ref.read(retainedPlanStoreProvider).clear(_trailId);
  }
}

final retainedDurationProvider =
    NotifierProvider<RetainedDurationNotifier, int?>(
        RetainedDurationNotifier.new);

/// Duree EFFECTIVE du programme, en jours — source unique lue par le
/// Programme, l'Itineraire, le Calendrier et le Resume.
///
/// = le decoupage RETENU par le randonneur s'il en a choisi un
/// ([retainedDurationProvider]), sinon la duree par defaut du sentier.
class SelectedDurationNotifier extends Notifier<int> {
  @override
  int build() {
    final fallback =
        ref.watch(trailConfigProvider.select((c) => c.defaultDuration));
    return ref.watch(retainedDurationProvider) ?? fallback;
  }

  /// Change la duree ET la retient durablement (D2) : toute duree choisie par
  /// le randonneur est une decision, d'ou qu'elle vienne — reco de la
  /// faisabilite ou curseur du Programme.
  void set(int duration) =>
      ref.read(retainedDurationProvider.notifier).retain(duration);
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
