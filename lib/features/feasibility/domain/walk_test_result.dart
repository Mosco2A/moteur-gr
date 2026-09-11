import 'package:freezed_annotation/freezed_annotation.dart';

part 'walk_test_result.freezed.dart';
part 'walk_test_result.g.dart';

/// Resultat DATE d'un test de marche 6 minutes (StepWays LOT 4, Ph2).
///
/// Stocke la distance mesuree (m), le niveau objectif deduit (cle i18n
/// `t.walkTest.levels.*`) et la date de realisation. Recurrent (~1x/mois) :
/// seul le DERNIER resultat est conserve (le test se refait pour suivre les
/// progres). `null` cote provider = test jamais fait -> fallback auto-eval.
@freezed
abstract class WalkTestResult with _$WalkTestResult {
  const WalkTestResult._();

  const factory WalkTestResult({
    /// Distance parcourue en 6 minutes, en metres.
    required double distanceMeters,

    /// Niveau objectif deduit (voir `WalkTestLevel`).
    required String level,

    /// Date de realisation du test.
    required DateTime takenAt,
  }) = _WalkTestResult;

  /// Deserialisation depuis JSON (prefs / miroir cloud).
  factory WalkTestResult.fromJson(Map<String, dynamic> json) =>
      _$WalkTestResultFromJson(json);
}
