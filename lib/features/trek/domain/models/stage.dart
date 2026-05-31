import 'package:freezed_annotation/freezed_annotation.dart';

part 'stage.freezed.dart';
part 'stage.g.dart';

/// Modele immutable representant une etape de sentier.
///
/// Supporte i18n 5 langues (fr, en, de, it, es),
/// coordonnees GPS depart/arrivee, et difficulte extensible (String).
@freezed
abstract class Stage with _$Stage {
  const Stage._();

  const factory Stage({
    /// Identifiant unique de l'etape
    required String id,

    /// Nom — francais
    required String nameFr,

    /// Nom — anglais
    @Default('') String nameEn,

    /// Nom — allemand
    @Default('') String nameDe,

    /// Nom — italien
    @Default('') String nameIt,

    /// Nom — espagnol
    @Default('') String nameEs,

    /// Distance en kilometres
    required double distance,

    /// Denivele positif en metres
    required int elevationGain,

    /// Denivele negatif en metres
    required int elevationLoss,

    /// Duree estimee en secondes (serialisable)
    @Default(0) int estimatedDurationSeconds,

    /// Difficulte — String extensible (easy, moderate, hard, extreme, ...)
    @Default('moderate') String difficulty,

    /// Ordre d'affichage (1-indexed)
    required int orderIndex,

    /// Latitude du point de depart
    required double startLat,

    /// Longitude du point de depart
    required double startLng,

    /// Latitude du point d'arrivee
    required double endLat,

    /// Longitude du point d'arrivee
    required double endLng,

    /// Description — francais
    @Default('') String descriptionFr,

    /// Description — anglais
    @Default('') String descriptionEn,

    /// Description — allemand
    @Default('') String descriptionDe,

    /// Description — italien
    @Default('') String descriptionIt,

    /// Description — espagnol
    @Default('') String descriptionEs,
  }) = _Stage;

  /// Duree estimee sous forme de Duration
  Duration get estimatedDuration =>
      Duration(seconds: estimatedDurationSeconds);

  /// Deserialisation depuis JSON
  factory Stage.fromJson(Map<String, dynamic> json) => _$StageFromJson(json);
}
