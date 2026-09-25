import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/planning/domain/planning_calculator.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// TACHE 558 — LE CURSEUR DE JOURS DOIT POUVOIR ALLEGER LE VERDICT.
///
/// CE QUI ETAIT CASSE, mesure sur l'emulateur par la campagne personas et par
/// Chris lui-meme, mot pour mot : « ca me propose 9jours, je peux pas augmenter
/// et ca met tout en rouge !!! », puis « si je passe a 20 jours en mettant des
/// jours de repos ca reste rouge ». Ce n'etait pas un bug de calcul, c'etait une
/// IMPASSE :
///
///  1. depuis GO-61, le verdict du circuit vaut C1 = LA PIRE JOURNEE et elle
///     seule. Ajouter du repos laisse les memes journees de marche, donc la
///     meme pire journee, donc le meme verdict — mathematiquement ;
///  2. le seul remede etait donc de COUPER la journee la plus dure. Mais
///     « Separer » ne savait que degrouper des etapes deja groupees, et la pire
///     journee du sentier de reference (Ghisonaccia-Catastaghju, 35,2 km-energie)
///     ne porte QU'UNE etape : le bouton etait mort exactement la ou il fallait ;
///  3. et la borne haute du curseur s'arretait au nombre d'etapes + la marge de
///     repos, c'est-a-dire pile la ou il aurait commence a servir.
///
/// CE QUE CES TESTS VERROUILLENT : qu'un humain qui pousse le curseur voie
/// quelque chose changer, et que l'application ne conseille plus jamais une
/// action qu'elle n'offre pas.
void main() {
  StageModel stage(int num, double km, int gain, {int? minutes}) => StageModel(
        trailId: 'test-trail',
        stageNumber: num,
        name: 'Etape $num',
        distanceKm: km,
        elevationGainM: gain,
        elevationLossM: (gain * 0.8).round(),
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.2,
        endLng: 9.2,
        estimatedDurationMinutes: minutes,
        departureName: 'Depart $num',
        arrivalName: 'Arrivee $num',
      );

  double energyOf(StageModel s) => FeasibilityScale.v2.energyOf(
        distanceKm: s.distanceKm,
        elevationGainM: s.elevationGainM,
      );

  // ---------------------------------------------------------------------------
  group('splitStage — deux portions de MEME ENERGIE', () {
    test('les deux portions somment EXACTEMENT l etape d origine', () {
      final entiere = stage(3, 21.3, 1247, minutes: 505);
      final parts = PlanningCalculator.splitStage(entiere);

      expect(parts.length, 2);
      // Aucun kilometre, aucun metre, aucune minute perdue dans un arrondi :
      // c'est la meme etape, decrite en deux moments.
      expect(parts[0].distanceKm + parts[1].distanceKm,
          closeTo(entiere.distanceKm, 1e-9));
      expect(parts[0].elevationGainM + parts[1].elevationGainM,
          entiere.elevationGainM);
      expect(parts[0].elevationLossM + parts[1].elevationLossM,
          entiere.elevationLossM);
      expect(
          parts[0].estimatedDurationMinutes! +
              parts[1].estimatedDurationMinutes!,
          entiere.estimatedDurationMinutes);
    });

    test('chaque portion pese la MOITIE de l energie, a l arrondi pres', () {
      // La coupe est a MI-ENERGIE et non a mi-distance : l unite du moteur est
      // l energie (1 km de plat = 42 m de D+). Les deux portions portant la
      // moitie de la distance ET la moitie du D+, chacune vaut, par linearite,
      // la moitie de l energie — c'est ce qui fait chuter la pire journee.
      final entiere = stage(1, 35.0, 1200);
      final parts = PlanningCalculator.splitStage(entiere);
      final moitie = energyOf(entiere) / 2;

      expect(energyOf(parts[0]), closeTo(moitie, 0.02));
      expect(energyOf(parts[1]), closeTo(moitie, 0.02));
    });

    test('les portions gardent le NUMERO d etape et s enchainent', () {
      final entiere = stage(4, 12.0, 600);
      final parts = PlanningCalculator.splitStage(entiere);

      // Meme numero : tout ce qui identifie une etape ailleurs (journal, carte,
      // verrou « deja marchee ») continue de la retrouver.
      expect(parts.every((p) => p.stageNumber == 4), isTrue);
      // Le nom porte un SIGNE, pas un mot : il se lit dans les cinq langues.
      expect(parts[0].name, 'Etape 4 (1/2)');
      expect(parts[1].name, 'Etape 4 (2/2)');
      // La 1re part demarre au depart REEL, la 2e s acheve a l arrivee REELLE,
      // et le point de coupe est commun aux deux (aucun trou dans le trace).
      expect(parts[0].startLat, entiere.startLat);
      expect(parts[1].endLat, entiere.endLat);
      expect(parts[0].endLat, parts[1].startLat);
      expect(parts[0].endLng, parts[1].startLng);
      // AUCUN NOM DE LIEU INVENTE sur le point de coupe : il n'en a pas.
      expect(parts[0].departureName, 'Depart 4');
      expect(parts[0].arrivalName, isNull);
      expect(parts[1].departureName, isNull);
      expect(parts[1].arrivalName, 'Arrivee 4');
    });
  });

  // ---------------------------------------------------------------------------
  group('distribute — le jour en trop COUPE au lieu de reposer', () {
    final trois = [stage(1, 10.0, 300), stage(2, 12.0, 400), stage(3, 8.0, 200)];

    test('SANS plafond de repos : comportement d origine, tout part en repos',
        () {
      // Aucun appelant historique ne connait le budget de repos : leur
      // comportement est INCHANGE, et c'est ce qui rend ce lot sans regression.
      final plan = PlanningCalculator.distribute(trois, 6);
      expect(plan.length, 6);
      expect(plan.where((d) => d.isRestDay).length, 3);
      expect(plan.where((d) => !d.isRestDay).length, 3);
    });

    test('AVEC plafond : le repos d abord, le decoupage ensuite', () {
      // Budget de repos = 1. A 4 jours : 3 marches + 1 repos (le budget).
      final quatre = PlanningCalculator.distribute(trois, 4, maxRestDays: 1);
      expect(quatre.where((d) => d.isRestDay).length, 1);
      expect(quatre.where((d) => !d.isRestDay).length, 3);

      // A 5 jours, le budget est epuise : le jour de plus COUPE une journee.
      final cinq = PlanningCalculator.distribute(trois, 5, maxRestDays: 1);
      expect(cinq.where((d) => d.isRestDay).length, 1);
      expect(cinq.where((d) => !d.isRestDay).length, 4,
          reason: 'un jour de marche de plus, pas un repos de plus');
      expect(cinq.length, 5);
    });

    test('la PIRE journee est coupee la PREMIERE, a l energie du verdict', () {
      // Deux etapes que les deux echelles classent A L ENVERS :
      //  * A : 20 km, 0 m D+  -> ancien score 20,0 · energie du verdict 20,0
      //  * B : 10 km, 900 m D+ -> ancien score 19,0 · energie du verdict 31,4
      // L ancien score de repartition aurait coupe A ; le verdict, lui, est fixe
      // par B. Couper A n aurait donc RIEN change au rouge.
      final a = stage(1, 20.0, 0);
      final b = stage(2, 10.0, 900);
      expect(PlanningCalculator.stageScore(a),
          greaterThan(PlanningCalculator.stageScore(b)));
      expect(PlanningCalculator.stageEnergyKm(b),
          greaterThan(PlanningCalculator.stageEnergyKm(a)));

      final plan = PlanningCalculator.distribute([a, b], 3, maxRestDays: 0);
      final marche = plan.where((d) => !d.isRestDay).toList();
      expect(marche.length, 3);
      // B (etape 2) est celle qui a ete coupee : elle occupe deux journees.
      expect(marche.where((d) => d.stages.single.stageNumber == 2).length, 2);
      expect(marche.where((d) => d.stages.single.stageNumber == 1).length, 1);
    });

    test('une etape ne se coupe qu UNE fois : le surplus redevient du repos',
        () {
      // 3 etapes -> 6 jours de marche au maximum. A 10 jours avec 0 de budget
      // repos, les 4 jours qui depassent ne peuvent PAS devenir des journees de
      // marche : ils redeviennent du repos, faute de quoi le curseur aurait une
      // plage morte.
      final plan = PlanningCalculator.distribute(trois, 10, maxRestDays: 0);
      expect(plan.length, 10);
      expect(plan.where((d) => !d.isRestDay).length, 6);
      expect(plan.where((d) => d.isRestDay).length, 4);
    });

    test('l ordre de marche est PRESERVE par le decoupage', () {
      final plan = PlanningCalculator.distribute(trois, 5, maxRestDays: 0);
      final numeros = [
        for (final d in plan)
          if (!d.isRestDay) d.stages.single.stageNumber,
      ];
      // Jamais de permutation : les numeros restent croissants au sens large.
      for (var i = 1; i < numeros.length; i++) {
        expect(numeros[i], greaterThanOrEqualTo(numeros[i - 1]));
      }
    });
  });

  // ---------------------------------------------------------------------------
  group('LE CURSEUR FAIT BAISSER LA PIRE JOURNEE (bout en bout)', () {
    // 5 etapes dont une NETTEMENT plus dure que les autres : c'est elle qui
    // fixe le verdict, et c'est elle qu'il faut voir se couper.
    final stages = [
      stage(1, 10.0, 300),
      stage(2, 12.0, 400),
      stage(3, 30.0, 1400), // la pire, et de loin
      stage(4, 9.0, 250),
      stage(5, 11.0, 350),
    ];

    ProviderContainer container() => ProviderContainer(overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail')
              .overrideWith((ref) => Future.value(stages)),
        ]);

    double pireJournee(List<dynamic> jours) {
      var pire = 0.0;
      for (final jour in jours) {
        if (jour.isRestDay as bool) continue;
        final energie = FeasibilityScale.v2.energyOf(
          distanceKm: jour.totalDistanceKm as double,
          elevationGainM: jour.totalElevationGainM as int,
        );
        if (energie > pire) pire = energie;
      }
      return pire;
    }

    test('UN JOUR DE PLUS au-dela du naturel, et la pire journee est coupee',
        () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(stagesProvider('test-trail').future);
      final bounds = c.read(durationBoundsProvider('test-trail'));

      // Duree NATURELLE : une etape par jour + le repos. C'est le programme par
      // defaut, et la pire journee y est l etape 3 entiere.
      c.read(selectedDurationProvider.notifier).set(bounds.naturalMax);
      final avant = c.read(plannedDaysProvider('test-trail'));
      final pireAvant = pireJournee(avant);
      expect(pireAvant, closeTo(energyOf(stages[2]), 0.01));

      // UN SEUL cran de plus sur le curseur.
      c.read(selectedDurationProvider.notifier).set(bounds.naturalMax + 1);
      final apres = c.read(plannedDaysProvider('test-trail'));

      // La pire journee a FONDU DE MOITIE : c'est tout l objet du lot.
      expect(pireJournee(apres), lessThan(pireAvant));
      expect(pireJournee(apres), closeTo(pireAvant / 2, 0.6));
      // Et c'est bien l etape 3 qui occupe deux journees.
      final jours3 = apres
          .where((d) =>
              !d.isRestDay && d.stages.any((s) => s.stageNumber == 3))
          .length;
      expect(jours3, 2);
    });

    test('POUSSE A FOND, chaque etape occupe deux journees et le curseur le dit',
        () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(stagesProvider('test-trail').future);
      final bounds = c.read(durationBoundsProvider('test-trail'));

      c.read(selectedDurationProvider.notifier).set(bounds.max);
      final stats = c.read(planningStatsProvider('test-trail'));

      // 5 etapes -> 10 jours de marche au maximum.
      expect(stats.trekDays, 10);
      // Le sentier compte toujours 5 ETAPES : le decoupage a change, pas lui.
      expect(stats.stageCount, 5);
      // Et l ecran sait qu il n y a plus rien a couper : c'est ce qu il DIT,
      // au lieu de laisser pousser un curseur qui ne sert plus a rien.
      expect(stats.canSplitFurther, isFalse);
    });

    test('a la duree naturelle, il reste du decoupage disponible', () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(stagesProvider('test-trail').future);
      final bounds = c.read(durationBoundsProvider('test-trail'));

      c.read(selectedDurationProvider.notifier).set(bounds.naturalMax);
      expect(c.read(planningStatsProvider('test-trail')).canSplitFurther,
          isTrue);
    });

    test('LE PROGRAMME PAR DEFAUT NE COUPE RIEN (GO-61 intact)', () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(stagesProvider('test-trail').future);

      // Aucun choix du randonneur : la duree par defaut s applique, et elle
      // reste sur la duree NATURELLE. Aucune etape n est coupee d office —
      // couper est une decision, jamais un defaut impose.
      final jours = c.read(plannedDaysProvider('test-trail'));
      final marche = jours.where((d) => !d.isRestDay).toList();
      expect(marche.length, stages.length);
      expect(marche.every((d) => d.stages.length == 1), isTrue);
      for (final j in marche) {
        expect(j.stages.single.name, isNot(contains('/2)')),
            reason: 'aucune portion dans le programme par defaut');
      }
    });

    test('LES REPOS NE S EMPILENT PLUS quand on bouge le curseur', () async {
      // Defaut corrige au passage, et il pesait lourd sur ce que Chris a vu :
      // le cache des repos manuels etait REINJECTE par-dessus ceux de la
      // repartition, donc chaque mouvement du curseur ajoutait une couche de
      // repos. De quoi arriver a vingt jours en croyant en avoir choisi dix.
      final c = container();
      addTearDown(c.dispose);
      await c.read(stagesProvider('test-trail').future);
      final bounds = c.read(durationBoundsProvider('test-trail'));

      c.read(selectedDurationProvider.notifier).set(bounds.naturalMax);
      final notifier = c.read(plannedDaysProvider('test-trail').notifier);
      // Une edition manuelle quelconque : elle alimente le cache des repos.
      notifier.addRestDay(0);
      final apresEdition = c.read(plannedDaysProvider('test-trail')).length;

      // Trois mouvements de curseur qui reviennent au point de depart.
      c.read(selectedDurationProvider.notifier).set(bounds.naturalMax + 1);
      c.read(selectedDurationProvider.notifier).set(bounds.naturalMax + 2);
      c.read(selectedDurationProvider.notifier).set(bounds.naturalMax);

      // Le programme n a pas gonfle : meme nombre de jours qu apres l edition.
      expect(c.read(plannedDaysProvider('test-trail')).length, apresEdition);
    });
  });

  // ---------------------------------------------------------------------------
  group('AUCUN CONSEIL QUE L APPLICATION N OFFRE PAS', () {
    StageEffort effort(int i, double km, int gain) =>
        StageEffort(index: i, name: 'J$i', distanceKm: km, elevationGainM: gain);

    final dures = [effort(0, 35.2, 1500), effort(1, 12.0, 400)];

    test('quand le decoupage est possible : « decoupe cette journee »', () {
      final a = FeasibilityFormula.evaluate(
        stages: dures,
        level: HikerLevel.beginner,
        // Deux journees par etape : il reste de la marge pour couper.
        maxWalkingDays: 4,
      );
      expect(a.advice.map((x) => x.key), contains('split'));
      expect(a.advice.map((x) => x.key), isNot(contains('splitImpossible')));
    });

    test('quand il n y a plus rien a couper : on DIT la verite', () {
      // maxWalkingDays == nombre de journees : le programme est au bout de ce
      // qu il sait faire. Conseiller « decoupe » serait envoyer le randonneur
      // chercher un bouton qui ne peut rien pour lui — c'est exactement ce qui
      // a fait exploser Chris.
      final a = FeasibilityFormula.evaluate(
        stages: dures,
        level: HikerLevel.beginner,
        maxWalkingDays: dures.length,
      );
      expect(a.advice.map((x) => x.key), contains('splitImpossible'));
      expect(a.advice.map((x) => x.key), isNot(contains('split')));
      // Et on ne conseille pas non plus un nombre de jours inatteignable.
      expect(a.suggestedDays, lessThanOrEqualTo(dures.length));
    });

    test('le conseil de duree peut desormais depasser le nombre d etapes', () {
      // Avant la tache 558, le plafond du conseil valait le nombre d etapes :
      // le moteur voulait etaler, et on l en empechait. Le decoupage lui rend
      // cette latitude, sans jamais depasser ce que le curseur sait atteindre.
      final a = FeasibilityFormula.evaluate(
        stages: dures,
        level: HikerLevel.beginner,
        maxWalkingDays: PlanningCalculator.maxWalkingDaysFor(dures.length),
      );
      expect(a.suggestedDays, greaterThan(dures.length));
      expect(a.suggestedDays,
          lessThanOrEqualTo(PlanningCalculator.maxWalkingDaysFor(dures.length)));
    });
  });
}
