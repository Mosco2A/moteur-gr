import 'package:freezed_annotation/freezed_annotation.dart';

part 'trail_feasibility_params.freezed.dart';
part 'trail_feasibility_params.g.dart';

/// Parametres de faisabilite specifiques au sentier.
///
/// Facteurs d'ajustement pour le calcul de difficulte
/// (altitude, technique, chaleur, neige) et templates
/// de recommandations personnalisables.
@freezed
class TrailFeasibilityParams with _$TrailFeasibilityParams {
  const TrailFeasibilityParams._();

  const factory TrailFeasibilityParams({
    /// Facteur d'ajustement pour l'altitude (1.0 = neutre)
    @Default(1.0) double altitudeFactor,

    /// Facteur d'ajustement pour la technicite (1.0 = neutre)
    @Default(1.0) double technicalFactor,

    /// Facteur d'ajustement pour la chaleur (1.0 = neutre)
    @Default(1.0) double heatFactor,

    /// Facteur d'ajustement pour la neige (1.0 = neutre)
    @Default(1.0) double snowFactor,

    /// Conditions specifiques au sentier (libres)
    @Default({}) Map<String, double> customConditions,

    /// Templates de recommandations par niveau de score
    @Default({}) Map<String, String> recommendationTemplates,
  }) = _TrailFeasibilityParams;

  /// Facteur combine (produit de tous les facteurs)
  double get combinedFactor =>
      altitudeFactor * technicalFactor * heatFactor * snowFactor;

  /// Deserialisation depuis JSON
  factory TrailFeasibilityParams.fromJson(Map<String, dynamic> json) =>
      _$TrailFeasibilityParamsFromJson(json);
}
