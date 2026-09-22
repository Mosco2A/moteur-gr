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
/// LES COEFFICIENTS D'ENRIGHT SONT INTOUCHABLES (#3-a, ARB-007 REJETE).
/// Le rapport mesure/predit est conserve TEL QUEL, terme de poids compris.
/// Chris : « le test est le test, c'est la capacite a faire l'exercice point. »
/// Les equations repondent a la question « est-ce que je marche bien pour
/// quelqu'un comme moi » — une question clinique legitime, et c'est exactement
/// pour cela que la taille, l'age et le poids figurent dans la prediction. Un
/// test qu'on triture pour lui faire dire autre chose n'est plus un test.
///
/// RESPECTER LE DOMAINE DE VALIDITE N'EST PAS TRITURER LE TEST (#3-k).
/// Modifier les coefficients serait le manipuler. REFUSER DE L'APPLIQUER HORS
/// DE L'ECHANTILLON SUR LEQUEL IL A ETE DERIVE, C'EST LE RESPECTER — et c'est
/// ce que fait [isWithinDerivationDomain], en appliquant les criteres
/// d'exclusion publies par Enright & Sherrill EUX-MEMES.
///
/// Classe PURE (zero dependance Flutter), directement testable.
class WalkTestNorms {
  const WalkTestNorms._();

  /// Bornes d'age couvertes par les equations (etalon 40-80 ; on extrapole
  /// prudemment hors bornes en clampant l'age effectif).
  ///
  /// A 120 ans (nouvelle borne de saisie), l'age est donc CLAMPE a 80 : c'est
  /// le comportement existant, il est desormais DECLARE a l'ecran plutot que
  /// subi (#5-j).
  static const int minAge = 40;
  static const int maxAge = 80;

  /// IMC maximal du domaine de derivation — CRITERE D'EXCLUSION PUBLIE par
  /// Enright & Sherrill (#3-l).
  static const double maxBmi = 35.0;

  /// Taille adulte minimale du domaine (cm). Meme borne que le dispositif
  /// poids : un adulte de 120 cm est hors de tout echantillon de stature
  /// normale (#3-n, #5-h).
  static const int minHeightCm = 147;

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

  /// Vrai si le profil tombe DANS le domaine sur lequel les equations ont ete
  /// derivees (#3-n) — IMC <= 35 et taille adulte >= 147 cm.
  ///
  /// POURQUOI CE GARDE-FOU EST DEVENU NECESSAIRE. Enright & Sherrill ont derive
  /// leurs equations sur 117 hommes et 173 femmes de 40 a 80 ans, avec des
  /// criteres d'exclusion EXPLICITES : age > 80 ans, IMC > 35, antecedent
  /// d'AVC. Le code bornait bien l'age (clamp 40-80) mais PAS l'IMC, et le seul
  /// garde-fou existant — `predicted <= 0` — ne rattrape qu'une prediction
  /// NEGATIVE. L'absurdite est reelle et les nouvelles bornes de saisie la
  /// rendent atteignable : a 130 cm, 200 kg, 50 ans, la prediction masculine
  /// vaut 72,1 m, positive et minuscule ; une marche mesuree a 300 m donnerait
  /// un rapport de 4,16, donc « excellent », donc UN CRAN DE NIVEAU NON MERITE
  /// (#3-m).
  ///
  /// ARB-007 aurait supprime ce cas ; il a ete rejete, le garde-fou prend sa
  /// place — et il n'invente rien, il applique les criteres d'Enright.
  static bool isWithinDerivationDomain(HikerProfile profile) {
    if (profile.heightCm < minHeightCm) return false;
    final bmi = profile.bmi;
    if (bmi == null || !bmi.isFinite) return false;
    return bmi <= maxBmi;
  }

  /// Distance PREDITE (m) selon le profil. Si le sexe n'est pas renseigne, on
  /// prend la MOYENNE des deux equations (approche neutre, honnete).
  ///
  /// Retourne null si la morpho minimale (age/taille/poids) manque, OU si le
  /// profil sort du domaine de derivation ([isWithinDerivationDomain]) : sans
  /// reference valable, le test ne peut pas etre normalise — le test, lui,
  /// reste parfaitement valable (#3-o).
  static double? predictedFor(HikerProfile profile) {
    if (profile.age <= 0 || !profile.hasMorphology) return null;
    if (!isWithinDerivationDomain(profile)) return null;
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
  /// Si la morpho manque, OU si le profil sort du domaine de derivation
  /// (#3-n), on retombe sur des seuils de distance ABSOLUE (repere grand
  /// public) : < 400 m faible ; 400-500 moyen ; 500-600 bon ; >= 600 excellent
  /// — coherents avec l'ordre de grandeur du 6MWT chez l'adulte. C'est
  /// EXACTEMENT le mecanisme de repli qui existait deja ; le garde-fou de
  /// domaine ne fait que l'atteindre dans un cas de plus.
  ///
  /// QUAND LE REPLI S'APPLIQUE, LE TEST RESTE VALABLE : c'est sa NORMALISATION
  /// qui ne l'est pas. Le niveau est lu sur l'echelle absolue, ET L'ECRAN LE
  /// DIT (#3-o) — voir [isNormalized].
  static String levelFor(HikerProfile profile, double measuredMeters) {
    final ratio = ratioFor(profile, measuredMeters);
    if (ratio != null) return levelFromRatio(ratio);
    if (measuredMeters < 400) return WalkTestLevel.low;
    if (measuredMeters < 500) return WalkTestLevel.moderate;
    if (measuredMeters < 600) return WalkTestLevel.good;
    return WalkTestLevel.excellent;
  }

  /// Vrai si le niveau rendu par [levelFor] a ete NORMALISE par les equations
  /// d'Enright ; faux s'il a ete lu sur l'echelle de distance absolue.
  ///
  /// L'ecran s'en sert pour dire lequel des deux il montre : un niveau lu sur
  /// l'echelle absolue et presente comme normalise serait un ecran qui ment.
  static bool isNormalized(HikerProfile profile) {
    final predicted = predictedFor(profile);
    return predicted != null && predicted > 0;
  }
}
