// TACHE 569 (LOT R) — R2, R3 ET R5 : LES NOMBRES PORTENT LEUR UNITE, LE VERDICT
// MONTRE SON CALCUL, ET LE TEXTE SUR LA DATE DIT CE QU'IL FAIT.
//
// R2 — TOUT NOMBRE DE JOURS PORTE SA NATURE. Trois retours de Chris etaient le
// MEME defaut : « vise 9 au lieu de 7 » (le 7 est le decoupage de REFERENCE du
// sentier, pas son choix), « vise 9 jours et ca propose 11 » (9 jours de MARCHE
// plus 2 de repos = 11 au TOTAL : le calcul etait juste, les unites n'etaient
// pas nommees), « faisabilite dit 11 et itineraire propose 9 » (meme cause entre
// deux ecrans). Aucun nombre de jours ne s'affiche plus sans dire s'il compte la
// marche, le repos ou le total.
//
// R3 — MONTRER LE CALCUL LA OU LE VERDICT TOMBE. Chris : « Le verdict c'est du
// blabla d'IA, tu mexplique comment c'est calcule au moment ou ca le fait? » et
// « score 1,30 sans echelle ca ne veut rien dire ». Il n'y a AUCUNE IA dans
// l'application — zero dependance — et c'est bien le probleme : une formule
// deterministe et sourcee qui ne se montre pas se lit comme une boite noire.
//
// R5 — LE TEXTE SUR LA DATE SE LISAIT COMME UN AVEU. « Aucune date de depart
// n'est posee : la saison ne change rien ici, faute de donnee » est
// litteralement exact, mais pose au-dessus d'un verdict il se lit « je ne peux
// pas juger ». On dit ce qui EST fait, pas ce qui manque.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  // -------------------------------------------------------------------------
  // R2 — LES UNITES
  // -------------------------------------------------------------------------
  group('R2 — aucun nombre de jours ne s affiche sans son unite', () {
    test('le conseil de duree porte SES TROIS NOMBRES, dans les 5 langues', () {
      for (final locale in AppLocale.values) {
        final a = locale.buildSync().feasibility.formula.advice;
        for (final texte in [
          a.optimalDays(days: 11, walk: 9, rest: 2, current: 7),
          a.optimalDaysNoChoice(days: 11, walk: 9, rest: 2, current: 7),
        ]) {
          expect(texte, contains('11'),
              reason: '${locale.languageCode} : le TOTAL manque — c est '
                  'l unite du curseur');
          expect(texte, contains('9'),
              reason: '${locale.languageCode} : les jours de MARCHE manquent');
          expect(texte, contains('2'),
              reason: '${locale.languageCode} : les jours de REPOS manquent');
        }
      }
    });

    test(
        'sans choix du randonneur, le conseil ne dit JAMAIS « au lieu de » : le '
        'nombre de depart est celui du topo, pas le sien', () {
      // Liste NOMMEE par langue : une forme est interdite parce qu elle est
      // ecrite ici, jamais parce qu un algorithme la trouve suspecte.
      const interdits = <AppLocale, List<String>>{
        AppLocale.fr: ['au lieu de', 'au lieu des'],
        AppLocale.en: ['instead of'],
        AppLocale.de: ['statt'],
        AppLocale.es: ['en vez de', 'en lugar de'],
        AppLocale.it: ['invece di', 'invece dei'],
      };
      for (final entree in interdits.entries) {
        final a = entree.key.buildSync().feasibility.formula.advice;
        final sansChoix =
            a.optimalDaysNoChoice(days: 11, walk: 9, rest: 2, current: 7)
                .toLowerCase();
        for (final mot in entree.value) {
          expect(sansChoix, isNot(contains(mot)),
              reason: '${entree.key.languageCode} : « $mot » suppose un choix '
                  'que le randonneur n a pas fait');
        }
        // Et la variante AVEC choix, elle, le dit : les deux formulations
        // doivent reellement differer, sinon le drapeau ne sert a rien.
        final avecChoix =
            a.optimalDays(days: 11, walk: 9, rest: 2, current: 7);
        expect(avecChoix, isNot(sansChoix));
      }
    });

    test(
        'le moteur choisit la formulation d apres fromProgram, pas au hasard',
        () {
      List<String> cles({required bool fromProgram}) =>
          FeasibilityFormula.evaluate(
            stages: const [
              StageEffort(
                  index: 0, name: 'A', distanceKm: 24, elevationGainM: 1600),
              StageEffort(
                  index: 1, name: 'B', distanceKm: 22, elevationGainM: 800),
              StageEffort(
                  index: 2, name: 'C', distanceKm: 10, elevationGainM: 200),
            ],
            level: HikerLevel.intermediate,
            fromProgram: fromProgram,
            durationAdvice:
                const ProgramDurationAdvice(walkingDays: 5, restDays: 1),
          ).advice.map((a) => a.key).toList();

      expect(cles(fromProgram: true), contains('optimalDays'));
      expect(cles(fromProgram: true), isNot(contains('optimalDaysNoChoice')));
      expect(cles(fromProgram: false), contains('optimalDaysNoChoice'));
      expect(cles(fromProgram: false), isNot(contains('optimalDays')));
    });

    test('les conseils qui NUMEROTENT des journees disent de quel decoupage',
        () {
      // Des charges tres inegales : la monotonie ne demande pas de repos, c est
      // donc la cle `rest` (blocs durs) qui parle — celle qui numerote.
      List<ProgramAdvice> conseils({required bool fromProgram}) =>
          FeasibilityFormula.evaluate(
            stages: const [
              StageEffort(
                  index: 0, name: 'A', distanceKm: 30, elevationGainM: 1500),
              StageEffort(
                  index: 1, name: 'B', distanceKm: 4, elevationGainM: 50),
              StageEffort(
                  index: 2, name: 'C', distanceKm: 4, elevationGainM: 50),
            ],
            level: HikerLevel.intermediate,
            fromProgram: fromProgram,
          ).advice;

      final propre = conseils(fromProgram: true).map((a) => a.key).toList();
      final reference = conseils(fromProgram: false).map((a) => a.key).toList();
      expect(propre.contains('rest') || propre.contains('restAdvised'), isTrue,
          reason: 'aucun conseil ne numerote de journee : le test ne prouve '
              'rien');
      if (propre.contains('rest')) {
        expect(reference, contains('restReference'));
        expect(reference, isNot(contains('rest')));
      }
      if (propre.contains('restAdvised')) {
        expect(reference, contains('restAdvisedReference'));
        expect(reference, isNot(contains('restAdvised')));
      }
    });

    test('la ligne « decoupage retenu » ne dit plus « jours de marche »', () {
      // C EST UN TOTAL, ET C EN ETAIT DEJA UN. `retainedDurationProvider` porte
      // la valeur du CURSEUR, marche et repos compris : le libelle annoncait
      // donc une unite qui n etait pas la sienne.
      const marche = <AppLocale, List<String>>{
        AppLocale.fr: ['jours de marche'],
        AppLocale.en: ['walking days'],
        AppLocale.de: ['wandertage'],
        AppLocale.es: ['días de marcha'],
        AppLocale.it: ['giorni di cammino'],
      };
      const total = <AppLocale, String>{
        AppLocale.fr: 'au total',
        AppLocale.en: 'in total',
        AppLocale.de: 'insgesamt',
        AppLocale.es: 'en total',
        AppLocale.it: 'in totale',
      };
      for (final locale in AppLocale.values) {
        final f = locale.buildSync().feasibility.formula;
        for (final texte in [
          f.retainedPlan(days: 11),
          f.retainedPlanNone(days: 9),
          f.generateProgram(days: 11),
          f.generateProgramDone(days: 11),
        ]) {
          final bas = texte.toLowerCase();
          for (final mot in marche[locale]!) {
            expect(bas, isNot(contains(mot)),
                reason: '${locale.languageCode} : « $texte » annonce des jours '
                    'de marche alors que la valeur est un total');
          }
          expect(bas, contains(total[locale]!),
              reason: '${locale.languageCode} : « $texte » ne dit pas que le '
                  'nombre est un total');
        }
      }
    });

    test('le curseur du Programme annonce des TOTAUX', () {
      const total = <AppLocale, String>{
        AppLocale.fr: 'au total',
        AppLocale.en: 'in total',
        AppLocale.de: 'insgesamt',
        AppLocale.es: 'en total',
        AppLocale.it: 'in totale',
      };
      for (final locale in AppLocale.values) {
        final d = locale.buildSync().programme.duration;
        expect(d.daysTotal.toLowerCase(), contains(total[locale]!),
            reason: '${locale.languageCode} : le grand compteur du curseur ne '
                'dit pas qu il compte un total');
        expect(d.daysTotal, contains('{count}'),
            reason: '${locale.languageCode} : le placeholder {count} a disparu');
        expect(d.daysWithRest.toLowerCase(), contains(total[locale]!));
        expect(d.daysWithRest, contains('{total}'));
        expect(d.daysWithRest, contains('{rest}'));
      }
    });

    test('l Itineraire dit que son compteur de jours est un TOTAL, et le detaille',
        () {
      const total = <AppLocale, String>{
        AppLocale.fr: 'total',
        AppLocale.en: 'total',
        AppLocale.de: 'insgesamt',
        AppLocale.es: 'total',
        AppLocale.it: 'totale',
      };
      for (final locale in AppLocale.values) {
        final i = locale.buildSync().itinerary;
        expect(i.daysTotal.toLowerCase(), contains(total[locale]!),
            reason: '${locale.languageCode} : « faisabilite dit 11 et '
                'itineraire propose 9 » — le compteur doit dire ce qu il compte');
        final detail = i.daysBreakdown(walk: 9, rest: 2);
        expect(detail, contains('9'));
        expect(detail, contains('2'));
      }
    });
  });

  // -------------------------------------------------------------------------
  // R3 — LE CALCUL MONTRE
  // -------------------------------------------------------------------------
  group('R3 — le verdict montre son calcul, et le score son echelle', () {
    test('les quatre lignes du calcul existent dans les 5 langues, avec les '
        'chiffres reels', () {
      for (final locale in AppLocale.values) {
        final f = locale.buildSync().feasibility.formula;
        expect(f.verdictHowTitle, isNotEmpty);
        final geo = f.verdictHowStage(
            stage: 'Sermano -> Corte', distance: '15', elevation: 850);
        expect(geo, contains('15'));
        expect(geo, contains('850'));
        expect(geo, contains('Sermano -> Corte'));
        final energie =
            f.verdictHowEnergy(distance: '15', elevation: 850, energy: '35,2');
        expect(energie, contains('42'),
            reason: '${locale.languageCode} : l unite d energie n est pas dite '
                'la ou elle sert');
        expect(energie, contains('35,2'));
        final plafond =
            f.verdictHowCeiling(capacity: '25,1', level: 'debutant');
        expect(plafond, contains('25,1'));
        final rapport = f.verdictHowRatio(
            energy: '35,2',
            capacity: '25,1',
            score: '1,40',
            green: '0,85',
            orange: '1,10');
        expect(rapport, contains('1,40'));
        expect(rapport, contains('0,85'),
            reason: '${locale.languageCode} : « score 1,30 sans echelle ca ne '
                'veut rien dire » — le seuil vert manque');
        expect(rapport, contains('1,10'),
            reason: '${locale.languageCode} : le seuil orange manque');
      }
    });

    test('les trois travaux qui nourrissent le calcul sont NOMMES', () {
      for (final locale in AppLocale.values) {
        final texte =
            locale.buildSync().feasibility.formula.verdictHowNoBlackBox;
        for (final travail in ['Minetti', 'MOVE', 'Linsell']) {
          expect(texte, contains(travail),
              reason: '${locale.languageCode} : « $travail » n est pas nomme, '
                  'donc le verdict reste une affirmation');
        }
      }
    });

    test('le score du circuit ne s affiche JAMAIS nu : il porte son echelle',
        () {
      for (final locale in AppLocale.values) {
        final texte = locale
            .buildSync()
            .feasibility
            .formula
            .circuitScore(value: '1,30', green: '0,85', orange: '1,10');
        expect(texte, contains('1,30'));
        expect(texte, contains('0,85'),
            reason: '${locale.languageCode} : le score s affiche sans son '
                'echelle');
        expect(texte, contains('1,10'));
      }
    });

    test('AUCUN texte de la faisabilite ne parle d IA, ni pour s en defendre',
        () {
      // Il n y a aucune IA dans cette application (zero dependance). On ne se
      // defend pas d une accusation : on montre le calcul. Le mot ne doit donc
      // apparaitre NI comme promesse NI comme denegation.
      const interdits = ['intelligence artificielle', ' ia ', 'artificial '
          'intelligence', ' ai ', ' ki ', 'künstliche intelligenz',
          'inteligencia artificial', 'intelligenza artificiale'];
      for (final locale in AppLocale.values) {
        final f = locale.buildSync().feasibility.formula;
        final textes = <String>[
          f.title,
          f.intro,
          f.verdictHowTitle,
          f.verdictHowNoBlackBox,
          f.circuitIsWorstStage,
          f.energyUnitNotice,
        ];
        for (final texte in textes) {
          final bas = ' ${texte.toLowerCase()} ';
          for (final mot in interdits) {
            expect(bas, isNot(contains(mot)),
                reason: '${locale.languageCode} : « $texte » parle d IA alors '
                    'qu il n y en a aucune dans le moteur');
          }
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // R5 — LA DATE DE DEPART
  // -------------------------------------------------------------------------
  group('R5 — le texte sur la saison dit ce qui EST fait', () {
    test('il ne se lit plus comme un aveu d impuissance', () {
      // Formes NOMMEES par langue. Elles disaient toutes la meme chose : ce qui
      // MANQUE. Pose au-dessus d un verdict, cela se lit « je ne peux pas
      // juger » — alors que le verdict, lui, est calcule et valide.
      const interdits = <AppLocale, List<String>>{
        AppLocale.fr: ['faute de donnée', 'faute de source', 'ne change rien'],
        AppLocale.en: ['for lack of', 'changes nothing'],
        AppLocale.de: ['mangels', 'ändert hier nichts'],
        AppLocale.es: ['por falta de', 'no cambia nada'],
        AppLocale.it: ['per mancanza di', 'non cambia nulla'],
      };
      for (final entree in interdits.entries) {
        final f = entree.key.buildSync().feasibility.formula;
        for (final texte in [f.seasonMissing, f.seasonNoSource]) {
          final bas = texte.toLowerCase();
          for (final mot in entree.value) {
            expect(bas, isNot(contains(mot)),
                reason: '${entree.key.languageCode} : « $texte » dit ce qui '
                    'manque au lieu de ce qui est fait');
          }
        }
      }
    });

    test('il dit CE QUI EST CALCULE, et reste verifiable', () {
      // Le facteur de chaleur vaut 0,93 en ETE et 1,00 partout ailleurs : sans
      // date, le verdict vaut donc exactement celui d un depart hors ete, et le
      // chiffre de 7 % est celui du moteur. Les deux textes doivent porter ce
      // 7 — c est ce qui les rend verifiables plutot que rassurants.
      const heat = TrekConditions(season: FeasibilitySeason.summer);
      const other = TrekConditions(season: FeasibilitySeason.spring);
      expect(heat.heatFactor, 0.93);
      expect(other.heatFactor, 1.0);
      for (final locale in AppLocale.values) {
        final f = locale.buildSync().feasibility.formula;
        expect(f.seasonMissing, contains('7'),
            reason: '${locale.languageCode} : le texte ne dit pas ce que la '
                'saison changerait, donc il n informe pas');
        expect(f.seasonNoSource, contains('7'),
            reason: '${locale.languageCode} : idem printemps / automne');
      }
    });
  });
}
