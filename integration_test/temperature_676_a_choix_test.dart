// L'UNITE DE TEMPERATURE EST-ELLE VRAIMENT ECRITE SUR LE TELEPHONE ? (tache
// 676, QA du lot 645-F1).
//
// CE QUE CE TEST PROUVE, SUR L'APPAREIL : un VRAI geste sur le bouton °F des
// Reglages ecrit `fahrenheit` dans le magasin du telephone, sous la cle
// `settings_temperature_unit` — et on le relit par une poignee
// `SharedPreferences` NEUVE (`resetStatic`), c'est-a-dire en repassant par le
// cote natif, pas par un cache en memoire.
//
// CE QU'IL NE PEUT PAS PROUVER, ET POURQUOI — MESURE, PAS SUPPOSE. Un
// redemarrage de bout en bout (choisir, tuer l'application, relancer, relire)
// n'est pas jouable sous `flutter test` : LES DONNEES DE L'APPLICATION SONT
// EFFACEES ENTRE DEUX FICHIERS DE TEST d'une meme invocation. Mesure du
// 04/10 : trois fichiers joues a la suite, chacun a lu `ABSENTE` au demarrage,
// y compris apres que le precedent eut ecrit `fahrenheit`. Les deux fichiers
// qui tentaient la relecture ont donc ete retires : ils mesuraient le harnais,
// pas le produit.
// LA RELECTURE AU DEMARRAGE EST PROUVEE AILLEURS, et deux fois :
//   * `test/features/settings/settings_provider_test.dart` — un conteneur neuf
//     apres `SharedPreferences.resetStatic()` relit Fahrenheit (lot 645-F1) ;
//   * ici meme, a l'envers : sur une installation vierge, le magasin rend
//     `ABSENTE` et l'ecran montre Celsius — l'application lit donc bien le
//     magasin a son demarrage, et retombe sur son repli.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/settings/presentation/settings_screen.dart';
import 'package:moteur_gr/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'persona_harness.dart';
import 'temperature_676_commun.dart';

const String P = 'TEMP676_1';

void main() {
  initHarness();

  testWidgets('676 — Fahrenheit choisi par un vrai geste dans les Reglages', (
    tester,
  ) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    app.main();
    await settleAndShoot(tester, P, '01_boot');
    await completeOnboardingIfPresent(tester, P);

    final ctx = tester.element(find.byType(Navigator).first);
    GoRouter.of(ctx).push('/settings');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    exige(
      P,
      'reglages',
      find.byType(SettingsScreen).evaluate().isNotEmpty,
      'l ecran Reglages est monte',
    );

    final avant = await uniteDansLeMagasin();
    logStep(P, 'magasin', 'unite dans le magasin AVANT le geste : $avant');
    logStep(
      P,
      'ecran',
      'unite selectionnee a l ecran AVANT : ${uniteAffichee(tester)}',
    );

    await choisirUnite(tester, P, '°F');
    await settleAndShoot(tester, P, '02_fahrenheit_choisi');

    exige(
      P,
      'ecran',
      uniteAffichee(tester) == 'fahrenheit',
      'le bouton Fahrenheit est selectionne a l ecran '
          '(lu : ${uniteAffichee(tester)})',
    );

    // LE MAGASIN DU TELEPHONE, RELU A NEUF : c'est lui qui devra survivre.
    SharedPreferences.resetStatic();
    final apres = await uniteDansLeMagasin();
    logStep(P, 'magasin', 'unite dans le magasin APRES le geste : $apres');
    exige(
      P,
      'magasin',
      apres == 'fahrenheit',
      'le magasin du telephone porte fahrenheit sous la cle '
          'settings_temperature_unit (lu : $apres)',
    );

    poigneeSemantique.dispose();
    verdictPersona(P);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}
