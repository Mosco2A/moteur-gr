import 'package:freezed_annotation/freezed_annotation.dart';

part 'hiker_profile.freezed.dart';
part 'hiker_profile.g.dart';

/// Sexe declare (optionnel) — utile aux normes du test 6 min (ATS/Enright).
///
/// String extensible pour resister a la serialisation ; valeurs stables
/// exposees ici. `null` cote profil = non renseigne.
abstract class HikerSex {
  static const String female = 'female';
  static const String male = 'male';
  static const List<String> values = [female, male];
}

/// Profil randonneur (fiche d'info, 1ere page de la faisabilite) — StepWays
/// LOT 4, Ph1. Donnee morpho SENSIBLE (art. 9 RGPD) : local + miroir cloud
/// anonyme uniquement.
///
/// L'IMC ([bmi]) est un getter CALCULE localement a partir de taille/poids —
/// JAMAIS stocke (donnee derivee). Le profil VIDE ([empty]) represente
/// « aucune fiche saisie » ([isEmpty] vrai) et sert de fallback.
@freezed
abstract class HikerProfile with _$HikerProfile {
  const HikerProfile._();

  const factory HikerProfile({
    /// Age en annees (0 = non renseigne).
    @Default(0) int age,

    /// Taille en centimetres (0 = non renseignee).
    @Default(0) int heightCm,

    /// Poids en kilogrammes (0 = non renseigne).
    @Default(0) double weightKg,

    /// Sexe declare (null = non renseigne / optionnel). Voir [HikerSex].
    String? sex,

    /// Code pays ISO 3166-1 alpha-2 (ex. 'FR'). Vide = non renseigne.
    @Default('') String countryIso,

    /// Horodatage de la derniere mise a jour (null si jamais saisi).
    DateTime? updatedAt,
  }) = _HikerProfile;

  /// Profil vide (aucune fiche saisie).
  static const HikerProfile empty = HikerProfile();

  /// Deserialisation depuis JSON (miroir cloud / prefs).
  factory HikerProfile.fromJson(Map<String, dynamic> json) =>
      _$HikerProfileFromJson(json);

  /// Vrai si aucune donnee morpho n'a ete saisie (fallback auto-eval).
  bool get isEmpty => age == 0 && heightCm == 0 && weightKg == 0;

  /// Vrai si la morpho minimale (taille + poids) est renseignee.
  bool get hasMorphology => heightCm > 0 && weightKg > 0;

  /// IMC calcule LOCALEMENT (kg / m^2), ou null si taille/poids manquants.
  ///
  /// Jamais stocke : recalcule a la volee depuis la source (honnetete =
  /// securite ; on ne persiste que taille/poids).
  double? get bmi {
    if (!hasMorphology) return null;
    final meters = heightCm / 100.0;
    return weightKg / (meters * meters);
  }

  /// Categorie OMS de l'IMC (cle i18n stable), ou null si IMC indisponible.
  ///
  /// Seuils OMS : < 18.5 maigreur ; 18.5-25 normal ; 25-30 surpoids ;
  /// >= 30 obesite. Cle destinee a `t.hikerProfile.bmiCategories.*`.
  String? get bmiCategory {
    final value = bmi;
    if (value == null) return null;
    if (value < 18.5) return 'underweight';
    if (value < 25) return 'normal';
    if (value < 30) return 'overweight';
    return 'obese';
  }

  /// Vrai si un rappel « consultation conseillee » doit etre montre (65+).
  bool get needsSeniorHealthReminder => age >= 65;
}
