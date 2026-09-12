// ignore_for_file: avoid_print
//
// S4 — INES, payeuse hors-ligne (tache 518, joue EN DIRECT). POINT SENSIBLE.
//
// Objectif persona : acceder a son contenu premium SANS reseau (le payeur ne
// doit JAMAIS etre bloque hors-ligne).
// Parcours vise (PLAN_TEST_PERSONAS S4) :
//   achete (demo) -> coupe le reseau (mode avion) -> rouvre entrainement + carte
//   offline -> verifie que le premium reste debloque.
//
// MODE AVION — MECANIQUE : la coupure/retablissement reseau est pilotee DEPUIS
//   L HOTE via `adb -s emulator-5554 shell svc wifi/data disable` (ou cmd
//   connectivity airplane-mode) — le lanceur host-side le fait PENDANT la
//   fenetre marquee « OFFLINE » de ce test. Le test, lui, OBSERVE que le contenu
//   (entrainement, carte) reste accessible.
//
// NB ACHAT : la vitrine est deja debloquee (jouable) sans achat ; on documente
//   le parcours d achat demo s il est atteignable, et on VERIFIE surtout la
//   NON-REGRESSION hors-ligne du contenu premium.
//
// Pilote l UI reelle, capture chaque etape, LOGue les coincements. Zero modif app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S4_Ines';

