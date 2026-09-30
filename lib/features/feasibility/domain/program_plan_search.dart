/// LE PROGRAMME CONSEILLE : LE PLAN DU SENTIER, PAS UN PLAN INVENTE.
///
/// TACHE 634 (DEM-260929-1132 et DEM-260929-1327). Retour de Christophe du
/// 29/09 11:32, verbatim : « pourquoi la faisabilite de mare a mare te le
/// propose en 4 jours ?????? En te disant que c'est exigeant, c'est
/// completement con !!! ».
///
/// D'OU VENAIENT LES 4 JOURS, MESURE. Ce fichier cherchait LE PLUS PETIT total
/// de jours du curseur dont le verdict n'etait pas rouge. La borne basse du
/// curseur valait `ceil(nbEtapes / 2)` — pour les 7 etapes du Mare a Mare
/// Centre, QUATRE. Le moteur essayait donc 4 en premier, y REGROUPAIT les 7
/// etapes en 4 journees (deux etapes par jour ou presque), trouvait le verdict
/// orange, et s'arretait la. Il proposait ainsi de son propre chef un plan
/// comprime que personne n'avait demande, puis le qualifiait d'exigeant.
/// Christophe a raison : c'est absurde. Un moteur qui sait qu'un plan est dur
/// ne le propose pas.
///
/// CE QUE LE MOTEUR PROPOSE MAINTENANT. Le plan d'etapes du sentier TEL QU'IL
/// EST DANS LES DONNEES : une etape, une journee de marche — 7 journees pour le
/// Mare a Mare Centre — plus les jours de repos que le moteur conseille
/// (GO-61). Rien n'est regroupe, rien n'est coupe. Le randonneur garde son
/// curseur s'il veut comprimer ; c'est SON choix, plus une proposition de
/// l'application.
///
/// ET IL N'Y A PLUS RIEN A CHERCHER, C'EST UNE CONSEQUENCE ET NON UN RACCOURCI.
/// Depuis GO-61 le verdict vaut C1 = la pire journee et elle seule. Un jour de
/// repos ne change l'energie d'aucune journee de marche, donc ne change pas
/// C1 : au-dessus du plan du sentier, TOUS les totaux donnent exactement le
/// meme verdict. En dessous, on regroupe, donc on aggrave. Le plan du sentier
/// est donc le meilleur plan atteignable, et il l'est par construction — il n'y
/// a aucun balayage a faire pour le trouver. Couper une etape, seul levier qui
/// pouvait encore alleger C1, a ete retire par cette meme tache
/// (DEM-260929-1327, voir [PlanningCalculator]) : une etape reste une etape du
/// sentier. Les leviers qui restent sont la FORME et la SAISON.
///
/// L'INVARIANTE DE CHRIS DU 26/09 EST TENUE, ET PLUS SIMPLEMENT QU'AVANT.
/// Verbatim : « le curseur est celui conseille et il n'est jamais en rouge
/// quand il est conseille en orange max ». Le plan du sentier est evalue avec
/// le moteur de verdict qui le colorera A L'ECRAN ; s'il est rouge, AUCUNE
/// duree n'est conseillee et l'application le dit franchement — parce qu'alors
/// aucune duree ne marcherait, une etape du sentier depassant a elle seule le
/// plafond du randonneur. L'ecran nomme cette etape (`hardStageAlert`).
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
  ProgramDurationAdvice toAdvice() =>
      ProgramDurationAdvice(walkingDays: walkingDays, restDays: restDays);

  @override
  String toString() =>
      'SuggestedProgram($totalDays j = $walkingDays marche + '
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
  }) => FeasibilityProgram.fromDayPlans(
    PlanningCalculator.distribute(stages, totalDays),
  );

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

  /// LE CONSEIL : LE PLAN DU SENTIER, repos conseilles compris.
  ///
  /// [joursDeReposConseilles] — le repos que le moteur conseille (GO-61). Le
  /// total propose vaut donc `nombre d'etapes + ce repos`, borne a la plage du
  /// curseur pour rester une valeur atteignable.
  ///
  /// `null` quand ce plan est ROUGE : l'application ne conseille alors aucune
  /// duree. Ce n'est pas un aveu d'impuissance mais la seule reponse vraie —
  /// aucune autre duree ne ferait mieux (voir l'en-tete du fichier), et une
  /// etape du sentier depasse a elle seule le plafond du randonneur.
  ///
  /// HIVER : la recherche ne cherche pas a rattraper un verdict declare NON
  /// VALIDE (#2-j). Les couleurs restent calculees ; c'est le bandeau hiver,
  /// place avant le feu, qui dit que le verdict ne tient plus.
  static SuggestedProgram? planDuSentier({
    required List<StageModel> stages,
    required HikerLevel level,
    required DurationSearchBounds bounds,
    required int joursDeReposConseilles,
    double demonstratedFloorEnergyKm = 0,
    double? habitualDailyEnergyKm,
    int longestConsecutiveDaysDone = 0,
    TrekConditions conditions = TrekConditions.unknown,
    FeasibilityThresholds thresholds = FeasibilityThresholds.median,
  }) {
    if (stages.isEmpty) return null;

    final repos = joursDeReposConseilles < 0 ? 0 : joursDeReposConseilles;
    var totalDays = stages.length + repos;
    if (totalDays > bounds.max) totalDays = bounds.max;
    if (totalDays < stages.length) return null;

    final plan = PlanningCalculator.distribute(stages, totalDays);
    // LE CONSEIL DOIT ETRE UNE VALEUR DE CURSEUR QUI REDONNE CE PROGRAMME.
    if (plan.length != totalDays) return null;
    final program = FeasibilityProgram.fromDayPlans(plan);
    if (program.isEmpty) return null;

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
    if (assessment.globalVerdict == FeasibilityVerdict.red) return null;

    // LES TROIS NOMBRES SONT LUS SUR LE PROGRAMME, PAS DEDUITS. Le compte des
    // repos vient des journees `isRestDay` du plan et non de
    // [FeasibilityProgram.restAfterDayIndex] : ce dernier est un ENSEMBLE
    // d'index, donc deux repos poses au meme endroit (ou apres la derniere
    // etape) n'y comptent qu'une fois. C'est juste pour la monotonie de
    // Foster, qui n'a besoin que des positions, et faux pour un affichage.
    final walking = plan
        .where((d) => !d.isRestDay && d.stages.isNotEmpty)
        .length;
    return SuggestedProgram(
      totalDays: totalDays,
      walkingDays: walking,
      restDays: totalDays - walking,
      verdict: assessment.globalVerdict,
    );
  }
}
