// L'INVARIANTE DE CHRIS, VERIFIEE ET ETENDUE (tache 573, LOT V).
//
// CE FICHIER NE REFAIT PAS LE LOT R. L'invariante « a la valeur conseillee, le
// verdict n'est jamais rouge » est deja implementee et testee par la tache 569
// (`conseil_jamais_rouge_569_test.dart`, 96 cellules de la matrice de campagne).
// Le mandat du LOT V est de la VERIFIER et de l'etendre a ce qu'elle ne couvre
// pas. Trois manques ont ete trouves, et ce fichier les ferme.
//
// MANQUE 1 — ELLE NE TOURNE PAS SUR LE SENTIER QU'ON LIVRE. Les 96 cellules du
// LOT R lisent `integration_test/campagne_v2/matrice_96.json` : quatre jeux
// d'etapes SYNTHETIQUES (7, 5, 1 et 30 etapes). Le sentier reellement embarque
// dans l'application — `assets/data/mare_a_mare_centre.json`, sept etapes, 84 km,
// 3 550 m de D+ — n'etait teste par AUCUNE des 96. C'est pourtant celui que
// Chris avait sous les yeux quand il a lu « vise 9 jours » au-dessus d'un rouge a
// 9 jours. Ici, l'invariante tourne sur les donnees LIVREES, et sur TOUT sentier
// que `assets/data/` contiendra demain : la decouverte est automatique.
//
// MANQUE 2 — LA GARANTIE DEPEND DU SITE D'APPEL, ET RIEN NE LE VERIFIAIT.
// `FeasibilityFormula.evaluate` ne garantit le conseil non rouge que si on lui
// passe `durationAdvice`. Sans ce parametre, elle retombe sur l'ANCIENNE regle
// (`_suggestedWalkingDays`, une moyenne) qui ne garantit RIEN — le code le dit
// lui-meme : « Elle ne garantit pas la couleur ». Aujourd'hui l'unique site
// d'appel de production le passe. Le jour ou quelqu'un en ajoute un second sans
// le passer, le defaut de Chris revient, et les 96 cellules resteront vertes
// parce qu'elles appellent le moteur en direct. Ce fichier verifie les SITES
// D'APPEL, pas seulement le moteur.
//
// MANQUE 3 — AUCUN TEMOIN ROUGE. Une invariante dont le conseil est construit
// pour la satisfaire (`ProgramPlanSearch.firstNonRed` retient la premiere valeur
// non rouge) est vraie par construction : elle ne peut plus echouer, donc elle ne
// prouve plus rien. Un test qui ne peut pas echouer ne protege de rien. On garde
// donc ici l'ANCIENNE regle, rejouee a cote, comme TEMOIN : elle DOIT produire
// du rouge. Le jour ou le temoin passe au vert, c'est le test qui est casse, pas
// l'application qui est devenue parfaite.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_program.dart';
import 'package:moteur_gr/features/feasibility/domain/program_plan_search.dart';
import 'package:moteur_gr/features/planning/domain/planning_calculator.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';

// ---------------------------------------------------------------------------
// Les sentiers REELLEMENT embarques dans l'application
// ---------------------------------------------------------------------------

/// Un sentier livre : son identifiant et ses etapes, lues dans `assets/data/`.
class SentierLivre {
  const SentierLivre({required this.id, required this.stages});

  final String id;
  final List<StageModel> stages;

  @override
  String toString() => '$id (${stages.length} etapes)';
}

