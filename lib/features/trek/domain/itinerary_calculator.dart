import 'dart:math';

import '../../../core/models/stage.dart';
import '../../../core/models/stage_duration.dart';
import 'models/feasibility_profile.dart';
import 'models/itinerary_config.dart';
import 'models/itinerary_day.dart';
import '../../trail/domain/models/trail_feasibility_params.dart';

/// Calculateur d'itineraire multi-jours.
///
/// Algorithme glouton : ajoute des etapes au jour courant
/// tant que la distance < maxKmPerDay ET la duree < maxHoursPerDay.
/// En mode groupe, utilise le profil le plus conservateur.
/// Calcule un score de faisabilite par jour base sur les facteurs du sentier.
class ItineraryCalculator {
  const ItineraryCalculator._();

  /// Duree estimee en heures pour une etape.
  ///
  /// Source unique [stageDurationMinutes] : privilegie la duree RICHE du sentier
  /// ([StageModel.estimatedDurationMinutes]) quand elle existe, sinon retombe sur
  /// la regle de marche Naismith (distance / 4 km/h + D+ / 400 m/h). La
  /// repartition en jours reste ainsi coherente avec les durees affichees.
  static double _estimatedHours(StageModel stage) =>
      stageDurationMinutes(stage) / 60.0;

  /// Calcule l'itineraire multi-jours a partir des etapes et parametres.
  ///
  /// [stages] : liste ordonnee des etapes a repartir.
  /// [config] : parametres utilisateur (maxKm, maxHeures, date depart).
  /// [profile] : profil de faisabilite (solo ou groupe).
  /// [trailParams] : facteurs d'ajustement du sentier.
  ///
  /// Retourne la liste des [ItineraryDay] avec score de faisabilite.
  static List<ItineraryDay> calculate(
    List<StageModel> stages,
    ItineraryConfig config,
    FeasibilityProfile profile,
    TrailFeasibilityParams trailParams,
  ) {
    if (stages.isEmpty) return [];

    // Determiner les limites effectives (mode groupe = min de tous les profils)
    final effectiveMaxKm = _effectiveMaxKm(config, profile);
    final effectiveMaxHours = _effectiveMaxHours(config, profile);

    // Algorithme glouton : repartir les etapes en jours
    return _greedyDistribute(stages, effectiveMaxKm, effectiveMaxHours);
  }

  /// Distance max effective : min entre config et profil (groupe inclus).
  static double _effectiveMaxKm(
    ItineraryConfig config,
    FeasibilityProfile profile,
  ) {
    var maxKm = min(config.maxKmPerDay, profile.maxKmPerDay);

    if (profile.groupMode && profile.groupProfiles != null) {
      for (final p in profile.groupProfiles!) {
        maxKm = min(maxKm, p.maxKmPerDay);
      }
    }

    return maxKm;
  }

  /// Heures max effectives : min entre config et profil (groupe inclus).
  static double _effectiveMaxHours(
    ItineraryConfig config,
    FeasibilityProfile profile,
  ) {
    var maxHours = min(config.maxHoursPerDay, profile.maxHoursPerDay);

    if (profile.groupMode && profile.groupProfiles != null) {
      for (final p in profile.groupProfiles!) {
        maxHours = min(maxHours, p.maxHoursPerDay);
      }
    }

    return maxHours;
  }

  /// Repartition gloutonne des etapes en jours.
  ///
  /// Ajoute une etape au jour courant tant que :
  /// - distance cumulee + etape <= maxKm
  /// - duree cumulee + etape <= maxHours
  /// Sinon, ouvre un nouveau jour.
  /// Exception : si un jour est vide, l'etape est toujours ajoutee
  /// (une etape trop longue occupe un jour entier).
  static List<ItineraryDay> _greedyDistribute(
    List<StageModel> stages,
    double maxKm,
    double maxHours,
  ) {
    final days = <ItineraryDay>[];
    var currentStages = <StageModel>[];
    var currentDistance = 0.0;
    var currentHours = 0.0;
    var dayNumber = 1;

    for (final stage in stages) {
      final stageHours = _estimatedHours(stage);

      if (currentStages.isNotEmpty &&
          (currentDistance + stage.distanceKm > maxKm ||
              currentHours + stageHours > maxHours)) {
        days.add(_buildDay(
            dayNumber, currentStages, currentDistance, currentHours));
        dayNumber++;
        currentStages = [];
        currentDistance = 0.0;
        currentHours = 0.0;
      }

      currentStages.add(stage);
      currentDistance += stage.distanceKm;
      currentHours += stageHours;
    }

    if (currentStages.isNotEmpty) {
      days.add(
          _buildDay(dayNumber, currentStages, currentDistance, currentHours));
    }

    return days;
  }

  /// Construit un ItineraryDay a partir des donnees accumulees.
  static ItineraryDay _buildDay(
    int dayNumber,
    List<StageModel> stages,
    double totalDistance,
    double estimatedHours,
  ) {
    final totalElevation =
        stages.fold<int>(0, (sum, s) => sum + s.elevationGainM);

    return ItineraryDay(
      dayNumber: dayNumber,
      stages: List.unmodifiable(stages),
      totalDistance: totalDistance,
      totalElevation: totalElevation,
      estimatedHours: estimatedHours,
    );
  }

  /// Calcule le score de faisabilite d'un jour.
  ///
  /// Score = 100 - altitudeFactor * altitudeImpact
  ///             - technicalFactor * technicalImpact
  ///             - heatFactor * heatImpact
  ///             - snowFactor * snowImpact
  ///
  /// Chaque impact est derive des totaux du jour.
  /// Score clamp entre 0 et 100.
  static double feasibilityScore(
    ItineraryDay day,
    TrailFeasibilityParams params,
  ) {
    final altitudeImpact = day.totalElevation / 100.0;
    final technicalImpact = day.stageCount * 5.0;
    final heatImpact = day.estimatedHours * 2.0;
    final snowImpact = day.totalDistance * 3.0;

    final score = 100.0 -
        params.altitudeFactor * altitudeImpact -
        params.technicalFactor * technicalImpact -
        params.heatFactor * heatImpact -
        params.snowFactor * snowImpact;

    return score.clamp(0.0, 100.0);
  }

  /// Genere les recommandations depuis les templates du sentier.
  static List<String> generateRecommendations(
    ItineraryDay day,
    TrailFeasibilityParams params,
  ) {
    final recommendations = <String>[];
    final templates = params.recommendationTemplates;

    if (templates.containsKey('altitude') && day.totalElevation > 500) {
      recommendations.add(templates['altitude']!);
    }

    if (templates.containsKey('heat') && day.estimatedHours > 5.0) {
      recommendations.add(templates['heat']!);
    }

    if (templates.containsKey('snow') && params.snowFactor > 1.0) {
      recommendations.add(templates['snow']!);
    }

    if (templates.containsKey('technical') && params.technicalFactor > 1.0) {
      recommendations.add(templates['technical']!);
    }

    for (final condition in params.customConditions) {
      if (templates.containsKey(condition)) {
        recommendations.add(templates[condition]!);
      }
    }

    return recommendations;
  }
}
