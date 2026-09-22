import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';

/// Tests du MOTEUR DE FAISABILITE V2 (spec finale #SW-FINAL, 22/09/2026).
///
/// Couvre : unite d'energie, plafonds re-derives, verdict tricolore
/// (vert/orange/rouge), verdict global + facteur limitant + jours au-dessus,
/// conseils programme (jours optimal, decoupe, repos), reco entrainement.
void main() {
  StageEffort stage({
    int index = 0,
    String name = 'Etape',
    double distanceKm = 0,
    int elevationGainM = 0,
  }) =>
      StageEffort(
        index: index,
        name: name,
        distanceKm: distanceKm,
        elevationGainM: elevationGainM,
      );

  const v2 = FeasibilityScale.v2;

  group('unite d energie (#1-a, #2-a)', () {
    test('energie = distance + D+/42 (Minetti 2002)', () {
      final s = stage(distanceKm: 12, elevationGainM: 840);
      expect(v2.energyOfStage(s), closeTo(12 + 20, 1e-9)); // 32 km-energie
      expect(v2.elevationEnergyOf(s), closeTo(20, 1e-9));
    });

    test('42 m de D+ valent 1 km de plat, et non plus 100', () {
      expect(v2.energyOfStage(stage(elevationGainM: 42)), closeTo(1, 1e-9));
      expect(FeasibilityScale.v1.energyOfStage(stage(elevationGainM: 100)),
          closeTo(1, 1e-9));
    });

    test('le bareme V1 reste disponible pour reconstituer la colonne AVANT',
        () {
      // C est sa SEULE raison d exister : sans lui, les verdicts « avant » de
      // la campagne seraient des chiffres recopies que personne ne verifierait.
      final s = stage(distanceKm: 12, elevationGainM: 800);
      expect(FeasibilityScale.v1.energyOfStage(s), closeTo(20, 1e-9));
      expect(v2.energyOfStage(s), greaterThan(20));
    });
  });

  group('plafonds re-derives (#2-f)', () {
    test('sur les MEMES reperes BP, avec la nouvelle unite', () {
      final b = v2.levelCeilingFor(HikerLevel.beginner);
      final i = v2.levelCeilingFor(HikerLevel.intermediate);
      final c = v2.levelCeilingFor(HikerLevel.confirmed);
      final e = v2.levelCeilingFor(HikerLevel.expert);
      expect(b, lessThan(i));
      expect(i, lessThan(c));
      expect(c, lessThan(e));
      expect(b, closeTo(18 + 300 / 42, 1e-9)); // 25,14
      expect(i, closeTo(22 + 700 / 42, 1e-9)); // 38,67
      expect(c, closeTo(27 + 1200 / 42, 1e-9)); // 55,57
      expect(e, closeTo(30 + 1500 / 42, 1e-9)); // 65,71
    });

    test('les anciens plafonds 21/29/39/45 appartiennent au bareme V1', () {
      expect(FeasibilityScale.v1.levelCeilingFor(HikerLevel.beginner),
          closeTo(21, 1e-9));
      expect(FeasibilityScale.v1.levelCeilingFor(HikerLevel.intermediate),
          closeTo(29, 1e-9));
    });
  });

  group('capacite du jour : L ORDRE COMPTE (#2-d, #2-e)', () {
    test('le plancher demontre s applique a la BASE, les conditions ensuite',
        () {
      // Un randonneur debutant qui a deja tenu 40 km-energie/jour : sa base
      // est 40, pas 25,14. L ete rabote ENSUITE cette base relevee.
      const ete = TrekConditions(season: FeasibilitySeason.summer);
      final capacity = FeasibilityFormula.dailyCapacityFor(
        level: HikerLevel.beginner,
        demonstratedFloorEnergyKm: 40,
        conditions: ete,
      );
      expect(capacity, closeTo(40 * 0.93, 1e-9));
      // L ORDRE INVERSE (conditions d abord, plancher ensuite) rendrait 40 et
      // effacerait silencieusement la chaleur. C est l erreur corrigee.
      expect(capacity, lessThan(40));
    });

    test('le plancher ne joue que s il DEPASSE le plafond du niveau', () {
      final capacity = FeasibilityFormula.dailyCapacityFor(
        level: HikerLevel.confirmed,
        demonstratedFloorEnergyKm: 20,
      );
      expect(capacity, closeTo(v2.levelCeilingFor(HikerLevel.confirmed), 1e-9));
    });

    test('k_altitude : 1 % par 100 m au-dessus de 1 500 m (#2-h)', () {
      expect(const TrekConditions(maxAltitudeM: 1050).altitudeFactor,
          closeTo(1.0, 1e-9));
      expect(const TrekConditions(maxAltitudeM: 1730).altitudeFactor,
          closeTo(0.977, 1e-9));
      // Altitude ABSENTE -> 1,00, et la raison est nommee pour l ecran.
      expect(TrekConditions.unknown.altitudeFactor, closeTo(1.0, 1e-9));
      expect(TrekConditions.unknown.altitudeNeutralReason,
          NeutralReason.missingData);
    });

    test('k_chaleur : ete 0,93, le reste NEUTRE ET DIT (#2-i)', () {
      expect(
          const TrekConditions(season: FeasibilitySeason.summer).heatFactor,
          closeTo(0.93, 1e-9));
      for (final s in [FeasibilitySeason.spring, FeasibilitySeason.autumn]) {
        final c = TrekConditions(season: s);
        expect(c.heatFactor, closeTo(1.0, 1e-9));
        // Neutre faute de SOURCE — pas faute de donnee : l ecran doit pouvoir
        // dire lequel des deux.
        expect(c.seasonNeutralReason, NeutralReason.noPublishedSource);
      }
    });

    test('hiver : AUCUN coefficient, le verdict est DECLARE non valide (#1-e)',
        () {
      const hiver = TrekConditions(season: FeasibilitySeason.winter);
      expect(hiver.heatFactor, closeTo(1.0, 1e-9));
      final a = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 10, elevationGainM: 400)],
        level: HikerLevel.intermediate,
        conditions: hiver,
      );
      expect(a.isVerdictValid, isFalse);
      // On ne durcit pas : la capacite est celle du niveau, intacte.
      expect(a.dailyCapacityEnergyKm,
          closeTo(v2.levelCeilingFor(HikerLevel.intermediate), 1e-9));
    });
  });

  group('LA MORPHOLOGIE NE PESE PAS DANS LE VERDICT (#3-d, #3-f)', () {
    test('le moteur n expose aucune entree de masse', () {
      // Test de CONTRAT : si un jour quelqu un ajoute un parametre de poids a
      // `evaluate`, c est ici que ca doit se voir. Le meme homme a 65 ou 95 kg
      // obtient le meme verdict parce qu il n y a rien ou le mettre.
      final a = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 20, elevationGainM: 900)],
        level: HikerLevel.intermediate,
      );
      final b = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 20, elevationGainM: 900)],
        level: HikerLevel.intermediate,
      );
      expect(a.stageVerdicts.first.score, b.stageVerdicts.first.score);
    });
  });

  group('decomposition du score (#2-l)', () {
    test('distance + denivele + chaleur + altitude = score, exactement', () {
      final a = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 18, elevationGainM: 1200)],
        level: HikerLevel.intermediate,
        conditions: const TrekConditions(
          maxAltitudeM: 2100,
          season: FeasibilitySeason.summer,
        ),
      );
      final v = a.stageVerdicts.first;
      expect(
        v.distanceShare + v.elevationShare + v.heatShare + v.altitudeShare,
        closeTo(v.score, 1e-12),
      );
      // Toutes les parts sont positives : aucune ne peut « rembourser » une
      // autre, donc la plus grosse est bien le facteur dominant.
      expect(v.heatShare, greaterThan(0));
      expect(v.altitudeShare, greaterThan(0));
    });
  });

  group('deriveLevel (profil -> niveau)', () {
    test('D+/jour eleve -> confirme ou plus', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 800,
        maxDistancePerDayDone: 24,
      );
      expect(level, HikerLevel.confirmed);
    });

    test('jamais rien fait -> debutant', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 0,
        maxDistancePerDayDone: 0,
      );
      expect(level, HikerLevel.beginner);
    });

    test('prend le plus prudent des deux axes (D+ eleve, distance faible)', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 1300, // expert par D+
        maxDistancePerDayDone: 10, // debutant par distance
      );
      expect(level, HikerLevel.beginner);
    });

    test('age >= 75 redescend de deux crans', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 1300,
        maxDistancePerDayDone: 30,
        age: 78,
      );
      // Brut expert (rang 3) -> -2 -> intermediaire (rang 1).
      expect(level, HikerLevel.intermediate);
    });

    test('forme excellente remonte d un cran', () {
      final level = FeasibilityFormula.deriveLevel(
        maxElevationGainPerDayDone: 500, // intermediaire
        maxDistancePerDayDone: 18, // intermediaire
        fitnessRank: 3,
      );
      expect(level, HikerLevel.confirmed);
    });
  });

  // Plafond intermediaire V2 = 38,67 km-energie. Seuils : vert <= 32,87,
  // orange <= 42,53, rouge au-dela.
  group('verdict tricolore par etape', () {
    test('VERT si score <= 0.85', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 15, elevationGainM: 500)], // 26,9
        level: HikerLevel.intermediate,
      );
      expect(r.stageVerdicts.single.verdict, FeasibilityVerdict.green);
    });

    test('ORANGE si 0.85 < score <= 1.10', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 25, elevationGainM: 500)], // 36,9
        level: HikerLevel.intermediate,
      );
      expect(r.stageVerdicts.single.verdict, FeasibilityVerdict.orange);
    });

    test('ROUGE si score > 1.10', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 35, elevationGainM: 800)], // 54,0
        level: HikerLevel.intermediate,
      );
      expect(r.stageVerdicts.single.verdict, FeasibilityVerdict.red);
    });

    test('seuils exacts 0.85 et 1.10 sont inclusifs (vert / orange)', () {
      const th = FeasibilityThresholds.median;
      expect(th.verdictFor(0.85), FeasibilityVerdict.green);
      expect(th.verdictFor(0.8500001), FeasibilityVerdict.orange);
      expect(th.verdictFor(1.10), FeasibilityVerdict.orange);
      expect(th.verdictFor(1.1000001), FeasibilityVerdict.red);
    });

    test('seuils parametrables (surcharge)', () {
      const strict = FeasibilityThresholds(green: 0.5, orange: 0.7);
      // 26,9 / 38,67 = 0,696 -> orange avec seuils stricts (vert par defaut).
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 15, elevationGainM: 500)],
        level: HikerLevel.intermediate,
        thresholds: strict,
      );
      expect(r.stageVerdicts.single.verdict, FeasibilityVerdict.orange);
    });
  });

  group('SCORE DE CIRCUIT (#2-m a #2-t)', () {
    test('C1 est bien le score de la pire etape', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 10, elevationGainM: 300),
          stage(index: 1, distanceKm: 35, elevationGainM: 800), // la pire
          stage(index: 2, distanceKm: 12, elevationGainM: 400),
        ],
        level: HikerLevel.intermediate,
      );
      expect(r.hardestStageIndex, 1);
      expect(r.circuit!.worstStage, closeTo(r.stageVerdicts[1].score, 1e-12));
    });

    test('C2 NE MORD JAMAIS : une moyenne n est jamais au-dessus d un maximum',
        () {
      // Mesure, pas supposition. La phrase #2-o de la spec (« un circuit dont
      // la moyenne depasse le plafond est intenable meme si aucune etape ne
      // depasse ») decrit un cas IMPOSSIBLE par construction. On le verrouille
      // ici pour que personne ne recable C2 en croyant corriger un bug.
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 30, elevationGainM: 900),
          stage(index: 1, distanceKm: 31, elevationGainM: 950),
          stage(index: 2, distanceKm: 29, elevationGainM: 880),
        ],
        level: HikerLevel.beginner,
      );
      expect(r.circuit!.averageLoad,
          lessThanOrEqualTo(r.circuit!.worstStage + 1e-12));
      expect(r.circuit!.dominant, isNot(CircuitConstraint.averageLoad));
    });

    test('CAS LIMITE : sur UNE seule etape, C3 est DECLARE non applicable', () {
      // L ecart-type d une charge unique vaut zero, la monotonie diverge. Une
      // contrainte non calculable est declaree, jamais remplacee par un
      // chiffre — c est le test le plus important de la famille (#10-e).
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 15, elevationGainM: 850)],
        level: HikerLevel.beginner,
      );
      expect(r.circuit!.rest, isNull);
      expect(r.circuit!.isRestApplicable, isFalse);
      expect(r.circuit!.dominant, isNot(CircuitConstraint.rest));
      // Le circuit retombe alors sur C1, et il reste calculable.
      expect(r.circuit!.score, closeTo(r.circuit!.worstStage, 1e-12));
    });

    test('LES JOURS DE REPOS ENTRENT DANS LA MONOTONIE, charge NULLE (#2-p)',
        () {
      // SANS repos, des journees qui se ressemblent font exploser la monotonie
      // et le circuit part au rouge alors que chaque etape est verte. AVEC un
      // repos, l ecart-type se creuse et le circuit redescend. C est tout
      // l objet de la contrainte, et c est le cablage qui manquait.
      final stages = [
        stage(index: 0, distanceKm: 10, elevationGainM: 200),
        stage(index: 1, distanceKm: 12, elevationGainM: 300),
      ];
      final sans = FeasibilityFormula.evaluate(
        stages: stages,
        level: HikerLevel.confirmed,
      );
      final avec = FeasibilityFormula.evaluate(
        stages: stages,
        level: HikerLevel.confirmed,
        restAfterStageIndex: const {0},
      );
      expect(sans.stageVerdicts.every((v) => !v.isOverCapacity), isTrue,
          reason: 'les deux etapes sont vertes dans les deux cas');
      expect(sans.circuit!.rest, greaterThan(avec.circuit!.rest!));
      expect(sans.globalVerdict, FeasibilityVerdict.red);
      expect(avec.globalVerdict, FeasibilityVerdict.green);
      expect(avec.restDaysPlanned, 1);
    });

    test('ARB-004 : le circuit PEUT etre plus severe que toutes ses etapes',
        () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 10, elevationGainM: 200),
          stage(index: 1, distanceKm: 12, elevationGainM: 300),
        ],
        level: HikerLevel.confirmed,
      );
      expect(r.worstStageVerdict, FeasibilityVerdict.green);
      expect(r.globalVerdict, FeasibilityVerdict.red);
      // L ecran a alors l OBLIGATION d expliquer pourquoi (#2-s).
      expect(r.isCircuitHarsherThanStages, isTrue);
      expect(r.circuit!.dominant, CircuitConstraint.rest);
    });

    test('les chiffres de repos de la spec sont reproduits (#2-t)', () {
      // 6 jours de marche egaux + 1 repos -> monotonie 2,45 (au-dessus de 2,0)
      // 5 jours egaux + 2 repos -> 1,58 (en dessous). Sur des etapes egales,
      // un jour de repos par semaine NE SUFFIT PAS, il en faut deux.
      expect(
        FeasibilityFormula.monotonyOf(const [30, 30, 30, 30, 30, 30, 0]),
        closeTo(2.449, 1e-3),
      );
      expect(
        FeasibilityFormula.monotonyOf(const [30, 30, 30, 30, 30, 0, 0]),
        closeTo(1.581, 1e-3),
      );
      // Des etapes INEGALES font monter l ecart-type et REDUISENT le besoin de
      // repos : lisser les pics et poser des repos sont deux leviers opposes.
      expect(
        FeasibilityFormula.monotonyOf(const [30, 45, 35, 50, 40, 0, 0]),
        closeTo(1.50, 1e-2),
      );
    });

    test('au-dela de 7 jours, la PIRE fenetre glissante est retenue (#10-e)',
        () {
      // 10 jours : une semaine tres reguliere au milieu, des pics autour. La
      // fenetre retenue doit etre la plus monotone, et elle doit etre NOMMEE.
      final stages = <StageEffort>[
        for (var i = 0; i < 10; i++)
          stage(
            index: i,
            distanceKm: (i >= 2 && i <= 8) ? 20 : 5,
            elevationGainM: (i >= 2 && i <= 8) ? 500 : 100,
          ),
      ];
      final r = FeasibilityFormula.evaluate(
        stages: stages,
        level: HikerLevel.confirmed,
      );
      expect(r.circuit!.monotonyWindowStartDay, 3);
      expect(r.circuit!.monotonyWindowEndDay, 9);
      expect(r.circuit!.monotonyCoversWholeTrek, isFalse);
    });

    test('C4 est calcule quand l habitude est connue, absent sinon (#2-q)', () {
      final sans = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 20, elevationGainM: 500)],
        level: HikerLevel.intermediate,
      );
      expect(sans.circuit!.habitGap, isNull);

      final avec = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 20, elevationGainM: 420)], // 30 km-energie
        level: HikerLevel.intermediate,
        habitualDailyEnergyKm: 20,
      );
      expect(avec.circuit!.habitGap, closeTo(1.5, 1e-9));
      // AFFICHE, JAMAIS DECISIF : C4 n est pas dans le max du score.
      expect(avec.circuit!.dominant, isNot(CircuitConstraint.habitGap));
      expect(avec.circuit!.score, closeTo(avec.circuit!.worstStage, 1e-12));
    });
  });

  group('verdict global + facteur limitant + jours au-dessus', () {
    test('l etape la plus contraignante est bien reperee', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 10, elevationGainM: 300),
          stage(index: 1, distanceKm: 35, elevationGainM: 800),
          stage(index: 2, distanceKm: 12, elevationGainM: 400),
        ],
        level: HikerLevel.intermediate,
      );
      expect(r.hardestStageIndex, 1);
      expect(r.worstStageVerdict, FeasibilityVerdict.red);
      expect(r.hardestStage!.stage.name, 'Etape');
    });

    test('facteur limitant = D+ quand le denivele domine', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 10, elevationGainM: 2500)],
        level: HikerLevel.intermediate,
      );
      expect(r.limitingFactor, LimitingFactor.elevation);
    });

    test('facteur limitant = distance quand la distance domine', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 40, elevationGainM: 200)],
        level: HikerLevel.intermediate,
      );
      expect(r.limitingFactor, LimitingFactor.distance);
    });

    test('facteur limitant = enchainement (2+ jours consecutifs au-dessus)',
        () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 25, elevationGainM: 500), // orange
          stage(index: 1, distanceKm: 25, elevationGainM: 500), // orange
          stage(index: 2, distanceKm: 10, elevationGainM: 200), // vert
        ],
        level: HikerLevel.intermediate,
      );
      expect(r.daysOverCapacity, 2);
      expect(r.limitingFactor, LimitingFactor.chaining);
    });

    test('tout vert ET repos suffisant -> aucun facteur limitant', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 10, elevationGainM: 200),
          stage(index: 1, distanceKm: 12, elevationGainM: 300),
        ],
        level: HikerLevel.confirmed,
        restAfterStageIndex: const {0},
      );
      expect(r.globalVerdict, FeasibilityVerdict.green);
      expect(r.limitingFactor, LimitingFactor.none);
      expect(r.daysOverCapacity, 0);
    });
  });

  group('conseils de programme', () {
    test('tout vert -> conseil balancedOk uniquement', () {
      final r = FeasibilityFormula.evaluate(
        stages: [stage(distanceKm: 10, elevationGainM: 200)],
        level: HikerLevel.confirmed,
      );
      expect(r.advice.map((a) => a.key), ['balancedOk']);
    });

    test('C3 dominante -> on conseille des REPOS, pas une decoupe', () {
      // Lisser les pics et poser des repos sont deux leviers OPPOSES (#2-t) :
      // conseiller « decoupe l etape N » quand c est le repos qui manque
      // enverrait le randonneur exactement dans le mauvais sens.
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 10, elevationGainM: 200),
          stage(index: 1, distanceKm: 12, elevationGainM: 300),
        ],
        level: HikerLevel.confirmed,
      );
      expect(r.advice.first.key, 'restDominant');
      expect(r.advice.map((a) => a.key), isNot(contains('split')));
    });

    test('etape rouge -> conseil de decoupe (split) + jours optimal', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 35, elevationGainM: 800), // rouge
          stage(index: 1, distanceKm: 10, elevationGainM: 200), // vert
        ],
        level: HikerLevel.intermediate,
      );
      final keys = r.advice.map((a) => a.key).toList();
      expect(keys, contains('split'));
      final split = r.advice.firstWhere((a) => a.key == 'split');
      expect(split.params['stage'], 1);
      expect(r.suggestedDays, greaterThan(2));
    });

    test('bloc au-dessus suivi d autres etapes -> conseil de repos', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(index: 0, distanceKm: 25, elevationGainM: 500), // orange
          stage(index: 1, distanceKm: 25, elevationGainM: 500), // orange
          stage(index: 2, distanceKm: 10, elevationGainM: 200), // vert
        ],
        level: HikerLevel.intermediate,
      );
      final rest = r.advice.where((a) => a.key == 'rest');
      expect(rest, isNotEmpty);
      expect(rest.first.params['stages'], '2');
    });

    test('jours optimal >= nb d etapes et couvre la charge totale', () {
      final r = FeasibilityFormula.evaluate(
        stages: [
          stage(distanceKm: 35, elevationGainM: 800), // 54,0
          stage(distanceKm: 35, elevationGainM: 800), // 54,0
        ],
        level: HikerLevel.intermediate, // capacite 38,67
      );
      // 108,1 / 38,67 = 2,80 -> ceil 3 ; 2 etapes au-dessus -> 2+2 = 4 -> 4.
      expect(r.suggestedDays, 4);
    });
  });

  group('reco entrainement', () {
    test('verdict vert -> 0 semaine', () {
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.confirmed, FeasibilityVerdict.green),
        0,
      );
    });

    test('debutant + orange -> 12 semaines (borne haute)', () {
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.beginner, FeasibilityVerdict.orange),
        12,
      );
    });

    test('expert + orange -> 6 semaines (entretien, borne basse)', () {
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.expert, FeasibilityVerdict.orange),
        6,
      );
    });

    test('rouge ajoute une marge mais reste borne a 12', () {
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.confirmed, FeasibilityVerdict.red),
        8,
      );
      expect(
        FeasibilityFormula.trainingWeeksFor(
            HikerLevel.beginner, FeasibilityVerdict.red),
        12,
      );
    });
  });

  group('cas limites', () {
    test('aucune etape -> verdict vert, aucun facteur, 0 jour', () {
      final r = FeasibilityFormula.evaluate(
        stages: const [],
        level: HikerLevel.intermediate,
      );
      expect(r.globalVerdict, FeasibilityVerdict.green);
      expect(r.circuit, isNull);
      expect(r.limitingFactor, LimitingFactor.none);
      expect(r.hardestStageIndex, -1);
      expect(r.suggestedDays, 0);
    });
  });
}
