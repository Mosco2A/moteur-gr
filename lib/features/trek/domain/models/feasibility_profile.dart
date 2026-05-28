import 'package:freezed_annotation/freezed_annotation.dart';

part 'feasibility_profile.freezed.dart';
part 'feasibility_profile.g.dart';

/// Profil de faisabilite d'un randonneur.
///
/// fitnessLevel et experience sont des String libres, pas des enums (#81752).
/// Supporte le mode groupe avec une liste optionnelle de profils.
@freezed
class FeasibilityProfile with _$FeasibilityProfile {
  const FeasibilityProfile._();

  const factory FeasibilityProfile({
    /// Niveau de forme physique — String libre, pas enum (#81752)
    /// Valeurs courantes : sedentary, average, fit, athletic
    required String fitnessLevel,

    /// Experience de randonnee — String libre, pas enum (#81752)
    /// Valeurs courantes : beginner, intermediate, experienced, expert
    required String experience,

    /// Distance maximale par jour en km
    required double maxKmPerDay,

    /// Duree maximale de marche par jour en heures
    required double maxHoursPerDay,

    /// True si evaluation en mode groupe
    @Default(false) bool groupMode,

    /// Profils des membres du groupe (null si solo)
    List<FeasibilityProfile>? groupProfiles,
  }) = _FeasibilityProfile;

  /// Nombre de membres du groupe (1 si solo)
  int get groupSize => groupProfiles?.length ?? 1;

  /// Deserialisation depuis JSON
  factory FeasibilityProfile.fromJson(Map<String, dynamic> json) =>
      _$FeasibilityProfileFromJson(json);
}
