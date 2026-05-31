import 'package:freezed_annotation/freezed_annotation.dart';

part 'trail_feasibility_params.freezed.dart';
part 'trail_feasibility_params.g.dart';

/// Parametres de faisabilite specifiques a un sentier.
///
/// Facteurs d'ajustement pour le calcul de faisabilite :
/// altitude, technicite, chaleur, neige, conditions custom.
/// Inclut des templates de recommandation par cle.
@freezed
abstract class TrailFeasibilityParams with _$TrailFeasibilityParams {
  const TrailFeasibilityParams._();

  const factory TrailFeasibilityParams({
    /// Facteur d'ajustement altitude (1.0 = neutre, >1 = plus difficile)
    required double altitudeFactor,

    /// Facteur d'ajustement technicite (1.0 = neutre)
    required double technicalFactor,

    /// Facteur d'ajustement chaleur (1.0 = neutre)
    required double heatFactor,

    /// Facteur d'ajustement neige (1.0 = neutre)
    required double snowFactor,

    /// Conditions supplementaires personnalisees
    @Default([]) List<String> customConditions,

    /// Templates de recommandation par cle (ex: "heat" -> "Prevoyez 3L d'eau/jour")
    @Default({}) Map<String, String> recommendationTemplates,
  }) = _TrailFeasibilityParams;

  /// Deserialisation depuis JSON
  factory TrailFeasibilityParams.fromJson(Map<String, dynamic> json) =>
      _$TrailFeasibilityParamsFromJson(json);
}
