// L'INVARIANTE DU LOT R (tache 569) : ON NE CONSEILLE JAMAIS UN ROUGE.
//
// DECISION DE CHRIS DU 26/09, VERBATIM : « OK mais le curseur est celui
// conseille et il n'est jamais en rouge quand il est conseille en orange max ».
//
// CE QUE LA CAMPAGNE A MESURE LA VEILLE, cran par cran sur le Mare a Mare :
// 9 jours donnait « Decoupage trop serre » (ROUGE), 10 rouge, 11 exigeant,
// 12 exigeant, 13 exigeant, 14 faisable — ET LE CONSEIL DISAIT « VISE 9 JOURS ».
// L'application pointait donc le randonneur vers une valeur qu'elle declarait
// mauvaise dans la meme page.
//
// LA CAUSE EXACTE, ET C'EST UN TROU DE TEST AUTANT QU'UN TROU DE CODE. Le
// conseil et le verdict etaient calcules par DEUX REGLES DIFFERENTES :
//   * le conseil par `_suggestedWalkingDays`, qui vise une CHARGE MOYENNE sous
//     la capacite (energie totale / capacite, arrondi au superieur) ;
//   * le verdict par le SCORE DE CIRCUIT, qui vaut C1 = LA PIRE JOURNEE et elle
//     seule depuis GO-61.
// Une moyenne ne garantit rien sur un maximum : viser la moyenne laisse la pire
// journee ou elle est. Aucun des 2 760 tests du depot ne verifiait l'ACCORD des
// deux calculs — ils les testaient separement, chacun juste de son cote.
//
// CE FICHIER FERME LE TROU. Il prend la valeur que l'application CONSEILLE,
// construit le programme REEL a cette valeur avec le moteur de repartition qui
// le produira sur l'ecran ([PlanningCalculator.distribute]), lui applique le
// moteur de verdict qui le colorera ([FeasibilityFormula.evaluate]) et exige :
//   1. le verdict a la valeur conseillee est VERT ou ORANGE, JAMAIS ROUGE ;
//   2. quand AUCUNE valeur du curseur ne fait mieux que rouge, l'application ne
//      conseille AUCUNE valeur et le dit franchement.
// Sur TOUS les sentiers et TOUS les profils de la matrice de campagne : 4 jeux
// d'etapes (7, 5, 1 et 30 etapes) x 6 personas x 4 rangs de forme = 96 cellules.
//
// TRACE DU ROUGE INITIAL, MESUREE AVANT CORRECTION LE 26/09 — deux lectures, et
// les deux comptent :
//
//   (A) LE TEXTE, LU SUR LE CURSEUR : 16 cellules sur 96. Le conseil ecrivait
//       « vise N jours » avec N en jours de MARCHE, le curseur compte des
//       TOTAUX. Lea sur le Mare a Mare (P2-J1) : texte « vise 10 jours », ROUGE
//       a 10 sur le curseur, premier total non rouge a 11. Et le curseur
//       s'ouvrait a 9, lui aussi ROUGE. C'est exactement ce que Chris a lu.
//
//   (B) LE BOUTON « Generer mon programme » : 0 sur 96 sur cette matrice — mais
//       ROUGE des qu'une etape est indivisible. Sur un sentier d'une seule etape
//       de 40 km et 3 000 m de D+, bornes 1..2, il conseillait 2 jours, le
//       verdict a 2 jours etait ROUGE, et les conseils affiches etaient
//       [optimalDays, split, training] : l'application proposait de couper une
//       etape dont chaque moitie depassait encore le plafond.
//
// L'ancien conseil n'etait donc pas faux par accident sur seize cas : il n'avait
// AUCUNE garantie, et la seule raison pour laquelle (B) passait sur la matrice
// est que ses quatre sentiers ont tous une solution accessible.
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
// Lecture de la matrice de campagne (source unique des sentiers et des profils)
// ---------------------------------------------------------------------------

