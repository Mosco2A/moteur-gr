// L'ACCUEIL EST ATTENDU SUR L'ETAT REEL, PLUS SUR UN DELAI FIXE — tache 685.
//
// CE QUE CE FICHIER EMPECHE DE REVENIR (kaizen #101252, mesure du 05/10/2026).
// `completeOnboardingIfPresent` donnait 10 SECONDES FIXES au libelle
// « Passer », puis journalisait « Onboarding absent (deja complete) » et
// rendait `false`. Sur une installation vierge — le cas NORMAL depuis que la
// recette desinstalle le paquet avant chaque run (tache 676) — le premier
// affichage peut demander plus de 20 s : `app.main()` est parti a 07:56:59.158
// et le harnais a declare l'accueil absent a 07:57:12.972, alors que
// l'application posait sa miette `screen:onboarding` juste apres. Le scenario
// s'est joue DERRIERE le carrousel, et quatre runs ont ete perdus sur les deux
// arbres de la QA du 645-05c.
//
// IL TOURNE EN `flutter test`, SANS EMULATEUR : il n'ouvre aucun ecran de
// l'application. Il attaque la couche d'attente du harnais (les miettes
// d'ecran, [attendreAccueilOuCockpit]) et, pour ce qui ne se joue qu'avec
// l'application, LA SOURCE de `completeOnboardingIfPresent` — parce qu'un
// retour au delai fixe se voit dans le texte et nulle part ailleurs tant que
// l'emulateur n'est pas la.
//
// IL EST VERT QUAND LE HARNAIS REGARDE L'ETAT. Un de ces tests qui rougit
// signifie le retour exact du defaut d'origine.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:moteur_gr/core/analytics/screen_breadcrumb.dart';

import '../../integration_test/persona_harness.dart';

/// La source du harnais, lue une fois.
final String _source = File(
  'integration_test/persona_harness.dart',
).readAsStringSync();

/// Le corps de `completeOnboardingIfPresent`, signature comprise.
///
/// La fonction se termine a la premiere accolade fermante EN DEBUT DE LIGNE :
/// en Dart formate, c'est la fin de la declaration de plus haut niveau.
String get _corpsCompleteOnboarding {
  const debut = 'Future<bool> completeOnboardingIfPresent(';
  final i = _source.indexOf(debut);
  expect(i, greaterThan(0), reason: 'completeOnboardingIfPresent a disparu');
  final j = _source.indexOf('\n}\n', i);
  expect(j, greaterThan(i), reason: 'fin de fonction introuvable');
  return _source.substring(i, j);
}

/// Pose une miette d'ecran comme l'application le fait (`_localLog.t`).
void _poserLaMiette(String nom) => Logger(
  printer: SimplePrinter(colors: false),
  output: _SansSortie(),
).t('screen:$nom');

/// Sortie muette : le test n'a pas a salir la console.
class _SansSortie extends LogOutput {
  @override
  void output(OutputEvent event) {}
}

