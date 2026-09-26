import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/track_point.dart';
import '../../../core/models/stage.dart';
import '../../checklist/domain/season.dart';
import '../../map/providers/gpx_track_provider.dart';
import '../../notifications/providers/download_reminder_provider.dart';
import '../../planning/models/planned_day.dart';
import '../../planning/providers/planned_days_provider.dart';
import '../../trek/providers/gps_providers.dart';
import '../../trek/providers/stage_providers.dart';
import '../domain/feasibility_formula.dart';
import '../domain/feasibility_program.dart';
import '../domain/hiker_profile.dart';
import '../domain/objective_profile.dart';
import '../domain/walk_test_result.dart';
import 'advised_program_provider.dart';
import 'hiker_profile_provider.dart';
import 'walk_test_provider.dart';

/// [FeasibilityProgram] vit desormais dans le domaine (tache 569) : la recherche
/// du conseil en a besoin hors de tout provider. Re-exportee pour que tout ce
/// qui la lisait ici continue de la trouver.
export '../domain/feasibility_program.dart' show FeasibilityProgram;

/// UN SEUL MOTEUR DE VERDICT (campagne personas 21/09, MAJEUR-4).
///
/// Il n'existe plus qu'une source de verdict dans l'application :
/// [feasibilityAssessmentProvider] (formule V1 #100068, feu tricolore). Le
/// croisement par seuils qui vivait ici (`trekRequirementsProvider` +
/// `trekFeasibilityResultProvider` + `TrekFeasibilityCalculator`) rendait, pour
/// LE MEME randonneur et LE MEME trek, un verdict OPPOSE a celui affiche par
/// l'ecran Faisabilite sur 3 profils sur 6 : il a ete SUPPRIME. Tout ecran qui
/// a besoin d'un verdict lit desormais [feasibilityAssessmentProvider].

/// Rang de forme de dépannage (questionnaire) quand le test 6 min manque.
///
/// Lit le dernier resultat SharedPreferences du questionnaire (0-24) et le
/// projette sur 0..3. Absent -> 1 (dépannage prudent, ni haut ni bas).
final _fallbackFitnessRankProvider = FutureProvider<int>((ref) async {
  // On reste tolerant : toute absence -> rang median bas (1).
  final result = await ref.watch(walkTestResultProvider.future);
  if (result != null) return 0; // ignore (le test prime, gere ailleurs)
  return 1;
});

/// Profil OBJECTIF deduit (fiche + test 6 min + 5 randos).
final objectiveProfileProvider =
    FutureProvider<ObjectiveProfile>((ref) async {
  final pastHikes = await ref.watch(pastHikesProvider.future);
  final WalkTestResult? walkTest =
      await ref.watch(walkTestResultProvider.future);
  final fallbackRank = await ref.watch(_fallbackFitnessRankProvider.future);
  return ObjectiveProfile.from(
    pastHikes: pastHikes,
    walkTest: walkTest,
    fallbackFitnessRank: fallbackRank,
  );
});

// ===========================================================================
// LES CRITERES QUI CONDITIONNENT LE VERDICT (correctif N2 / D1, #100293).
//
// CE QUI N'ALLAIT PAS. L'ecran rendait un verdict des que l'UNE des trois
// saisies existait — la morphologie suffisait. Or la morphologie n'entre PAS
// dans le niveau : `deriveLevel` part du D+/jour et des km/jour DEJA REALISES
// (les randos passees), corrige par la forme (test 6 min) puis par l'age. Sans
// rando saisie, ces deux maxima valent zero et le niveau retombe
// mecaniquement sur « debutant », quel que soit le randonneur : c'etait un
// verdict rendu sur du vide, et Chris l'a vu en deux minutes.
//
// CE QU'ON REPRODUIT. GR20 ne propose rien tant que le questionnaire n'est pas
// complet (`feasibility_questionnaire_screen.dart` : `_submitQuestionnaire`
// n'ouvre le resultat que `if (answers.isComplete)`, et la preview live n'est
// affichee que dans ce meme cas). On fait pareil, en le DISANT : tant qu'un
// critere obligatoire manque, aucun verdict, et l'ecran nomme ce qui manque.
// ===========================================================================

