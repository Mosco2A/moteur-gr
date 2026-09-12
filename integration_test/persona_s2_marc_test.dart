// ignore_for_file: avoid_print
//
// S2 — MARC, randonneur confirme et presse (tache 518, joue EN DIRECT).
//
// Objectif persona : evaluer vite un trek dur et se lancer.
// Parcours vise (PLAN_TEST_PERSONAS S2) :
//   selectionne un trek dur -> faisabilite « go » rapide -> « Mes treks »
//   multi-treks -> cockpit -> reglages (change la langue, voit la version
//   v0.1.0) -> profil.
//
// Pilote l UI reelle, capture chaque etape, LOGue les coincements. Zero modif app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S2_Marc';

void main() {
  initHarness();

  testWidgets('S2 — Marc evalue vite un trek dur et se lance', (tester) async {
    logStep(P, 'boot', 'Lancement de app.main()');
    app.main();
    await settleAndShoot(tester, P, '01_boot', timeout: const Duration(seconds: 12));

    // Consentement pub + onboarding (bilingue, Marc est presse -> Passer/Skip).
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_skip');

    // --- Accueil « Mes treks » : etat multi-treks ---
    _logLocation(tester, P, 'accueil');
    await settleAndShoot(tester, P, '03_mes_treks');
    // Compter les cartes de trek possedees (cle trek-summary-*).
    final trekCards = find
        .byWidgetPredicate((w) => w.key.toString().contains('trek-summary-'));
    logStep(P, 'mes_treks',
        'Treks possedes visibles (cartes trek-summary-*) = ${trekCards.evaluate().length}');

    // --- Selectionne un trek (entre dans le cockpit) ---
    // Marc ouvre un trek depuis « Mes treks » : tap sur la 1re carte. NB : s il a
    // saute l onboarding sans entrer dans un sentier, « Mes treks » peut etre
    // VIDE (0 carte) — signal QA note ci-dessus. Repli : catalogue -> Entrer
    // (selectionne le sentier, ouvre la carte) puis on rejoint le cockpit /home.
    if (present(trekCards)) {
      await tester.tap(trekCards.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'selection', 'TAP OK : ouverture du 1er trek possede -> cockpit');
    } else {
      logStep(P, 'selection',
          'FINDING : « Mes treks » VIDE apres skip onboarding (0 trek possede). '
          'Repli catalogue.');
      if (!present(textFrEn('Catalogue des sentiers', 'Trail catalog'))) {
        await tapIfPresent(tester, textFrEn('Découvrir des sentiers', 'Discover trails'),
            P, 'selection', 'Decouvrir des sentiers (repli)', warnIfMissing: false);
      }
      await tapIfPresent(
          tester,
          find.byKey(const ValueKey('catalog-enter-mare-a-mare-centre')),
          P,
          'selection',
          'Entrer dans la vitrine (repli)');
      // « Entrer » ouvre la CARTE ; le sentier est desormais selectionne -> on
      // rejoint le cockpit de preparation.
      _goHome(tester, P);
    }
    await settleAndShoot(tester, P, '04_cockpit');
    _logLocation(tester, P, 'cockpit');

    // --- Faisabilite « go » rapide ---
    final feasCard = textFrEn('Faisabilité', 'Feasibility');
    await scrollUntil(tester, feasCard, P, 'faisabilite', 'carte Faisabilite');
    await tapIfPresent(tester, feasCard, P, 'faisabilite', 'ouvrir Faisabilite');
    await settleAndShoot(tester, P, '05_faisabilite');
    // Verdict visible ?
    _logVisibleVerdict(tester, P);
    // Retour cockpit par le routeur (etat connu).
    _goHome(tester, P);

    // --- Cockpit : verifier presence du CTA principal (en tete) ---
    await _scrollToTop(tester, P);
    await settleAndShoot(tester, P, '06_retour_cockpit');
    logStep(
        P,
        'cockpit',
        'CTA Demarrer present = ${present(textFrEn('Démarrer la randonnée', 'Start the trek'))} ; '
            'Reprendre present = ${present(textFrEn('Reprendre la navigation', 'Resume navigation'))}');

    // --- Reglages : changer la langue + voir la version ---
    // Acces reglages via l icone parametres du header du cockpit.
    final gearBtn = find.byIcon(Icons.settings_outlined);
    await tapIfPresent(
        tester, gearBtn, P, 'reglages', 'ouvrir Reglages (icone parametres)');
    await settleAndShoot(tester, P, '07_reglages');

    // Changer la langue : taper « English » (ListTile de la section langue).
    final langOk = await tapIfPresent(
        tester, find.text('English'), P, 'reglages', 'choisir la langue English');
    await settleAndShoot(tester, P, '08_langue_en');
    if (langOk) {
      // Verifier la bascule : le titre « Settings » (EN) devrait apparaitre.
      final switched = present(find.text('Settings')) ||
          present(find.text('Language')) ||
          present(find.text('Version'));
      logStep(P, 'reglages',
          'Bascule EN detectee (Settings/Language visible) = $switched');
      // Remettre le francais pour ne pas perturber les autres scenarios.
      await tapIfPresent(tester, find.text('French'), P, 'reglages',
          'remettre Francais', warnIfMissing: false);
      await tapIfPresent(tester, find.text('Français'), P, 'reglages',
          'remettre Francais (accent)', warnIfMissing: false);
    }

    // Voir la version : defiler jusqu a la section version et lire « 0.1.0 ».
    await scrollUntil(tester, find.textContaining('0.1.0'), P, 'version',
        'numero de version (0.1.0)');
    final versionShown = present(find.textContaining('0.1.0'));
    logStep(P, 'version',
        'Version 0.1.0 visible dans les reglages = $versionShown');
    await settleAndShoot(tester, P, '09_version');

    // --- Profil ---
    await _back(tester, P, 'profil');
    // Icone profil du header du cockpit.
    await tapIfPresent(tester, find.byIcon(Icons.person_outline), P, 'profil',
        'ouvrir Profil (icone personne)');
    await settleAndShoot(tester, P, '10_profil');
    _logLocation(tester, P, 'profil');

    logStep(P, 'fin', 'Scenario S2 termine');
    await flushJournal(P);
  });
}

