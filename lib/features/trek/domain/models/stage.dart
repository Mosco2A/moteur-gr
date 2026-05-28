import 'package:freezed_annotation/freezed_annotation.dart';

part 'stage.freezed.dart';
part 'stage.g.dart';

/// Modele immutable representant une etape de trek.
///
/// Les noms sont i18n (fr, en, de, it, es).
/// La difficulte est un String libre (jamais enum) pour extensibilite (#81752).
@freezed
class Stage with _$Stage {
  const Stage._();

  const factory Stage({
    /// Identifiant unique de l'etape
    required String id,

    /// Nom en francais
    required String nameFr,

    /// Nom en anglais
    required String nameEn,

    /// Nom en allemand
    @Default('') String nameDe,

    /// Nom en italien
    @Default('') String nameIt,

    /// Nom en espagnol
    @Default('') String nameEs,

    /// Distance en kilometres
    required double distance,

    /// Denivele positif en metres
    required int elevationGain,

    /// Denivele negatif en metres
    required int elevationLoss,

    /// Duree estimee en minutes (serialise en int pour JSON)
    required int estimatedDurationMinutes,

    /// Difficulte — String libre, pas enum (#81752)
    /// Valeurs courantes : easy, moderate, hard, extreme
    @Default('moderate') String difficulty,

    /// Ordre d'affichage
    required int orderIndex,

    /// Latitude du point de depart
    required double startLat,

    /// Longitude du point de depart
    required double startLng,

    /// Latitude du point d'arrivee
    required double endLat,

    /// Longitude du point d'arrivee
    required double endLng,

    /// Description en francais
    @Default('') String descriptionFr,

    /// Description en anglais
    @Default('') String descriptionEn,

    /// Description en allemand
    @Default('') String descriptionDe,

    /// Description en italien
    @Default('') String descriptionIt,

    /// Description en espagnol
    @Default('') String descriptionEs,
  }) = _Stage;

  /// Duree estimee sous forme de Duration Dart
  Duration get estimatedDuration =>
      Duration(minutes: estimatedDurationMinutes);

  /// Deserialisation depuis JSON
  factory Stage.fromJson(Map<String, dynamic> json) => _$StageFromJson(json);
}
