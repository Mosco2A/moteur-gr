/// Le bilan de faisabilite rendu au randonneur.
///
/// Bibliotheque de la formule de faisabilite (lot 645-06b), re-exportee par
/// `feasibility_formula.dart` : les appelants n'importent que cette racine.
library;

import 'feasibility_scale.dart';
import 'feasibility_stages.dart';
import 'feasibility_types.dart';

/// Resultat complet du moteur de faisabilite V2.
class FeasibilityAssessment {
  const FeasibilityAssessment({
    required this.scale,
    required this.level,
    required this.levelCeilingEnergyKm,
    required this.demonstratedFloorEnergyKm,
    required this.baseCapacityEnergyKm,
    required this.dailyCapacityEnergyKm,
    required this.conditions,
    required this.stageVerdicts,
    required this.circuit,
    required this.globalVerdict,
    required this.hardestStageIndex,
    required this.daysOverCapacity,
    required this.limitingFactor,
    required this.recommendedTrainingWeeks,
    required this.advice,
    required this.suggestedDays,
    required this.suggestedRestDays,
    required this.isDurationSearched,
    required this.isDurationAdvised,
    required this.fromProgram,
    required this.restDaysPlanned,
    required this.recommendedRestAfterStageIndex,
    required this.walkingDays,
    required this.longestConsecutiveDaysDone,
  });

  /// Bareme applique (V2 en production, V1 pour la colonne AVANT).
  final FeasibilityScale scale;

  /// Niveau retenu (corrige age + condition).
  final HikerLevel level;

  /// Plafond journalier du NIVEAU seul (km-energie), avant plancher demontre.
  final double levelCeilingEnergyKm;

  /// E_max_realise : meilleure journee DEMONTREE (km-energie), 0 si inconnue.
  final double demonstratedFloorEnergyKm;

  /// Capacite de BASE = max(plafond du niveau ; plancher demontre) (#2-d).
  final double baseCapacityEnergyKm;

  /// Capacite du jour de REFERENCE = base × k_altitude × k_chaleur (#2-d/#2-e).
  final double dailyCapacityEnergyKm;

  /// Conditions appliquees (altitude, saison) — l'ecran doit pouvoir les dire.
  final TrekConditions conditions;

  /// Verdict par etape (meme ordre que l'entree).
  final List<StageVerdict> stageVerdicts;

  /// Score de circuit (C1 a C4) — `null` si aucune etape.
  final CircuitScore? circuit;

  /// Verdict global = verdict du CIRCUIT (et non plus la seule pire etape).
  final FeasibilityVerdict globalVerdict;

  /// Index 0-based de l'etape la plus contraignante (score max), -1 si aucune.
  final int hardestStageIndex;

  /// Nombre de jours (etapes) au-dessus du plafond (orange + rouge).
  final int daysOverCapacity;

  /// Facteur limitant nomme du verdict global.
  final LimitingFactor limitingFactor;

  /// Reco d'entrainement en semaines (6-12 selon le profil), 0 si verdict vert.
  final int recommendedTrainingWeeks;

  /// Conseils de programme (nb de jours optimal, regroupement, repos).
  final List<ProgramAdvice> advice;

  /// Nombre de jours de MARCHE du programme conseille (hors repos).
  ///
  /// NE S'AFFICHE JAMAIS SEUL (tache 569, R2) : un nombre de jours doit dire
  /// s'il compte la marche, le repos ou le total. L'ecran ecrit les trois.
  final int suggestedDays;

  /// Nombre de jours de REPOS du programme conseille.
  final int suggestedRestDays;

  /// LA DUREE DU PLAN CONSEILLE — les jours de MARCHE, et eux seuls
  /// (DEM-260930-1238 : « Si c est 7 jours c est 7 jours »).
  ///
  /// C'est cette valeur, et aucune autre, que le bouton « Generer mon programme »
  /// applique et que la reponse annonce. Voir [ProgramDurationAdvice.planDays]
  /// pour le raisonnement complet.
  int get suggestedPlanDays => suggestedDays;