/// Retour cockpit /home (etat connu via routeur).
void _goHome(WidgetTester tester, String persona) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    if (router != null) {
      router.go('/home');
      logStep(persona, 'nav', 'Retour cockpit /home');
    }
  } catch (e) {
    logStep(persona, 'nav', 'Retour /home impossible : $e');
  }
}

/// Remonte en tete de la 1re liste defilante.
Future<void> _scrollToTop(WidgetTester tester, String persona) async {
  if (find.byType(Scrollable).evaluate().isEmpty) return;
  final scroller = find.byType(Scrollable).first;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scroller, const Offset(0, 600));
    await pumpAndSettleTolerant(tester);
  }
  logStep(persona, 'nav', 'Remontee en tete du cockpit');
}

Future<void> _back(WidgetTester tester, String persona, String etape) async {
  // Bouton back bilingue (tooltip Retour/Back) sinon pop routeur.
  final tip = find.byTooltip('Retour');
  final tipEn = find.byTooltip('Back');
  if (present(tip) || present(tipEn)) {
    await tester.tap((present(tip) ? tip : tipEn).first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
    logStep(persona, etape, 'RETOUR via bouton back');
    return;
  }
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    if (router != null && router.canPop()) {
      router.pop();
      await pumpAndSettleTolerant(tester);
      logStep(persona, etape, 'RETOUR via GoRouter.pop');
      return;
    }
  } catch (_) {}
  logStep(persona, etape, 'RETOUR impossible');
}

void _logLocation(WidgetTester tester, String persona, String etape) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    final loc =
        router?.routerDelegate.currentConfiguration.uri.toString() ?? 'inconnu';
    logStep(persona, etape, 'LOCALISATION routeur = $loc');
  } catch (e) {
    logStep(persona, etape, 'Localisation routeur illisible : $e');
  }
}

void _logVisibleVerdict(WidgetTester tester, String persona) {
  const verdicts = <String>[
    'Déconseillé',
    'Préparation nécessaire',
    'Faisable',
    'Excellent',
  ];
  for (final v in verdicts) {
    if (present(find.text(v))) {
      logStep(persona, 'verdict', 'VERDICT visible = "$v"');
      return;
    }
  }
  logStep(persona, 'verdict', 'Aucun verdict standard visible — voir capture');
}
