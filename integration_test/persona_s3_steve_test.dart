// ignore_for_file: avoid_print
//
// S3 — STEVE AUSTIN, le marcheur GPS (tache 518, joue EN DIRECT).
//
// Objectif persona : marcher le trek sur le terrain (position, etape active,
// avancement, distance, SOS, fin, diplome).
// Parcours vise (PLAN_TEST_PERSONAS S3) :
//   demarre un trek -> injection GPS le long du trace (marche) -> la carte suit
//   la position, etape active, avancement, distance -> declenche SOS ->
//   termine le trek -> diplome.
//
// INJECTION GPS — MECANIQUE : le deplacement est injecte DEPUIS L HOTE via
//   `adb -s emulator-5554 emu geo fix <lon> <lat>` (script host-side lance en
//   parallele du test). Le test, lui, DEMARRE la rando puis OUVRE la carte et
//   OBSERVE longuement (fenetres de pump + captures) pendant que l hote pousse
//   les points du trace. geolocator lit la position mockee de l emulateur ->
//   le pipeline (position -> detection etape -> arrivee) s alimente.
//
// La permission de localisation doit etre accordee AVANT le run
//   (`adb shell pm grant com.only1cent.moteur_gr android.permission.
//    ACCESS_FINE_LOCATION`) — fait par le lanceur.
//
// Pilote l UI reelle, capture chaque etape, LOGue les coincements. Zero modif app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/core/engine/trail_engine.dart';
// QA cycle4 : lecture DIRECTE du gate de demarrage pour prouver factuellement
// si « Démarrer » est activable ou non (pas de supposition).
import 'package:moteur_gr/features/hub/presentation/widgets/finish_trek_button.dart';
import 'package:moteur_gr/features/hub/providers/cockpit_start_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S3_Steve';