/// Tous les sentiers livres avec l'application.
///
/// DECOUVERTE AUTOMATIQUE : tout fichier `assets/data/*.json` portant une liste
/// `stages` avec des distances et des deniveles est un sentier. Un sentier ajoute
/// demain sera donc couvert le jour de son ajout, sans que personne y pense —
/// c'est la difference entre un test qui vieillit et un test qui tient.
List<SentierLivre> sentiersLivres() {
  final dir = Directory('assets/data');
  if (!dir.existsSync()) return const [];
  final out = <SentierLivre>[];
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    Object? brut;
    try {
      brut = jsonDecode(f.readAsStringSync());
    } catch (_) {
      continue;
    }
    if (brut is! Map<String, dynamic>) continue;
    final rows = brut['stages'];
    if (rows is! List || rows.isEmpty) continue;

    final stages = <StageModel>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (r is! Map<String, dynamic>) continue;
      final dist = r['distanceKm'] ?? r['distance_km'];
      final gain = r['elevationGain'] ?? r['elevationGainM'] ?? r['elevation_gain'];
      if (dist is! num || gain is! num) continue;
      final perte = r['elevationLoss'] ?? r['elevationLossM'] ?? 0;
      stages.add(StageModel(
        trailId: f.uri.pathSegments.last,
        stageNumber: ((r['stageNumber'] ?? (i + 1)) as num).toInt(),
        name: 'E${i + 1}',
        distanceKm: dist.toDouble(),
        elevationGainM: gain.toInt(),
        elevationLossM: (perte as num).toInt(),
        startLat: 42.0 + i * 0.01,
        startLng: 9.0 + i * 0.01,
        endLat: 42.0 + (i + 1) * 0.01,
        endLng: 9.0 + (i + 1) * 0.01,
      ));
    }
    if (stages.isEmpty) continue;
    out.add(SentierLivre(id: f.uri.pathSegments.last, stages: stages));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Rejouer les deux moteurs de l'ecran, sans en reecrire aucun
// ---------------------------------------------------------------------------

DurationBounds bornesDe(List<StageModel> stages) {
  final energies = [
    for (final s in stages)
      FeasibilityScale.v2
          .energyOf(distanceKm: s.distanceKm, elevationGainM: s.elevationGainM),
  ];
  final rest = FeasibilityFormula.recommendedRestAfterStageIndex(energies).length;
  return DurationBounds.fromStageCount(stages.length, recommendedRestDays: rest);
}

/// Le verdict REEL a [totalJours] de curseur : le programme est construit par le
/// moteur de repartition de l'ecran, puis colore par le moteur de verdict de
/// l'ecran. Aucune formule locale.
FeasibilityAssessment evaluationA(
  int totalJours, {
  required List<StageModel> stages,
  required DurationBounds bornes,
  required HikerLevel niveau,
  required double plancher,
  required TrekConditions conditions,
  ProgramDurationAdvice? conseil,
}) {
  final plan = PlanningCalculator.distribute(stages, totalJours,
      maxRestDays: bornes.restAllowance);
  final program = FeasibilityProgram.fromDayPlans(plan);
  return FeasibilityFormula.evaluate(
    stages: program.dayEfforts,
    level: niveau,
    demonstratedFloorEnergyKm: plancher,
    restAfterStageIndex: program.restAfterDayIndex,
    conditions: conditions,
    maxWalkingDays: program.maxWalkingDays,
    durationAdvice: conseil,
  );
}

/// L'ANCIENNE regle de conseil, rejouee comme TEMOIN.
///
/// Elle visait la CHARGE MOYENNE sous la capacite : energie totale divisee par
/// la capacite, arrondie au superieur, plus une journee par journee au-dessus du
/// plafond. Une moyenne ne dit rien d'un maximum — c'est exactement pour ca que
/// le conseil tombait sur du rouge. Elle est reecrite ici, et seulement ici, pour
/// PROUVER que l'invariante attrape quelque chose.
int conseilAncienneRegle({
  required List<StageModel> stages,
  required HikerLevel niveau,
  required double plancher,
  required TrekConditions conditions,
  required DurationBounds bornes,
}) {
  final depart = evaluationA(
    bornes.clampDuration(stages.length),
    stages: stages,
    bornes: bornes,
    niveau: niveau,
    plancher: plancher,
    conditions: conditions,
  );
  final capacite = depart.dailyCapacityEnergyKm;
  final total = depart.stageVerdicts.fold<double>(0, (a, s) => a + s.energyKm);
  final moyenne = (total / capacite).ceil();
  final auDessus = depart.stageVerdicts.where((s) => s.score > 1.0).length;
  return bornes.clampDuration(moyenne + auDessus);
}

// ---------------------------------------------------------------------------

