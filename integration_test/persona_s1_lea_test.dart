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

    // --- Etape 3 : entree dans le sentier -> COCKPIT DE PREPARATION ---
    // FIX CYCLE 2 (issue 1) : « Entrer » ouvre desormais le COCKPIT (`/home`,
    // sections Preparer/Randonner/Apres), PAS la carte de navigation live. On
    // VERIFIE ce comportement corrige : apres le tap, on ne doit PAS etre sur la
    // carte terrain. La carte reste reservee au demarrage effectif du trek.
    final entered = await tapIfPresent(
        tester,
        find.byKey(const ValueKey('catalog-enter-mare-a-mare-centre')),
        P,
        'cockpit',
        'Entrer dans le sentier vitrine (cle catalog-enter)');
    if (!entered) {
      await tapIfPresent(tester, enterBtn, P, 'cockpit',
          'Entrer (1er sentier du catalogue)');
    }
    await settleAndShoot(tester, P, '07_apres_entrer');
    _logLocation(tester, P, 'apres_entrer');
    final onMapAfterEnter = _onMap(tester);
    logStep(
        P,
        'cockpit',
        'VERIF issue 1 : apres « Entrer », carte terrain = $onMapAfterEnter '
            '(ATTENDU false — « Entrer » catalogue -> cockpit /home, pas /map).');

    // Filet : si (regression) on atterrissait quand meme sur la carte, on
    // rejoint le cockpit par le chemin utilisateur (Mes treks -> trek possede).
    if (onMapAfterEnter) {
      await _goMyTreks(tester, P);
      await settleAndShoot(tester, P, '07b_mes_treks');
      final trekCard = find
          .byWidgetPredicate((w) => w.key.toString().contains('trek-summary-'));
      if (present(trekCard)) {
        await tester.tap(trekCard.first, warnIfMissed: false);
        await pumpAndSettleTolerant(tester);
        logStep(P, 'cockpit', 'Filet : carte de trek possede -> cockpit /home');
      } else {
        _goHome(tester, P);
      }
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
    // Verdict AVANT profil : le croisement produit deja un verdict reel (souvent
    // « Déconseillé » car aucune experience saisie -> ecart bloquant), mais la
    // SOURCE reste « questionnaire (en attendant votre profil) ». On capture cet
    // etat de depart pour comparaison avec le verdict APRES profil complet.
    _logVisibleVerdict(tester, P, phase: 'avant_profil');
    _logVerdictSource(tester, P, phase: 'avant_profil');

    // 4a — Fiche d info randonneur : REMPLIR la morpho (CYCLE 3). Valeurs demo
    // d'une debutante coherente (F, 32 ans, 165 cm, 62 kg -> IMC ~22,8 « normal »)
    // + consentement morpho (art. 9) pour constituer un PROFIL COMPLET, afin que
    // la faisabilite s'appuie sur le profil objectif (et non le fallback).
    if (await tapIfPresent(tester, textFrEn("Ma fiche d'info", 'My details'), P,
        'faisabilite', 'raccourci Ma fiche d info',
        warnIfMissing: false)) {
      await settleAndShoot(tester, P, '09_fiche_info');
      await _fillHikerProfile(tester, P);
      await settleAndShoot(tester, P, '09b_fiche_info_remplie');
      // « Enregistrer » repop vers la faisabilite (Navigator.pop dans _save).
      final saved = await tapIfPresent(
          tester, textFrEn('Enregistrer', 'Save'), P, 'fiche_info',
          'enregistrer la fiche morpho', warnIfMissing: false);
      logStep(P, 'fiche_info',
          'Fiche morpho remplie (age/taille/poids + consentement art.9) et '
          'enregistree = $saved. Profil desormais COMPLET pour la faisabilite.');
      await settleAndShoot(tester, P, '09c_apres_enregistrer_fiche');
      // Filet : si on n'est pas revenu sur la faisabilite, y retourner.
      if (!present(textFrEn('Ma fiche d\'info', 'My details')) &&
          !present(feasCard)) {
        await _back(tester, P, 'faisabilite');
      }
    } else {
      logStep(P, 'faisabilite',
          'Raccourci « Ma fiche d info » introuvable — capture pour analyse');
    }

    // 4b — Test 6 minutes : on OUVRE l'ecran et on DEMARRE pour observer le
    // mecanisme (compte a rebours -> chrono). MECANIQUE (documentee, regle L3) :
    // le test est un CHRONO WALL-CLOCK de 6:00 pile (`kWalkTestDuration`) qui
    // s'arrete AUTOMATIQUEMENT a 0 et calcule distance->niveau via le flux GPS
    // live (`WalkTestController`). Il n'existe AUCUN mode demo/fast-forward :
    // obtenir le resultat distance->niveau exige 6 minutes reelles de marche GPS.
    // On ne PRETEND donc PAS l'avoir joue en entier ; on capture le demarrage +
    // on documente. Le profil objectif reste alimente par les 5 randos (4c).
    if (await tapIfPresent(tester, textFrEn('Test 6 minutes', '6-minute test'), P,
        'faisabilite', 'raccourci Test 6 minutes',
        warnIfMissing: false)) {
      await settleAndShoot(tester, P, '10_test_6min');
      // Demarrer pour rendre le mecanisme OBSERVABLE (compte a rebours 3-2-1).
      await tapIfPresent(tester, textFrEn('Demarrer', 'Start'), P, 'test_6min',
          'demarrer le test 6 min (observation du chrono)', warnIfMissing: false);
      await settleAndShoot(tester, P, '10b_test_6min_demarre');
      logStep(P, 'test_6min',
          'Test 6 min OUVERT + demarrage observe (compte a rebours puis chrono). '
          'NON joue en entier : chrono wall-clock de 6:00 a arret auto, sans mode '
          'fast-forward -> resultat distance->niveau exige 6 min de marche GPS '
          'reelle, hors rejeu rapide (mecanisme documente, regle L3).');
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
      // Revenir sur la faisabilite pour la reouvrir proprement.
      if (!present(feasCard)) {
        await _back(tester, P, 'faisabilite');
      }
    }

    // 4d — CYCLE 3 : ROUVRIR la faisabilite avec le PROFIL COMPLET (morpho + 1
    // rando) et CAPTURER le VRAI verdict croise + sa SOURCE. Le croisement lit
    // desormais le profil objectif (au moins une rando saisie -> usedObjective
    // profile=true) : la SOURCE doit basculer sur « Base sur votre profil
    // objectif », et le verdict est l'un des libelles standard (Déconseillé /
    // Préparation nécessaire / Faisable). On passe par le routeur pour repartir
    // d'un etat propre (invalide les providers -> recalcul).
    await _goHome(tester, P);
    await _reopenFeasibility(tester, P);
    await settleAndShoot(tester, P, '12c_faisabilite_verdict_reel');
    final verdictReel = _logVisibleVerdict(tester, P, phase: 'apres_profil');
    _logVerdictSource(tester, P, phase: 'apres_profil');
    logStep(P, 'verdict',
        'VERDICT REEL (profil complet) capture = ${verdictReel ?? "(non lu)"} '
        '— voir capture 12c_faisabilite_verdict_reel.');

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

    // --- Etape 8 : DEMARRER le trek ---
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
      // Trek deja actif d'un run precedent -> « Reprendre la navigation ».
      await tapIfPresent(tester,
          textFrEn('Reprendre la navigation', 'Resume navigation'), P,
          'demarrer', 'Reprendre la navigation (trek deja actif)',
          warnIfMissing: false);
    }
    // Conflit trek (C4) : un autre trek tourne -> resoudre (Terminer l'autre).
    await tapIfPresent(tester, find.textContaining('Terminer'), P, 'demarrer',
        'resoudre conflit trek (Terminer l autre)', warnIfMissing: false);
    await _observe(tester, const Duration(seconds: 2));
    await settleAndShoot(tester, P, '20_demarrage');
    _logLocation(tester, P, 'apres_demarrage');

    // ================================================================
    // CIRCUIT COMPLET (directive Chris 12/09) — Lea vit AUSSI la phase
    // RANDONNER puis APRES-TREK, dans le meme parcours continu :
    //   MARCHER (GPS injecte) -> SOS -> TERMINER -> DIPLOME -> JOURNAL
    //   (souvenir) -> RECAP.
    // ================================================================

    // --- Etape 9 : MARCHER — s'assurer d'etre sur la CARTE ---
    // Le demarrage (HubTrekCard) pousse /map une fois les permissions resolues
    // (pre-accordees via adb au lancement). Filet : sinon on force la carte.
    if (!_onMap(tester)) {
      _goMap(tester, P);
      await _observe(tester, const Duration(seconds: 1));
    }
    await settleAndShoot(tester, P, '21_carte');
    logStep(
        P,
        'carte',
        'Sur la carte = ${_onMap(tester)} ; FlutterMap present = '
            '${present(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'FlutterMap'))}.');

    // Fenetre d'injection GPS (~40 s) : l'hote pousse les points du trace via
    // `adb emu geo fix` (tool/persona_s3_geo_push.py). On observe + on capture le
    // suivi (carte qui suit, barre d'etape, distance restante).
    logStep(P, 'gps',
        'DEBUT fenetre injection GPS (~40 s). Observation + captures periodiques.');
    for (var i = 0; i < 8; i++) {
      await _observe(tester, const Duration(seconds: 5));
      await settleAndShoot(tester, P, '22_gps_tick_${i.toString().padLeft(2, '0')}',
          timeout: const Duration(seconds: 2));
      final suivi = _firstTextMatching(tester,
          RegExp(r'\betape\b|\bEtape\b|\bkm\b|restant', caseSensitive: false));
      logStep(P, 'gps',
          'tick $i — indice suivi visible: ${suivi ?? "(aucun texte etape/km capte)"}');
    }
    logStep(P, 'gps', 'FIN fenetre injection GPS');
    await settleAndShoot(tester, P, '23_apres_gps');

    // --- Etape 10 : SOS (acces unique aligne GR20, overlay heroTag sos_e515) ---
    final sos = find.byWidgetPredicate((w) =>
        w is FloatingActionButton && (w.heroTag == 'sos_e515'));
    logStep(P, 'sos',
        'FAB SOS overlay present = ${present(sos)}.');
    var sosTapped = false;
    if (present(sos)) {
      await tester.tap(sos.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      sosTapped = true;
      logStep(P, 'sos', 'TAP OK : bouton SOS (overlay carte)');
    } else {
      logStep(P, 'sos',
          'COINCE : overlay SOS introuvable (trek non actif ?) — capture pour analyse');
    }
    await settleAndShoot(tester, P, '24_sos_dialog');
    if (sosTapped) {
      logStep(
          P,
          'sos',
          'Dialog SOS ouvert = ${present(find.byType(Dialog)) || present(find.byType(AlertDialog))}. '
              'On NE confirme PAS l appel 112 (pas d appel reel en test).');
      await tapIfPresent(tester, find.textContaining('Annuler'), P, 'sos',
          'fermer le dialog SOS (Annuler)', warnIfMissing: false);
      if (present(find.byType(Dialog)) || present(find.byType(AlertDialog))) {
        await tester.tapAt(const Offset(20, 20));
        await pumpAndSettleTolerant(tester);
      }
    }
    await settleAndShoot(tester, P, '25_apres_sos');

    // --- Etape 11 : TERMINER le trek ---
    // IMPORTANT (fiabilite) : terminer le trek ARRETE le service GPS de fond ->
    // plus d'isolate vivant au teardown -> le run se cloture proprement.
    await _goHome(tester, P);
    await settleAndShoot(tester, P, '26_cockpit_fin');
    final finished = await scrollUntil(tester, find.textContaining('Terminer'),
        P, 'terminer', 'bouton Terminer le trek (fin de scroll)');
    if (finished) {
      await tapIfPresent(tester, find.textContaining('Terminer'), P, 'terminer',
          'Terminer le trek');
      // Confirmer si une boite de dialogue de confirmation apparait.
      await tapIfPresent(tester, find.textContaining('Terminer'), P, 'terminer',
          'confirmer fin de trek', warnIfMissing: false);
    }
    await settleAndShoot(tester, P, '27_apres_terminer');

    // --- Etape 12 : DIPLOME ---
    await _goHome(tester, P);
    var diploma = await tapIfPresent(
        tester, find.byKey(const ValueKey('completed-diploma')),
        P, 'diplome', 'bouton Diplome (carte trek termine)', warnIfMissing: false);
    if (!diploma) {
      await scrollUntil(tester, find.text('Diplôme'), P, 'diplome',
          'carte Diplome (section Apres)');
      diploma = await tapIfPresent(
          tester, find.text('Diplôme'), P, 'diplome', 'ouvrir Diplome');
    }
    await settleAndShoot(tester, P, '28_diplome');
    _logLocation(tester, P, 'diplome');
    logStep(P, 'diplome', 'Diplome ouvert = $diploma.');

    // --- Etape 13 : APRES-TREK — Journal « Vos notes et souvenirs » ---
    await _goHome(tester, P);
    final journalCard = textFrEn('Journal', 'Journal');
    await scrollUntil(tester, journalCard, P, 'apres_journal',
        'carte Journal (Vos notes et souvenirs)');
    await tapIfPresent(tester, journalCard, P, 'apres_journal',
        'ouvrir le Journal', warnIfMissing: false);
    await settleAndShoot(tester, P, '29_journal_ouvert');
    _logLocation(tester, P, 'apres_journal');
    // Ouvrir le dialog d'ajout de note (FloatingActionButton + du journal).
    await tapIfPresent(tester, find.byIcon(Icons.add), P, 'apres_journal',
        'bouton + (ajouter une note/souvenir)', warnIfMissing: false);
    await settleAndShoot(tester, P, '30_journal_add_dialog');
    // Saisir un vrai souvenir de debutante dans le champ texte du dialog.
    final noteField = find.byType(TextField);
    const souvenir =
        'Ma toute premiere rando bouclee. Fiere de moi, la vue valait chaque pas !';
    if (present(noteField)) {
      await tester.enterText(noteField.first, souvenir);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'apres_journal', 'SAISIE souvenir : "$souvenir"');
    } else {
      logStep(P, 'apres_journal',
          'COINCE : champ de saisie de note introuvable dans le dialog');
    }
    await settleAndShoot(tester, P, '31_journal_note_saisie');
    final noteSaved = await tapIfPresent(
        tester, textFrEn('Enregistrer', 'Save'), P, 'apres_journal',
        'enregistrer le souvenir', warnIfMissing: false);
    await settleAndShoot(tester, P, '32_journal_note_enregistree');
    final noteVisible = present(find.textContaining('premiere rando'));
    logStep(P, 'apres_journal',
        'Souvenir enregistre = $noteSaved ; visible dans le journal = '
        '$noteVisible (le journal n\'est plus vide -> apres-trek couvert).');

    // --- Etape 14 : APRES-TREK — Recap « Mon aventure » ---
    await _goHome(tester, P);
    final recapCard = textFrEn('Récapitulatif', 'Recap');
    await scrollUntil(tester, recapCard, P, 'apres_recap',
        'carte Recapitulatif (Votre aventure en resume)');
    final recapOpened = await tapIfPresent(tester, recapCard, P, 'apres_recap',
        'ouvrir le recap post-trek', warnIfMissing: false);
    await settleAndShoot(tester, P, '33_recap_apres_trek');
    _logLocation(tester, P, 'apres_recap');
    final recapContent = present(find.text('Votre aventure')) ||
        present(find.text('Your adventure')) ||
        present(find.textContaining('Statistiques')) ||
        present(find.textContaining('Statistics'));
    logStep(P, 'apres_recap',
        'Recap post-trek ouvert = $recapOpened ; contenu bilan visible = '
        '$recapContent.');

    logStep(P, 'fin',
        'Scenario S1 termine — CIRCUIT COMPLET (preparer -> randonner -> apres).');
    // Cloture propre : draine les artefacts de teardown (trek deja termine).
    await finalizeScenario(tester, P);
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

