// LES DOUZE REPRODUCTIONS DU DEFAUT DE PILE, REJOUEES SUR L'EMULATEUR (tache
// 676, QA du lot 645-09b).
//
// CE QU'ON MESURE. Le 04/10, sur la tete du lot 645-09, l'ouverture des
// Reglages par-dessus une pile d'ecrans instrumentes DANS `build` faisait
// reposer leur miette aux ecrans restes vivants SOUS celui du dessus : la
// derniere miette du journal — donc la valeur de la cle `screen` au moment d'un
// plantage — designait un ecran que le randonneur ne regardait pas. Mesure 12
// fois sur 12 (memoire #101121).
//
// COMMENT ON LE REJOUE. On empile d'abord TROIS ecrans instrumentes dans
// `build` (detail d'etape, meteo, journal) : c'est la condition du defaut, deux
// ecrans `build` au moins restes vivants sous la pile. Puis douze fois de
// suite : on pousse les Reglages, on redescend. A chaque fois le journal local
// doit porter `screen:settings` pendant que les Reglages sont devant, et
// `screen:journal` des qu'on redescend — jamais le nom d'un ecran cache.
//
// CE TEST NE LIT PAS LE JOURNAL LUI-MEME : la miette part dans la console
// (logger -> print -> sortie du run), pas dans une variable observable depuis
// le test. Il BORNE donc chaque tour par un marqueur, et la mesure se fait sur
// le journal du run entre deux marqueurs (voir le rapport de la tache 676).
// L'assertion interne, elle, porte sur ce que le test peut voir : les Reglages
// sont bien devant apres le push, et l'ecran du dessous est bien revenu apres
// le pop.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/journal/presentation/journal_screen.dart';
import 'package:moteur_gr/features/settings/presentation/settings_screen.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'PILE676';
const int kTours = 12;

BuildContext _ctxNavigateur(WidgetTester tester) =>
    tester.element(find.byType(Navigator).first);

void _pousser(WidgetTester tester, String chemin) {
  final routeur = GoRouter.maybeOf(_ctxNavigateur(tester));
  if (routeur == null) {
    logStep(P, 'nav', 'ROUTEUR ABSENT : $chemin non pousse');
    return;
  }
  routeur.push(chemin);
}

void _depiler(WidgetTester tester) {
  final ctx = _ctxNavigateur(tester);
  final routeur = GoRouter.maybeOf(ctx);
  if (routeur != null && routeur.canPop()) {
    routeur.pop();
    return;
  }
  Navigator.of(ctx).pop();
}

void main() {
  initHarness();

  testWidgets('645-09b — douze empilements des Reglages sur une pile d ecrans '
      'build : la cle screen suit l ecran visible', (tester) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main() sur emulateur, mode local');
    app.main();
    await settleAndShoot(tester, P, '01_boot');
    await completeOnboardingIfPresent(tester, P);

    // LA PILE DU DEFAUT : trois ecrans instrumentes dans `build`, laisses
    // vivants l'un sous l'autre.
    const sentier = 'mare-a-mare-centre';
    _pousser(tester, '/trail/$sentier/stage/1');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    _pousser(tester, '/trail/$sentier/weather');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    _pousser(tester, '/journal');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '02_pile_de_trois');

    logStep(
      P,
      'pile',
      'PILE PRETE : detail d etape, meteo, journal empiles (ecrans build)',
    );

    var reglagesDevant = 0;
    var journalRevenu = 0;

    for (var tour = 1; tour <= kTours; tour++) {
      logStep(P, 'pile', 'PILE676_MARQUEUR tour=$tour etape=avant_empilement');
      _pousser(tester, '/settings');
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
      final devant = find.byType(SettingsScreen).evaluate().isNotEmpty;
      if (devant) reglagesDevant++;
      logStep(
        P,
        'pile',
        'PILE676_MARQUEUR tour=$tour etape=empile reglages_montes=$devant',
      );

      _depiler(tester);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
      final revenu =
          find.byType(JournalScreen).evaluate().isNotEmpty &&
          find.byType(SettingsScreen).evaluate().isEmpty;
      if (revenu) journalRevenu++;
      logStep(
        P,
        'pile',
        'PILE676_MARQUEUR tour=$tour etape=depile journal_revenu=$revenu',
      );
    }

    await settleAndShoot(tester, P, '03_apres_douze_tours');
    logStep(
      P,
      'pile',
      'DOUZE TOURS JOUES : reglages devant $reglagesDevant/$kTours, '
          'journal revenu $journalRevenu/$kTours',
    );

    expect(
      reglagesDevant,
      kTours,
      reason:
          'les Reglages ne sont pas montes a tous les tours : la mesure du '
          'journal ne vaudrait rien',
    );
    expect(
      journalRevenu,
      kTours,
      reason:
          'le journal n est pas redevenu l ecran du dessus a tous les tours : '
          'la mesure du journal ne vaudrait rien',
    );

    poigneeSemantique.dispose();
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}