  /// Jours totaux conseilles (marche + repos) — valeur INFORMATIVE.
  ///
  /// CE COMMENTAIRE DISAIT L'INVERSE, ET C'EST CE QUI A PRODUIT LE DEFAUT. Il
  /// annoncait : « C'est cette valeur, et aucune autre, que le bouton Generer mon
  /// programme applique et sur laquelle le curseur s'ouvre » (tache 569, R1-a).
  /// L'ecran l'appliquait donc, et le Mare a Mare Centre — SEPT etapes —
  /// s'annoncait « en 9 jours ». Verbatim de Christophe le 30/09 a 12:37 : « Si c
  /// est 7 jours c est 7 jours ».
  ///
  /// LE REPOS N'EST PAS PERDU : il reste CONSEILLE ([suggestedRestDays], « nous
  /// conseillons n jours de repos »). Ce total ne sert plus qu'a dire combien de
  /// jours on passe dehors en suivant AUSSI ce conseil.
  int get suggestedTotalDays => suggestedDays + suggestedRestDays;

  /// Vrai quand une RECHERCHE de duree a eu lieu (tache 569, R1).
  ///
  /// Faux pour un appel de moteur nu : l'absence de recherche n'est pas une
  /// preuve d'impossibilite, et l'ecran ne doit pas annoncer « aucune duree ne
  /// marche » quand personne n'a cherche.
  final bool isDurationSearched;

  /// Vrai quand une duree est REELLEMENT conseillee.
  ///
  /// Faux quand la recherche a essaye toutes les valeurs du curseur et n'en a
  /// trouve aucune qui ne soit pas rouge : l'application ne conseille alors
  /// aucune valeur, n'affiche pas le bouton, et dit que l'etape bloque.
  final bool isDurationAdvised;

  /// Vrai si le programme evalue est celui CHOISI par le randonneur, faux s'il
  /// s'agit du programme de REFERENCE du sentier (lot A, drapeau `fromProgram`).
  ///
  /// CE QUE CE DRAPEAU CHANGE A L'ECRAN (tache 569, R2). Les conseils qui
  /// numerotent des journees — « pose un repos apres la journee 3 » — ne
  /// designent pas la meme chose dans les deux cas, et « vise 11 jours AU LIEU
  /// DE 7 » n'a aucun sens quand le randonneur n'a jamais choisi 7 : c'est le
  /// programme du topo, pas le sien.
  final bool fromProgram;

  /// Nombre de jours de REPOS pris en compte dans la contrainte C3.
  final int restDaysPlanned;

  /// REPOS CONSEILLES : index 0-based des etapes APRES lesquelles poser un jour
  /// de repos pour que la monotonie repasse sous son seuil.
  ///
  /// UN CONSEIL, PLUS UN VERDICT (GO-61). C'est aussi ce que le programme par
  /// defaut POSE : le randonneur part d'un itineraire tenable et voit le
  /// chiffre du repos bouger s'il les retire, au lieu de partir d'un itineraire
  /// qu'il devrait reparer sans savoir comment.
  final Set<int> recommendedRestAfterStageIndex;

  /// Nombre de jours de repos conseilles (= taille de
  /// [recommendedRestAfterStageIndex]).
  int get recommendedRestDays => recommendedRestAfterStageIndex.length;

  /// Vrai si le repos merite d'etre CONSEILLE : la monotonie depasse son seuil
  /// (C3 > 1) et le programme courant ne porte pas encore ce qu'il faudrait.
  ///
  /// Ne conditionne AUCUNE couleur : c'est le declencheur d'une phrase, pas
  /// d'un verdict.
  bool get isRestAdvised {
    final c = circuit;
    final r = c?.rest;
    return r != null && r > 1 && recommendedRestAfterStageIndex.isNotEmpty;
  }