/// Etat de completude des criteres qui alimentent le verdict.
class FeasibilityCriteria {
  const FeasibilityCriteria({
    required this.profileComplete,
    required this.hasPastHike,
    required this.hasWalkTest,
  });

  /// Fiche d'info COMPLETE : age + taille + poids (l'age corrige le niveau).
  final bool profileComplete;

  /// Au moins une des 5 dernieres randos saisie (source unique des maxima
  /// realises, donc du niveau : critere OBLIGATOIRE).
  final bool hasPastHike;

  /// Test de marche 6 minutes realise (rang de forme 0..3).
  ///
  /// OPTIONNEL et assume comme tel : il exige une vraie marche GPS de six
  /// minutes. Son absence n'empeche pas le verdict — elle le rend PROVISOIRE,
  /// et l'ecran le dit (bandeau « profil partiel »).
  final bool hasWalkTest;

  /// Tous les criteres OBLIGATOIRES sont fournis -> le verdict peut tomber.
  bool get isComplete => profileComplete && hasPastHike;

  /// Verdict fonde sur un profil entier (test 6 min inclus).
  bool get isFullyInformed => isComplete && hasWalkTest;

  /// Nombre d'etapes du parcours guide remplies (barre de progression, /3).
  int get doneCount =>
      (profileComplete ? 1 : 0) + (hasWalkTest ? 1 : 0) + (hasPastHike ? 1 : 0);
}

/// Completude des criteres du verdict (fiche, randos, test 6 min).
final feasibilityCriteriaProvider =
    FutureProvider<FeasibilityCriteria>((ref) async {
  final profile = await ref.watch(hikerProfileProvider.future);
  final pastHikes = await ref.watch(pastHikesProvider.future);
  final walkTest = await ref.watch(walkTestResultProvider.future);
  return FeasibilityCriteria(
    profileComplete: profile.isComplete,
    hasPastHike: pastHikes.isNotEmpty,
    hasWalkTest: walkTest != null,
  );
});

/// Vrai si le verdict s'appuie sur un profil ENTIER (criteres obligatoires
/// remplis ET test 6 min fait).
///
/// Avant le correctif N2, ce provider repondait « oui » des qu'UNE saisie
/// existait (`randos OU test OU fiche`) : c'est ce OU qui laissait la seule
/// morphologie declencher le verdict. Il ne sert plus de porte d'entree — la
/// porte, c'est [feasibilityCriteriaProvider] — mais de drapeau d'honnetete :
/// il pilote le bandeau « resultat provisoire » (critere #10 de la fiche
/// `data/boites/ia/faisabilite.md` : un profil incomplet rend quand meme un
/// verdict, mais l'ecran le signale).
final hasObjectiveProfileProvider = FutureProvider<bool>((ref) async {
  final criteria = await ref.watch(feasibilityCriteriaProvider.future);
  return criteria.isFullyInformed;
});

// ===========================================================================
// MOTEUR DE FAISABILITE V2 — spec finale #SW-FINAL
// (`data/apport_stepways/SPEC_FINALE_faisabilite_et_poids.md`), arbitrages
// Chris du 22/09/2026. Croise l'ENERGIE de chaque etape (distance + D+/42) a la
// capacite journaliere -> verdict d'etape + SCORE DE CIRCUIT + conseils.
// ===========================================================================

/// Altitude maximale (m) du sentier actif, DERIVEE DE LA TRACE GPX (#2-h, #N1).
///
/// `null` quand la trace est indisponible ou ne porte aucune altitude : le
/// facteur d'altitude vaut alors 1,00 ET L'ECRAN LE DIT. On ne devine jamais
/// une altitude — une dimension neutre faute de donnee n'a pas le meme statut
/// qu'une dimension neutre faute de source (#8-b).
final trailMaxAltitudeProvider = FutureProvider<double?>((ref) async {
  final trailId = ref.watch(trailIdProvider);
  try {
    final points = await ref.watch(gpxTrackProvider(trailId).future);
    return _maxAltitudeOf(points);
  } catch (_) {
    // Trace absente ou illisible : aucune altitude, et on le dira.
    return null;
  }
});

