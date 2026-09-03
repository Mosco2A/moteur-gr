import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/stage.dart';
import '../../trail/providers/stages_provider.dart';
import '../domain/planning_calculator.dart';
import '../models/day_plan.dart';
import '../models/planned_day.dart';
import 'planning_provider.dart';

/// PROGRAMME editable (parite GR20 `plannedDaysProvider`).
///
/// Source generique : les etapes du sentier courant ([stagesProvider]) reparties
/// sur la duree choisie ([selectedDurationProvider], deja pilotee par l'ecran
/// Programme et le reste de l'app). Le calcul initial reutilise
/// [PlanningCalculator.distribute] (meme moteur que la repartition), puis
/// l'utilisateur EDITE : reorganiser, regrouper / separer des etapes, ajouter /
/// supprimer des jours de repos, replanifier. Aucune localite en dur.
///
/// Famille indexee par `trailId` (multi-sentiers). Recree quand les etapes ou la
/// duree changent (via `ref.watch`), en preservant les jours de repos manuels
/// (cache externe [_restDayCacheProvider], meme strategie que GR20).
final plannedDaysProvider = StateNotifierProvider.family<PlannedDaysNotifier,
    List<PlannedDay>, String>((ref, trailId) {
  // Etapes du sentier courant (asynchrones). Tant qu'elles ne sont pas la, on
  // part d'une liste vide : l'ecran affiche alors son etat vide, puis le
  // provider est recree avec les etapes reelles (ref.watch).
  final stagesAsync = ref.watch(stagesProvider(trailId));
  final duration = ref.watch(selectedDurationProvider);
  final stages = stagesAsync.maybeWhen(
    data: (list) => List<StageModel>.of(list)
      ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber)),
    orElse: () => const <StageModel>[],
  );

  final cachedRestDays = ref.read(_restDayCacheProvider);
  final notifier = PlannedDaysNotifier(stages, duration, ref);
  if (cachedRestDays.isNotEmpty) {
    notifier.restoreRestDaysFromCache(cachedRestDays);
  }
  return notifier;
});

/// Cache externe des positions (index) des jours de repos manuels.
///
/// Survit aux recreations du notifier par `ref.watch` (parite GR20 : les repos
/// ajoutes a la main ne doivent pas disparaitre a chaque changement de duree).
final _restDayCacheProvider = StateProvider<List<int>>((ref) => const []);

/// Notifier du PROGRAMME editable (drag & drop, regrouper / separer, repos).
///
/// Porte a l'identique la grammaire d'edition de GR20 (`PlannedDaysNotifier`),
/// mais generique : il opere sur des [StageModel] du sentier courant et non sur
/// une base d'etapes en dur.
class PlannedDaysNotifier extends StateNotifier<List<PlannedDay>> {
  PlannedDaysNotifier(this._stages, this._duration, this._ref)
      : _hasManualEdits = false,
        super(_generate(_stages, _duration));

  final List<StageModel> _stages;
  final int _duration;
  final Ref _ref;

  bool _hasManualEdits;

  /// Limite de temps de marche pour un regroupement manuel (parite GR20 : 16 h).
  static const double maxManualHoursPerDay = 16.0;

  /// Genere le programme initial : repartition des etapes sur la duree via le
  /// meme calculateur que l'ecran de repartition, converti en jours editables.
  static List<PlannedDay> _generate(List<StageModel> stages, int duration) {
    if (stages.isEmpty) return const [];
    final plans = PlanningCalculator.distribute(stages, duration);
    return _fromDayPlans(plans);
  }

  /// Convertit les [DayPlan] (calcul) en [PlannedDay] (editables) puis
  /// renumerote. Un [DayPlan.isRestDay] devient un jour de repos sans etape.
  static List<PlannedDay> _fromDayPlans(List<DayPlan> plans) {
    final days = <PlannedDay>[];
    for (final p in plans) {
      days.add(PlannedDay(
        dayNumber: p.dayNumber,
        stages: p.isRestDay ? const [] : List<StageModel>.of(p.stages),
        isRestDay: p.isRestDay,
      ));
    }
    return _renumber(days);
  }

  // --- Etat derive ---

  /// Indique si le programme contient au moins un jour de repos.
  bool get hasManualRestDays => state.any((d) => d.isRestDay);

  /// Indique si l'utilisateur a fait des modifications manuelles.
  bool get hasManualEdits => _hasManualEdits;

  // --- Edition : reorganiser ---