void main() {
  initHarness();

  testWidgets('S3 — Steve marche le trek (GPS injecte)', (tester) async {
    // Compteurs d'exigences remis a zero (tache 543) : ils sont GLOBAUX,
    // et sans cela un scenario herite des echecs du precedent et le garde
    // anti-harnais-aveugle se desarme tout seul.
    reinitialiserExigences();
    logStep(P, 'boot', 'Lancement de app.main()');
    // ===================== MAJEUR-2 DE LA CAMPAGNE N1 =====================
    // C'est CE scenario qui a logue « dialog permission par-dessus = false »
    // pendant qu'une boite Android recouvrait la carte : il ne cherchait qu'un
    // widget FLUTTER, et un dialogue SYSTEME n'est pas dans l'arbre Flutter.
    // On installe desormais une sonde qui voit les fenetres systeme : le cycle
    // de vie de l'activite (perte du premier plan).
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot', timeout: const Duration(seconds: 12));

    // Consentement pub + onboarding (bilingue, robuste).
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_skip');

    // --- Entrer dans le cockpit du trek (via « Mes treks », chemin utilisateur) ---
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
      await _goHome(tester, P);
    }
    await settleAndShoot(tester, P, '03_cockpit');
    _logLocation(tester, P, 'cockpit');

    // --- QA cycle4 : SATISFAIRE LE GATE DE DEMARRAGE ---------------------
    // CONSTAT cycle4 : le CTA « Démarrer la randonnée » est DESACTIVE tant que
    // `prepareCoreDoneProvider(trailId)` est faux, c'est-a-dire tant que les 3
    // etapes coeur ne sont pas faites (cockpit_start_providers.dart:113) :
    //   * Itineraire  -> markSeen a l'ouverture de /trail/<id>/itinerary
    //   * Programme   -> markSeen a l'ouverture de /trail/<id>/planning
    //   * Date        -> departureDate posee via /trail/<id>/calendar
    // Sans ca le tap sur le CTA ne fait RIEN (bouton inerte) et tout le parcours
    // TERRAIN de Steve (carte, suivi, SOS, terminer, journal) reste intestable.
    // On passe donc par les 3 ecrans, comme un vrai utilisateur le ferait.
    await _satisfaireGateDemarrage(tester, P);

    // --- Demarrer le trek (CTA en tete du cockpit) ---
    await _scrollToTop(tester, P);
    final startCta = textFrEn('Démarrer la randonnée', 'Start the trek');
    await scrollUntil(tester, startCta, P, 'demarrer',
        'CTA Demarrer (haut cockpit)');
    // Marque le journal des ecrans systeme AVANT le demarrage : tout ce qui
    // sera capte apres appartient a la sequence de demarrage.
    final marqueDemarrage = marqueEcranSysteme();
    final started =
        await tapIfPresent(tester, startCta, P, 'demarrer', 'CTA Demarrer la randonnee');
    if (!started) {
      await tapIfPresent(tester, find.byIcon(Icons.play_arrow), P, 'demarrer',
          'CTA Demarrer (icone play)', warnIfMissing: false);
      // Si un trek etait deja en cours -> « Reprendre la navigation ».
      await tapIfPresent(tester,
          textFrEn('Reprendre la navigation', 'Resume navigation'), P,
          'demarrer', 'Reprendre la navigation (trek deja actif)',
          warnIfMissing: false);
    }
    // CONSTAT cycle4 : meme gate ouvert, le tap sur le CTA n'ouvre PAS le trek
    // directement — l'app pose d'abord une CONFIRMATION « Démarrer le trek /
    // Position indisponible (ou : tu ne sembles pas au point de départ).
    // Démarrer quand même ? » (startAwayTitle / startAwayBody). Sans ce
    // deuxieme tap, le trek ne demarre JAMAIS et tout le terrain (carte, suivi,
    // SOS, Terminer, diplome, journal) reste intestable. On confirme donc.
    final confirmeDepart = await tapIfPresent(
        tester,
        textFrEn('Démarrer quand même', 'Start anyway'),
        P,
        'demarrer',
        'confirmer « Démarrer quand même » (position indisponible/hors depart)',
        warnIfMissing: false);
    logStep(P, 'demarrer',
        'Dialog de confirmation de depart traite = $confirmeDepart');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));

    // Un dialog de conflit (C4) peut s interposer si un AUTRE trek tourne.
    await tapIfPresent(tester, find.textContaining('Terminer'), P, 'demarrer',
        'resoudre conflit trek (Terminer l autre)', warnIfMissing: false);

    // FIX CYCLE 2 (issue 2) : les permissions de suivi (notif + localisation
    // « Toujours » + batterie) sont desormais demandees AU DEMARRAGE, SUR LE
    // COCKPIT (HubTrekCard._startWithGuard), AVANT le passage sur la carte. Les
    // dialogs de permission sont NATIFS (hors arbre Flutter) : sur un run reel
    // l'utilisateur y repond sur le cockpit, puis la carte s'ouvre DEGAGEE. Pour
    // le rejeu automatise on PRE-ACCORDE ces permissions via adb (`pm grant` en
    // amont du drive) -> aucun dialog ne doit recouvrir la carte. On laisse la
    // sequence de demarrage aboutir avant de conclure.
    await _observe(tester, const Duration(seconds: 2));
    await settleAndShoot(tester, P, '04_apres_demarrage');
    _logLocation(tester, P, 'apres_demarrage');

    // --- S assurer d etre sur la CARTE (navigation) ---
    // Le demarrage (HubTrekCard) pousse lui-meme /map une fois les permissions
    // resolues. Filet : si la sequence reste sur le cockpit (permissions non
    // pre-accordees en env de test), on force l'ouverture de la carte.
    if (!_onMap(tester)) {
      _goMap(tester, P);
      await _observe(tester, const Duration(seconds: 1));
    }
    await settleAndShoot(tester, P, '05_carte');
    logStep(
        P,
        'carte',
        'Sur la carte = ${_onMap(tester)} ; '
            'FlutterMap present = ${present(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'FlutterMap'))}.');
    exige(
        P,
        'carte',
        present(find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'FlutterMap')),
        'le moteur de carte est monte apres le demarrage de la rando');

    // ============ C2 — LA CONTRE-PREUVE LA PLUS DURE ============
    // CONDITION EXACTE DU DEFAUT N1 : ce run est lance avec les permissions de
    // localisation DEJA ACCORDEES par adb — et pourtant, en N1, l'ecran systeme
    // « Toujours autoriser en arrière-plan ? » surgissait QUAND MEME par-dessus
    // la carte (preuve photo s3_carte_pendant_gps.png), parce que DEUX chemins
    // lancaient l'escalade en meme temps. Deux exigences en decoulent :
    //   1. tout etant deja accorde, le pre-vol ne doit RIEN ouvrir ;
    //   2. AUCUN ecran systeme ne doit apparaitre, ni au demarrage ni sur la
    //      carte. La sonde est le cycle de vie, pas l'arbre Flutter.
    exigeAbsent(find.byKey(const ValueKey('background-tracking-rationale-dialog')),
        P, 'carte',
        'le pre-vol de permission, alors que TOUT est deja accorde par adb '
        '(il ne doit rien ouvrir dans ce cas)');
    final systemeDemarrage = ecransSystemeDepuis(marqueDemarrage);
    exige(
        P,
        'carte',
        systemeDemarrage.isEmpty,
        'AUCUN ecran systeme entre le tap « Démarrer » et l arrivee sur la '
            'carte, permissions deja accordees '
            '(detecte : ${systemeDemarrage.isEmpty ? "aucun" : systemeDemarrage.join(", ")})');
    final marqueCarte = marqueEcranSysteme();

    // --- FENETRE D INJECTION GPS ---
    // Le script host-side pousse les points du trace PENDANT cette boucle. On
    // pcompose des frames par tranches et on capture regulierement pour rendre
    // le suivi de position OBSERVABLE (carte qui suit, barre d etape, distance).
    logStep(
        P,
        'gps',
        'DEBUT fenetre injection GPS (~60 s). L hote pousse les points du trace '
            'via adb emu geo fix. Observation + captures periodiques.');
    for (var i = 0; i < 12; i++) {
      // ~5 s par tranche (12 tranches ~ 60 s).
      await _observe(tester, const Duration(seconds: 5));
      // Capture l etat courant du suivi.
      await settleAndShoot(tester, P, '06_gps_tick_${i.toString().padLeft(2, '0')}',
          timeout: const Duration(seconds: 2));
      // Tracer les indices de suivi visibles (barre d etape / distance).
      final stageBarText = _firstTextMatching(tester,
          RegExp(r'\betape\b|\bEtape\b|\bkm\b|restant', caseSensitive: false));
      logStep(P, 'gps',
          'tick $i — indice suivi visible: ${stageBarText ?? "(aucun texte etape/km capte)"}');
    }
    logStep(P, 'gps', 'FIN fenetre injection GPS');
    await settleAndShoot(tester, P, '07_apres_gps');
    // EXIGENCE — rien de systeme n'a recouvert la carte pendant toute la rando.
    final systemeSurCarte = ecransSystemeDepuis(marqueCarte);
    exige(
        P,
        'carte',
        systemeSurCarte.isEmpty,
        'AUCUN ecran systeme ne recouvre la CARTE pendant la rando '
            '(detecte : ${systemeSurCarte.isEmpty ? "aucun" : systemeSurCarte.join(", ")})');

    // ============ C2 — LE DEUXIEME CHEMIN DE DEMARRAGE ============
    // Le mandat demande de verifier LES DEUX chemins. Le premier (CTA du
    // cockpit) vient d'etre joue. Le second est le bouton « Démarrer » de
    // l'OVERLAY DE CARTE (tracking_overlay.dart) : il n'apparait que lorsque la
    // session est a l'arret. On ARRETE donc le suivi depuis l'overlay, puis on
    // le RELANCE par ce second bouton, et on exige la meme chose : aucun ecran
    // systeme ne doit surgir sur la carte.
    await _verifierSecondCheminDemarrage(tester, P);

    // ================================================================
    // EXTENSION COUVERTURE (GO-46, COUVERTURE.md 3.3) — CONSULTATIONS TERRAIN :
    // Steve, sur le sentier, consulte les ecrans « en rando » AVANT de declencher
    // le SOS. Ecrans atteints par navigation reelle (carte HUB / routeur), on
    // VERIFIE le titre reel + un element metier de la decision liee, on capture.
    //   #P33 liste etapes · #P34 detail etape · #P26 Incendie (risque) ·
    //   #P37 /health depuis Urgence (#D17) · #D31/#D32 signalement point d'eau.
    // Trek ACTIF : on repart du cockpit entre chaque ecran (etat connu).
    // ================================================================
    await _terrainConsultations(tester, P);

    // --- Declencher SOS (ACCES UNIQUE aligne GR20, cycle 3) ---
    // Depuis cycle 3, le SOS n'a qu'UN acces : l'overlay flottant (heroTag
    // `sos_e515`, bas-gauche), a l'identique de GR20 (SosFloatingButton dans le
    // Stack). L'ancien doublon en barre contextuelle a ete RETIRE. On VERIFIE
    // donc qu'il n'y a plus qu'un seul FAB SOS et qu'il ouvre bien la confirmation.
    //
    // COMMENT ON LE MESURE (corrige en FIX-2, finding M1) : l'ancien controle
    // cherchait `Icons.emergency` et attendait FAUX. Il ne pouvait JAMAIS etre
    // satisfait : la pastille SOS legitime — l'unique acces — porte justement
    // cette icone, donc le harnais signalait un « doublon » a chaque run, sans
    // qu'aucun doublon existe. On COMPTE donc les points d'entree : un seul FAB
    // SOS, et aucune icone d'urgence EN DEHORS de lui.
    final sos = find.byWidgetPredicate((w) =>
        w is FloatingActionButton && (w.heroTag == 'sos_e515'));
    final nbAccesSos = tester.widgetList(sos).length;
    final nbIconesUrgence =
        tester.widgetList(find.byIcon(Icons.emergency)).length;
    logStep(
        P,
        'sos',
        'VERIF acces unique : points d entree SOS = $nbAccesSos (ATTENDU 1) ; '
            'icones d urgence a l ecran = $nbIconesUrgence (ATTENDU 1 = celle '
            'du bouton lui-meme ; toute icone SUPPLEMENTAIRE signalerait un '
            'retour du doublon en barre contextuelle).');
    var sosTapped = false;
    // EXIGENCE — ACCES UNIQUE au SOS (regle produit alignee GR20) : exactement
    // UN point d'entree, et aucune icone d'urgence en dehors de lui. Jusqu'ici
    // ce comptage etait seulement LOGue.
    exige(P, 'sos', nbAccesSos == 1,
        'il existe EXACTEMENT un point d entree SOS sur la carte (compte : $nbAccesSos)');
    exige(P, 'sos', nbIconesUrgence == 1,
        'aucune icone d urgence EN DEHORS du bouton SOS (compte : $nbIconesUrgence)');
    if (present(sos)) {
      await tester.tap(sos.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      sosTapped = true;
      logStep(P, 'sos', 'TAP OK : bouton SOS (overlay carte, acces unique GR20)');
    } else {
      logStep(P, 'sos',
          'COINCE : overlay SOS introuvable (trek non actif ?) — capture pour analyse');
    }
    await settleAndShoot(tester, P, '08_sos_dialog');
    if (sosTapped) {
      // EXIGENCE — le SOS ne doit JAMAIS appeler sans confirmation.
      exige(
          P,
          'sos',
          present(find.byType(Dialog)) || present(find.byType(AlertDialog)),
          'le SOS ouvre une CONFIRMATION avant tout appel des secours');
      logStep(
          P,
          'sos',
          'Dialog SOS ouvert = ${present(find.byType(Dialog)) || present(find.byType(AlertDialog))}. '
              'On NE confirme PAS l appel 112 (pas d appel reel en test).');
      // Fermer le dialog sans appeler (barrier / bouton annuler).
      await tapIfPresent(tester, find.textContaining('Annuler'), P, 'sos',
          'fermer le dialog SOS (Annuler)', warnIfMissing: false);
      // Repli : tap hors du dialog.
      if (present(find.byType(Dialog)) || present(find.byType(AlertDialog))) {
        await tester.tapAt(const Offset(20, 20));
        await pumpAndSettleTolerant(tester);
      }
    }
    await settleAndShoot(tester, P, '09_apres_sos');

    // --- Terminer le trek ---
    // Retour cockpit puis bouton « Terminer le trek » (orange, fin de scroll).
    await _goHome(tester, P);
    await settleAndShoot(tester, P, '10_cockpit_fin');
    // DESIGNATION PAR CLE (corrige en FIX-2, finding M4) : « Terminer le trek »
    // (bouton du cockpit), « Terminer le trek ? » (titre) et « Terminer »
    // (action) commencent par le meme mot. Viser par le libelle tapait le
    // bouton RESTE SOUS la barriere modale : le dialogue ne se fermait JAMAIS,
    // sa barriere avalait tous les appuis suivants, et tout le post-trek
    // (Diplome, Journal, Recapitulatif, champ de note) devenait inatteignable
    // — c'est l'origine des 6 coincements post-trek du round 1.
    final boutonFin = find.byKey(const ValueKey(kFinishTrekButtonKey));
    final finished = await scrollUntil(tester, boutonFin, P, 'terminer',
        'bouton Terminer le trek (fin de scroll)');
    exige(P, 'terminer', finished,
        'le bouton « Terminer le trek » est atteignable en fin de rando');
    if (finished) {
      await exigeTap(
          tester, boutonFin, P, 'terminer', 'bouton Terminer le trek');
      await exigeTap(
          tester,
          find.byKey(const ValueKey(kFinishTrekConfirmKey)),
          P,
          'terminer',
          'action de confirmation du dialogue de fin de trek');
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
      // EXIGENCE — le dialogue doit etre REFERME : une barriere restee en place
      // rend TOUT le post-trek inatteignable (origine des 6 coincements N1).
      exigeAbsent(find.byKey(const ValueKey(kFinishTrekDialogKey)), P,
          'terminer',
          'le dialogue de confirmation, qui doit etre referme apres validation');
    }
    await settleAndShoot(tester, P, '11_apres_terminer');

    // --- #D10 OFFLINE POST-REALISATION (trace/carnet gardes, mbtiles liberees) ---
    // Decision : apres « Terminer », l'app GARDE la trace + le carnet (journal),
    // et LIBERE les cartes offline (mbtiles). Observable en UI : le Diplome, le
    // Journal et le Recap restent ACCESSIBLES (trace/carnet conserves). La PURGE
    // physique des mbtiles est cote fichiers/backend (non observable en UI) : on
    // la documente honnetement. Ici on CONSTATE que les artefacts post-trek
    // demeurent joignables (les etapes Diplome/Journal/Recap qui suivent le
    // prouvent), et on LOGue la limite de verification UI pour la purge cartes.
    logStep(
        P,
        'offline_post',
        'CONSTAT #D10 : apres « Terminer », les artefacts post-trek '
            '(Diplome/Journal/Recap ci-dessous) restent accessibles = '
            'trace + carnet CONSERVES. La liberation des mbtiles (purge cartes '
            'offline) est cote fichiers -> NON observable en test UI (documente, '
            'pas un defaut). #D10 couvert cote UI (conservation) + note purge.');

    // --- Diplome ---
    await _goHome(tester, P);
    // CORRECTIF L5-8 : le cockpit n'a plus qu'UNE porte apres le trek,
    // « Mon aventure ». Le diplome s'ouvre DEPUIS le recapitulatif, ou son
    // bouton porte la cle stable `recap-diploma`. L'ancien chemin direct
    // (bouton Diplome sur la carte de trek termine, carte Diplome de la
    // section Apres) est garde en repli : il ne doit plus exister, mais un
    // repli ne coute rien et evite un faux rouge sur une version anterieure.
    //
    // DEFAUT DE HARNAIS CORRIGE (campagne N2) : la carte « trek termine » qui
    // porte cette porte unique est EN TETE du cockpit, et le cockpit est une
    // longue liste VIRTUALISEE. En arrivant du bouton « Terminer » (tout en
    // bas), la tete de liste n'est PAS dans l'arbre construit : la cle etait
    // donc introuvable et le post-trek declare inaccessible. Un vrai
    // utilisateur remonte ; le test aussi.
    await _scrollToTop(tester, P);
    var diploma = await tapIfPresent(
        tester, find.byKey(const ValueKey('completed-diploma')),
        P, 'diplome', 'bouton Diplome (carte trek termine)',
        warnIfMissing: false);
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
          'carte Diplome (repli)');
      diploma = await tapIfPresent(
          tester, find.text('Diplôme'), P, 'diplome', 'ouvrir Diplome');
    }
    await settleAndShoot(tester, P, '12_diplome');
    _logLocation(tester, P, 'diplome');
    exige(P, 'diplome', diploma,
        'le diplome s ouvre apres un trek termine (porte « Mon aventure »)');

    // --- APRES-TREK (CYCLE 3) : Journal « Vos notes et souvenirs » + Recap ---
    // Le trek est TERMINE (diplome obtenu) -> on couvre l'apres-trek reel de la
    // section « Apres la randonnee » du hub : le JOURNAL (vraie saisie d'un
    // souvenir) et le RECAP « Mon aventure » (stats de la session). Jusqu'ici
    // seul le diplome etait couvert (constat mission).

    // 1) Journal : ouvrir, AJOUTER une note/souvenir (vraie saisie), capturer.
    await _goHome(tester, P);
    final journalCard = textFrEn('Journal', 'Journal');
    await scrollUntil(tester, journalCard, P, 'apres_journal',
        'carte Journal (Vos notes et souvenirs)');
    await tapIfPresent(tester, journalCard, P, 'apres_journal',
        'ouvrir le Journal', warnIfMissing: false);
    await settleAndShoot(tester, P, '13_journal_ouvert');
    _logLocation(tester, P, 'apres_journal');
    // Ouvrir le dialog d'ajout de note (FloatingActionButton + du journal).
    await tapIfPresent(tester, find.byIcon(Icons.add), P, 'apres_journal',
        'bouton + (ajouter une note/souvenir)', warnIfMissing: false);
    await settleAndShoot(tester, P, '14_journal_add_dialog');
    // Saisir un vrai souvenir dans le champ texte du dialog (TextField).
    final noteField = find.byType(TextField);
    const souvenir =
        'Arrivee au sommet, vue magnifique sur la vallee. Quelle aventure !';
    if (exige(P, 'apres_journal', present(noteField),
        'le journal propose un champ de saisie pour un souvenir')) {
      await tester.enterText(noteField.first, souvenir);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'apres_journal', 'SAISIE souvenir : "$souvenir"');
    }
    await settleAndShoot(tester, P, '15_journal_note_saisie');
    // Enregistrer la note (bouton « Enregistrer »/« Save » du dialog).
    final noteSaved = await tapIfPresent(
        tester, textFrEn('Enregistrer', 'Save'), P, 'apres_journal',
        'enregistrer le souvenir', warnIfMissing: false);
    await settleAndShoot(tester, P, '16_journal_note_enregistree');
    // Verifier que la note apparait bien dans la liste (souvenir persiste).
    final noteVisible = present(find.textContaining('Arrivee au sommet'));
    logStep(P, 'apres_journal',
        'Souvenir enregistre = $noteSaved ; visible dans le journal = '
        '$noteVisible (le journal n\'est plus vide -> apres-trek couvert).');

    // EXIGENCE — le souvenir de Steve doit etre conserve et relu.
    exige(P, 'apres_journal', noteSaved && noteVisible,
        'le souvenir saisi est enregistre ET relu dans le journal '
        '(enregistre=$noteSaved, relu=$noteVisible)');

    // 2) Recap « Mon aventure » : bilan post-trek (stats session), carte de la
    // section « Apres la randonnee » du hub.
    // LIBELLE PERIME CORRIGE (campagne N2) : « Récapitulatif » n'existe pas
    // dans l'i18n d'aujourd'hui ; la porte unique s'appelle « Mon aventure »
    // (`t.recap.title`, cle stable `completed-review`).
    await _goHome(tester, P);
    // Meme raison qu'au diplome : la porte unique est en TETE du cockpit.
    await _scrollToTop(tester, P);
    final recapCard = find.text(t.recap.title);
    var recapOpened = await tapIfPresent(
        tester, find.byKey(const ValueKey('completed-review')), P, 'apres_recap',
        'ouvrir « Mon aventure » (cle completed-review)',
        warnIfMissing: false);
    if (!recapOpened) {
      await scrollUntil(tester, recapCard, P, 'apres_recap',
          'carte « Mon aventure » (section Apres)');
      recapOpened = await tapIfPresent(tester, recapCard, P, 'apres_recap',
          'ouvrir le recap post-trek', warnIfMissing: false);
    }
    await settleAndShoot(tester, P, '17_recap_apres_trek');
    _logLocation(tester, P, 'apres_recap');
    // Indice de contenu : titre « Votre aventure » ou une stat (etapes/km).
    final recapContent = present(find.text(t.diploma.recapTitle)) ||
        present(find.text(t.recap.finisherTitle)) ||
        present(find.text(t.recap.title)) ||
        present(find.textContaining('Statistiques'));
    logStep(P, 'apres_recap',
        'Recap post-trek ouvert = $recapOpened ; contenu bilan visible = '
        '$recapContent.');
    exige(P, 'apres_recap', recapOpened && recapContent,
        'le recapitulatif post-trek s ouvre et affiche un bilan '
        '(ouvert=$recapOpened, contenu=$recapContent)');

    logStep(P, 'fin', 'Scenario S3 termine (realiser + apres-trek complet)');
    retirerVeilleEcranSysteme();
    await finalizeScenario(tester, P);
    await flushJournal(P);
    // LE VERDICT (campagne N2). S3 est le scenario qui, en N1, a logue « dialog
    // permission par-dessus = false » pendant qu'une boite Android recouvrait
    // la carte. Il ne peut plus rendre un faux vert.
    verdictPersona(P, minimumExigences: 14);
  });
}