/// Altitude maximale d'une liste de points, `null` si aucune altitude utile.
double? _maxAltitudeOf(List<TrackPoint> points) {
  double? best;
  for (final p in points) {
    final a = p.altitude;
    if (!a.isFinite || a == 0) continue;
    if (best == null || a > best) best = a;
  }
  return best;
}

/// CONDITIONS du trek appliquees a la capacite journaliere (#2-h a #2-j).
///
/// La saison est celle du DEPART pose au Calendrier — la meme source que le Sac
/// adaptatif ([checklistSeasonFromDepartureProvider]), pour qu'une seule date
/// de depart pilote toute l'application. Aucun depart pose -> saison inconnue,
/// et le moteur le declare au lieu de supposer la date du jour : le trek n'est
/// pas forcement pour aujourd'hui.
final trekConditionsProvider = FutureProvider<TrekConditions>((ref) async {
  final trailId = ref.watch(trailIdProvider);
  // Une date de depart illisible (prefs indisponibles) ne doit PAS emporter le
  // verdict avec elle : elle rend la saison inconnue, et l'ecran le declare.
  // Perdre la saison coute une ligne d'explication ; perdre le verdict coute
  // l'ecran entier.
  DateTime? departure;
  try {
    departure = ref.watch(downloadReminderProvider(trailId)).departureDate;
  } catch (_) {
    departure = null;
  }
  final altitude = await ref.watch(trailMaxAltitudeProvider.future);
  return TrekConditions(
    maxAltitudeM: altitude,
    season: departure == null ? null : Season.fromDate(departure),
  );
});

/// Etapes du sentier actif dans le SENS DE MARCHE choisi, converties en
/// [StageEffort] (une par jour de marche de reference).
///
/// Reprend la meme logique de sens que [itineraryProvider] (le sens inverse
/// inverse l'ordre des etapes) pour rester coherent avec le programme (LOT 2).
final stageEffortsProvider = FutureProvider<List<StageEffort>>((ref) async {
  final stages = await ref.watch(stagesProvider.future);
  if (stages.isEmpty) return const [];

  final sorted = List<StageModel>.of(stages)
    ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

  // Sens de marche : identique a itineraryProvider (direction-aware).
  final directions = ref.watch(trailConfigProvider.select((c) => c.directions));
  final forward = directions.isNotEmpty ? directions.first : null;
  final selected = ref.watch(selectedDirectionProvider);
  final reversed = forward != null && selected != null && selected != forward;
  final ordered = reversed ? sorted.reversed.toList() : sorted;

  return [
    for (var i = 0; i < ordered.length; i++)
      StageEffort(
        index: i,
        name: ordered[i].name,
        distanceKm: ordered[i].distanceKm,
        elevationGainM: ordered[i].elevationGainM,
        // Le D− n'entre PAS dans le score (#1-d) : il classe les etapes de
        // l'alerte descente du dispositif poids (#4-l).
        elevationLossM: ordered[i].elevationLossM,
      ),
  ];
});

/// Niveau de randonneur deduit du profil objectif (fiche + test 6 min + randos),
/// corrige age + condition — entree de la formule de faisabilite.
final hikerLevelProvider = FutureProvider<HikerLevel>((ref) async {
  final ObjectiveProfile objective =
      await ref.watch(objectiveProfileProvider.future);
  final HikerProfile profile = await ref.watch(hikerProfileProvider.future);
  return FeasibilityFormula.deriveLevel(
    maxElevationGainPerDayDone: objective.maxElevationGainPerDayDone,
    maxDistancePerDayDone: objective.maxDistancePerDayDone,
    age: profile.age,
    // Le rang de forme vient du test 6 min (0..3), sinon fallback median (1).
    fitnessRank: objective.fitnessLevelRank,
  );
});

