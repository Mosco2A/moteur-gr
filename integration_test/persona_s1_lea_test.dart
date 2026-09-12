// ignore_for_file: avoid_print
//
// S1 — LEA, debutante prudente (tache 518, joue EN DIRECT sur emulator-5554).
//
// Objectif persona : preparer sa premiere rando en securite.
// Parcours vise (PLAN_TEST_PERSONAS S1) :
//   onboarding -> catalogue -> fiche sentier -> faisabilite (fiche info + test
//   6 min + 5 randos) -> verdict « prudence » -> pack (demo) -> entrainement
//   (coche des seances) -> calendrier (pose une date) -> checklist/sac ->
//   demarre.
//
// Ce test PILOTE l'UI reelle et CAPTURE chaque etape. Il ne modifie pas l'app.
// La vitrine (mare-a-mare-centre) est jouable sans achat : Lea peut donc tout
// parcourir en mode demo. Chaque coincement (widget introuvable, ecran faux)
// est LOGue comme signal QA, sans stopper le scenario.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S1_Lea';

void main() {
  initHarness();

  testWidgets('S1 — Lea prepare sa premiere rando', (tester) async {
    // --- Lancement de la VRAIE app ---
    logStep(P, 'boot', 'Lancement de app.main() sur emulateur');
    app.main();
    await settleAndShoot(tester, P, '01_boot', timeout: const Duration(seconds: 12));

    // --- Etape 1 : consentement pub + onboarding (bilingue, robuste) ---
    // Au 1er lancement : un formulaire UMP (« Publisher Test Ads ») peut
    // recouvrir l'ecran, puis l'onboarding (3 pages). Le helper gere les deux,
    // en FR comme en EN, et attend le boot (bootstrap+seed lents).
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '05_apres_onboarding');

    // --- Etape 2 : catalogue (Lea decouvre les sentiers) ---
    // Depuis l accueil « Mes treks », « Decouvrir des sentiers » ouvre /catalog.
    // (Apres onboarding l app va deja sur /catalog.)
    final catTitle = textFrEn('Catalogue des sentiers', 'Trail catalog');
    if (!present(catTitle)) {
      await tapIfPresent(tester, textFrEn('Découvrir des sentiers', 'Discover trails'),
          P, 'catalogue', 'Decouvrir des sentiers (accueil -> catalogue)',
          warnIfMissing: false);
    }
    await settleAndShoot(tester, P, '06_catalogue');
    final enterBtn = textFrEn('Entrer', 'Enter');
    logStep(P, 'catalogue',
        'Catalogue affiche = ${present(catTitle)} ; '
        'sentiers avec bouton Entrer = ${enterBtn.evaluate().length}');

    // --- Etape 3 : fiche sentier ---
    // FINDING attendu : le bouton « Entrer » du catalogue fait push('/map') ->
    // il ouvre la CARTE terrain du sentier (pas le cockpit de preparation). On
    // le JOUE et on TRACE la destination reelle (signal QA), puis on rejoint le
    // cockpit par le chemin utilisateur normal (accueil « Mes treks »).
    final entered = await tapIfPresent(
        tester,
        find.byKey(const ValueKey('catalog-enter-mare-a-mare-centre')),
        P,
        'fiche_sentier',
        'Entrer dans le sentier vitrine (cle catalog-enter)');
    if (!entered) {
      await tapIfPresent(tester, enterBtn, P, 'fiche_sentier',
          'Entrer (1er sentier du catalogue)');
    }
    await settleAndShoot(tester, P, '07_apres_entrer');
    _logLocation(tester, P, 'apres_entrer');
    logStep(
        P,
        'fiche_sentier',
        'Ecran apres Entrer : carte terrain = ${_onMap(tester)} '
            '(FINDING : « Entrer » catalogue -> /map, pas le cockpit de preparation).');

    // Rejoindre le COCKPIT de preparation par le chemin utilisateur : retour a
    // « Mes treks » puis ouverture du trek possede (go('/home')).
    await _goMyTreks(tester, P);
    await settleAndShoot(tester, P, '07b_mes_treks');
    final trekCard = find
        .byWidgetPredicate((w) => w.key.toString().contains('trek-summary-'));
    if (present(trekCard)) {
      await tester.tap(trekCard.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'cockpit', 'TAP OK : carte de trek possede -> cockpit /home');
    } else {
      logStep(P, 'cockpit',
          'Aucune carte trek-summary-* sur Mes treks — on force /home');
      _goHome(tester, P);
    }
    await settleAndShoot(tester, P, '07c_cockpit');
    _logLocation(tester, P, 'cockpit');

    // --- Etape 4 : faisabilite (fiche info + test 6 min + 5 randos) ---
    // Carte « Faisabilite » de la section Preparer.
    final feasCard = textFrEn('Faisabilité', 'Feasibility');
    await scrollUntil(tester, feasCard, P, 'faisabilite',
        'carte Faisabilite (section Preparer)');
    await tapIfPresent(tester, feasCard, P, 'faisabilite', 'ouvrir Faisabilite');
    await settleAndShoot(tester, P, '08_faisabilite');
    // Verdict affiche a l ouverture (avant d avoir renseigne le profil : la
    // faisabilite retombe sur le questionnaire de depannage — signal QA).
    _logVisibleVerdict(tester, P);

    // 4a — Fiche d info randonneur (raccourci « Ma fiche d'info »).
    if (await tapIfPresent(tester, textFrEn("Ma fiche d'info", 'My details'), P,
        'faisabilite', 'raccourci Ma fiche d info',
        warnIfMissing: false)) {
      await settleAndShoot(tester, P, '09_fiche_info');
      logStep(P, 'fiche_info',
          'Ecran fiche d info randonneur ouvert (age/taille/poids -> IMC local, '
          'donnee morpho sensible). On ne remplit pas les champs sensibles ici.');
      await _back(tester, P, 'faisabilite');
    } else {
      logStep(P, 'faisabilite',
          'Raccourci « Ma fiche d info » introuvable — capture pour analyse');
    }

    // 4b — Test 6 minutes (on OUVRE l ecran ; le test reel = 6 min GPS, hors
    // scope automatise, on le documente).
    if (await tapIfPresent(tester, textFrEn('Test 6 minutes', '6-minute test'), P,
        'faisabilite', 'raccourci Test 6 minutes',
        warnIfMissing: false)) {
      await settleAndShoot(tester, P, '10_test_6min');
      logStep(P, 'test_6min',
          'Test 6 min OUVERT. Non joue en entier : requiert 6 min de marche GPS '
          'reelle (chrono live) — infaisable en test rapide. Documente.');
      await _back(tester, P, 'faisabilite');
    }

    // 4c — 5 dernieres randos (interview). On ouvre + on ajoute une rando
    // modeste via le formulaire (dialog), coherent avec une debutante.
    if (await tapIfPresent(tester, textFrEn('Mes 5 dernieres randos', 'My last 5 hikes'),
        P, 'faisabilite', 'raccourci 5 dernieres randos',
        warnIfMissing: false)) {
      await settleAndShoot(tester, P, '11_past_hikes');
      // Ouvrir le formulaire d ajout (bouton « Ajouter une rando »).
      await tapIfPresent(tester,
          textFrEn('Ajouter une rando', 'Add a hike'), P, 'past_hikes',
          'ajouter une rando', warnIfMissing: false);
      await settleAndShoot(tester, P, '12_past_hikes_form');
      // Renseigner les champs numeriques presents (valeurs modestes).
      final formFields = find.byType(TextFormField);
      final n = formFields.evaluate().length;
      logStep(P, 'past_hikes', 'Formulaire rando : $n champs TextFormField');
      // Valeurs debutante : rando courte (1 jour, ~8 km/j, ~300 m D+...).
      const values = ['1', '8', '8', '300', '1'];
      for (var i = 0; i < n && i < values.length; i++) {
        await tester.enterText(formFields.at(i), values[i]);
        await pumpAndSettleTolerant(tester);
      }
      if (n > 0) {
        logStep(P, 'past_hikes', 'SAISIE valeurs modestes dans le formulaire');
      }
      // Valider le formulaire (« Enregistrer »).
      await tapIfPresent(tester, textFrEn('Enregistrer', 'Save'), P, 'past_hikes',
          'enregistrer la rando', warnIfMissing: false);
      await settleAndShoot(tester, P, '12b_past_hikes_saved');
    }

    // Retour au COCKPIT par le routeur (etat connu, evite le cumul de piles).
    await _goHome(tester, P);
    await settleAndShoot(tester, P, '13_retour_cockpit');

    // --- Etape 5 : entrainement (depuis le cockpit -> carte « Preparation
    // physique » de la section Preparer, route /training). ---
    await _scrollToTop(tester, P);
    final trainingCard = textFrEn('Préparation physique', 'Physical prep');
    await scrollUntil(tester, trainingCard, P, 'entrainement',
        'carte Preparation physique (section Preparer)');
    await tapIfPresent(tester, trainingCard, P, 'entrainement',
        'ouvrir Preparation physique');
    await settleAndShoot(tester, P, '14_entrainement');

    // Cocher une seance si des cartes de seance sont presentes (cle
    // training-session-*).
    final sessionCard =
        find.byWidgetPredicate((w) => w.key.toString().contains('training-session-'));
    if (present(sessionCard)) {
      await tester.tap(sessionCard.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'entrainement', 'TAP OK : 1re seance d entrainement cochee/ouverte');
    } else {
      logStep(P, 'entrainement',
          'Aucune carte de seance (training-session-*) — paywall/plan generique '
          'possible. Capture pour analyse.');
    }
    await settleAndShoot(tester, P, '15_entrainement_seance');

    // --- Etape 6 : calendrier (pose une date) ---
    await _goHome(tester, P);
    final calCard = textFrEn('Calendrier', 'Calendar');
    await scrollUntil(tester, calCard, P, 'calendrier',
        'carte Calendrier (section Preparer)');
    await tapIfPresent(tester, calCard, P, 'calendrier', 'ouvrir Calendrier');
    await settleAndShoot(tester, P, '16_calendrier');
    // Poser une date : tenter un tap sur un jour du calendrier (nombre) — best
    // effort, on documente si le selecteur differe.
    logStep(P, 'calendrier',
        'Selection de date : depend du widget calendrier (voir capture). '
        'Tentative de tap sur un jour.');
    await tapIfPresent(tester, find.text('15'), P, 'calendrier',
        'poser une date (jour 15)', warnIfMissing: false);
    await settleAndShoot(tester, P, '17_calendrier_date');

    // --- Etape 7 : checklist / sac ---
    await _goHome(tester, P);
    final checklistCard = textFrEn('Materiel & Sac', 'Gear & Pack');
    await scrollUntil(tester, checklistCard, P, 'checklist',
        'carte Materiel & Sac (section Preparer)');
    await tapIfPresent(tester, checklistCard, P, 'checklist',
        'ouvrir Materiel & Sac');
    await settleAndShoot(tester, P, '18_checklist');
    // Les items sont ranges par CATEGORIES pliables (Sac & portage, Couchage...).
    // On DEPLIE d'abord une categorie (tap sur son entete) pour faire apparaitre
    // les cases a cocher, puis on coche le 1er item.
    await tapIfPresent(tester, textFrEn('Sac & portage', 'Pack & carry'), P,
        'checklist', 'deplier la categorie « Sac & portage »',
        warnIfMissing: false);
    await settleAndShoot(tester, P, '18b_checklist_categorie');
    // Cocher un item (premiere Checkbox / CheckboxListTile presente).
    final checkbox = find.byWidgetPredicate(
        (w) => w is Checkbox || w is CheckboxListTile);
    if (present(checkbox)) {
      await tester.tap(checkbox.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'checklist', 'TAP OK : 1er item de checklist coche');
    } else {
      // Repli : cocher via un ListTile d article (tap sur la ligne).
      logStep(P, 'checklist',
          'Pas de Checkbox directe — les items se cochent peut-etre au tap sur '
          'la ligne (voir capture 18b). Signal QA a confirmer visuellement.');
    }
    await settleAndShoot(tester, P, '19_checklist_coche');

    // --- Etape 8 : demarre ---
    await _goHome(tester, P);
    // Le CTA « Demarrer la randonnee » est porte par la HubTrekCard, EN HAUT du
    // cockpit : on remonte en tete de la liste avant de le chercher (la liste
    // lazy ne construit pas les widgets hors ecran).
    await _scrollToTop(tester, P);
    final startCta = textFrEn('Démarrer la randonnée', 'Start the trek');
    await scrollUntil(tester, startCta, P, 'demarrer',
        'CTA Demarrer la randonnee (haut du cockpit)');
    final started = await tapIfPresent(
        tester, startCta, P, 'demarrer', 'CTA Demarrer la randonnee');
    if (!started) {
      await tapIfPresent(tester, find.byIcon(Icons.play_arrow), P, 'demarrer',
          'CTA Demarrer (icone play)', warnIfMissing: false);
    }
    await settleAndShoot(tester, P, '20_demarrage');
    _logLocation(tester, P, 'apres_demarrage');

    logStep(P, 'fin', 'Scenario S1 termine');
    await flushJournal(P);
  });
}

