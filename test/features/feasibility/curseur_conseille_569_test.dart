// TACHE 569 (LOT R), R1-a — LE CURSEUR S'OUVRE SUR LA VALEUR CONSEILLEE, ET
// CETTE VALEUR N'EST JAMAIS ROUGE.
//
// DECISION DE CHRIS DU 26/09, VERBATIM : « OK mais le curseur est celui conseille
// et il n'est jamais en rouge quand il est conseille en orange max ».
//
// CE QUE CE FICHIER VERROUILLE, ET C'EST LE TROU EXACT DES 2 760 TESTS
// PRECEDENTS. Le conseil de duree et le verdict etaient testes SEPAREMENT,
// chacun juste de son cote, et rien ne verifiait leur ACCORD une fois cables
// ensemble. Ici on part du sentier de production et d'un randonneur, on lit ce
// que l'application CONSEILLE, on lit ce que le CURSEUR pose, et on exige :
//   1. le curseur s'ouvre sur la valeur conseillee ;
//   2. le verdict a cette valeur est vert ou orange, jamais rouge ;
//   3. un decoupage RETENU par le randonneur prime toujours sur le conseil ;
//   4. tant que le profil est incomplet, on ne conseille rien et le sentier
//      garde son decoupage de reference — un conseil est une sortie du moteur de
//      verdict, il n'existe pas la ou le verdict n'existe pas.
//
// MESURE AVANT CORRECTION, sur ce meme sentier et ce meme randonneur : le
// curseur s'ouvrait a 9 jours (7 de marche + 2 de repos conseilles) et le
// verdict a 9 jours etait ROUGE, tandis que le texte conseillait « vise 10 jours »
// — lu sur le curseur, 10 etait ROUGE aussi. Le premier total non rouge etait 11.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/providers/advised_program_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  /// Seed de PRODUCTION Mare a Mare Centre (7 etapes) — celui que Chris a lu.
  const seed = <(double, int)>[
    (15.0, 850),
    (12.0, 600),
    (10.0, 400),
    (11.0, 550),
    (14.0, 650),
    (12.0, 500),
    (10.0, 200),
  ];

  const config = TrailConfig(
    id: 'test-trail',
    name: 'Mare a Mare Centre (test)',
    displayName: 'Mare a Mare',
    tagline: 'test',
    totalStages: 7,
    totalDistanceKm: 84,
    totalElevationGain: 3750,
    region: 'Corse',
    country: 'France',
    primaryColorValue: 0xFF8B4513,
    secondaryColorValue: 0xFFD2691E,
    gpxAssetPath: 'assets/gpx/test_trail.gpx',
    directions: ['NS', 'SN'],
    availableDurations: [7],
    defaultDuration: 7,
  );

  final stages = [
    for (var i = 0; i < seed.length; i++)
      StageModel(
        trailId: 'test-trail',
        stageNumber: i + 1,
        name: 'Etape ${i + 1}',
        distanceKm: seed[i].$1,
        elevationGainM: seed[i].$2,
        elevationLossM: 300,
        startLat: 42.0 + i * 0.01,
        startLng: 9.0 + i * 0.01,
        endLat: 42.0 + (i + 1) * 0.01,
        endLng: 9.0 + (i + 1) * 0.01,
      ),
  ];

  /// Le randonneur, et POURQUOI SON NIVEAU EST DEVENU UN PARAMETRE (tache 634).
  ///
  /// Ce fichier n'exercait qu'un DEBUTANT : plafond 25,14 km-energie, alors que
  /// la premiere etape du sentier en pese 35,24 (15 km + 850 m / 42). Elle est
  /// donc rouge a elle seule, et le lot 558 la COUPAIT pour faire tomber le
  /// verdict — c'etait tout l'objet du curseur elargi.
  ///
  /// Christophe a retire le decoupage (DEM-260929-1327). Pour un debutant, ce
  /// sentier n'a donc plus de solution, et la reponse honnete est « aucune
  /// duree conseillee » — verrouillee plus bas comme un cas a part entiere. Le
  /// conseil, lui, s'exerce avec un randonneur INTERMEDIAIRE, pour qui le plan
  /// du sentier tient.
  ProviderContainer conteneur({
    bool profilComplet = true,
    HikerLevel niveau = HikerLevel.intermediate,
  }) {
    final container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(config),
        stagesProvider(
          'test-trail',
        ).overrideWith((ref) => Future.value(stages)),
        feasibilityCriteriaProvider.overrideWith(
          (ref) async => FeasibilityCriteria(
            profileComplete: profilComplet,
            hasPastHike: profilComplet,
            hasWalkTest: false,
          ),
        ),
        hikerLevelProvider.overrideWith((ref) async => niveau),
        objectiveProfileProvider.overrideWith(
          (ref) async => const ObjectiveProfile(
            maxElevationGainPerDayDone: 200,
            maxDistancePerDayDone: 9,
            maxConsecutiveDaysDone: 1,
            maxDailyEnergyKmDone: 0,
            habitualDailyEnergyKm: null,
            fitnessLevelRank: 1,
            hasWalkTest: false,
          ),
        ),
        trekConditionsProvider.overrideWith(
          (ref) async => TrekConditions.unknown,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Amorce le conteneur : les etapes, puis le conseil (tous deux asynchrones).
  Future<void> amorcer(ProviderContainer c) async {
    await c.read(stagesProvider('test-trail').future);
    // Un abonnement permanent : sans lui, un FutureProvider auto-dispose se
    // detruit entre deux lectures et le conseil ne se pose jamais.
    c.listen(selectedDurationProvider, (_, __) {});
    await c.read(advisedTotalDaysProvider.future);
  }

  group('R1-a — le curseur s ouvre sur la valeur conseillee', () {
    test('une duree est conseillee, et le curseur s y pose', () async {
      final c = conteneur();
      await amorcer(c);

      final conseil = await c.read(advisedTotalDaysProvider.future);
      expect(
        conseil,
        isNotNull,
        reason: 'aucune duree conseillee alors que le sentier a une solution',
      );

      // TACHE 634 (DEM-260929-1132) — LE CONSEIL EST LE PLAN DU SENTIER. Ce
      // test exigeait l'inverse : que le conseil S'ECARTE du decoupage du topo,
      // parce que le lot 558 devait couper des etapes pour sortir du rouge. Le
      // moteur ne propose plus de plan a lui : 7 etapes, 7 journees de marche.
      //
      // TACHE 639 (DEM-260930-1238) — ET LE REPOS N'EST PLUS COMPTE DEDANS. Ce
      // test attendait `stages.length + programme.restDays` : le curseur
      // s'ouvrait donc sur NEUF jours pour sept etapes. Verbatim de Christophe le
      // 30/09 a 12:37 : « Si c est 7 jours c est 7 jours ». Le repos reste
      // CONSEILLE et s'affiche comme tel, il ne gonfle plus la duree.
      final programme = await c.read(advisedSuggestedProgramProvider.future);
      expect(programme!.walkingDays, stages.length);
      expect(
        conseil,
        stages.length,
        reason:
            'sept etapes font sept jours : le repos est un conseil, pas une '
            'duree',
      );
      expect(
        c.read(selectedDurationProvider),
        conseil,
        reason: 'le curseur ne s ouvre pas sur la valeur conseillee',
      );
    });

    test('LE VERDICT A LA VALEUR OUVERTE N EST PAS ROUGE', () async {
      final c = conteneur();
      await amorcer(c);

      final ouverture = c.read(selectedDurationProvider);
      final jours = c.read(plannedDaysProvider('test-trail'));
      expect(
        jours.length,
        ouverture,
        reason: 'le programme ne fait pas la longueur du curseur',
      );

      final a = await c.read(feasibilityAssessmentProvider.future);
      expect(a, isNotNull);
      expect(
        a!.globalVerdict,
        isNot(FeasibilityVerdict.red),
        reason:
            'le curseur s ouvre sur un verdict que l ecran declare '
            'mauvais dans la meme page',
      );
      expect(
        a.isDurationSearched,
        isTrue,
        reason:
            'le chemin de production doit TOUJOURS passer par la '
            'recherche — sinon l estimation de lissage revient par la fenetre',
      );
      expect(a.isDurationAdvised, isTrue);
      // TACHE 639 (DEM-260930-1238) : c'est la duree du PLAN qui doit coincider
      // avec le curseur, pas le total repos compris. La regle verrouillee ici ne
      // change pas de nature — « le conseil affiche et la position du curseur
      // doivent etre le meme nombre » — elle porte sur le bon nombre.
      expect(
        a.suggestedPlanDays,
        ouverture,
        reason:
            'le conseil affiche et la position du curseur doivent etre '
            'le meme nombre',
      );
      expect(a.suggestedPlanDays, a.suggestedDays);
      expect(a.suggestedDays + a.suggestedRestDays, a.suggestedTotalDays);
    });

    test(
      'le conseil ne dit plus de couper une etape, et l ecran n affiche plus '
      'le decoupage comme solution',
      () async {
        final c = conteneur();
        await amorcer(c);
        final a = await c.read(feasibilityAssessmentProvider.future);
        final cles = a!.advice.map((x) => x.key).toList();
        expect(cles, isNot(contains('split')));
        expect(cles, isNot(contains('splitImpossible')));
      },
    );

    test(
      'un decoupage RETENU par le randonneur prime sur le conseil',
      () async {
        final c = conteneur();
        await amorcer(c);
        final conseil = c.read(selectedDurationProvider);

        // Le randonneur decide, l application propose : choisir la borne basse
        // (il COMPRIME son sentier, ce qui est SON droit) et le conseil ne
        // revient pas par-dessus.
        final bornes = c.read(durationBoundsProvider('test-trail'));
        c.read(selectedDurationProvider.notifier).set(bornes.min);
        expect(c.read(selectedDurationProvider), bornes.min);
        expect(
          bornes.min,
          isNot(conseil),
          reason:
              'le test ne prouve rien si la borne basse est deja le conseil',
        );
      },
    );

    test('DEBUTANT sur ce sentier -> AUCUN conseil, au lieu d un plan comprime '
        'qualifie d exigeant', () async {
      // LE CAS QUE LE LOT 558 RATTRAPAIT EN COUPANT UNE ETAPE. Pour un
      // debutant, la premiere etape (35,24 km-energie) depasse le plafond
      // (25,14) et aucune duree ne peut plus rien y faire : le repos ne change
      // pas une journee de marche, et regrouper aggrave. Le moteur se TAIT.
      final c = conteneur(niveau: HikerLevel.beginner);
      await amorcer(c);

      expect(await c.read(advisedTotalDaysProvider.future), isNull);
      // Et l'ecran le dit franchement, en NOMMANT l etape qui bloque.
      final a = await c.read(feasibilityAssessmentProvider.future);
      expect(a!.isDurationAdvised, isFalse);
      final cles = a.advice.map((x) => x.key).toList();
      expect(cles, contains('noViableDuration'));
      expect(cles, isNot(contains('split')));
      // Le curseur retombe sur le decoupage de reference du sentier.
      expect(
        c.read(selectedDurationProvider),
        c.read(defaultDurationWithRestProvider('test-trail')),
      );
    });

    test('profil incomplet -> AUCUN conseil, et le sentier garde son decoupage '
        'de reference', () async {
      final c = conteneur(profilComplet: false);
      await amorcer(c);
      expect(
        await c.read(advisedTotalDaysProvider.future),
        isNull,
        reason:
            'un conseil est une sortie du moteur de verdict : il ne '
            'existe pas la ou le verdict n existe pas',
      );
      expect(
        await c.read(advisedProgramProvider.future),
        isNull,
        reason:
            'aucune recherche : l ecran ne doit pas annoncer que rien ne '
            'marche',
      );
      expect(
        c.read(selectedDurationProvider),
        c.read(defaultDurationWithRestProvider('test-trail')),
      );
    });
  });
}