HikerLevel _levelFromName(String name) => switch (name) {
      'beginner' => HikerLevel.beginner,
      'intermediate' => HikerLevel.intermediate,
      'confirmed' => HikerLevel.confirmed,
      'expert' => HikerLevel.expert,
      _ => throw ArgumentError('niveau inconnu: $name'),
    };

/// Les etapes d'un jeu, en [StageModel] — le type que le moteur de repartition
/// consomme reellement (le conseil doit etre calcule sur ce qu'on lui donnera).
List<StageModel> _stageModelsOf(Map<String, dynamic> jeu, String trailId) {
  final rows = (jeu['stages'] as List).cast<Map<String, dynamic>>();
  return [
    for (var i = 0; i < rows.length; i++)
      StageModel(
        trailId: trailId,
        stageNumber: (rows[i]['n'] as num).toInt(),
        name: 'E${rows[i]['n']}',
        distanceKm: (rows[i]['distanceKm'] as num).toDouble(),
        elevationGainM: (rows[i]['elevationGainM'] as num).toInt(),
        elevationLossM: ((rows[i]['elevationLossM'] ?? 0) as num).toInt(),
        startLat: 42.0 + i * 0.01,
        startLng: 9.0 + i * 0.01,
        endLat: 42.0 + (i + 1) * 0.01,
        endLng: 9.0 + (i + 1) * 0.01,
      ),
  ];
}

/// Les bornes du CURSEUR pour ce jeu d'etapes — exactement celles que l'ecran
/// Programme appliquera ([durationBoundsProvider] passe par la meme fabrique).
DurationBounds _boundsOf(List<StageModel> stages) {
  final energies = [
    for (final s in stages)
      FeasibilityScale.v2
          .energyOf(distanceKm: s.distanceKm, elevationGainM: s.elevationGainM),
  ];
  final rest =
      FeasibilityFormula.recommendedRestAfterStageIndex(energies).length;
  return DurationBounds.fromStageCount(stages.length,
      recommendedRestDays: rest);
}

