import '../domain/hiker_profile.dart';

/// Niveau de forme objectif deduit du test de marche 6 minutes.
///
/// Cles i18n stables (`t.walkTest.levels.*`). Ordre croissant de forme.
abstract class WalkTestLevel {
  static const String low = 'low';
  static const String moderate = 'moderate';
  static const String good = 'good';
  static const String excellent = 'excellent';

  /// Ordre pour comparaisons (croissant).
  static const List<String> ordered = [low, moderate, good, excellent];

  /// Rang numerique (0..3) du niveau (fallback 0 si inconnu).
  static int rank(String level) {
    final i = ordered.indexOf(level);
    return i < 0 ? 0 : i;
  }
}

/// Normes du test de marche 6 minutes (6MWT) — data STATIQUE embarquee.
///
/// Distance de REFERENCE predite par les equations de Enright & Sherrill
/// (1998), etalon clinique du 6MWT pour adultes sains (40-80 ans) :
///   - Hommes  : 6MWD = 7.57*taille_cm - 5.02*age - 1.76*poids_kg - 309
///   - Femmes  : 6MWD = 2.11*taille_cm - 2.29*poids_kg - 5.78*age + 667
/// (References : Enright PL, Sherrill DL. « Reference equations for the
/// six-minute walk in healthy adults ». Am J Respir Crit Care Med 1998 ;
/// 158:1384-7. Cadre BP StepWays `BP_faisabilite_entrainement.md`, test 6 min.)
///
/// Le NIVEAU objectif est derive du RATIO distance mesuree / distance predite
/// (0..) : < 0.70 faible ; 0.70-0.90 moyen ; 0.90-1.10 bon ; >= 1.10 excellent.
/// Ces seuils calent le barème BP (non public) — externalisables si besoin.
///
/// Classe PURE (zero dependance Flutter), directement testable.
class WalkTestNorms {
  const WalkTestNorms._();

  /// Bornes d'age couvertes par les equations (etalon 40-80 ; on extrapole
  /// prudemment hors bornes en clampant l'age effectif).
  static const int minAge = 40;
  static const int maxAge = 80;

  /// Seuils de ratio (distance / prediction) -> niveau.
  static const double ratioModerate = 0.70;
  static const double ratioGood = 0.90;
  static const double ratioExcellent = 1.10;

  /// Distance PREDITE (m) pour un homme sain de cet age/taille/poids.
  static double predictedMale({
    required int age,
    required int heightCm,
    required double weightKg,
  }) {
    final a = age.clamp(minAge, maxAge).toDouble();
    return 7.57 * heightCm - 5.02 * a - 1.76 * weightKg - 309;
  }

  /// Distance PREDITE (m) pour une femme saine de cet age/taille/poids.
  static double predictedFemale({
    required int age,
    required int heightCm,
    required double weightKg,
  }) {
    final a = age.clamp(minAge, maxAge).toDouble();
    return 2.11 * heightCm - 2.29 * weightKg - 5.78 * a + 667;
  }

  /// Distance PREDITE (m) selon le profil. Si le sexe n'est pas renseigne, on
  /// prend la MOYENNE des deux equations (approche neutre, honnete).
  ///
  /// Retourne null si la morpho minimale (age/taille/poids) manque : sans
  /// reference, le test ne peut pas etre normalise.
  static double? predictedFor(HikerProfile profile) {
    if (profile.age <= 0 || !profile.hasMorphology) return null;
    final male = predictedMale(
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
    );
    final female = predictedFemale(
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
    );
    switch (profile.sex) {
      case HikerSex.male:
        return male;
      case HikerSex.female:
        return female;
      default:
        return (male + female) / 2;
    }
  }

  /// Ratio distance mesuree / distance predite, ou null si non normalisable.
  static double? ratioFor(HikerProfile profile, double measuredMeters) {
    final predicted = predictedFor(profile);
    if (predicted == null || predicted <= 0) return null;
    return measuredMeters / predicted;
  }

  /// Niveau objectif a partir d'un RATIO (distance / prediction).
  static String levelFromRatio(double ratio) {
    if (ratio < ratioModerate) return WalkTestLevel.low;
    if (ratio < ratioGood) return WalkTestLevel.moderate;
    if (ratio < ratioExcellent) return WalkTestLevel.good;
    return WalkTestLevel.excellent;
  }

  /// Niveau objectif a partir du profil + distance mesuree.
  ///
  /// Si la morpho manque (pas de reference), on retombe sur des seuils de
  /// distance ABSOLUE (repere grand public) : < 400 m faible ; 400-500 moyen ;
  /// 500-600 bon ; >= 600 excellent — coherents avec l'ordre de grandeur du
  /// 6MWT chez l'adulte.
  static String levelFor(HikerProfile profile, double measuredMeters) {
    final ratio = ratioFor(profile, measuredMeters);
    if (ratio != null) return levelFromRatio(ratio);
    if (measuredMeters < 400) return WalkTestLevel.low;
    if (measuredMeters < 500) return WalkTestLevel.moderate;
    if (measuredMeters < 600) return WalkTestLevel.good;
    return WalkTestLevel.excellent;
  }
}
