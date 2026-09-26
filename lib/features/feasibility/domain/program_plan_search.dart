/// LA RECHERCHE DU PROGRAMME CONSEILLE — L'INVARIANTE DU LOT R (tache 569).
///
/// DECISION DE CHRIS DU 26/09, VERBATIM : « OK mais le curseur est celui
/// conseille et il n'est jamais en rouge quand il est conseille en orange max ».
///
/// CE QUI N'ALLAIT PAS, ET CE N'ETAIT PAS UN ARBITRAGE DE CONFORT. Le conseil de
/// duree et le verdict etaient produits par DEUX REGLES DIFFERENTES :
///
///   * le conseil par `FeasibilityFormula._suggestedWalkingDays`, qui cherche le
///     nombre de journees pour que la CHARGE MOYENNE tienne sous la capacite
///     (energie totale / capacite, arrondi au superieur, plus une journee par
///     journee au-dessus du plafond) ;
///   * le verdict par le SCORE DE CIRCUIT, qui vaut C1 = LA PIRE JOURNEE et elle
///     seule depuis GO-61.
///
/// Une MOYENNE ne dit rien d'un MAXIMUM : viser la moyenne laisse la pire
/// journee exactement ou elle est. Et deux unites s'ajoutaient au malentendu —
/// le conseil comptait des jours de MARCHE, le curseur affiche des TOTAUX. Mesure
/// sur les 96 cellules de la campagne avant correction : 16 conseils dont le
/// nombre, lu sur le curseur, tombait sur un verdict ROUGE (dont Lea sur le Mare
/// a Mare : « vise 10 jours », rouge a 10, orange a 11).
///
/// CE QUE FAIT CE FICHIER, ET POURQUOI C'EST LA SEULE FACON D'ETRE SUR. On
/// n'essaie pas de rendre les deux formules compatibles : on SUPPRIME la seconde
/// formule. Le conseil est desormais trouve par ESSAI REEL — pour chaque valeur
/// atteignable du curseur, on construit le programme avec le moteur de
/// repartition qui le produira a l'ecran ([PlanningCalculator.distribute]), on
/// le colore avec le moteur de verdict qui le colorera a l'ecran
/// ([FeasibilityFormula.evaluate]), et on retient LA PREMIERE valeur qui n'est
/// pas rouge. L'accord des deux calculs n'est donc plus une propriete a esperer :
/// c'est la definition du conseil.
///
/// ORANGE EST ACCEPTABLE, CHRIS L'A TRANCHE. On ne vise pas forcement le vert :
/// on garantit de ne jamais conseiller un rouge, et on prend la valeur la plus
/// PETITE qui tienne — allonger un trek au-dela du necessaire est aussi un
/// mauvais conseil.
///
/// ET QUAND RIEN NE MARCHE, ON LE DIT. Si aucune valeur du curseur ne fait mieux
/// que rouge — une etape indivisible au-dessus du plafond, meme coupee en deux —
/// la recherche rend `null` et l'application NE CONSEILLE AUCUNE VALEUR. Mieux
/// vaut avouer qu'il n'y a pas de solution de programme que d'en pointer une
/// fausse : c'est le cas de l'etape de 40 km et 3 000 m de D+ pour un debutant,
/// ou l'ancien code conseillait 2 jours et affichait rouge a 2 jours.
library;

import '../../../core/models/stage.dart';
import '../../planning/domain/planning_calculator.dart';
import 'feasibility_formula.dart';
import 'feasibility_program.dart';

/// Un programme CONSEILLE : ses trois nombres de jours, et le verdict qu'il
/// obtient REELLEMENT — vert ou orange, jamais rouge.
class SuggestedProgram {
  const SuggestedProgram({
    required this.totalDays,
    required this.walkingDays,
    required this.restDays,
    required this.verdict,
  });

  /// Jours TOTAUX : c'est la valeur du CURSEUR, et l'unite qu'il affiche.
  final int totalDays;

  /// Jours de MARCHE de ce programme.
  final int walkingDays;

  /// Jours de REPOS de ce programme.
  final int restDays;

  /// Verdict REEL a cette valeur (vert ou orange — jamais rouge, par
  /// construction de [ProgramPlanSearch.firstNonRed]).
  final FeasibilityVerdict verdict;

  /// Le conseil, sous la forme que le moteur de verdict consomme.
  ProgramDurationAdvice toAdvice() => ProgramDurationAdvice(
        walkingDays: walkingDays,
        restDays: restDays,
      );

  @override
  String toString() => 'SuggestedProgram($totalDays j = $walkingDays marche + '
      '$restDays repos, ${verdict.name})';
}

/// Les bornes du curseur dont la recherche a besoin.
///
/// Volontairement un contrat MINIMAL et non `DurationBounds` : ce dernier vit
/// dans les providers du Programme, et le domaine de la faisabilite n'a pas a en
/// dependre. `DurationBounds` le satisfait tel quel.
abstract class DurationSearchBounds {
  int get min;
  int get max;
  int get restAllowance;
  List<int> get options;
}

/// La recherche du programme conseille (fonctions PURES).
class ProgramPlanSearch {
  const ProgramPlanSearch._();