/// JOURS DE REPOS DU PROGRAMME, traduits en index d'etapes (#2-p).
///
/// SANS CETTE ALIMENTATION, LA MONOTONIE DE FOSTER N'A AUCUN SENS. La monotonie
/// vaut moyenne ÷ ecart-type des charges journalieres, jours de repos comptes
/// comme CHARGE NULLE. Si le moteur ne voit jamais un jour de repos, toutes les
/// charges sont non nulles, l'ecart-type s'effondre et la monotonie explose :
/// mesure sur le sentier de production, 4,04 — donc C3 a 2,02, donc circuit
/// ROUGE sur les 24 cellules, y compris pour un profil expert dont la pire
/// etape est a 0,54, c'est-a-dire vert franc. La contre-preuve a ete faite sur
/// le moteur reel : en posant deux jours de repos, l'expert repasse au vert.
/// Le calcul etait juste, c'est l'alimentation qui manquait.
///
/// LA SOURCE EST LE PROGRAMME, PAS UNE SUPPOSITION. [plannedDaysProvider] porte
/// le decoupage reel choisi par le randonneur — jours de marche et jours de
/// repos, dans l'ordre. On le parcourt en comptant les etapes consommees : un
/// jour de repos est enregistre APRES la derniere etape marchee avant lui. Un
/// jour qui regroupe deux etapes en consomme deux, donc l'index suit.
///
/// Les repos poses APRES la derniere etape sont ignores : ils n'aident aucune
/// recuperation a l'interieur du trek (le moteur les ecarte lui aussi).
final restDaysAfterStageProvider = Provider<Set<int>>((ref) {
  final trailId = ref.watch(trailIdProvider);
  final days = ref.watch(plannedDaysProvider(trailId));
  final result = <int>{};
  var stagesConsumed = 0;
  for (final day in days) {
    if (day.isRestDay || day.stages.isEmpty) {
      // Aucun repos « avant la premiere etape » : il ne repose de rien.
      if (stagesConsumed > 0) result.add(stagesConsumed - 1);
      continue;
    }
    stagesConsumed += day.stages.length;
  }
  return result;
});

// ===========================================================================
// LE DECOUPAGE SUR LEQUEL LE VERDICT PORTE (retour Chris 5 du 25/09, #100417).
//
// CE QUI N'ALLAIT PAS. Mot pour mot : « la faisabilite ne tient pas compte du
// nombre de jours choisi et des repos. » Verifie ligne par ligne :
// [stageEffortsProvider] lit [stagesProvider], LES ETAPES BRUTES DU SENTIER. Le
// nombre de jours choisi, les regroupements et les separations d'etapes
// n'etaient JAMAIS lus. Les jours de repos, EUX, l'etaient
// ([restDaysAfterStageProvider]) : un demi-cablage, pire qu'aucun, parce qu'il
// donnait l'illusion que l'ecran suivait les choix du randonneur.
//
// CE QUI CHANGE. Le verdict porte desormais sur LE PROGRAMME REEL : une charge
// par JOUR DE MARCHE de [plannedDaysProvider]. Un jour qui regroupe deux etapes
// pese la SOMME des deux — c'est la journee qui se marche, pas la ligne du topo
// — et les jours de repos sont a leur place dans la sequence. Bouger le curseur
// des jours change le decoupage, donc les charges, donc le verdict : a la baisse
// (regroupement -> journees plus lourdes) comme a la hausse (separation ->
// journees plus legeres). C'est la boucle demandee au retour 6.
//
// LE REPLI EST EXPLICITE, ET IL NE REND JAMAIS UN VERDICT SUR DU VIDE. Tant
// qu'aucun programme n'existe (etapes pas encore chargees, container de test
// sans programme), on retombe sur les etapes brutes — une etape par jour — qui
// sont exactement le decoupage de reference du sentier. [fromProgram] dit
// laquelle des deux sources a parle, pour que ce soit verifiable et non suppose.
//
// TACHE 569 : la classe [FeasibilityProgram] et sa conversion sont passees dans
// le DOMAINE (`domain/feasibility_program.dart`), parce que la recherche du
// conseil en a besoin hors de tout provider. Elle est re-exportee ici pour que
// tout ce qui la lisait continue de la trouver au meme endroit.
// ===========================================================================