void main() {
  initHarness();

  testWidgets('S4 — Ines accede a son premium hors-ligne', (tester) async {
    logStep(P, 'boot', 'Lancement de app.main()');
    app.main();
    await settleAndShoot(tester, P, '01_boot', timeout: const Duration(seconds: 12));

    // Consentement pub + onboarding (bilingue, robuste).
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_skip');

    // --- Entrer dans le cockpit du trek (via « Mes treks ») ---
    await _goMyTreks(tester, P);
    final trekCards = find
        .byWidgetPredicate((w) => w.key.toString().contains('trek-summary-'));
    if (present(trekCards)) {
      await tester.tap(trekCards.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'entree', 'TAP OK : ouverture trek possede -> cockpit');
    } else {
      await tapIfPresent(tester, textFrEn('Découvrir des sentiers', 'Discover trails'),
          P, 'entree', 'Decouvrir des sentiers');
      await tapIfPresent(
          tester,
          find.byKey(const ValueKey('catalog-enter-mare-a-mare-centre')),
          P,
          'entree',
          'Entrer dans la vitrine');
      _goHome(tester, P);
    }
    await settleAndShoot(tester, P, '03_cockpit');
    _logLocation(tester, P, 'cockpit');

    // --- Achat (demo) : documenter le parcours si un CTA d achat existe ---
    // La vitrine est deja jouable ; on cherche un eventuel « Debloquer » (paywall
    // entrainement) pour montrer le geste d achat, sinon on note l etat.
    logStep(P, 'achat',
        'Vitrine deja debloquee (jouable sans achat). Recherche d un CTA achat/'
        'Debloquer a titre de demonstration.');

    // --- FENETRE ONLINE : verifier l acces AVANT coupure ---
    // Entrainement (contenu premium).
    final trainingCard = textFrEn('Préparation physique', 'Physical prep');
    await _scrollToTop(tester, P);
    await scrollUntil(tester, trainingCard, P,
        'entrainement_online', 'carte Preparation physique');
    await tapIfPresent(tester, trainingCard, P,
        'entrainement_online', 'ouvrir Preparation physique (ONLINE)');
    await settleAndShoot(tester, P, '04_entrainement_online');
    final unlockOnline = present(find.text('Debloquer')) ||
        present(find.textContaining('Débloquer'));
    logStep(P, 'entrainement_online',
        'Paywall « Debloquer » visible ONLINE = $unlockOnline ; '
        'seances presentes = ${present(find.byWidgetPredicate((w) => w.key.toString().contains('training-session-')))}');
    if (unlockOnline) {
      // Geste d achat demo (debloque le pack).
      await tapIfPresent(tester, find.textContaining('Débloquer'), P, 'achat',
          'Debloquer le pack (achat demo)', warnIfMissing: false);
      await settleAndShoot(tester, P, '05_apres_achat');
    }
    await _back(tester, P, 'entrainement_online');

    // Carte offline (contenu premium terrain).
    _goMap(tester, P);
    await settleAndShoot(tester, P, '06_carte_online');
    logStep(P, 'carte_online',
        'Carte ouverte ONLINE. FlutterMap present = ${present(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'FlutterMap'))}');
    await _back(tester, P, 'carte_online');

    // --- BASCULE OFFLINE ---
    // Le lanceur host-side coupe le reseau (mode avion) MAINTENANT. On laisse un
    // temps large pour que la coupure prenne effet avant de re-parcourir.
    logStep(
        P,
        'offline',
        'DEBUT fenetre OFFLINE (~25 s). L hote coupe le reseau (adb svc '
            'wifi/data disable). On attend la prise d effet.');
    await _observe(tester, const Duration(seconds: 25));
    await settleAndShoot(tester, P, '07_bascule_offline');

    // --- Re-verifier l acces PENDANT la coupure (LE point sensible) ---
    // 1) Entrainement doit rester accessible (contenu premium local).
    _goHome(tester, P);
    await _scrollToTop(tester, P);
    await scrollUntil(tester, trainingCard, P,
        'entrainement_offline', 'carte Preparation physique (OFFLINE)');
    await tapIfPresent(tester, trainingCard, P,
        'entrainement_offline', 'ouvrir Preparation physique (OFFLINE)');
    await settleAndShoot(tester, P, '08_entrainement_offline');
    final blockedOffline = present(find.textContaining('Débloquer')) ||
        present(find.text('Debloquer'));
    final sessionsOffline = present(find
        .byWidgetPredicate((w) => w.key.toString().contains('training-session-')));
    logStep(
        P,
        'entrainement_offline',
        'PAYWALL reapparait hors-ligne = $blockedOffline (DOIT etre false) ; '
            'seances toujours presentes = $sessionsOffline (DOIT etre true si achete). '
            'C EST LE POINT SENSIBLE : le payeur ne doit JAMAIS etre bloque hors-ligne.');
    await _back(tester, P, 'entrainement_offline');

    // 2) Carte offline : le fond OSM (reseau) peut ne pas charger, mais l ecran
    //    et le trace local doivent rester accessibles (pas d ecran bloquant).
    _goMap(tester, P);
    await settleAndShoot(tester, P, '09_carte_offline');
    final mapErrorOffline = present(find.textContaining('impossible')) ||
        present(find.textContaining('Impossible')) ||
        present(find.textContaining('introuvable'));
    logStep(
        P,
        'carte_offline',
        'Carte OFFLINE : ecran d erreur bloquant visible = $mapErrorOffline ; '
            'FlutterMap present = ${present(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'FlutterMap'))} '
            '(le fond OSM en ligne peut manquer, mais l ecran ne doit pas etre bloque).');
    await _back(tester, P, 'carte_offline');

    // 3) Cockpit toujours navigable hors-ligne ?
    _goHome(tester, P);
    await settleAndShoot(tester, P, '10_cockpit_offline');
    logStep(P, 'cockpit_offline',
        'Cockpit accessible hors-ligne = ${present(find.byType(Scaffold))} ; '
        'sections Preparer visibles = ${present(textFrEn('Préparer', 'Prepare'))}');

    logStep(
        P,
        'fin',
        'Scenario S4 termine. L hote peut retablir le reseau. Verdict premium '
            'hors-ligne consigne dans les logs entrainement_offline/carte_offline.');
    await flushJournal(P);
  });
}

Future<void> _observe(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _back(WidgetTester tester, String persona, String etape) async {
  final backBtn = find.byTooltip('Retour');
  if (present(backBtn)) {
    await tester.tap(backBtn.first, warnIfMissed: false);
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

void _goMap(WidgetTester tester, String persona) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    if (router != null) {
      router.push('/map');
      logStep(persona, 'nav', 'Ouverture carte /map (push)');
    }
  } catch (e) {
    logStep(persona, 'nav', 'Ouverture carte impossible : $e');
  }
}

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

Future<void> _goMyTreks(WidgetTester tester, String persona) async {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    if (router != null) {
      router.go('/my-treks');
      await pumpAndSettleTolerant(tester);
      logStep(persona, 'nav', 'Retour accueil /my-treks');
    }
  } catch (e) {
    logStep(persona, 'nav', 'Retour /my-treks impossible : $e');
  }
}

Future<void> _scrollToTop(WidgetTester tester, String persona) async {
  if (find.byType(Scrollable).evaluate().isEmpty) return;
  final scroller = find.byType(Scrollable).first;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scroller, const Offset(0, 600));
    await pumpAndSettleTolerant(tester);
  }
  logStep(persona, 'nav', 'Remontee en tete du cockpit');
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