/// Retour arriere (bouton back de l AppBar ou pop du routeur).
Future<void> _back(WidgetTester tester, String persona, String etape) async {
  final backBtn = find.byTooltip('Retour');
  if (present(backBtn)) {
    await tester.tap(backBtn.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
    logStep(persona, etape, 'RETOUR via bouton back');
    return;
  }
  final ctx = tester.element(find.byType(Navigator).first);
  final router = GoRouter.maybeOf(ctx);
  if (router != null && router.canPop()) {
    router.pop();
    await pumpAndSettleTolerant(tester);
    logStep(persona, etape, 'RETOUR via GoRouter.pop');
  } else {
    logStep(persona, etape, 'RETOUR impossible (pas de page a depiler)');
  }
}

/// Force le retour au cockpit /home (accueil terrain).
Future<void> _goHome(WidgetTester tester, String persona) async {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    if (router != null) {
      router.go('/home');
      await pumpAndSettleTolerant(tester);
      logStep(persona, 'nav', 'Retour cockpit /home');
    }
  } catch (e) {
    logStep(persona, 'nav', 'Retour /home impossible : $e');
  }
}

/// Retour a l accueil « Mes treks » (chemin utilisateur d entree cockpit).
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

/// Heuristique : l ecran carte (MapScreen) est-il monte ?
bool _onMap(WidgetTester tester) {
  return present(find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'FlutterMap')) ||
      present(find.text('Étape en cours'));
}

/// Remonte en tete de la 1re liste defilante (fling vers le bas repete).
Future<void> _scrollToTop(WidgetTester tester, String persona) async {
  if (find.byType(Scrollable).evaluate().isEmpty) return;
  final scroller = find.byType(Scrollable).first;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scroller, const Offset(0, 600));
    await pumpAndSettleTolerant(tester);
  }
  logStep(persona, 'nav', 'Remontee en tete du cockpit');
}

/// Trace la localisation courante du routeur (signal QA precis).
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

/// Cherche un libelle de verdict de faisabilite visible et le LOGue.
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
  logStep(persona, 'verdict',
      'Aucun libelle de verdict standard visible (profil peut-etre incomplet) '
      '— voir capture 13_verdict');
}
