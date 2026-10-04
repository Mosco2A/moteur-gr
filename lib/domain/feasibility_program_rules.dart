/// Les regles de programme de la formule de faisabilite : score de circuit,
/// facteur limitant, jours de marche suggeres et conseils.
///
/// HISTOIRE (lot 645-06b). Ces quatre regles etaient `static` et privees DANS
/// la classe [FeasibilityFormula], qui faisait a elle seule 801 lignes. Le lot
/// 645-06 (vague 2) en avait fait des fonctions privees d'un fichier `part` ;
/// la regle 12 (« pas de `part` hors code genere ») en fait une bibliotheque
/// a part entiere. Elles sont donc PUBLIQUES, parce que la formule les appelle
/// depuis un autre fichier — mais elles ne sont PAS re-exportees par
/// `feasibility_formula.dart` : l'API de la formule ne change pas. Les deux
/// aides qu'elles sont seules a utiliser restent privees ici.
library;

import 'dart:math' as math;

import 'feasibility_engine.dart';
import 'feasibility_scale.dart';
import 'feasibility_stages.dart';
import 'feasibility_types.dart';

/// Calcule C1 a C4 et le score de circuit.
CircuitScore computeCircuitScore({
  required List<StageVerdict> verdicts,
  required double capacity,
  required Set<int> restAfterStageIndex,
  required double? habitualDailyEnergyKm,
  required FeasibilityThresholds thresholds,
}) {
  // C1 — la pire etape (#2-n).
  final c1 = verdicts.map((v) => v.score).reduce(math.max);

  // C2 — la charge moyenne (#2-o).
  final totalEnergy = verdicts.map((v) => v.energyKm).reduce((a, b) => a + b);
  final c2 = capacity > 0
      ? totalEnergy / (verdicts.length * capacity)
      : double.infinity;

  // C3 — le repos (#2-p) : PIRE fenetre glissante de 7 jours, jours de repos
  // comptes comme charge nulle.
  final loads = FeasibilityFormula.dailyLoads(
    stageEnergies: verdicts.map((v) => v.energyKm).toList(),
    restAfterStageIndex: restAfterStageIndex,
  );
  final window = FeasibilityFormula.worstMonotonyWindow(loads);
  final monotony = window.monotony;
  final windowStart = window.startDay;
  final windowEnd = window.endDay;
  final c3 = monotony == null
      ? null
      : monotony / FeasibilityFormula.monotonyThreshold;

  // C4 — l'ecart a l'habitude (#2-q). AFFICHE, JAMAIS DECISIF.
  final habitual = habitualDailyEnergyKm;
  final c4 = (habitual == null || !habitual.isFinite || habitual <= 0)
      ? null
      : (totalEnergy / verdicts.length) / habitual;

  // S_circuit = C1, ET RIEN D'AUTRE (GO-61). C2, C3 et C4 sont calculees,
  // affichees, et pour C3 conseillee — aucune n'entre dans le verdict. La
  // demonstration complete est portee par [CircuitScore.score] : elle tient
  // en une phrase, ce qui n'est pas source s'affiche mais ne decide pas, et
  // C3 etait la derniere contrainte extrapolee a avoir garde ce droit.
  final score = c1;
  const dominant = CircuitConstraint.worstStage;

  return CircuitScore(
    worstStage: c1,
    averageLoad: c2,
    rest: c3,
    habitGap: c4,
    monotony: monotony,
    monotonyWindowStartDay: windowStart,
    monotonyWindowEndDay: windowEnd,
    totalDays: loads.length,
    score: score,
    dominant: dominant,
    verdict: thresholds.verdictFor(score),
  );
}

/// Determine le facteur limitant du verdict global : d'abord l'ENCHAINEMENT
/// (>=2 jours consecutifs au-dessus du plafond), sinon le facteur dominant de
/// l'etape la plus dure (distance, denivele, altitude ou chaleur).
LimitingFactor computeLimitingFactor({
  required List<StageVerdict> verdicts,
  required int daysOver,
  required int hardestIndex,
  required FeasibilityVerdict globalVerdict,
}) {
  if (hardestIndex < 0) return LimitingFactor.none;
  if (globalVerdict == FeasibilityVerdict.green) return LimitingFactor.none;
  // Enchainement : plusieurs jours consecutifs au-dessus = c'est LA contrainte.
  if (daysOver >= 2 && _hasConsecutiveOver(verdicts)) {
    return LimitingFactor.chaining;
  }
  return verdicts[hardestIndex].dominantFactor;
}