/// LE DECOUPAGE COURANT, source unique du verdict (retour Chris 5).
///
/// Lit le PROGRAMME du randonneur ([plannedDaysProvider] : jours reellement
/// choisis, etapes regroupees, jours de repos) et le traduit en charges
/// journalieres. Repli sur les etapes brutes quand aucun programme n'existe.
final feasibilityProgramProvider =
    FutureProvider<FeasibilityProgram>((ref) async {
  // Le sentier courant peut etre indisponible (container de test minimal) : une
  // lecture de config ne doit pas emporter l'evaluation avec elle.
  List<PlannedDay> days;
  try {
    final trailId = ref.watch(trailIdProvider);
    days = ref.watch(plannedDaysProvider(trailId));
  } catch (_) {
    days = const [];
  }

  // LA CONVERSION EST ECRITE UNE SEULE FOIS (tache 569) : la meme que celle
  // qu'emprunte la recherche du conseil, pour que le conseil porte exactement
  // sur le decoupage que l'ecran affichera.
  final fromDays = FeasibilityProgram.fromPlannedDays(days);
  if (!fromDays.isEmpty) return fromDays;

  // REPLI : le decoupage de reference du sentier, une etape par jour.
  final rawStages = await ref.watch(stageEffortsProvider.future);
  if (rawStages.isEmpty) return FeasibilityProgram.empty;
  Set<int> rawRest;
  try {
    rawRest = ref.watch(restDaysAfterStageProvider);
  } catch (_) {
    rawRest = const {};
  }
  return FeasibilityProgram.fromRawStages(rawStages,
      restAfterStageIndex: rawRest);
});

/// Evaluation complete de faisabilite (etapes + circuit + conseils) — V2.
///
/// Null si aucune etape (pas de sentier charge) -> l'UI retombe sur le
/// questionnaire de dépannage, comme le verdict objectif.
final feasibilityAssessmentProvider =
    FutureProvider<FeasibilityAssessment?>((ref) async {
  final program = await ref.watch(feasibilityProgramProvider.future);
  if (program.isEmpty) return null;
  final level = await ref.watch(hikerLevelProvider.future);
  final objective = await ref.watch(objectiveProfileProvider.future);
  final conditions = await ref.watch(trekConditionsProvider.future);
  final restDays = program.restAfterDayIndex;
  // LE CONSEIL DE DUREE, CHERCHE PAR ESSAI REEL (tache 569, R1). Le moteur ne le
  // calcule plus : il le recoit. C'est ce qui garantit que la valeur conseillee
  // n'est jamais rouge — elle a ete essayee avant d'etre proposee.
  final advice = await ref.watch(advisedProgramProvider.future);
  return FeasibilityFormula.evaluate(
    stages: program.dayEfforts,
    level: level,
    durationAdvice: advice,
    // R2 : sans choix du randonneur, les numeros de journees et le « au lieu de
    // N » designent le decoupage de REFERENCE du sentier, pas le sien.
    fromProgram: program.fromProgram,
    // PLAFOND DU CONSEIL : jamais plus de jours de marche que le decoupage
    // n'en permet — deux journees par etape depuis la tache 558. Sans cette
    // borne, l'ecran pouvait conseiller un nombre de jours que le curseur du
    // Programme ne sait pas atteindre — un conseil inapplicable.
    maxWalkingDays: program.maxWalkingDays,
    // Plancher demontre (#2-g) : on ne dit jamais a quelqu'un qu'il ne peut
    // pas faire ce qu'il a deja demontre faire.
    demonstratedFloorEnergyKm: objective.maxDailyEnergyKmDone,
    // C4, l'ecart a l'habitude : AFFICHE, JAMAIS DECISIF (#2-q).
    habitualDailyEnergyKm: objective.habitualDailyEnergyKm,
    // Constat de DUREE : le modele ne capte la duree cumulee nulle part, et
    // aucun seuil publie ne permet de la scorer. On enonce le fait.
    longestConsecutiveDaysDone: objective.maxConsecutiveDaysDone,
    // C3, le repos : les jours de repos du PROGRAMME, charge nulle (#2-p).
    // Reperes en index de JOURNEES DE MARCHE depuis la tache 551 — c'est la
    // sequence des charges journalieres que la monotonie consomme.
    restAfterStageIndex: restDays,
    conditions: conditions,
  );
});