  /// Le programme REEL a [totalDays] jours de curseur.
  ///
  /// Meme moteur de repartition que l'ecran Programme, meme conversion en
  /// charges journalieres que l'ecran Faisabilite ([FeasibilityProgram]).
  static FeasibilityProgram programAt(
    List<StageModel> stages,
    int totalDays, {
    required int restAllowance,
  }) =>
      FeasibilityProgram.fromDayPlans(PlanningCalculator.distribute(
        stages,
        totalDays,
        maxRestDays: restAllowance,
      ));

  /// Le verdict REEL a [totalDays] jours de curseur.
  ///
  /// Appelle [FeasibilityFormula.evaluate] SANS conseil de duree : on ne lit ici
  /// que la couleur, et passer un conseil rendrait la recherche circulaire.
  static FeasibilityAssessment assessmentAt(
    int totalDays, {
    required List<StageModel> stages,
    required HikerLevel level,
    required int restAllowance,
    double demonstratedFloorEnergyKm = 0,
    double? habitualDailyEnergyKm,
    int longestConsecutiveDaysDone = 0,
    TrekConditions conditions = TrekConditions.unknown,
    FeasibilityThresholds thresholds = FeasibilityThresholds.median,
  }) {
    final program = programAt(stages, totalDays, restAllowance: restAllowance);
    return FeasibilityFormula.evaluate(
      stages: program.dayEfforts,
      level: level,
      demonstratedFloorEnergyKm: demonstratedFloorEnergyKm,
      habitualDailyEnergyKm: habitualDailyEnergyKm,
      longestConsecutiveDaysDone: longestConsecutiveDaysDone,
      restAfterStageIndex: program.restAfterDayIndex,
      conditions: conditions,
      maxWalkingDays: program.maxWalkingDays,
      thresholds: thresholds,
    );
  }

  /// LE CONSEIL : le PLUS PETIT total de jours dont le verdict n'est pas rouge.
  ///
  /// `null` quand AUCUNE valeur du curseur ne fait mieux que rouge — et alors
  /// l'application ne conseille aucune duree (voir l'en-tete du fichier).
  ///
  /// HIVER : la recherche ne cherche pas a rattraper un verdict declare NON
  /// VALIDE (#2-j). Les couleurs restent calculees et la plus petite valeur non
  /// rouge reste la meilleure proposition disponible ; c'est le bandeau hiver,
  /// place avant le feu, qui dit que le verdict ne tient plus.
  static SuggestedProgram? firstNonRed({
    required List<StageModel> stages,
    required HikerLevel level,
    required DurationSearchBounds bounds,
    double demonstratedFloorEnergyKm = 0,
    double? habitualDailyEnergyKm,
    int longestConsecutiveDaysDone = 0,
    TrekConditions conditions = TrekConditions.unknown,
    FeasibilityThresholds thresholds = FeasibilityThresholds.median,
  }) {
    if (stages.isEmpty) return null;
    for (final totalDays in bounds.options) {
      if (totalDays <= 0) continue;
      final plan = PlanningCalculator.distribute(stages, totalDays,
          maxRestDays: bounds.restAllowance);
      // LE CONSEIL DOIT ETRE UNE VALEUR DE CURSEUR QUI REDONNE CE PROGRAMME.
      // En dessous du nombre d'etapes, la repartition greedy peut rendre MOINS
      // de journees que demande (elle ne trouve pas assez de points de coupe) :
      // conseiller cette valeur ferait afficher un programme d'une autre
      // longueur que celui qu'on vient de juger. On passe.
      if (plan.length != totalDays) continue;
      final program = FeasibilityProgram.fromDayPlans(plan);
      if (program.isEmpty) continue;
      final assessment = FeasibilityFormula.evaluate(
        stages: program.dayEfforts,
        level: level,
        demonstratedFloorEnergyKm: demonstratedFloorEnergyKm,
        habitualDailyEnergyKm: habitualDailyEnergyKm,
        longestConsecutiveDaysDone: longestConsecutiveDaysDone,
        restAfterStageIndex: program.restAfterDayIndex,
        conditions: conditions,
        maxWalkingDays: program.maxWalkingDays,
        thresholds: thresholds,
      );
      if (assessment.globalVerdict == FeasibilityVerdict.red) continue;
      // LES TROIS NOMBRES SONT LUS SUR LE PROGRAMME, PAS DEDUITS. Le compte des
      // repos vient des journees `isRestDay` du plan et non de
      // [FeasibilityProgram.restAfterDayIndex] : ce dernier est un ENSEMBLE
      // d'index, donc deux repos poses au meme endroit (ou apres la derniere
      // etape) n'y comptent qu'une fois. C'est juste pour la monotonie de
      // Foster, qui n'a besoin que des positions, et faux pour un affichage.
      final walking =
          plan.where((d) => !d.isRestDay && d.stages.isNotEmpty).length;
      return SuggestedProgram(
        totalDays: totalDays,
        walkingDays: walking,
        restDays: totalDays - walking,
        verdict: assessment.globalVerdict,
      );
    }
    return null;
  }
}
