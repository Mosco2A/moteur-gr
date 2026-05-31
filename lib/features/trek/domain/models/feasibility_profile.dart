import 'package:freezed_annotation/freezed_annotation.dart';

part 'feasibility_profile.freezed.dart';
part 'feasibility_profile.g.dart';

/// Profil de faisabilite d'un randonneur.
///
/// Decrit les capacites physiques et l'experience du randonneur.
/// En mode groupe, aggrege plusieurs profils via groupProfiles
/// et utilise le pire profil pour les recommandations.
@freezed
abstract class FeasibilityProfile with _$FeasibilityProfile {
  const FeasibilityProfile._();

  const factory FeasibilityProfile({
    /// Niveau de forme physique (String extensible, ex: beginner, intermediate, advanced)
    required String fitnessLevel,

    /// Experience de randonnee (String extensible, ex: novice, experienced, expert)
    required String experience,

    /// Distance maximale par jour en km
    required double maxKmPerDay,

    /// Duree maximale de marche par jour en heures
    required double maxHoursPerDay,

    /// True si evaluation de groupe (utilise le pire profil)
    @Default(false) bool groupMode,

    /// Profils des membres du groupe (null si pas en mode groupe)
    List<FeasibilityProfile>? groupProfiles,
  }) = _FeasibilityProfile;

  /// Deserialisation depuis JSON
  factory FeasibilityProfile.fromJson(Map<String, dynamic> json) =>
      _$FeasibilityProfileFromJson(json);
}
