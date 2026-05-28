import 'package:freezed_annotation/freezed_annotation.dart';

part 'feasibility_result.freezed.dart';
part 'feasibility_result.g.dart';

/// Resultat d'une evaluation de faisabilite.
///
/// Score de 0 a 100, nombre de jours recommandes,
/// et avertissements eventuels. En mode groupe,
/// worstProfileIndex pointe vers le profil le plus limitant.
@freezed
class FeasibilityResult with _$FeasibilityResult {
  const FeasibilityResult._();

  const factory FeasibilityResult({
    /// Score de faisabilite (0 = impossible, 100 = facile)
    required double score,

    /// Nombre de jours recommandes
    required int recommendedDays,

    /// Liste des avertissements
    @Default([]) List<String> warnings,

    /// True si evaluation en mode groupe
    @Default(false) bool isGroupAssessment,

    /// Index du profil le plus limitant dans le groupe (null si solo)
    int? worstProfileIndex,
  }) = _FeasibilityResult;

  /// Le trek est-il faisable ? (score >= 30)
  bool get isFeasible => score >= 30;

  /// Deserialisation depuis JSON
  factory FeasibilityResult.fromJson(Map<String, dynamic> json) =>
      _$FeasibilityResultFromJson(json);
}