void main() {
  setUp(() {
    reinitialiserExigences();
    poserLEcouteDesMiettesDEcran();
  });
  tearDown(reinitialiserExigences);

  group('LES MIETTES D ECRAN SONT LUES PAR LE HARNAIS', () {
    test('une miette posee par l application est VUE', () {
      expect(mietteDEcranVue(ScreenBreadcrumb.onboarding), isFalse);
      _poserLaMiette(ScreenBreadcrumb.onboarding.name);
      expect(
        mietteDEcranVue(ScreenBreadcrumb.onboarding),
        isTrue,
        reason:
            'LE HARNAIS NE VOIT PLUS L OBSERVABILITE : sans la miette '
            'screen:onboarding, il ne peut plus savoir que l accueil est la '
            'et il retombera sur un delai.',
      );
    });

    test('la remise a zero efface les miettes du scenario precedent', () {
      _poserLaMiette(ScreenBreadcrumb.hub.name);
      expect(cockpitAtteint(), isTrue);
      reinitialiserExigences();
      expect(
        cockpitAtteint(),
        isFalse,
        reason:
            'deux scenarios dans le meme processus se partagent les miettes : '
            'sans remise a zero, le second conclurait « accueil deja passe » '
            'sur la preuve du premier',
      );
    });

    test('un journal qui ne parle pas d ecran ne fabrique pas de miette', () {
      Logger(
        printer: SimplePrinter(colors: false),
        output: _SansSortie(),
      ).w('[observabilite] miette perdue (hub) : pas de Firebase');
      expect(kMiettesEcran, isEmpty);
    });
  });

  group('L ATTENTE DU PREMIER ECRAN REGARDE L ETAT, PAS L HORLOGE', () {
    testWidgets('l accueil a l ecran est detecte TOUT DE SUITE', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Passer'))),
      );
      final debut = DateTime.now();
      final etat = await attendreAccueilOuCockpit(tester, 'AutoTest');
      expect(etat, EtatAuPremierEcran.accueil);
      expect(
        DateTime.now().difference(debut).inSeconds,
        lessThan(5),
        reason:
            'SORTIE ANTICIPEE PERDUE : un appareil rapide ne doit pas payer '
            'l attente du plus lent',
      );
    });

    testWidgets('la miette de la suite PROUVE que l accueil est passe', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Mes treks'))),
      );
      _poserLaMiette(ScreenBreadcrumb.trailCatalog.name);
      expect(
        await attendreAccueilOuCockpit(tester, 'AutoTest'),
        EtatAuPremierEcran.cockpit,
        reason:
            'un « deja complete » doit etre PROUVE par une miette de la '
            'suite, jamais deduit d une absence',
      );
    });

    testWidgets('NI accueil NI suite rend « rien », pas « deja complete »', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      expect(
        await attendreAccueilOuCockpit(
          tester,
          'AutoTest',
          budgetBase: const Duration(milliseconds: 40),
          budgetMax: const Duration(milliseconds: 80),
          pas: const Duration(milliseconds: 5),
        ),
        EtatAuPremierEcran.rien,
        reason:
            'C EST LE DEFAUT D ORIGINE : un ecran introuvable doit rendre '
            '« rien » (que l appelant transforme en run rouge), pas un '
            '« absent (deja complete) » qui laisse jouer tout le scenario '
            'derriere le carrousel.',
      );
    });

    test(
      'le budget est adaptatif, et son plafond est celui qui a ete mesure',
      () {
        expect(
          kBudgetPremierEcranBase,
          const Duration(seconds: 20),
          reason: 'le plancher doit couvrir un boot ordinaire',
        );
        expect(
          kBudgetPremierEcranMax,
          const Duration(seconds: 60),
          reason:
              'le plafond doit couvrir le pire premier affichage mesure sur '
              'installation vierge (26,5 s le 05/10), avec marge',
        );
        expect(
          kBudgetPremierEcranMax > kBudgetPremierEcranBase,
          isTrue,
          reason: 'un budget qui ne s etend pas n est pas adaptatif',
        );
      },
    );
  });

  group('LE DELAI FIXE NE PEUT PLUS REVENIR', () {
    test('completeOnboardingIfPresent attend l etat reel', () {
      expect(
        _corpsCompleteOnboarding,
        contains('attendreAccueilOuCockpit('),
        reason:
            'LE DELAI FIXE EST REVENU : la completion de l accueil doit '
            'passer par l attente de l etat reel.',
      );
    });

    test('aucun delai fixe de 10 s ne garde l accueil', () {
      expect(
        _corpsCompleteOnboarding,
        isNot(contains('Duration(seconds: 10)')),
        reason:
            'LE DELAI FIXE DE 10 S EST REVENU — c est exactement ce qui a '
            'fait perdre quatre runs le 05/10 (kaizen #101252).',
      );
      expect(
        _corpsCompleteOnboarding,
        isNot(contains('waitFor(')),
        reason:
            'une attente sur un seul libelle, dans un delai borne, est le '
            'defaut d origine sous un autre nom',
      );
    });

    test(
      'un premier ecran introuvable fait ECHOUER le run, avec sa capture',
      () {
        final corps = _corpsCompleteOnboarding;
        expect(
          corps,
          contains('EtatAuPremierEcran.rien'),
          reason: 'le cas « rien trouve » doit etre traite explicitement',
        );
        expect(
          corps,
          contains('fail('),
          reason:
              'ECHEC FRANC EXIGE : sans `fail`, le scenario continue derriere '
              'un carrousel invisible et rend un faux rapport de defauts.',
        );
        expect(
          corps,
          contains("settleAndShoot(tester, persona, '00_accueil_introuvable')"),
          reason:
              'la capture doit partir AVANT l echec : c est elle qui dira ce '
              'que l ecran montrait',
        );
        expect(
          corps.indexOf('settleAndShoot'),
          lessThan(corps.indexOf('fail(')),
          reason: 'une capture demandee apres l echec ne sera jamais prise',
        );
      },
    );

    test('« absent (deja complete) » ne se dit plus sans preuve', () {
      // LA PHRASE A LE DROIT DE RESTER EN COMMENTAIRE — elle explique le
      // defaut d'origine, et c'est elle qu'on retrouve dans les vieux journaux
      // de run. Ce qui est interdit, c'est qu'elle reparte AU JOURNAL.
      final vivantes = _source
          .split('\n')
          .where((l) => l.contains('Onboarding absent (deja complete)'))
          .where((l) {
            final t = l.trimLeft();
            return !t.startsWith('//');
          })
          .toList();
      expect(
        vivantes,
        isEmpty,
        reason:
            'cette phrase etait le mensonge du harnais : elle s ecrivait '
            'alors que l accueil etait a l ecran. Un « deja complete » doit '
            'nommer la miette qui le prouve. Lignes fautives : '
            '${vivantes.join(" | ")}',
      );
    });

    test('l ecoute des miettes est posee AVANT app.main()', () {
      final i = _source.indexOf(
        'IntegrationTestWidgetsFlutterBinding initHarness(',
      );
      expect(i, greaterThan(0));
      final corps = _source.substring(i, _source.indexOf('\n}', i));
      expect(
        corps,
        contains('poserLEcouteDesMiettesDEcran()'),
        reason:
            'une ecoute posee plus tard raterait le boot, c est-a-dire '
            'exactement le moment qu on mesure',
      );
    });
  });
}