  /// Reordonne les jours (drag & drop). Corrige l'index cible comme le
  /// `ReorderableListView` de Material (parite GR20).
  void reorder(int oldIndex, int newIndex) {
    final days = List<PlannedDay>.of(state);
    if (newIndex > oldIndex) newIndex--;
    final item = days.removeAt(oldIndex);
    days.insert(newIndex, item);
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  // --- Edition : jours de repos ---

  /// Ajoute un jour de repos apres [afterIndex] (parite GR20).
  void addRestDay(int afterIndex) {
    final days = List<PlannedDay>.of(state);
    days.insert(
      afterIndex + 1,
      const PlannedDay(dayNumber: 0, stages: [], isRestDay: true),
    );
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  /// Supprime le jour de repos a [index] (parite GR20).
  void removeRestDay(int index) {
    if (index < 0 || index >= state.length) return;
    if (!state[index].isRestDay) return;
    final days = List<PlannedDay>.of(state)..removeAt(index);
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  // --- Edition : regrouper / separer (parite GR20 merge / split) ---

  double _hoursFor(List<StageModel> stages) => stages.fold<double>(
      0, (sum, s) => sum + PlanningCalculator.estimatedHours(s));

  /// Message explicatif si le regroupement avec le jour suivant est impossible.
  /// `null` si le regroupement est possible (parite GR20 `mergeBlockedReason`,
  /// libelles i18n a l'appelant : ici on ne renvoie qu'un code semantique).
  String? mergeBlockedReason(int dayIndex) {
    if (dayIndex < 0 || dayIndex + 1 >= state.length) return 'no-next';
    final a = state[dayIndex];
    final b = state[dayIndex + 1];
    if (a.isRestDay || b.isRestDay) return 'rest';
    final hours = _hoursFor([...a.stages, ...b.stages]);
    if (hours > maxManualHoursPerDay) return 'too-long';
    return null;
  }

  /// Vrai si le jour [dayIndex] peut etre regroupe avec le suivant.
  bool canMergeWithNext(int dayIndex) => mergeBlockedReason(dayIndex) == null;

  /// Regroupe le jour [dayIndex] avec le suivant (parite GR20).
  void mergeWithNext(int dayIndex) {
    if (!canMergeWithNext(dayIndex)) return;
    final days = List<PlannedDay>.of(state);
    final a = days[dayIndex];
    final b = days[dayIndex + 1];
    days[dayIndex] = a.copyWith(stages: [...a.stages, ...b.stages]);
    days.removeAt(dayIndex + 1);
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  /// Vrai si le jour [dayIndex] (multi-etapes, hors repos) peut etre separe.
  bool canSplit(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= state.length) return false;
    final day = state[dayIndex];
    return !day.isRestDay && day.stages.length > 1;
  }

  /// Separe un jour multi-etapes en N jours d'une etape (parite GR20).
  void splitDay(int dayIndex) {
    if (!canSplit(dayIndex)) return;
    final days = List<PlannedDay>.of(state);
    final toSplit = days[dayIndex];
    final newDays = toSplit.stages
        .map((s) => PlannedDay(dayNumber: 0, stages: [s]))
        .toList(growable: false);
    days.removeAt(dayIndex);
    days.insertAll(dayIndex, newDays);
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  // --- Replanification (parite GR20) ---

  /// Replanifie en preservant les jours de repos manuels a leurs positions.
  void regeneratePreservingRestDays() {
    final restIndices = <int>[];
    for (var i = 0; i < state.length; i++) {
      if (state[i].isRestDay) restIndices.add(i);
    }
    var days = _generate(_stages, _duration);
    var offset = 0;
    for (final restIndex in restIndices) {
      final insertAt = (restIndex + offset).clamp(0, days.length);
      days = List<PlannedDay>.of(days)
        ..insert(insertAt,
            const PlannedDay(dayNumber: 0, stages: [], isRestDay: true));
      offset++;
    }
    _hasManualEdits = restIndices.isNotEmpty;
    state = _renumber(days);
    _updateRestDayCache();
  }

  // --- Restauration / cache ---

  /// Reinjecte les jours de repos depuis le cache externe (appelee a la
  /// (re)creation du notifier). Parite GR20.
  void restoreRestDaysFromCache(List<int> cachedIndices) {
    var days = List<PlannedDay>.of(state);
    var offset = 0;
    for (final restIndex in cachedIndices) {
      final insertAt = (restIndex + offset).clamp(0, days.length);
      days.insert(
          insertAt, const PlannedDay(dayNumber: 0, stages: [], isRestDay: true));
      offset++;
    }
    _hasManualEdits = cachedIndices.isNotEmpty;
    state = _renumber(days);
  }

  void _updateRestDayCache() {
    final indices = <int>[];
    for (var i = 0; i < state.length; i++) {
      if (state[i].isRestDay) indices.add(i);
    }
    _ref.read(_restDayCacheProvider.notifier).state = indices;
  }

  /// Renumerote les jours (1-indexed) apres toute mutation.
  static List<PlannedDay> _renumber(List<PlannedDay> days) =>
      List.generate(days.length, (i) => days[i].copyWith(dayNumber: i + 1));
}

/// Statistiques agregees du PROGRAMME courant (parite GR20 `planningStatsProvider`).
///
/// Refletent les editions manuelles (recalcul depuis l'etat des jours).
final planningStatsProvider =
    Provider.family<PlanningStats, String>((ref, trailId) {
  final days = ref.watch(plannedDaysProvider(trailId));

  var totalDistance = 0.0;
  var totalGain = 0;
  var totalLoss = 0;
  var totalHours = 0.0;
  var stageCount = 0;
  for (final day in days) {
    if (day.isRestDay) continue;
    totalDistance += day.totalDistanceKm;
    totalGain += day.totalElevationGainM;
    totalLoss += day.totalElevationLossM;
    totalHours += day.estimatedHours;
    stageCount += day.stages.length;
  }
  final restDays = days.where((d) => d.isRestDay).length;
  final trekDays = days.where((d) => !d.isRestDay).length;

  return PlanningStats(
    totalDistance: totalDistance,
    totalElevationGain: totalGain,
    totalElevationLoss: totalLoss,
    totalHours: totalHours,
    trekDays: trekDays,
    restDays: restDays,
    stageCount: stageCount,
  );
});

/// Statistiques du programme (parite GR20 `PlanningStats`).
class PlanningStats {
  const PlanningStats({
    required this.totalDistance,
    required this.totalElevationGain,
    required this.totalElevationLoss,
    required this.totalHours,
    required this.trekDays,
    required this.restDays,
    required this.stageCount,
  });

  final double totalDistance;
  final int totalElevationGain;
  final int totalElevationLoss;
  final double totalHours;
  final int trekDays;
  final int restDays;
  final int stageCount;

  int get totalDays => trekDays + restDays;
}
