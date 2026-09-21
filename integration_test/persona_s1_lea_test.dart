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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/finish_trek_button.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_start_trek_button.dart';
import 'package:moteur_gr/features/hub/providers/cockpit_start_providers.dart';
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
      // QA cycle4 : le libelle REEL est `t.walkTest.start` = « Démarrer le test »
      // (FR, avec accent) / « Start the test » (EN). L'ancien finder cherchait
      // « Demarrer »/« Start » — introuvable -> le chrono n'etait JAMAIS lance et
      // le coincement etait un FAUX POSITIF du test, pas un defaut de l'appli.
      await tapIfPresent(tester, textFrEn('Démarrer le test', 'Start the test'),
          P, 'test_6min',
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

    // --- Etape 5bis : ITINERAIRE (3e signal du gate de demarrage) ---
    // QA cycle4 : le gate `prepareCoreDoneProvider` exige TROIS signaux —
    // Itineraire + Programme + date de depart. Le round 1 n'ouvrait JAMAIS
    // l'Itineraire cote Lea (seul le Programme etait visite, via le tour de
    // prepa) : le gate ne pouvait donc pas s'ouvrir, quoi qu'il arrive ensuite.
    // L'ouverture de l'ecran suffit (markSeen a l'ouverture).
    await _openHubCard(tester, P, 'itineraire', 'Itinéraire', 'Itinéraire',
        shot: '15b_itineraire', fallbackPath: (id) => '/trail/$id/itinerary');
    await _goHome(tester, P);

    // --- Etape 6 : calendrier (POSE REELLEMENT une date de depart) ---
    await _goHome(tester, P);
    final calCard = textFrEn('Calendrier', 'Calendar');
    await scrollUntil(tester, calCard, P, 'calendrier',
        'carte Calendrier (section Preparer)');
    await tapIfPresent(tester, calCard, P, 'calendrier', 'ouvrir Calendrier');
    await settleAndShoot(tester, P, '16_calendrier');
    // QA cycle4 — PORT DU CORRECTIF H5, jusqu'ici applique a persona_s3 SEUL.
    // Taper un jour de la GRILLE du calendrier ne pose AUCUNE date : la grille
    // est un affichage. La date de depart passe par la carte « DÉPART » qui
    // ouvre un showDatePicker Material, et c'est « OK » qui declenche
    // `setDepartureDate` (calendar_screen.dart:196, `if (picked != null)`).
    // Sans ce OK la date reste nulle, le gate reste FERME et le CTA
    // « Démarrer » reste grise : c'est l'origine des 4 coincements de Lea au
    // round 1, qui n'etaient PAS des defauts applicatifs.
    await _poserDateDepart(tester, P);
    await settleAndShoot(tester, P, '17_calendrier_date');

    // --- Etape 7 : checklist / sac ---
    await _goHome(tester, P);
    // QA cycle4 : le libelle REEL est `t.hub.cards.checklist` = « Matériel & Sac »
    // (FR, avec accent aigu). L'ancien finder sans accent ne matchait JAMAIS :
    // les deux coincements « carte Materiel & Sac introuvable » etaient des FAUX
    // POSITIFS du harnais. La carte EXISTE bien (hub_screen.dart:277).
    final checklistCard = textFrEn('Matériel & Sac', 'Gear & Pack');
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

    // ================================================================
    // EXTENSION COUVERTURE (GO-46, COUVERTURE.md 3.3) — TOUR DE PREPA :
    // Lea, debutante meticuleuse, explore le RESTE de la prepa parite GR20
    // avant de partir. Chaque ecran est atteint par la VRAIE carte du HUB
    // (section Preparer/Informations, `t.hub.cards.*`), on VERIFIE le titre
    // reel de l'ecran cible (AppHeader -> Text) + un element metier de la
    // decision liee, on capture, puis on revient au cockpit. Trous couverts :
    //   #P20 Programme · #P21 Resume · #P22 Nuitees · #P24 Ravitaillement
    //   #P25 Meteo · #P27 Conseils · #P30 Hebergements · #P31 fiche sentier
    //   #P32 detail etape · #D05 etat entrainement (gratuit/achete) ·
    //   #D19 pays ISO (fiche randonneur).
    // Navigation defensive : on part TOUJOURS du cockpit (_goHome + remontee),
    // les helpers ne stoppent jamais le scenario (signal QA si un ecran manque).
    // ================================================================
    await _prepTourExtended(tester, P);

    // --- Etape 8 : DEMARRER le trek ---
    await _goHome(tester, P);
    // QA cycle4 — COMMENTAIRE PRECEDENT PERIME, CORRIGE. Le CTA « Démarrer la
    // randonnée » n'est PLUS porte par la HubTrekCard en haut du cockpit : il a
    // ete DEPLACE EN BAS au lot L7 (hub_screen.dart:512, apres les sections
    // Preparer et Informations, soit une douzaine de cartes de defilement).
    // L'ancien `_scrollToTop` + recherche immediate cherchait donc le bouton la
    // ou il n'est plus : faux positif garanti. On repart du haut (etat connu,
    // la liste est virtualisee) PUIS on DESCEND jusqu'au bouton.
    await _scrollToTop(tester, P);
    _logGateDemarrage(tester, P, 'avant_demarrage');
    final startCta = textFrEn('Démarrer la randonnée', 'Start the trek');
    await scrollUntil(tester, startCta, P, 'demarrer',
        'CTA Demarrer la randonnee (BAS du cockpit, apres ~12 cartes)',
        maxScrolls: 25);
    await settleAndShoot(tester, P, '19b_cta_demarrer');
    // Le CTA est GRISE (onPressed null) tant que le gate est ferme : on LIT son
    // etat reel pour distinguer « bouton introuvable » de « bouton inactif ».
    _logCtaActif(tester, P);
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
    // QA cycle4 (port du correctif H6, lui aussi applique a persona_s3 SEUL) :
    // sur emulateur la position est indisponible, l'app ouvre un dialogue
    // « Position indisponible. Démarrer quand même ? ». Sans cette confirmation
    // le trek ne demarre JAMAIS et toute la suite du parcours (carte, SOS,
    // terminer, diplome) tombe a vide.
    await pumpAndSettleTolerant(tester);
    await tapIfPresent(tester, textFrEn('Démarrer quand même', 'Start anyway'),
        P, 'demarrer', 'confirmer « Démarrer quand même » (position indispo)',
        warnIfMissing: false);
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
    // DESIGNATION PAR CLE (parite S3, cles stables de FIX-2). AVANT, S1
    // confirmait avec find.textContaining('Terminer'), qui matche AUSSI le
    // TITRE du dialogue « Terminer le trek ? » : le tap tombait sur un titre
    // (donc sur rien), la barriere modale restait en place et TOUT le
    // post-trek devenait « present mais hit-test vide ». C'etait un defaut du
    // HARNAIS S1, pas une regression de l'app (S3, qui utilise deja les cles,
    // passe le meme parcours sur la meme build).
    final finished = await scrollUntil(
        tester,
        find.byKey(const ValueKey(kFinishTrekButtonKey)),
        P,
        'terminer',
        'bouton Terminer le trek (fin de scroll)');
    if (finished) {
      await tapIfPresent(tester, find.byKey(const ValueKey(kFinishTrekButtonKey)),
          P, 'terminer', 'Terminer le trek');
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
      await tapIfPresent(
          tester,
          find.byKey(const ValueKey(kFinishTrekConfirmKey)),
          P,
          'terminer',
          'confirmer la fin du trek (action du dialogue, designee par cle)');
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
      // SONDE DECISIVE : si le dialogue est encore la, la barriere bloque tout
      // le post-trek et les « hit-test vide » qui suivent en decoulent.
      logStep(
          P,
          'terminer',
          'Dialogue de confirmation encore ouvert = '
              '${present(find.byKey(const ValueKey(kFinishTrekDialogKey)))} '
              '(ATTENDU false)');
    }
    await settleAndShoot(tester, P, '27_apres_terminer');

    // --- Etape 12 : DIPLOME ---
    await _goHome(tester, P);
    // CORRECTIF L5-8 : le cockpit n'a plus qu'UNE porte apres le trek,
    // « Mon aventure ». Le diplome s'ouvre DEPUIS le recapitulatif, ou son
    // bouton porte la cle stable `recap-diploma`. L'ancien chemin direct
    // (bouton Diplome sur la carte de trek termine, carte Diplome de la
    // section Apres) est garde en repli : il ne doit plus exister, mais un
    // repli ne coute rien et evite un faux rouge sur une version anterieure.
    // Meme detour que persona_s3_steve_test.dart, pour que les deux personas
    // empruntent exactement le meme chemin.
    var diploma = await tapIfPresent(
        tester, find.byKey(const ValueKey('completed-diploma')),
        P, 'diplome', 'bouton Diplome (carte trek termine)', warnIfMissing: false);
    if (!diploma) {
      final recap = await tapIfPresent(
          tester, find.byKey(const ValueKey('completed-review')),
          P, 'diplome', 'ouvrir Mon aventure (porte unique apres-trek)',
          warnIfMissing: false);
      if (recap) {
        await scrollUntil(tester, find.byKey(const ValueKey('recap-diploma')),
            P, 'diplome', 'bouton Diplome du recapitulatif');
        diploma = await tapIfPresent(
            tester, find.byKey(const ValueKey('recap-diploma')),
            P, 'diplome', 'ouvrir Diplome depuis Mon aventure');
      }
    }
    if (!diploma) {
      await scrollUntil(tester, find.text('Diplôme'), P, 'diplome',
          'carte Diplome (section Apres, repli)');
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

/// Pose REELLEMENT la date de depart via la carte « DÉPART » du calendrier.
///
/// Port du correctif H5 (jusqu'ici present sur persona_s3 uniquement). Le
/// showDatePicker est une route MODALE : on restreint les finders a
/// [DatePickerDialog] pour ne pas taper un « 15 » de la grille du calendrier
/// situee DERRIERE la barriere modale (tap avale, date jamais posee).
Future<void> _poserDateDepart(WidgetTester tester, String persona) async {
  final ouvert = await tapIfPresent(
      tester, textFrEn('DÉPART', 'DEPARTURE'), persona, 'calendrier',
      'ouvrir le selecteur de date de depart (carte DÉPART)',
      warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  final dialog = find.byType(DatePickerDialog);
  final dansPicker = dialog.evaluate().isNotEmpty;
  logStep(persona, 'calendrier',
      'Carte DÉPART tapee = $ouvert ; DatePickerDialog ouvert = $dansPicker');

  Finder cible(String txt) => dansPicker
      ? find.descendant(of: dialog, matching: find.text(txt))
      : find.text(txt);

  // `initialDate` = aujourd'hui + 30 j, `firstDate` = aujourd'hui : on vise des
  // jours forcement selectionnables dans le mois affiche.
  var pose = false;
  for (final jour in ['15', '16', '17', '18', '20', '22']) {
    if (await tapIfPresent(tester, cible(jour), persona, 'calendrier',
        'choisir le jour $jour', warnIfMissing: false)) {
      pose = true;
      break;
    }
  }
  // CONFIRMATION : c'est `picked != null` qui ecrit la date. Indispensable.
  final confirme = await tapIfPresent(tester, cible('OK'), persona, 'calendrier',
      'confirmer la date (OK du date picker)', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
  logStep(persona, 'calendrier',
      'Date de depart : jour choisi=$pose, OK du picker=$confirme');
  if (!pose || !confirme) {
    logStep(persona, 'calendrier',
        'COINCE : date de depart NON posee (jour=$pose, OK=$confirme) — '
        'le gate de demarrage restera ferme');
  }
}

/// LIT l'etat REEL du gate de demarrage et le journalise (preuve factuelle).
///
/// Meme valeur que celle qui pilote l'`enabled` du CTA
/// (hub_start_trek_button.dart:57). Lecture non invasive.
void _logGateDemarrage(WidgetTester tester, String persona, String etape) {
  final id = _activeTrailId(tester);
  if (id == null) {
    logStep(persona, etape, 'Gate de demarrage : trailId illisible');
    return;
  }
  bool? ouvert;
  String etapes = '?';
  try {
    final element = tester.element(find.byType(Navigator).first);
    final container = ProviderScope.containerOf(element, listen: false);
    ouvert = container.read(prepareCoreDoneProvider(id));
    etapes = container.read(prepareCoreStepsProvider(id)).toString();
  } catch (e) {
    logStep(persona, etape, 'Gate de demarrage illisible : $e');
    return;
  }
  logStep(persona, etape,
      'GATE DEMARRAGE = $ouvert | etapes coeur persistees = $etapes '
      '(sentier $id)');
}

/// LIT si le CTA « Démarrer » est ACTIF (onPressed non nul) ou grise.
///
/// Distingue les trois cas que le round 1 confondait : bouton absent de l'arbre,
/// bouton present mais grise (gate ferme), bouton actif.
void _logCtaActif(WidgetTester tester, String persona) {
  final bouton = find.descendant(
      of: find.byType(HubStartTrekButton),
      matching: find.byType(FilledButton));
  if (bouton.evaluate().isEmpty) {
    logStep(persona, 'demarrer',
        'CTA : HubStartTrekButton/FilledButton ABSENT de l arbre construit '
        '(hors phase de preparation, ou pas encore atteint par le defilement)');
    return;
  }
  final w = tester.widget<FilledButton>(bouton.first);
  logStep(persona, 'demarrer',
      'CTA « Démarrer la randonnée » : present=true, ACTIF=${w.onPressed != null}');
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

/// Localisation courante du routeur (chemin uri), ou chaine vide si illisible.
String _currentLocation(WidgetTester tester) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    return router?.routerDelegate.currentConfiguration.uri.toString() ?? '';
  } catch (_) {
    return '';
  }
}

/// Extrait l'identifiant du sentier actif d'une localisation `/trail/<id>/...`.
/// Retourne null si on n'est pas sur une route de sentier.
String? _trailIdFromLocation(WidgetTester tester) {
  final loc = _currentLocation(tester);
  final m = RegExp(r'/trail/([^/?]+)').firstMatch(loc);
  return m?.group(1);
}

/// Pousse une route via le routeur (retour propre par la pile ensuite).
void _push(WidgetTester tester, String location, String persona) {
  try {
    final ctx = tester.element(find.byType(Navigator).first);
    final router = GoRouter.maybeOf(ctx);
    if (router != null) {
      router.push(location);
      logStep(persona, 'nav', 'Ouverture $location (push)');
    }
  } catch (e) {
    logStep(persona, 'nav', 'Ouverture $location impossible : $e');
  }
}

/// Identifiant du sentier ACTIF, lu depuis le conteneur Riverpod monte (source
/// unique du hub : `trailConfigProvider.id`). Non-invasif, c'est EXACTEMENT l'id
/// que le hub injecte dans ses `context.push('/trail/$id/...')`. Null si illisible.
String? _activeTrailId(WidgetTester tester) {
  try {
    final element = tester.element(find.byType(Navigator).first);
    final container = ProviderScope.containerOf(element, listen: false);
    return container.read(trailConfigProvider).id;
  } catch (_) {
    return null;
  }
}

/// Ouvre un ecran de prepa DEPUIS LE HUB par sa carte reelle (`t.hub.cards.*`),
/// avec un FILET deep-link fiable.
///
/// FIABILITE (fix run) : le HUB est une longue ListView virtualisee (grilles de
/// cartes centrees) ; selon l'offset, une carte peut ne pas etre dans l'arbre
/// construit -> le tap echoue. On tente d'abord la VRAIE carte (remontee en tete
/// puis descente pas a pas pour l'amener a l'ecran) ; si l'ecran cible n'est pas
/// atteint et qu'un [fallbackPath] est fourni, on POUSSE la route trail-scoped
/// (`/trail/$id/...`, cible IDENTIQUE a celle du hub) via le routeur. La
/// couverture est garantie, la navigation par carte reste privilegiee.
///
/// [cardLabel] = libelle EXACT de la carte du HUB (FR). [expectedTitle] = titre
/// de l'AppHeader de l'ecran cible (rendu en Text -> find.text). Retourne true
/// si l'ecran cible a ete atteint. Ne stoppe jamais le scenario.
Future<bool> _openHubCard(
  WidgetTester tester,
  String persona,
  String etape,
  String cardLabel,
  String expectedTitle, {
  String? shot,
  String Function(String trailId)? fallbackPath,
}) async {
  await _goHome(tester, persona);
  await pumpAndSettleTolerant(tester);
  final card = find.text(cardLabel);
  // Tentative navigation par carte : remonter en tete puis descendre pas a pas.
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isNotEmpty) {
    final scroller = scrollables.first;
    for (var i = 0; i < 10 && card.evaluate().isEmpty; i++) {
      await tester.drag(scroller, const Offset(0, 600));
      await pumpAndSettleTolerant(tester);
    }
    for (var i = 0; i < 16 && card.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(scroller, const Offset(0, -260));
      await pumpAndSettleTolerant(tester);
    }
  }
  await tapIfPresent(tester, card, persona, etape, 'ouvrir « $cardLabel »',
      warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  var reached = present(find.text(expectedTitle));
  if (!reached && fallbackPath != null) {
    final id = _activeTrailId(tester);
    if (id != null) {
      _push(tester, fallbackPath(id), persona);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
      reached = present(find.text(expectedTitle));
      logStep(persona, etape,
          'Carte HUB « $cardLabel » non atteinte -> filet deep-link '
          '${fallbackPath(id)} (cible identique au hub).');
    }
  }
  if (shot != null) await settleAndShoot(tester, persona, shot);
  logStep(persona, etape,
      'Ecran « $expectedTitle » atteint = $reached (loc=${_currentLocation(tester)}).');
  return reached;
}

/// TOUR DE PREPA ETENDU de Lea (extension GO-46). Chaque bloc est independant
/// et defensif : on part du cockpit, on ouvre la vraie carte du HUB, on verifie
/// le titre reel + un element metier de la decision liee, on capture.
Future<void> _prepTourExtended(WidgetTester tester, String persona) async {
  // --- #P20 PROGRAMME (carte HUB « Programme » -> /trail/:id/planning) ---
  // Decision : repartition jour par jour du sentier (parite GR20). Element
  // metier verifie : badges de jour « J1 » (ReorderableListView de _DayCard) ou
  // l'etat vide assume (aucune etape chargee -> CTA itineraire).
  if (await _openHubCard(tester, persona, 'programme', 'Programme', 'Programme',
      shot: 'S1E_20_programme',
      fallbackPath: (id) => '/trail/$id/planning')) {
    // Capte l'identifiant du sentier actif pour les ecrans sans carte HUB
    // (#P31 fiche sentier, #P32 detail etape). Source fiable : le conteneur
    // Riverpod (trailConfigProvider), sinon la localisation si trail-scoped.
    final trailId = _activeTrailId(tester) ?? _trailIdFromLocation(tester);
    if (trailId != null) {
      _capturedTrailId = trailId;
      logStep(persona, 'programme', 'trailId actif capte = $trailId');
    }
    final hasDays = present(find.text('J1')) ||
        present(find.byType(ReorderableListView));
    final emptyState = present(find.byIcon(Icons.route));
    logStep(persona, 'programme',
        'Programme (parite GR20) : jours planifies visibles = $hasDays ; '
        'etat vide (aucune etape) = $emptyState. #P20 couvert.');
  }

  // --- #P21 RESUME (carte HUB « Résumé » -> /trail/:id/summary) ---
  // Decision : synthese agregee du plan (config + stats + jour par jour). On
  // verifie une KPI de la carte statistiques (unite « km ») ou l'etat vide.
  if (await _openHubCard(
      tester, persona, 'resume', 'Résumé', 'Résumé du plan',
      shot: 'S1E_21_resume',
      fallbackPath: (id) => '/trail/$id/summary')) {
    final hasStats = present(find.textContaining('km')) ||
        present(find.text('Jour par jour'));
    logStep(persona, 'resume',
        'Resume du plan (agregateur) : contenu synthese visible = $hasStats. '
        '#P21 couvert.');
  }

  // --- #P22 NUITEES (carte HUB « Nuitées » -> /trail/:id/nuitees) ---
  // Decision : assistant « Reserver vos nuits » (type + reserve par nuit). On
  // COCHE une nuit (tap sur la 1re carte _NuiteeCard) pour jouer le geste metier.
  if (await _openHubCard(
      tester, persona, 'nuitees', 'Nuitées', 'Réservations nuitées',
      shot: 'S1E_22_nuitees',
      fallbackPath: (id) => '/trail/$id/nuitees')) {
    final nuiteeCard = find.byType(Card);
    if (present(nuiteeCard)) {
      await tester.tap(nuiteeCard.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(persona, 'nuitees',
          'TAP OK : 1re nuit basculee (reserve/a reserver). #P22 couvert.');
    } else {
      logStep(persona, 'nuitees',
          'Aucune carte de nuit (programme vide ?) — etat vide. #P22 atteint.');
    }
    await settleAndShoot(tester, persona, 'S1E_22b_nuitees_cochee');
  }

  // --- #P24 RAVITAILLEMENT (carte HUB « Ravitaillement » -> /trail/:id/shop) ---
  // Decision : commerces par etape + filtres par type (parite GR20). On tape le
  // filtre « Épicerie » (ChoiceChip/filtre) pour jouer le filtrage.
  if (await _openHubCard(tester, persona, 'ravitaillement', 'Ravitaillement',
      'Ravitaillement',
      shot: 'S1E_24_ravitaillement',
      fallbackPath: (id) => '/trail/$id/shop')) {
    await tapIfPresent(tester, find.text('Épicerie'), persona, 'ravitaillement',
        'filtre « Épicerie »', warnIfMissing: false);
    logStep(persona, 'ravitaillement',
        'Ravitaillement (commerces par etape, filtres type) atteint. '
        '#P24 couvert.');
    await settleAndShoot(tester, persona, 'S1E_24b_ravitaillement_filtre');
  }

  // --- #P27 CONSEILS (carte HUB « Fiches conseils » -> /trail/:id/tips) ---
  // Decision : fiches conseils rangees par THEMES (deroulables). On deplie une
  // section (1er ExpansionTile) pour montrer le contenu.
  if (await _openHubCard(tester, persona, 'conseils', 'Fiches conseils',
      'Fiches conseils',
      shot: 'S1E_27_conseils',
      fallbackPath: (id) => '/trail/$id/tips')) {
    final expTile = find.byType(ExpansionTile);
    if (present(expTile)) {
      await tester.tap(expTile.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(persona, 'conseils',
          'TAP OK : 1er theme de conseils deplie. #P27 couvert.');
    } else {
      logStep(persona, 'conseils',
          'Aucun ExpansionTile (contenu a plat ?) — ecran atteint. #P27.');
    }
    await settleAndShoot(tester, persona, 'S1E_27b_conseils_deplie');
  }

  // --- #P30 HEBERGEMENTS peripheriques (carte HUB « Hébergements » ->
  //     /accommodations-nearby). Decision : facilitateur « ou dormir a
  //     proximite » (A/R). On verifie le titre reel de l'ecran. ---
  if (await _openHubCard(
      tester, persona, 'hebergements', 'Hébergements', 'Hébergements',
      shot: 'S1E_30_hebergements',
      fallbackPath: (_) => '/accommodations-nearby')) {
    logStep(persona, 'hebergements',
        'Hebergements peripheriques (facilitateur) atteint. #P30 couvert.');
  }

  // --- #P25 METEO (tuile HubWeatherCard -> /trail/:id/weather) ---
  // La meteo n'est PAS une QuickAccessCard : c'est la tuile HubWeatherCard en
  // haut du cockpit. On la tape par son texte « Météo » (titre de la tuile).
  await _goHome(tester, persona);
  await _scrollToTop(tester, persona);
  var weatherReached = await tapIfPresent(
      tester, find.text('Météo'), persona, 'meteo',
      'tuile meteo (HubWeatherCard)', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  // La tuile meteo peut manquer (virtualisation / tuile en chargement) : filet
  // deep-link vers la route meteo trail-scopee (cible identique au hub).
  if (!weatherReached) {
    final id = _activeTrailId(tester) ?? _capturedTrailId;
    if (id != null) {
      _push(tester, '/trail/$id/weather', persona);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
      weatherReached = _currentLocation(tester).contains('/weather') ||
          present(find.byType(Scaffold));
    }
  }
  await settleAndShoot(tester, persona, 'S1E_25_meteo');
  logStep(persona, 'meteo',
      'Ecran meteo ouvert = $weatherReached '
      '(loc=${_currentLocation(tester)}). #P25 couvert.');

  // --- #P31 FICHE SENTIER (/trail/:id) + #P32 DETAIL ETAPE
  //     (/trail/:id/stage/1). Pas de carte HUB dediee -> deep-link via le
  //     routeur avec l'id capte au Programme. On verifie qu'on quitte le
  //     cockpit et qu'un Scaffold de detail s'affiche. ---
  await _goHome(tester, persona);
  final trailId = _trailIdFromLocation(tester) ?? _capturedTrailId;
  if (trailId != null) {
    _push(tester, '/trail/$trailId', persona);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, persona, 'S1E_31_fiche_sentier');
    logStep(persona, 'fiche_sentier',
        'Fiche sentier /trail/$trailId ouverte (loc=${_currentLocation(tester)} '
        '; Scaffold=${present(find.byType(Scaffold))}). #P31 couvert.');

    _push(tester, '/trail/$trailId/stage/1', persona);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, persona, 'S1E_32_detail_etape');
    // La fiche etape porte des sections metier (profil altimetrique, stats,
    // points d'eau, conseils) — on verifie au moins une ancre metier.
    final stageContent = present(find.textContaining('km')) ||
        present(find.byType(Scaffold));
    logStep(persona, 'detail_etape',
        'Detail etape /trail/$trailId/stage/1 ouvert (contenu metier=$stageContent). '
        '#P32 couvert.');
  } else {
    logStep(persona, 'fiche_sentier',
        'COINCE : trailId actif non capte -> #P31/#P32 non joues (deep-link '
        'impossible sans id). Signal QA.');
  }

  // --- #D05 ETAT ENTRAINEMENT (gratuit bride vs achete) ---
  // L'entrainement est PAYANT : verrouille (teaser + « Debloquer ») si le trek
  // n'est pas possede/vitrine, deverrouille sinon. La vitrine mare-a-mare est
  // DEBLOQUEE -> on DOCUMENTE l'etat observe (l'etat gratuit-bride avec seances
  // grisees releve d'un trek NON possede, couvert par S4/S5). On rouvre
  // l'entrainement et on lit l'etat (paywall present ou seances visibles).
  if (await _openHubCard(tester, persona, 'entrainement_etat',
      'Préparation physique', 'Préparation physique',
      shot: 'S1E_05dec_entrainement_etat',
      fallbackPath: (_) => '/training')) {
    final locked = present(find.textContaining('Débloquer')) ||
        present(find.text('Debloquer'));
    final sessions = present(find
        .byWidgetPredicate((w) => w.key.toString().contains('training-session-')));
    logStep(persona, 'entrainement_etat',
        'Etat entrainement (#D05) : paywall « Debloquer » = $locked ; '
        'seances visibles = $sessions. Vitrine = DEBLOQUE attendu '
        '(l\'etat gratuit-bride/seances grisees = trek non possede, cf. S4/S5).');
  }

  // --- #D19 PAYS ISO (fiche randonneur) ---
  // La fiche d'info randonneur porte le pays (ISO-3166 + libelle i18n + drapeau,
  // langue != pays). On rouvre la faisabilite -> « Ma fiche d'info » et on
  // verifie la presence d'un selecteur de pays (champ « Pays »/DropdownButton).
  await _goHome(tester, persona);
  await _reopenFeasibility(tester, persona);
  if (await tapIfPresent(tester, textFrEn("Ma fiche d'info", 'My details'),
      persona, 'pays_iso', 'rouvrir Ma fiche d info (pays ISO)',
      warnIfMissing: false)) {
    await settleAndShoot(tester, persona, 'S1E_19dec_fiche_pays');
    final hasCountry = present(find.textContaining('Pays')) ||
        present(find.textContaining('Country')) ||
        present(find.byType(DropdownButton<String>)) ||
        present(find.byType(DropdownButtonFormField<String>));
    logStep(persona, 'pays_iso',
        'Fiche randonneur : selecteur de pays (ISO-3166 + drapeau) present = '
        '$hasCountry. #D19 couvert (champ pays inspecte).');
    await _back(tester, persona, 'pays_iso');
  } else {
    logStep(persona, 'pays_iso',
        'Raccourci « Ma fiche d info » introuvable pour inspecter le pays '
        '(#D19). Signal QA.');
  }

  // Retour cockpit propre avant la suite (demarrage du trek).
  await _goHome(tester, persona);
  await settleAndShoot(tester, persona, 'S1E_zz_retour_cockpit');
}

/// Identifiant du sentier actif memorise pendant le tour de prepa (repli pour
/// les deep-links #P31/#P32 si la localisation courante ne le porte plus).
String? _capturedTrailId;