/// Force l ouverture de la carte via le routeur (phase RANDONNER du circuit).
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

/// Observation « live » : compose des frames pendant [d] sans exiger le repos
/// (la carte GL / le suivi GPS ne se stabilisent jamais completement).
Future<void> _observe(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Renvoie le 1er texte visible correspondant au motif (indice de suivi), ou null.
String? _firstTextMatching(WidgetTester tester, RegExp re) {
  final texts = find.byType(Text);
  for (final e in texts.evaluate()) {
    final w = e.widget as Text;
    final data = w.data ?? w.textSpan?.toPlainText();
    if (data != null && re.hasMatch(data)) return data;
  }
  return null;
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

/// Cherche un libelle de verdict de faisabilite visible, le LOGue et le renvoie.
///
/// [phase] documente le moment de la capture (avant/apres profil complet).
/// Retourne le libelle trouve, ou null si aucun.
String? _logVisibleVerdict(WidgetTester tester, String persona,
    {String phase = ''}) {
  const verdicts = <String>[
    'Déconseillé',
    'Préparation nécessaire',
    'Faisable',
    'Excellent',
  ];
  final tag = phase.isEmpty ? '' : ' [$phase]';
  for (final v in verdicts) {
    if (present(find.text(v))) {
      logStep(persona, 'verdict', 'VERDICT visible$tag = "$v"');
      return v;
    }
  }
  logStep(persona, 'verdict',
      'Aucun libelle de verdict standard visible$tag (profil peut-etre '
      'incomplet ou ecran en chargement) — voir capture.');
  return null;
}

/// LOGue la SOURCE du verdict affichee sous le badge (objectif vs fallback).
///
/// « Base sur votre profil objectif » = croisement reel (profil complet) ;
/// « Base sur le questionnaire (en attendant votre profil) » = fallback.
void _logVerdictSource(WidgetTester tester, String persona,
    {String phase = ''}) {
  final tag = phase.isEmpty ? '' : ' [$phase]';
  const objective = 'Base sur votre profil objectif';
  final fallback = find.byWidgetPredicate((w) =>
      w is Text && (w.data?.startsWith('Base sur le questionnaire') ?? false));
  if (present(find.text(objective))) {
    logStep(persona, 'verdict', 'SOURCE verdict$tag = PROFIL OBJECTIF (reel)');
  } else if (present(fallback)) {
    logStep(persona, 'verdict',
        'SOURCE verdict$tag = QUESTIONNAIRE (fallback, profil incomplet)');
  } else {
    logStep(persona, 'verdict',
        'SOURCE verdict$tag non lue (badge/fallback absent a l ecran).');
  }
}

/// Remplit la fiche morpho (CYCLE 3) : age/taille/poids + consentement art. 9.
///
/// Valeurs demo d'une debutante coherente. Cible les champs par label (FR/EN)
/// avec repli sur l'ordre des `TextFormField` (age, taille, poids). Active le
/// `SwitchListTile` de consentement morpho (obligatoire pour enregistrer la
/// morpho, art. 9 RGPD) — sans quoi `_save` ne persiste pas la morphologie.
Future<void> _fillHikerProfile(WidgetTester tester, String persona) async {
  // Saisie par label si possible (robuste a l'ordre), sinon par index.
  final byLabel = <String, String>{
    'Age': '32',
    'Taille': '165',
    'Poids': '62',
  };
  var filledByLabel = 0;
  // IMPORTANT : sous LiveTestWidgetsFlutterBinding (framePolicy fullyLive),
  // `enterText` est une API guardee qui DOIT etre awaitee — un `forEach` avec
  // closure synchrone declenche « Guarded function conflict » (2e enterText
  // avant la fin du 1er) et FAIT ECHOUER le scenario. On boucle donc en `for`
  // avec `await` sur chaque saisie.
  for (final entry in byLabel.entries) {
    final field = find.widgetWithText(TextFormField, entry.key);
    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field.first, entry.value);
      await pumpAndSettleTolerant(tester);
      filledByLabel++;
    }
  }
  if (filledByLabel >= 3) {
    logStep(persona, 'fiche_info',
        'SAISIE morpho par label : Age=32, Taille=165, Poids=62');
  } else {
    // Repli : les 3 premiers TextFormField = age, taille, poids (ordre du form).
    final fields = find.byType(TextFormField);
    const order = ['32', '165', '62'];
    final n = fields.evaluate().length;
    for (var i = 0; i < n && i < order.length; i++) {
      await tester.enterText(fields.at(i), order[i]);
      await pumpAndSettleTolerant(tester);
    }
    logStep(persona, 'fiche_info',
        'SAISIE morpho par index ($n champs) : 32/165/62 (repli label partiel=$filledByLabel)');
  }
  // Consentement morpho (art. 9) : activer le SwitchListTile s'il est off.
  final consentSwitch = find.byType(SwitchListTile);
  if (consentSwitch.evaluate().isNotEmpty) {
    final tile = tester.widget<SwitchListTile>(consentSwitch.first);
    if (tile.value != true) {
      await tester.tap(consentSwitch.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(persona, 'fiche_info',
          'Consentement morpho (art. 9) ACTIVE (requis pour enregistrer la morpho)');
    } else {
      logStep(persona, 'fiche_info', 'Consentement morpho deja actif');
    }
  } else {
    logStep(persona, 'fiche_info',
        'COINCE : SwitchListTile de consentement morpho introuvable');
  }
}

/// Rouvre l'ecran de faisabilite depuis le cockpit (CYCLE 3, capture verdict).
Future<void> _reopenFeasibility(WidgetTester tester, String persona) async {
  await _scrollToTop(tester, persona);
  final feasCard = textFrEn('Faisabilité', 'Feasibility');
  await scrollUntil(tester, feasCard, persona, 'faisabilite',
      'carte Faisabilite (reouverture verdict reel)');
  await tapIfPresent(tester, feasCard, persona, 'faisabilite',
      'rouvrir Faisabilite (verdict profil complet)');
  // Laisse le temps aux FutureProvider (profil/randos/trek) de recalculer.
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
}
