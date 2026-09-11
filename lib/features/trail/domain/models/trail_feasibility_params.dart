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

    // --- Cotation FFRandonnee (StepWays LOT 4, Ph4) ------------------------
    // 3 notes independantes 1-5 (FFRandonnee). Etend le modele au-dela du
    // simple `difficulty` (string). Nullable = non renseigne par ce sentier.

    /// EFFORT (1-5) — derive de l'indice IBP calcule sur le trace GPX
    /// (`IbpCalculator`). Peut etre pre-renseigne par la donnee du sentier ou
    /// calcule a la volee. Null = non cote.
    int? effortRating,

    /// TECHNICITE du terrain (1-5). Donnee du sentier (renseignee/tenue a jour
    /// par le systeme de donnees, DECISIONS §4.2). Null = non cotee.
    int? technicite,

    /// RISQUE — gravite d'une chute (1-5). Donnee du sentier. Null = non cote.
    int? risque,
  }) = _TrailFeasibilityParams;

  /// Deserialisation depuis JSON
  factory TrailFeasibilityParams.fromJson(Map<String, dynamic> json) =>
      _$TrailFeasibilityParamsFromJson(json);
}
