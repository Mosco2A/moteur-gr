import 'package:freezed_annotation/freezed_annotation.dart';

part 'feasibility_result.freezed.dart';
part 'feasibility_result.g.dart';

/// Resultat d'une evaluation de faisabilite.
///
/// Score de 0 a 100, nombre de jours recommandes,
/// liste d'avertissements, et en mode groupe, l'index du pire profil.
@freezed
abstract class FeasibilityResult with _$FeasibilityResult {
  const FeasibilityResult._();

  const factory FeasibilityResult({
    /// Score de faisabilite (0-100, 100 = tres faisable)
    required double score,

    /// Nombre de jours recommandes pour le parcours
    required int recommendedDays,

    /// Liste d'avertissements (ex: denivele trop important, meteo)
    required List<String> warnings,

    /// True si l'evaluation porte sur un groupe
    @Default(false) bool isGroupAssessment,

    /// Index du profil le plus faible dans le groupe (null si solo)
    int? worstProfileIndex,
  }) = _FeasibilityResult;

  /// Deserialisation depuis JSON
  factory FeasibilityResult.fromJson(Map<String, dynamic> json) =>
      _$FeasibilityResultFromJson(json);
}
