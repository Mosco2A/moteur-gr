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

  /// Vrai si la fiche est COMPLETE : age ET taille ET poids renseignes.
  ///
  /// A ne pas confondre avec `!isEmpty`, qui n'exige qu'UN seul des trois.
  /// C'est cette completude — et pas la simple presence d'un champ — qui
  /// conditionne le verdict de faisabilite (correctif N2 / D1, #100293) : une
  /// fiche a moitie remplie est une fiche a moitie fausse.
  bool get isComplete => age > 0 && heightCm > 0 && weightKg > 0;

  /// IMC calcule LOCALEMENT (kg / m^2), ou null si taille/poids manquants.
  ///
  /// Jamais stocke : recalcule a la volee depuis la source (honnetete =
  /// securite ; on ne persiste que taille/poids).
  double? get bmi {
    if (!hasMorphology) return null;
    final meters = heightCm / 100.0;
    return weightKg / (meters * meters);
  }

  // IL N'Y A PLUS DE `bmiCategory` ICI, ET C'EST VOULU (tache 560, N2).
  //
  // Ce getter classait l'IMC en quatre categories (`underweight`, `normal`,
  // `overweight`, `obese`) et ne servait QU'A UNE CHOSE : nommer la cle Slang
  // d'un libelle affiche sur la fiche d'info. La tache 552 avait deja du
  // rehabiller la categorie la plus haute (« Fort surpoids » au lieu
  // d'« obesite ») ; la campagne personas 559 a montre que le probleme n'etait
  // pas le MOT mais le FAIT MEME d'afficher un jugement sur le corps — et de
  // l'afficher pendant la saisie, avant tout consentement article 9.
  //
  // L'affichage est parti, les cinq tables de traduction ont perdu
  // `bmiCategories`, et ce getter part avec eux : le laisser en place, c'etait
  // laisser une categorie toute prete a recabler sur un ecran, et des libelles
  // a re-creer. #S14 (Zwolinski 2025, 162 randonneurs, p = 0,708) ne lie
  // d'ailleurs aucune categorie d'IMC a la blessure en randonnee : cette
  // classification n'a jamais rien eu a dire au randonneur.
  //
  // [bmi], lui, RESTE : c'est une grandeur, pas une etiquette, et
  // `WalkTestNorms` l'utilise comme borne de calcul sans jamais l'afficher.

  /// Vrai si un rappel « consultation conseillee » doit etre montre (65+).
  bool get needsSeniorHealthReminder => age >= 65;
}