  /// Nombre de jours de MARCHE du trek (= nombre d'etapes evaluees).
  ///
  /// ENONCE, JAMAIS SCORE. Voir [longestConsecutiveDaysDone].
  final int walkingDays;

  /// Plus longue sortie ENCHAINEE deja realisee, en jours. 0 = inconnue.
  ///
  /// POURQUOI CE CONSTAT EXISTE, ET POURQUOI IL N'EST PAS UNE COULEUR.
  /// Le modele ne capte la DUREE CUMULEE nulle part. C3 mesure l'absence de
  /// recuperation, c'est-a-dire une forme de REGULARITE, pas une LONGUEUR : sur
  /// des etapes regulieres sans repos, C3 rend exactement le meme chiffre pour
  /// trois jours et pour dix-sept. Aucun seuil publie n'existe pour combler ce
  /// trou (#M06), donc on ne l'invente pas : on ENONCE LE FAIT — « ce trek dure
  /// dix-sept jours de marche, ta plus longue sortie enchainee est de trois
  /// jours » — et le randonneur juge. Un constat, pas un verdict.
  final int longestConsecutiveDaysDone;

  /// Vrai si le constat de duree peut etre enonce (les deux chiffres existent).
  bool get hasDurationStatement =>
      walkingDays > 0 && longestConsecutiveDaysDone > 0;

  /// Etape la plus contraignante (null si aucune etape).
  StageVerdict? get hardestStage =>
      hardestStageIndex >= 0 ? stageVerdicts[hardestStageIndex] : null;

  /// LE VERDICT EST-IL VALIDE (#1-e / #2-j).
  ///
  /// En hiver, on ne durcit pas le verdict : ON DIT QU'IL NE TIENT PLUS. Les
  /// chiffres restent calcules et visibles — les masquer reviendrait a cacher
  /// ce sur quoi la declaration porte — mais l'ecran DOIT afficher la
  /// non-validite (#8-d).
  bool get isVerdictValid => !conditions.isWinterDeparture;

  /// ARB-004 (#2-s) : le circuit est-il PLUS SEVERE que toutes ses etapes ?
  ///
  /// STRUCTURELLEMENT FAUX DEPUIS GO-61, et c'est exactement pour cela que ce
  /// getter reste : S_circuit vaut C1, donc le verdict du circuit EST celui de
  /// sa pire etape, et cette propriete doit pouvoir etre VERIFIEE plutot que
  /// supposee. Un test la verrouille ; le jour ou une contrainte informative
  /// rentrerait a nouveau dans le verdict, il rougirait au lieu de laisser
  /// passer un randonneur devant des etapes vertes surmontees d'un circuit
  /// rouge, sans explication.
  bool get isCircuitHarsherThanStages {
    final c = circuit;
    if (c == null || stageVerdicts.isEmpty) return false;
    return c.verdict.index > worstStageVerdict.index;
  }

  /// Verdict de la PIRE etape (C1 seule), pour l'explication d'ARB-004.
  FeasibilityVerdict get worstStageVerdict => hardestStageIndex >= 0
      ? stageVerdicts[hardestStageIndex].verdict
      : FeasibilityVerdict.green;

  /// Vrai si le plancher demontre a REELLEMENT releve la capacite (#2-g) :
  /// le randonneur a deja fait mieux que le plafond de son cran.
  bool get isDemonstratedFloorActive =>
      demonstratedFloorEnergyKm > levelCeilingEnergyKm;

  /// Etapes triees par denivele NEGATIF decroissant (#4-l) : le dispositif
  /// poids enonce sa charge excedentaire sur les premieres, sans inventer de
  /// seuil de declenchement.
  List<StageVerdict> get stagesByDescentDesc {
    final sorted = List<StageVerdict>.of(
      stageVerdicts,
    )..sort((a, b) => b.stage.elevationLossM.compareTo(a.stage.elevationLossM));
    return sorted;
  }
}
