import '../../../core/models/stage.dart';
import '../models/day_plan.dart';

/// Calculateur de planning : répartit N étapes sur D jours.
///
/// Algorithme greedy qui équilibre la charge entre les jours
/// en se basant sur un score de difficulté par étape
/// (distance + dénivelé positif / 100).
class PlanningCalculator {
  const PlanningCalculator._();

  /// Calcule le score de difficulté d'une étape.
  ///
  /// Formule : distanceKm + elevationGainM / 100
  /// Plus le score est élevé, plus l'étape est exigeante.
  static double stageScore(StageModel stage) {
    return stage.distanceKm + stage.elevationGainM / 100.0;
  }

  /// Calcule la durée estimée en heures pour une étape.
  ///
  /// Formule randonneur : distance / 4 km/h + dénivelé positif / 400 m/h
  static double estimatedHours(StageModel stage) {
    return stage.distanceKm / 4.0 + stage.elevationGainM / 400.0;
  }

  /// Répartit les [stages] sur [days] jours de manière équilibrée.
  ///
  /// - Si jours >= étapes : une étape par jour, les jours restants
  ///   deviennent des jours de repos.
  /// - Si jours < étapes : distribution greedy qui minimise l'écart
  ///   de score entre les jours.
  /// - Les étapes conservent leur ordre séquentiel (pas de mélange).
  static List<DayPlan> distribute(List<StageModel> stages, int days) {
    if (stages.isEmpty || days <= 0) return [];

    if (days >= stages.length) {
      return _distributeWithRestDays(stages, days);
    }

    return _distributeGreedy(stages, days);
  }

  /// Distribution quand il y a assez de jours pour tout le monde.
  static List<DayPlan> _distributeWithRestDays(
    List<StageModel> stages,
    int days,
  ) {
    final result = <DayPlan>[];
    final restDays = days - stages.length;
    final restPositions =
        _computeRestPositions(stages.length, restDays);

    var dayNumber = 1;
    for (var i = 0; i < stages.length; i++) {
      final restBefore = restPositions[i];
      for (var r = 0; r < restBefore; r++) {
        result.add(DayPlan(
          dayNumber: dayNumber,
          stages: const [],
          totalDistanceKm: 0,
          totalElevationGainM: 0,
          estimatedDurationHours: 0,
          isRestDay: true,
        ));
        dayNumber++;
      }

      final stage = stages[i];
      result.add(DayPlan(
        dayNumber: dayNumber,
        stages: [stage],
        totalDistanceKm: stage.distanceKm,
        totalElevationGainM: stage.elevationGainM,
        estimatedDurationHours: estimatedHours(stage),
        isRestDay: false,
      ));
      dayNumber++;
    }

    while (result.length < days) {
      result.add(DayPlan(
        dayNumber: dayNumber,
        stages: const [],
        totalDistanceKm: 0,
        totalElevationGainM: 0,
        estimatedDurationHours: 0,
        isRestDay: true,
      ));
      dayNumber++;
    }

    return result;
  }

  /// Calcule combien de jours de repos placer avant chaque étape.
  static List<int> _computeRestPositions(
    int stageCount,
    int restDays,
  ) {
    final positions = List.filled(stageCount, 0);
    if (restDays <= 0) return positions;

    final interval = stageCount / (restDays + 1);
    for (var r = 0; r < restDays; r++) {
      final pos =
          ((r + 1) * interval).round().clamp(0, stageCount - 1);
      positions[pos]++;
    }

    return positions;
  }

  /// Distribution greedy quand il y a plus d'étapes que de jours.
  ///
  /// Approche DP simplifiée : calcule les points de coupure optimaux
  /// pour répartir les étapes séquentiellement en [days] groupes,
  /// minimisant l'écart de score maximum entre groupes.
  static List<DayPlan> _distributeGreedy(
    List<StageModel> stages,
    int days,
  ) {
    final n = stages.length;
    final scores =
        stages.map((s) => stageScore(s)).toList();

    // Calculer les sommes de préfixes pour accès O(1)
    final prefix = List.filled(n + 1, 0.0);
    for (var i = 0; i < n; i++) {
      prefix[i + 1] = prefix[i] + scores[i];
    }
    final totalScore = prefix[n];
    final targetPerDay = totalScore / days;

    // Trouver les points de coupure greedy en visant la cible
    final cutPoints = <int>[]; // indices de début de chaque groupe
    cutPoints.add(0);

    var accumulated = 0.0;
    for (var i = 0; i < n && cutPoints.length < days; i++) {
      accumulated += scores[i];
      final remainingCuts = days - cutPoints.length;
      final remainingStages = n - i - 1;

      // Si le score accumulé dépasse la cible et qu'il reste
      // assez d'étapes pour les jours restants
      if (accumulated >= targetPerDay &&
          remainingStages >= remainingCuts) {
        cutPoints.add(i + 1);
        accumulated = 0;
      }
    }

    // Construire les groupes à partir des points de coupure
    final groups = <List<StageModel>>[];
    for (var g = 0; g < cutPoints.length; g++) {
      final start = cutPoints[g];
      final end =
          g + 1 < cutPoints.length ? cutPoints[g + 1] : n;
      groups.add(stages.sublist(start, end));
    }

    // Construire les DayPlan
    return groups.asMap().entries.map((entry) {
      final stageList = entry.value;
      final totalDist = stageList.fold<double>(
        0,
        (sum, s) => sum + s.distanceKm,
      );
      final totalGain = stageList.fold<int>(
        0,
        (sum, s) => sum + s.elevationGainM,
      );
      final totalHours = stageList.fold<double>(
        0,
        (sum, s) => sum + estimatedHours(s),
      );

      return DayPlan(
        dayNumber: entry.key + 1,
        stages: stageList,
        totalDistanceKm: totalDist,
        totalElevationGainM: totalGain,
        estimatedDurationHours: totalHours,
        isRestDay: false,
      );
    }).toList();
  }
}