/// Vrai s'il existe au moins DEUX etapes consecutives au-dessus du plafond.
bool _hasConsecutiveOver(List<StageVerdict> verdicts) {
  for (var i = 1; i < verdicts.length; i++) {
    if (verdicts[i].isOverCapacity && verdicts[i - 1].isOverCapacity) {
      return true;
    }
  }
  return false;
}

/// ESTIMATION DE LISSAGE HISTORIQUE — N'EST PLUS LE CONSEIL (tache 569).
///
/// CE QU'ELLE CALCULE : le nombre de journees pour que la CHARGE MOYENNE
/// tienne sous la capacite, en lissant les pics : max(nb de journees,
/// ceil(energie totale / capacite), nb de journees + nb de journees
/// au-dessus de la capacite).
///
/// POURQUOI ELLE NE PEUT PAS ETRE LE CONSEIL, ET C'EST UNE DEMONSTRATION, PAS
/// UN AVIS. Le verdict vaut C1 = LE MAXIMUM des scores journaliers (GO-61).
/// Cette fonction vise une MOYENNE. Une moyenne ne borne pas un maximum :
/// viser la moyenne laisse la pire journee exactement ou elle est. Mesure sur
/// les 96 cellules de la campagne : 16 conseils dont le nombre, lu sur le
/// curseur, tombait sur un verdict ROUGE. Le conseil est desormais trouve par
/// ESSAI REEL ([ProgramPlanSearch.firstNonRed]) et INJECTE dans [evaluate] ;
/// cette fonction ne sert plus que de repli quand aucune recherche n'a eu lieu
/// (appels de moteur nu, reconstitution de la colonne « AVANT » de la
/// campagne).
///
/// [maxWalkingDays] plafonne le resultat au nombre de journees REELLEMENT
/// atteignable (une etape ne se coupe pas en deux : elle s'arrete la ou il y a
/// un toit). Le plafond ne descend jamais sous le programme courant :
/// conseiller MOINS de jours que ce qui est deja pose n'a aucun sens ici, la
/// fonction cherchant toujours a etaler l'effort.
int suggestWalkingDays(
  List<StageVerdict> verdicts,
  double capacity, {
  int maxWalkingDays = 0,
}) {
  if (verdicts.isEmpty) return 0;
  final total = verdicts.map((v) => v.energyKm).reduce((a, b) => a + b);
  final byLoad = capacity > 0 ? (total / capacity).ceil() : verdicts.length;
  // Chaque journee au-dessus de la capacite merite au moins d'etre coupee en 2.
  final overCount = verdicts
      .where((v) => capacity > 0 && v.energyKm > capacity)
      .length;
  final byOver = verdicts.length + overCount;
  final raw = math.max(verdicts.length, math.max(byLoad, byOver));
  if (maxWalkingDays <= 0) return raw;
  return math.min(raw, math.max(maxWalkingDays, verdicts.length));
}

