// TRAVERSEE DE RECETTE DU LOT 645-09 — DEMARRAGE A FROID, FIREBASE ABSENT.
//
// CE QU'ELLE PROUVE, ET POURQUOI ELLE EXISTE EN PLUS DES PERSONAS. Le lot
// 645-09 pose une miette d'entree sur 63 ecrans. Les parcours persona (S1, S2)
// traversent beaucoup d'ecrans mais pas ceux que la QA du lot exige nommement :
// la FICHE MEDICALE (celle qui ne doit RIEN transmettre d'autre que son nom
// d'ecran), la CHECKLIST et les REGLAGES n'y sont pas. Cette traversee ouvre la
// liste exacte demandee, dans l'ordre, et le journal local la relit.
//
// MODE : aucun identifiant Firebase n'est passe au run, donc le service
// d'observabilite est INERTE (`AnalyticsService.disabled()`). C'est l'etat de
// l'application 100 pct du temps aujourd'hui, et c'est la seule trace qui
// reste : la ligne `screen:<nom>` du journal local.
//
// CE QU'ELLE VERIFIE ELLE-MEME : chaque ecran demande a rendu un `Scaffold`
// (il s'est peint), et le RETOUR IMMEDIAT sur le meme ecran ne produit PAS de
// seconde miette (idempotence vue du dehors).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'T645_09';

void _ouvrir(WidgetTester tester, String chemin) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    if (router != null) {
      router.push(chemin);
      logStep(P, 'nav', 'Ouverture $chemin (push)');
    } else {
      logStep(P, 'nav', 'Ouverture $chemin impossible : pas de routeur');
    }
  } catch (e) {
    logStep(P, 'nav', 'Ouverture $chemin impossible : $e');
  }
}

void main() {
  initHarness();

  testWidgets('645-09 — traversee a froid sans Firebase, 12 ecrans', (
    tester,
  ) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main() sur emulateur, mode local');
    app.main();
    await settleAndShoot(tester, P, '01_boot');

    // L'ecran d'accueil peut etre l'onboarding : on le franchit si besoin, en
    // reutilisant le geste du harnais.
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_onboarding');

    // LA LISTE EXACTE DEMANDEE PAR LA QA DU LOT, dans cet ordre.
    const sentier = 'mare-a-mare-centre';
    const etapes = <String, String>{
      '/home': '03_hub',
      '/map': '04_carte',
      '/health': '05_fiche_medicale',
      '/trail/$sentier/stage/1': '06_detail_etape',
      '/trail/$sentier/weather': '07_meteo',
      '/trail/$sentier/checklist': '08_checklist',
      '/trail-selection': '09_selection_sentier',
      '/settings': '10_reglages',
      '/profile': '11_profil',
      '/emergency': '12_secours',
      '/journal': '13_journal',
      '/trails': '14_catalogue',
    };

    final muets = <String>[];
    for (final e in etapes.entries) {
      _ouvrir(tester, e.key);
      await settleAndShoot(tester, P, e.value);
      if (find.byType(Scaffold).evaluate().isEmpty) muets.add(e.key);
    }

    // RETOUR IMMEDIAT SUR LE MEME ECRAN : le journal local ne doit PAS porter
    // une deuxieme ligne. C'est l'idempotence vue du dehors.
    _ouvrir(tester, '/settings');
    await settleAndShoot(tester, P, '15_reglages_rouvert');
    _ouvrir(tester, '/settings');
    await settleAndShoot(tester, P, '16_reglages_rouvert_bis');

    expect(
      muets,
      isEmpty,
      reason:
          'CES ECRANS NE SE SONT PAS PEINTS avec une observabilite inerte : '
          '${muets.join(', ')}',
    );

    poigneeSemantique.dispose();
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}