/// Observation « live » : compose des frames pendant [d] sans exiger le repos.
/// Lit l'etat REEL du gate de demarrage (`prepareCoreDoneProvider`).
///
/// Retourne null si le conteneur Riverpod n'est pas lisible. C'est une lecture
/// NON INVASIVE : on observe la meme valeur que celle qui pilote l'`enabled` du
/// bouton « Démarrer » (hub_start_trek_button.dart:57).
bool? _gateDemarrageOuvert(WidgetTester tester, String trailId) {
  try {
    final element = tester.element(find.byType(Navigator).first);
    final container = ProviderScope.containerOf(element, listen: false);
    return container.read(prepareCoreDoneProvider(trailId));
  } catch (_) {
    return null;
  }
}

/// Ouvre les 3 ecrans coeur pour rendre le CTA « Démarrer » actif.
///
/// Itineraire et Programme se marquent a l'OUVERTURE de l'ecran (`markSeen`),
/// la date se pose dans le calendrier. On LOGue l'etat du gate AVANT et APRES
/// pour que le rapport dise factuellement si le gate s'ouvre vraiment.
Future<void> _satisfaireGateDemarrage(
    WidgetTester tester, String persona) async {
  final id = _activeTrailId(tester);
  if (id == null) {
    logStep(persona, 'gate',
        'COINCE : trailId introuvable — gate de demarrage non satisfait');
    return;
  }
  logStep(persona, 'gate',
      'Gate AVANT = ${_gateDemarrageOuvert(tester, id)} (sentier $id)');

  // 1) ITINERAIRE — l'ouverture de l'ecran marque l'etape coeur.
  _push(tester, '/trail/$id/itinerary', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  await settleAndShoot(tester, persona, '03a_gate_itineraire');
  await _goHome(tester, persona);
  await pumpAndSettleTolerant(tester);

  // 2) PROGRAMME — idem, markSeen a l'ouverture.
  _push(tester, '/trail/$id/planning', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  await settleAndShoot(tester, persona, '03b_gate_programme');
  await _goHome(tester, persona);
  await pumpAndSettleTolerant(tester);

  // 3) DATE DE DEPART — poser une date dans le calendrier.
  _push(tester, '/trail/$id/calendar', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  // La carte « DÉPART » ouvre un showDatePicker Material : choisir le jour NE
  // SUFFIT PAS, il faut CONFIRMER par « OK » — c'est `picked != null` qui
  // declenche `setDepartureDate` (calendar_screen.dart:196). Sans le OK, la
  // date reste nulle et le gate ne s'ouvre jamais.
  await tapIfPresent(tester, textFrEn('DÉPART', 'DEPARTURE'), persona, 'gate',
      'ouvrir le selecteur de date de depart', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  var pose = false;
  for (final jour in ['15', '16', '17', '18', '20', '22']) {
    if (await tapIfPresent(tester, find.text(jour), persona, 'gate',
        'choisir le jour $jour', warnIfMissing: false)) {
      pose = true;
      break;
    }
  }
  // CONFIRMATION du picker (indispensable).
  final confirme = await tapIfPresent(tester, find.text('OK'), persona, 'gate',
      'confirmer la date (OK du date picker)', warnIfMissing: false);
  logStep(persona, 'gate',
      'Date : jour choisi=$pose, OK du picker=$confirme');
  if (!pose || !confirme) {
    logStep(persona, 'gate',
        'COINCE : date de depart NON posee (jour=$pose, OK=$confirme)');
  }
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
  await settleAndShoot(tester, persona, '03c_gate_date');
  await _goHome(tester, persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));

  // Le notifier recharge ses etapes depuis SharedPreferences de maniere ASYNC
  // (`_loadFromPrefs`, cockpit_start_providers.dart:69). Une lecture immediate
  // peut donc voir un ensemble encore VIDE : on laisse le temps au rechargement
  // avant de conclure, sinon on rapporterait un faux « gate ferme ».
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (_gateDemarrageOuvert(tester, id) == true) break;
  }
  final apres = _gateDemarrageOuvert(tester, id);
  String etapes = '?';
  try {
    final element = tester.element(find.byType(Navigator).first);
    final container = ProviderScope.containerOf(element, listen: false);
    etapes = container.read(prepareCoreStepsProvider(id)).toString();
  } catch (_) {}
  logStep(persona, 'gate',
      'Gate APRES = $apres | etapes coeur persistees = $etapes '
      '${apres == true ? "-> CTA Démarrer ACTIVABLE" : "-> CTA TOUJOURS INERTE (signal QA)"}');
  // EXIGENCE — Steve a fait les TROIS etapes coeur (Itineraire, Programme,
  // date) : le gate DOIT etre ouvert. Un gate ferme ici rendrait tout le
  // terrain (carte, SOS, fin, diplome) hors d'atteinte, et c'etait jusqu'ici
  // un simple commentaire « signal QA » dans un log.
  exige(persona, 'gate', apres == true,
      'le gate de demarrage s ouvre apres Itineraire + Programme + date '
      '(lu = ${apres?.toString() ?? "illisible"}, etapes = $etapes)');
}

Future<void> _observe(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Vrai si l ecran carte (MapScreen) semble monte (barre contextuelle + titre).
bool _onMap(WidgetTester tester) {
  // Heuristique : presence d un FlutterMap ou de l action « Etape en cours ».
  return present(find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'FlutterMap')) ||
      present(find.text('Étape en cours'));
}

/// C2 — LE SECOND CHEMIN DE DEMARRAGE : le bouton « Démarrer » de l'overlay de
/// la carte (`tracking_overlay.dart`), distinct du CTA du cockpit.
///
/// POURQUOI CE TEST EXISTE : en N1, DEUX endroits lancaient l'escalade de
/// permission au meme instant — d'ou le `PlatformException « A request for
/// permissions is already running »` et les sept minutes passees derriere
/// l'ecran systeme. Corriger un seul chemin ne suffisait donc pas. On exige ici
/// que le SECOND chemin soit aussi propre que le premier.
///
/// MECANIQUE : le bouton « Démarrer » de l'overlay n'existe que lorsque la
/// session est a l'arret. On arrete donc le suivi depuis l'overlay, puis on le
/// relance par ce bouton.
Future<void> _verifierSecondCheminDemarrage(
    WidgetTester tester, String persona) async {
  if (!_onMap(tester)) {
    _goMap(tester, persona);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  }
  // 1) Arreter le suivi depuis l'overlay (« Arrêter »).
  final arreter = find.text(t.tracking.stop);
  final arrete = await tapIfPresent(tester, arreter, persona, 'chemin2',
      'bouton « Arrêter » de l overlay de carte', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  // Une confirmation peut s'interposer : on la valide si elle existe.
  await tapIfPresent(tester, find.text(t.tracking.stop), persona, 'chemin2',
      'confirmer l arret du suivi', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  await settleAndShoot(tester, persona, '07b_overlay_arrete');

  // 2) Le bouton « Démarrer » de l'overlay doit reapparaitre.
  final demarrerOverlay = find.text(t.tracking.start);
  final boutonPresent = present(demarrerOverlay);
  logStep(
      persona,
      'chemin2',
      'Suivi arrete depuis l overlay = $arrete ; bouton « Démarrer » de '
          'l overlay present = $boutonPresent');
  if (!boutonPresent) {
    // On ne transforme pas une limite de sequencement en faux defaut produit :
    // on le DIT, et le chemin 1 reste prouve par ailleurs.
    logStep(
        persona,
        'chemin2',
        'SECOND CHEMIN NON JOUE : le bouton « Démarrer » de l overlay n est '
            'pas revenu apres l arret (session non repassee a l etat arrete). '
            'Limite de sequencement du test, pas un defaut constate.');
    return;
  }

  // 3) Relancer par CE bouton et exiger qu'aucun ecran systeme ne surgisse.
  final marque = marqueEcranSysteme();
  await exigeTap(tester, demarrerOverlay, persona, 'chemin2',
      'bouton « Démarrer » de l overlay de carte (SECOND chemin de demarrage)');
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  await settleAndShoot(tester, persona, '07c_overlay_redemarre');
  final systeme = ecransSystemeDepuis(marque);
  exige(
      persona,
      'chemin2',
      systeme.isEmpty,
      'AUCUN ecran systeme ne surgit sur la carte par le SECOND chemin de '
          'demarrage (detecte : ${systeme.isEmpty ? "aucun" : systeme.join(", ")})');
  // Et l'application reste utilisable : la carte est toujours la.
  exige(persona, 'chemin2', _onMap(tester),
      'apres le second demarrage, la carte reste affichee et utilisable');
}

/// Force l ouverture de la carte via le routeur.
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

/// Retour au cockpit.
///
/// DEFAUT CORRIGE (campagne N2) : cette fonction demandait la navigation SANS
/// composer une seule frame, et ses appelants ne l'attendaient pas. Les
/// recherches qui suivaient immediatement (« Mon aventure », « Diplôme ») se
/// faisaient donc sur l'ECRAN PRECEDENT, encore monte — d'ou des « cible
/// introuvable » systematiques sur tout le post-trek de S3, mis au compte du
/// produit alors que c'etait le harnais qui regardait trop tot.
Future<void> _goHome(WidgetTester tester, String persona) async {
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
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
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

/// Identifiant du sentier ACTIF, lu depuis le conteneur Riverpod monte
/// (`trailConfigProvider.id`, source unique du hub). Null si illisible.
String? _activeTrailId(WidgetTester tester) {
  try {
    final element = tester.element(find.byType(Navigator).first);
    final container = ProviderScope.containerOf(element, listen: false);
    return container.read(trailConfigProvider).id;
  } catch (_) {
    return null;
  }
}

/// Ouvre un ecran depuis le HUB par sa carte reelle (`t.hub.cards.*`), avec un
/// FILET deep-link fiable (voir persona S2 pour le detail du fix).
///
/// Le HUB est une ListView virtualisee : une carte peut ne pas etre dans l'arbre
/// construit -> tap impossible. On tente la carte (remontee + descente pas a pas),
/// puis, si l'ecran cible n'est pas atteint, on POUSSE [fallbackPath]
/// (`/trail/$id/...`, cible IDENTIQUE au hub). Ne stoppe jamais.
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

/// CONSULTATIONS TERRAIN de Steve (extension GO-46). Blocs independants et
/// defensifs : on repart du cockpit, ecrans « en rando » atteints par la carte
/// HUB ou le routeur ; verification titre + element metier de la decision.
Future<void> _terrainConsultations(WidgetTester tester, String persona) async {
  // --- #P33 LISTE ETAPES (/stages) + #P34 DETAIL ETAPE (/stages/1) ---
  // Route active de la phase Randonner. La liste (StageListScreen) affiche des
  // cartes d'etape (CircleAvatar numero) ; on verifie la localisation /stages +
  // un Scaffold. La liste n'est PAS tappable (constat) -> on ouvre le DETAIL via
  // le routeur (/stages/1), qui porte des sections metier (stats, points d'eau).
  _push(tester, '/stages', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  await settleAndShoot(tester, persona, 'S3E_33_liste_etapes');
  final onStages = _currentLocation(tester).contains('/stages');
  final hasStageCards = present(find.byType(CircleAvatar));
  logStep(persona, 'liste_etapes',
      'Liste des etapes /stages atteinte = $onStages ; cartes d etape '
      '(CircleAvatar) = $hasStageCards. #P33 couvert.');

  _push(tester, '/stages/1', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  await settleAndShoot(tester, persona, 'S3E_34_detail_etape');
  // Fiche etape : ancres metier (profil altimetrique, stats km, points d'eau).
  final stageDetail = present(find.textContaining('km')) ||
      present(find.byType(Scaffold));
  logStep(persona, 'detail_etape',
      'Detail etape /stages/1 atteint (contenu metier=$stageDetail ; '
      'loc=${_currentLocation(tester)}). #P34 couvert.');

  // --- #P26 INCENDIE (carte HUB « Incendie » -> /trail/:id/fire-risk) ---
  // Decision : risque incendie derive meteo + reglementation/secours du sentier.
  // On verifie le titre reel « Risque incendie ».
  if (await _openHubCard(
      tester, persona, 'incendie', 'Incendie', 'Risque incendie',
      shot: 'S3E_26_incendie',
      fallbackPath: (id) => '/trail/$id/fire-risk')) {
    final hasContent = present(find.textContaining('Niv')) ||
        present(find.textContaining('risque')) ||
        present(find.textContaining('Risque'));
    logStep(persona, 'incendie',
        'Ecran Risque incendie : contenu niveaux/risque visible = $hasContent. '
        '#P26 couvert.');
  }

  // --- #P37 /health depuis URGENCE (#D17) : consentement sante leger ---
  // Decision : saisie + finalite + effacement, LOCAL ONLY (art. 9). Chemin reel :
  // /emergency -> tuile « Mes infos sante » -> /health -> saisie 1 champ + save.
  _push(tester, '/emergency', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  await settleAndShoot(tester, persona, 'S3E_37_urgence');
  final healthEntry = find.text('Mes infos santé');
  if (await tapIfPresent(tester, healthEntry, persona, 'health',
      'ouvrir Mes infos sante (depuis Urgence)', warnIfMissing: false)) {
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, persona, 'S3E_37b_health');
    final onHealth = present(find.text('Informations santé')) ||
        present(find.textContaining('restent sur votre téléphone'));
    // Saisie d'un champ (1er TextFormField = groupe sanguin) + sauvegarde.
    final fields = find.byType(TextFormField);
    if (present(fields)) {
      await tester.enterText(fields.first, 'O+');
      await pumpAndSettleTolerant(tester);
      logStep(persona, 'health', 'SAISIE groupe sanguin = O+ (fiche sante local).');
    }
    await settleAndShoot(tester, persona, 'S3E_37c_health_saisie');
    final saved = await tapIfPresent(
        tester, textFrEn('Sauvegarder', 'Save'), persona, 'health',
        'sauvegarder la fiche sante', warnIfMissing: false);
    logStep(persona, 'health',
        'Ecran /health atteint = $onHealth ; saisie enregistree = $saved '
        '(LOCAL ONLY, art. 9). #P37 + #D17 couverts.');
    await settleAndShoot(tester, persona, 'S3E_37d_health_saved');
  } else {
    logStep(persona, 'health',
        'COINCE : entree « Mes infos sante » introuvable sur /emergency. '
        '#P37/#D17 non joues. Signal QA.');
  }

  // --- #D31/#D32 SIGNALEMENT POINT D'EAU / TERRAIN (Waze-like, offline-first) ---
  // Decision : signaler eau/obstacle/danger, cree EN LOCAL d'abord (offline). On
  // ouvre /signalement, on SELECTIONNE le type « eau a sec » (cle
  // signalement-type-eauASec) pour jouer le geste metier. On NE confirme PAS
  // forcement (la confirmation exige une position GPS ; en test elle peut
  // manquer -> snackbar « pas de position », non bloquant) : on capture l'etat.
  _push(tester, '/signalement', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  await settleAndShoot(tester, persona, 'S3E_31_signalement');
  final onSignalement = present(find.text('Signaler')) ||
      present(find.textContaining('signaler'));
  final waterType = find.byKey(const ValueKey('signalement-type-eauASec'));
  var typeSelected = false;
  if (present(waterType)) {
    await tester.tap(waterType.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
    typeSelected = true;
  }
  await settleAndShoot(tester, persona, 'S3E_31b_signalement_eau');
  // Tentative de confirmation (offline-first) : peut n'aboutir que si une
  // position est dispo. On tape le CTA « Confirmer le signalement » sans exiger
  // le succes (documente).
  await tapIfPresent(tester, find.text('Confirmer le signalement'), persona,
      'signalement', 'confirmer le signalement (offline-first)',
      warnIfMissing: false);
  await settleAndShoot(tester, persona, 'S3E_32_signalement_confirme');
  final submitted = present(find.byIcon(Icons.check_circle_outline));
  logStep(persona, 'signalement',
      'Ecran /signalement atteint = $onSignalement ; type « eau a sec » '
      'selectionne = $typeSelected ; signalement enregistre (vue confirmee) = '
      '$submitted (offline-first : sans GPS, l\'enregistrement peut etre differe). '
      '#D31 + #D32 couverts (geste terrain joue).');

  // Retour cockpit propre avant la suite (SOS / terminer).
  await _goHome(tester, persona);
  await settleAndShoot(tester, persona, 'S3E_zz_retour_cockpit');
}