/// Construit les conseils de programme (cles i18n + parametres). Coherent avec
/// l'ecran Programme (LOT 2) : jours + repos.
///
/// TACHE 569 — DEUX REGLES NOUVELLES, TOUTES DEUX TRANCHEES PAR CHRIS.
///
/// R2 — TOUT NOMBRE DE JOURS PORTE SA NATURE. Aucun conseil n'ecrit plus un
/// nombre de jours sans dire s'il compte la marche, le repos ou le total, et
/// aucun n'ecrit « au lieu de N » quand le randonneur n'a rien choisi : N est
/// alors le PROGRAMME DE REFERENCE du topo. Les conseils qui NUMEROTENT des
/// journees disent de quel programme ils parlent, pour la meme raison.
///
/// R4 — COUPER UNE ETAPE N'EST NI CONSEILLE NI POSSIBLE. Verbatim : « decoupe
/// la journee 1 en 2 === comment on fait???? pas une solution, mettre juste
/// une alerte coimme quoi elle va etre cramoisie, et puis il y a
/// l'entrainement non??? ». Une etape se termine la ou il y a un TOIT : couper
/// a mi-distance envoie quelqu'un dormir dans un ravin.
///
/// TACHE 634 puis 639 — LE MECANISME N'EXISTE PLUS, ET LE MOT NON PLUS. Ce
/// commentaire affirmait le contraire (« le MECANISME reste, Chris l'a
/// tranche ») : c'etait vrai en 569, faux depuis le lot 634 (86dacc67), qui a
/// retire `maxDaysPerStage`, `splitStage`, `_splitHeaviestFirst` et la borne a
/// 2N. La tache 639 acheve le retrait cote LIBELLES — verbatim de Christophe
/// (30/09 10:12) : « jour par jour on dit que la premiere etape est en
/// decoupage trop serre alors que je ne veux pas qu on decoupe les etapes ! ».
/// Ce qui reste : l'ALERTE sur la journee qui fait mal, et l'entrainement, qui
/// est la vraie reponse — monter d'un cran releve le plafond, donc fait passer
/// la journee.
List<ProgramAdvice> programAdviceFor({
  required List<StageVerdict> verdicts,
  required CircuitScore? circuit,
  required FeasibilityVerdict globalVerdict,
  required int hardestIndex,
  required int suggestedTotalDays,
  required int suggestedWalkingDays,
  required int suggestedRestDays,
  required int currentTotalDays,
  required int trainingWeeks,
  required Set<int> recommendedRest,
  required bool durationAdvised,
  required bool durationSearched,
  required bool fromProgram,
}) {
  final advice = <ProgramAdvice>[];

  // 0. LE REPOS, EN CONSEIL (GO-61). Il ne decide plus rien, donc il ne
  // depend plus de la couleur : un programme dont toutes les etapes sont
  // vertes peut parfaitement n'offrir aucune recuperation, et c'est encore
  // plus vrai quand il est vert — personne ne pensera a souffler. La phrase
  // dit COMBIEN et OU, parce qu'un conseil qu'on ne peut pas appliquer n'en
  // est pas un.
  final c3 = circuit?.rest;
  final restAdvised = c3 != null && c3 > 1 && recommendedRest.isNotEmpty;
  // R2 : les numeros de journees ne designent pas la meme chose selon que le
  // randonneur a choisi son programme ou non. Deux formulations, une cle par
  // situation — plutot qu'un seul texte ambigu.
  final restAdvice = ProgramAdvice(
    key: fromProgram ? 'restAdvised' : 'restAdvisedReference',
    params: {
      'days': recommendedRest.length,
      'stages': (recommendedRest.toList()..sort()).map((i) => i + 1).join(', '),
    },
  );

  // Tout vert : le programme actuel tient, on encourage a garder des marges.
  // Le conseil de repos vient APRES — il nuance, il ne contredit pas.
  if (globalVerdict == FeasibilityVerdict.green) {
    advice.add(const ProgramAdvice(key: 'balancedOk'));
    if (restAdvised) advice.add(restAdvice);
    return advice;
  }

  // Hors du vert, le repos passe DEVANT : conseiller d'etaler les jours
  // quand c'est la recuperation qui manque enverrait dans le mur, lisser les
  // pics et poser des repos etant deux leviers OPPOSES (#2-t).
  if (restAdvised) advice.add(restAdvice);

  // 1. LA DUREE CONSEILLEE — OU L'AVEU QU'IL N'Y EN A PAS (tache 569, R1).
  //
  // Trois situations, et une seule conseille un nombre :
  //   * la recherche a eu lieu et n'a RIEN trouve de mieux que rouge : on ne
  //     conseille AUCUNE valeur et on dit franchement que cette journee-la
  //     bloque, quoi qu'on fasse du programme. C'est le remplacant honnete du
  //     « decoupe la journee N en deux » de la tache 558 ;
  //   * une duree est conseillee et elle allonge le programme : on l'ecrit
  //     avec SES TROIS NOMBRES (marche, repos, total — R2), et sans « au lieu
  //     de » quand rien n'a encore ete choisi ;
  //   * une duree est conseillee et c'est deja celle du randonneur : rien a
  //     changer au rythme, on le dit.
  if (durationSearched && !durationAdvised) {
    advice.add(
      ProgramAdvice(
        key: 'noViableDuration',
        params: {'stage': hardestIndex + 1},
      ),
    );
  } else if (suggestedTotalDays > currentTotalDays) {
    advice.add(
      ProgramAdvice(
        key: fromProgram ? 'optimalDays' : 'optimalDaysNoChoice',
        params: {
          'days': suggestedTotalDays,
          'walk': suggestedWalkingDays,
          'rest': suggestedRestDays,
          'current': currentTotalDays,
        },
      ),
    );
  } else {
    advice.add(const ProgramAdvice(key: 'balanced'));
  }

  // 2. LA JOURNEE QUI FAIT MAL EST NOMMEE, ET ON NE CONSEILLE PLUS DE LA
  //    COUPER (tache 569, R4).
  //
  // CE QUI DISPARAIT, ET POURQUOI. La tache 558 conseillait de couper la
  // journee N en deux (cle `split`), et, quand chaque etape occupait deja deux
  // journees, « elle reste au-dessus meme coupee » (`splitImpossible`).
  // Christophe a tranche le 26/09 : couper une etape en deux, ce n'est pas une
  // solution qu'on peut conseiller a quelqu'un, parce qu'une etape se termine
  // la ou il y a un TOIT. Le point de coupe du modele est une interpolation
  // sur le segment depart -> arrivee : conseiller de s'y arreter, c'est
  // envoyer dormir dans un ravin.
  //
  // CE QUI RESTE : l'alerte. La journee est nommee, on dit qu'elle sera dure,
  // et on renvoie a l'entrainement — qui est la vraie reponse, puisqu'il
  // releve le plafond du randonneur, donc le denominateur du score, donc fait
  // passer la journee.
  //
  // ET RIEN D'AUTRE (taches 634 puis 639). Ces deux lignes disaient encore que
  // « le mecanisme de decoupage reste en place et disponible au curseur » :
  // c'est faux depuis le lot 634, qui l'a retire du calcul. Le curseur ne
  // produit plus que des jours de REPOS, et une etape reste une etape du
  // sentier.
  if (hardestIndex >= 0 &&
      verdicts[hardestIndex].verdict == FeasibilityVerdict.red &&
      !(durationSearched && !durationAdvised)) {
    advice.add(
      ProgramAdvice(key: 'hardStageAlert', params: {'stage': hardestIndex + 1}),
    );
  }

  // 3. Ou poser les repos : apres chaque bloc d'etapes au-dessus du plafond.
  //
  // SAUTE si le conseil de rythme a deja parle : deux phrases de repos qui
  // designent des etapes differentes — l'une sur les blocs durs, l'autre sur
  // la regularite — se contrediraient a l'ecran. Le conseil de rythme est
  // alors le plus complet des deux (il dit combien ET ou).
  final restAfter = restAdvised ? const <int>[] : _restDaySuggestions(verdicts);
  if (restAfter.isNotEmpty) {
    advice.add(
      ProgramAdvice(
        // R2 : meme regle que `restAdvised` — on dit de quel programme ces
        // numeros de journees parlent.
        key: fromProgram ? 'rest' : 'restReference',
        params: {'stages': restAfter.map((i) => i + 1).join(', ')},
      ),
    );
  }

  // 4. Entrainement (renvoi vers la prepa physique).
  if (trainingWeeks > 0) {
    advice.add(
      ProgramAdvice(key: 'training', params: {'weeks': trainingWeeks}),
    );
  }

  return advice;
}

/// Index (0-based) des etapes APRES lesquelles poser un jour de repos : la
/// derniere etape de chaque bloc consecutif au-dessus du plafond (hors toute
/// derniere etape du trek, ou un repos n'a pas de sens).
List<int> _restDaySuggestions(List<StageVerdict> verdicts) {
  final suggestions = <int>[];
  for (var i = 0; i < verdicts.length; i++) {
    final over = verdicts[i].isOverCapacity;
    final nextOver = i + 1 < verdicts.length && verdicts[i + 1].isOverCapacity;
    // Fin d'un bloc « au-dessus » suivi d'une autre etape -> repos utile.
    if (over && !nextOver && i + 1 < verdicts.length) {
      suggestions.add(i);
    }
  }
  return suggestions;
}