void main() {
  late Map<String, dynamic> jeux;
  late Map<String, dynamic> personas;
  late List<Map<String, dynamic>> cellules;

  setUpAll(() {
    final f = File('integration_test/campagne_v2/matrice_96.json');
    expect(f.existsSync(), isTrue,
        reason: 'matrice de campagne introuvable : ${f.absolute.path}');
    final matrice = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    jeux = matrice['jeuxEtapes'] as Map<String, dynamic>;
    personas = matrice['personas'] as Map<String, dynamic>;
    cellules = (matrice['cellules'] as List).cast<Map<String, dynamic>>();
  });

  /// Tout ce qu'il faut pour rejouer une cellule : le sentier et le randonneur.
  ({
    List<StageModel> stages,
    DurationBounds bounds,
    HikerLevel level,
    double floor,
    TrekConditions conditions,
  }) cas(Map<String, dynamic> cellule) {
    final jeu = jeux[cellule['jeu'] as String] as Map<String, dynamic>;
    final persona = personas[cellule['profil'] as String] as Map<String, dynamic>;
    final stages = _stageModelsOf(jeu, cellule['jeu'] as String);
    return (
      stages: stages,
      bounds: _boundsOf(stages),
      level: _levelFromName((cellule['v2'] as Map)['niveau'] as String),
      floor: ((persona['eMaxRealise'] as num?) ?? 0).toDouble(),
      conditions: TrekConditions(
        maxAltitudeM: (jeu['aMaxM'] as num?)?.toDouble(),
        season: cellule['saison'] as String?,
      ),
    );
  }

  /// LE VERDICT REEL a [totalDays] jours de curseur : le programme est construit
  /// par le moteur de repartition de l'ecran, puis colore par le moteur de
  /// verdict de l'ecran. Aucune formule locale : ce sont les deux memes calculs
  /// que le randonneur verra.
  FeasibilityVerdict verdictA(
    int totalDays, {
    required List<StageModel> stages,
    required DurationBounds bounds,
    required HikerLevel level,
    required double floor,
    required TrekConditions conditions,
  }) {
    final plan = PlanningCalculator.distribute(stages, totalDays,
        maxRestDays: bounds.restAllowance);
    final program = FeasibilityProgram.fromDayPlans(plan);
    return FeasibilityFormula.evaluate(
      stages: program.dayEfforts,
      level: level,
      demonstratedFloorEnergyKm: floor,
      restAfterStageIndex: program.restAfterDayIndex,
      conditions: conditions,
      maxWalkingDays: program.maxWalkingDays,
    ).globalVerdict;
  }

  group('R1 — L INVARIANTE : la valeur conseillee n est JAMAIS rouge', () {
    test(
        'sur les 96 cellules (4 sentiers x 6 personas x 4 rangs), le verdict a '
        'la valeur conseillee est vert ou orange', () {
      final fautes = <String>[];
      for (final cellule in cellules) {
        final c = cas(cellule);
        final conseil = ProgramPlanSearch.firstNonRed(
          stages: c.stages,
          level: c.level,
          demonstratedFloorEnergyKm: c.floor,
          conditions: c.conditions,
          bounds: c.bounds,
        );
        if (conseil == null) continue; // couvert par le test suivant.
        final reel = verdictA(
          conseil.totalDays,
          stages: c.stages,
          bounds: c.bounds,
          level: c.level,
          floor: c.floor,
          conditions: c.conditions,
        );
        if (reel == FeasibilityVerdict.red) {
          fautes.add('${cellule['id']} : conseil ${conseil.totalDays} j '
              '(${conseil.walkingDays} marche + ${conseil.restDays} repos) '
              '-> verdict ROUGE');
        }
        // Le conseil ANNONCE aussi son verdict : il doit etre celui que
        // l'ecran affichera, sinon le conseil se contredirait lui-meme.
        if (conseil.verdict != reel) {
          fautes.add('${cellule['id']} : le conseil annonce ${conseil.verdict} '
              'et l ecran affichera $reel');
        }
      }
      expect(fautes, isEmpty,
          reason: 'l application conseille une valeur qu elle declare '
              'mauvaise :\n${fautes.join('\n')}');
    });

    test(
        'quand AUCUNE valeur n est conseillee, c est que TOUTES les valeurs du '
        'curseur sont rouges', () {
      // LES 96 CELLULES, PLUS UN SENTIER QUI BLOQUE. Les quatre jeux de la
      // matrice ont tous une solution, meme pour un debutant sans rien de
      // demontre : leur pire etape coupee en deux repasse sous le plafond. Le
      // cas « rien ne marche » n'y est donc pas — et sans lui ce test ne
      // prouverait rien. On y ajoute le sentier d'une etape indivisible :
      // 40 km et 3 000 m de D+, dont chaque moitie (20 km, 1 500 m, soit 55,7
      // km-energie) depasse encore le plafond d'un debutant (25,14).
      final jeux = <String, ({
        List<StageModel> stages,
        DurationBounds bounds,
        HikerLevel level,
        double floor,
        TrekConditions conditions,
      })>{};
      for (final cellule in cellules) {
        jeux[cellule['id'] as String] = cas(cellule);
      }
      final bloquant = [
        const StageModel(
          trailId: 'bloquant',
          stageNumber: 1,
          name: 'Mur',
          distanceKm: 40,
          elevationGainM: 3000,
          elevationLossM: 0,
          startLat: 42,
          startLng: 9,
          endLat: 42.1,
          endLng: 9.1,
        ),
      ];
      jeux['BLOQUANT-debutant'] = (
        stages: bloquant,
        bounds: _boundsOf(bloquant),
        level: HikerLevel.beginner,
        floor: 0.0,
        conditions: TrekConditions.unknown,
      );

      var sansSolution = 0;
      for (final entree in jeux.entries) {
        final c = entree.value;
        final conseil = ProgramPlanSearch.firstNonRed(
          stages: c.stages,
          level: c.level,
          demonstratedFloorEnergyKm: c.floor,
          conditions: c.conditions,
          bounds: c.bounds,
        );
        if (conseil != null) continue;
        sansSolution++;
        for (final d in c.bounds.options) {
          final v = verdictA(
            d,
            stages: c.stages,
            bounds: c.bounds,
            level: c.level,
            floor: c.floor,
            conditions: c.conditions,
          );
          expect(v, FeasibilityVerdict.red,
              reason: '${entree.key} : aucune valeur conseillee alors que '
                  '$d jours donne $v — on a tu une solution qui existe');
        }
      }
      expect(sansSolution, greaterThan(0),
          reason: 'le cas « l etape bloque » n est pas exerce : ce test ne '
              'prouve alors rien');
    });

    test('le conseil est le PLUS PETIT total qui ne soit pas rouge', () {
      for (final cellule in cellules) {
        final c = cas(cellule);
        final conseil = ProgramPlanSearch.firstNonRed(
          stages: c.stages,
          level: c.level,
          demonstratedFloorEnergyKm: c.floor,
          conditions: c.conditions,
          bounds: c.bounds,
        );
        if (conseil == null) continue;
        for (final d in c.bounds.options) {
          if (d >= conseil.totalDays) break;
          final v = verdictA(
            d,
            stages: c.stages,
            bounds: c.bounds,
            level: c.level,
            floor: c.floor,
            conditions: c.conditions,
          );
          expect(v, FeasibilityVerdict.red,
              reason: '${cellule['id']} : $d jours donne $v et le conseil est '
                  'a ${conseil.totalDays} — on fait marcher le randonneur '
                  '${conseil.totalDays - d} jour(s) de plus que necessaire');
        }
      }
    });

    test('le conseil tient dans les bornes du curseur : il est APPLICABLE', () {
      for (final cellule in cellules) {
        final c = cas(cellule);
        final conseil = ProgramPlanSearch.firstNonRed(
          stages: c.stages,
          level: c.level,
          demonstratedFloorEnergyKm: c.floor,
          conditions: c.conditions,
          bounds: c.bounds,
        );
        if (conseil == null) continue;
        expect(conseil.totalDays, greaterThanOrEqualTo(c.bounds.min),
            reason: '${cellule['id']} : conseil sous la borne basse');
        expect(conseil.totalDays, lessThanOrEqualTo(c.bounds.max),
            reason: '${cellule['id']} : conseil au-dessus de la borne haute');
        expect(conseil.walkingDays + conseil.restDays, conseil.totalDays,
            reason: '${cellule['id']} : les trois nombres ne s additionnent pas');
      }
    });
  });

  group('R1 — le moteur porte le conseil, l ecran ne le recalcule pas', () {
    /// Un sentier dont UNE etape est hors de portee quoi qu on fasse : meme
    /// coupee en deux, chaque moitie depasse le plafond d un debutant.
    List<StageModel> sentierBloquant() => const [
          StageModel(
            trailId: 'bloquant',
            stageNumber: 1,
            name: 'Mur',
            distanceKm: 40,
            elevationGainM: 3000,
            elevationLossM: 0,
            startLat: 42,
            startLng: 9,
            endLat: 42.1,
            endLng: 9.1,
          ),
        ];

    test('conseil viable -> l evaluation porte les trois nombres', () {
      final stages = _stageModelsOf(
          jeux['J1'] as Map<String, dynamic>, 'J1');
      final bounds = _boundsOf(stages);
      final conseil = ProgramPlanSearch.firstNonRed(
        stages: stages,
        level: HikerLevel.beginner,
        conditions: const TrekConditions(maxAltitudeM: 1050, season: 'summer'),
        bounds: bounds,
      );
      expect(conseil, isNotNull);
      final plan = PlanningCalculator.distribute(stages, conseil!.totalDays,
          maxRestDays: bounds.restAllowance);
      final program = FeasibilityProgram.fromDayPlans(plan);
      final a = FeasibilityFormula.evaluate(
        stages: program.dayEfforts,
        level: HikerLevel.beginner,
        restAfterStageIndex: program.restAfterDayIndex,
        conditions: const TrekConditions(maxAltitudeM: 1050, season: 'summer'),
        maxWalkingDays: program.maxWalkingDays,
        durationAdvice: conseil.toAdvice(),
      );
      expect(a.isDurationAdvised, isTrue);
      expect(a.suggestedTotalDays, conseil.totalDays);
      expect(a.suggestedDays, conseil.walkingDays);
      expect(a.suggestedRestDays, conseil.restDays);
      expect(a.globalVerdict, isNot(FeasibilityVerdict.red));
    });

    test(
        'AUCUN conseil possible -> aucune duree conseillee, et l etape qui '
        'bloque est NOMMEE', () {
      final stages = sentierBloquant();
      final bounds = _boundsOf(stages);
      final conseil = ProgramPlanSearch.firstNonRed(
        stages: stages,
        level: HikerLevel.beginner,
        bounds: bounds,
      );
      expect(conseil, isNull,
          reason: 'une etape de 40 km et 3 000 m D+ ne passe pas, meme coupee');
      final plan = PlanningCalculator.distribute(stages, bounds.min,
          maxRestDays: bounds.restAllowance);
      final program = FeasibilityProgram.fromDayPlans(plan);
      final a = FeasibilityFormula.evaluate(
        stages: program.dayEfforts,
        level: HikerLevel.beginner,
        restAfterStageIndex: program.restAfterDayIndex,
        maxWalkingDays: program.maxWalkingDays,
        durationAdvice: ProgramDurationAdvice.impossible,
      );
      expect(a.isDurationAdvised, isFalse,
          reason: 'mieux vaut avouer qu il n y a pas de solution de programme '
              'que d en pointer une fausse');
      final cles = a.advice.map((x) => x.key).toList();
      expect(cles, contains('noViableDuration'));
      expect(cles, isNot(contains('optimalDays')));
      expect(cles, isNot(contains('optimalDaysNoChoice')));
      expect(cles, contains('training'),
          reason: 'l entrainement est la vraie reponse quand le programme n en '
              'a pas');
      final franc = a.advice.firstWhere((x) => x.key == 'noViableDuration');
      expect(franc.params['stage'], a.hardestStageIndex + 1);
    });
  });

  group('R4 — le decoupage d etape n est PLUS JAMAIS conseille', () {
    test('une etape rouge produit une ALERTE, pas un conseil de coupe', () {
      final r = FeasibilityFormula.evaluate(
        stages: const [
          StageEffort(index: 0, name: 'A', distanceKm: 35, elevationGainM: 800),
          StageEffort(index: 1, name: 'B', distanceKm: 10, elevationGainM: 200),
        ],
        level: HikerLevel.intermediate,
      );
      final cles = r.advice.map((a) => a.key).toList();
      expect(cles, isNot(contains('split')),
          reason: 'une etape se termine la ou il y a un toit : couper a '
              'mi-distance envoie quelqu un dormir dans un ravin');
      expect(cles, isNot(contains('splitImpossible')));
      expect(cles, contains('hardStageAlert'));
      final alerte = r.advice.firstWhere((a) => a.key == 'hardStageAlert');
      expect(alerte.params['stage'], r.hardestStageIndex + 1);
      expect(cles, contains('training'),
          reason: 's entrainer eleve le plafond, donc fait passer la journee');
    });

    test('le MECANISME de decoupage reste en place (il n est pas conseille)',
        () {
      // La borne a 2N du lot G et [splitStage] sont conserves : Chris l a
      // tranche. Ce qui disparait, c est le CONSEIL, pas l outil.
      expect(PlanningCalculator.maxDaysPerStage, 2);
      expect(PlanningCalculator.maxWalkingDaysFor(7), 14);
      const stage = StageModel(
        trailId: 't',
        stageNumber: 1,
        name: 'A',
        distanceKm: 20,
        elevationGainM: 1000,
        elevationLossM: 400,
        startLat: 42,
        startLng: 9,
        endLat: 43,
        endLng: 10,
      );
      final parts = PlanningCalculator.splitStage(stage);
      expect(parts.length, 2);
      expect(parts[0].distanceKm + parts[1].distanceKm, closeTo(20, 1e-9));
    });
  });
}