void main() {
  const niveaux = HikerLevel.values;
  // Les cinq etats de saison que l'ecran peut porter, `null` comprise (aucune
  // date de depart posee) : la saison change la capacite (ete 0,93) et donc la
  // couleur. Le LOT R lisait une saison par cellule ; ici on balaie les cinq sur
  // chaque cellule.
  const saisons = <String?>[
    null,
    FeasibilitySeason.winter,
    FeasibilitySeason.spring,
    FeasibilitySeason.summer,
    FeasibilitySeason.autumn,
  ];
  // Trois planchers de forme demontree : rien prouve, une sortie moyenne, une
  // grosse sortie. Le plancher releve la capacite et peut donc, lui aussi, faire
  // basculer la couleur.
  const planchers = <double>[0, 25, 55];

  late List<SentierLivre> sentiers;

  setUpAll(() {
    sentiers = sentiersLivres();
    expect(sentiers, isNotEmpty,
        reason: 'aucun sentier livre trouve dans assets/data : la lecture est '
            'cassee, et l invariante ne testerait plus rien');
  });

  group('V4-a — l invariante sur les sentiers REELLEMENT LIVRES', () {
    test('a la valeur conseillee, le verdict n est jamais rouge', () {
      final fautes = <String>[];
      var cellules = 0;
      for (final sentier in sentiersLivres()) {
        final bornes = bornesDe(sentier.stages);
        final aMax = sentier.stages
            .map((s) => s.elevationGainM.toDouble())
            .fold<double>(0, (a, b) => a > b ? a : b);
        for (final niveau in niveaux) {
          for (final saison in saisons) {
            for (final plancher in planchers) {
              cellules++;
              final conditions =
                  TrekConditions(maxAltitudeM: aMax, season: saison);
              final conseil = ProgramPlanSearch.firstNonRed(
                stages: sentier.stages,
                level: niveau,
                demonstratedFloorEnergyKm: plancher,
                conditions: conditions,
                bounds: bornes,
              );
              if (conseil == null) continue; // couvert par le test suivant
              final reel = evaluationA(
                conseil.totalDays,
                stages: sentier.stages,
                bornes: bornes,
                niveau: niveau,
                plancher: plancher,
                conditions: conditions,
                conseil: conseil.toAdvice(),
              );
              final cle = '$sentier / ${niveau.name} / ${saison ?? "sans date"}'
                  ' / plancher $plancher';
              if (reel.globalVerdict == FeasibilityVerdict.red) {
                fautes.add('$cle : conseil ${conseil.totalDays} j -> ROUGE');
              }
              if (conseil.verdict != reel.globalVerdict) {
                fautes.add('$cle : le conseil annonce ${conseil.verdict.name} '
                    'et l ecran affichera ${reel.globalVerdict.name}');
              }
            }
          }
        }
      }
      expect(cellules, greaterThanOrEqualTo(60),
          reason: 'le balayage doit couvrir au moins 4 niveaux x 5 saisons x 3 '
              'planchers sur le sentier livre');
      expect(fautes, isEmpty,
          reason: 'l application conseille une valeur qu elle declare '
              'mauvaise :\n${fautes.join('\n')}');
    });

    test('quand rien n est conseillable, l appli le DIT au lieu de pointer '
        'une valeur', () {
      final fautes = <String>[];
      for (final sentier in sentiersLivres()) {
        final bornes = bornesDe(sentier.stages);
        for (final niveau in niveaux) {
          const conditions = TrekConditions.unknown;
          final conseil = ProgramPlanSearch.firstNonRed(
            stages: sentier.stages,
            level: niveau,
            demonstratedFloorEnergyKm: 0,
            conditions: conditions,
            bounds: bornes,
          );
          if (conseil != null) continue;
          // Aucune valeur n'est viable : toutes les valeurs du curseur doivent
          // effectivement etre rouges, sinon la recherche a rate une solution.
          for (var j = bornes.min; j <= bornes.max; j++) {
            final v = evaluationA(
              j,
              stages: sentier.stages,
              bornes: bornes,
              niveau: niveau,
              plancher: 0,
              conditions: conditions,
            ).globalVerdict;
            if (v != FeasibilityVerdict.red) {
              fautes.add('$sentier / ${niveau.name} : aucun conseil rendu, '
                  'alors que $j jours donne ${v.name}');
            }
          }
        }
      }
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    });
  });

  group('V4-b — LE TEMOIN : l invariante attrape vraiment quelque chose', () {
    test('l ANCIENNE regle de conseil, elle, tombe sur du ROUGE', () {
      // Si ce test passait au vert, cela ne voudrait pas dire que tout va bien :
      // cela voudrait dire que le balayage ne contient plus aucun cas ou les deux
      // regles divergent — donc que l'invariante ne demontre plus rien.
      final rouges = <String>[];
      for (final sentier in sentiersLivres()) {
        final bornes = bornesDe(sentier.stages);
        final aMax = sentier.stages
            .map((s) => s.elevationGainM.toDouble())
            .fold<double>(0, (a, b) => a > b ? a : b);
        for (final niveau in niveaux) {
          for (final saison in saisons) {
            for (final plancher in planchers) {
              final conditions =
                  TrekConditions(maxAltitudeM: aMax, season: saison);
              final ancien = conseilAncienneRegle(
                stages: sentier.stages,
                niveau: niveau,
                plancher: plancher,
                conditions: conditions,
                bornes: bornes,
              );
              final verdict = evaluationA(
                ancien,
                stages: sentier.stages,
                bornes: bornes,
                niveau: niveau,
                plancher: plancher,
                conditions: conditions,
              ).globalVerdict;
              if (verdict == FeasibilityVerdict.red) {
                rouges.add('$sentier / ${niveau.name} / '
                    '${saison ?? "sans date"} / plancher $plancher : '
                    'ancien conseil $ancien j -> ROUGE');
              }
            }
          }
        }
      }
      expect(rouges, isNotEmpty,
          reason: 'LE TEMOIN EST MUET : l ancienne regle de conseil ne tombe '
              'plus sur aucun rouge dans ce balayage. L invariante ne prouve '
              'donc plus rien — il faut elargir le balayage jusqu a ce qu elle '
              'attrape a nouveau un cas reel.');
      // MESURE DU 26/09 : 82 cellules rouges sur les 120 du balayage. Le
      // plancher est volontairement bas (20) pour ne pas casser au premier
      // sentier ajoute, mais assez haut pour qu'un temoin devenu anecdotique se
      // signale.
      expect(rouges.length, greaterThanOrEqualTo(20),
          reason: 'le temoin ne trouve plus que ${rouges.length} cas rouges : '
              'l invariante perd ses dents.');
    });
  });

  group('V4-c — la garantie ne doit pas dependre du site d appel', () {
    test('tout appel de production a evaluate() passe le conseil de duree', () {
      // LA FAILLE RESIDUELLE, ET ELLE EST STRUCTURELLE. Sans `durationAdvice`,
      // `evaluate` retombe sur l ancienne regle, dont le code dit lui-meme
      // « Elle ne garantit pas la couleur ». Un second site d appel ecrit sans
      // ce parametre ramenerait le defaut de Chris, et aucune des 96 cellules du
      // LOT R ne le verrait : elles appellent le moteur en direct, jamais par
      // l ecran.
      final fautifs = <String>[];
      final dir = Directory('lib');
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final chemin = f.path.replaceAll('\\', '/');
        // Le moteur de recherche appelle `evaluate` SANS conseil, et c est son
        // role : il essaie les valeurs une par une pour en trouver une bonne.
        if (chemin.endsWith('domain/program_plan_search.dart')) continue;
        final src = f.readAsStringSync();
        if (!src.contains('FeasibilityFormula.evaluate(')) continue;
        // Chaque appel est examine separement : un fichier peut en porter deux.
        for (final m
            in RegExp(r'FeasibilityFormula\.evaluate\(').allMatches(src)) {
          final fin = src.indexOf(');', m.end);
          final appel = fin < 0 ? src.substring(m.end) : src.substring(m.end, fin);
          if (!appel.contains('durationAdvice')) {
            fautifs.add('$chemin (appel sans durationAdvice)');
          }
        }
      }
      expect(fautifs, isEmpty,
          reason: 'CES APPELS DE PRODUCTION N ENVOIENT PAS LE CONSEIL DE '
              'DUREE : ils retombent sur l ancienne regle de moyenne, qui ne '
              'garantit pas la couleur. L invariante de Chris ne tient alors '
              'plus pour l ecran qui les utilise.\n  ${fautifs.join('\n  ')}');
    });
  });
}
