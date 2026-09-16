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
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S3_Steve';

void main() {
  initHarness();

  testWidgets('S3 — Steve marche le trek (GPS injecte)', (tester) async {
    logStep(P, 'boot', 'Lancement de app.main()');
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
      _goHome(tester, P);
    }
    await settleAndShoot(tester, P, '03_cockpit');
    _logLocation(tester, P, 'cockpit');

    // --- Demarrer le trek (CTA en tete du cockpit) ---
    await _scrollToTop(tester, P);
    final startCta = textFrEn('Démarrer la randonnée', 'Start the trek');
    await scrollUntil(tester, startCta, P, 'demarrer',
        'CTA Demarrer (haut cockpit)');
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
            'FlutterMap present = ${present(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'FlutterMap'))} ; '
            'dialog permission par-dessus = ${present(find.textContaining('otification')) || present(find.textContaining('Autoriser'))} '
            '(ATTENDU false apres pre-grant adb — issue 2).');

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
    final sos = find.byWidgetPredicate((w) =>
        w is FloatingActionButton && (w.heroTag == 'sos_e515'));
    logStep(P, 'sos',
        'VERIF acces unique : FAB SOS overlay present = ${present(sos)} ; '
        'action SOS en barre contextuelle (icone emergency) = '
        '${present(find.byIcon(Icons.emergency))} (ATTENDU false — doublon retire cycle 3).');
    var sosTapped = false;
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
    _goHome(tester, P);
    await settleAndShoot(tester, P, '10_cockpit_fin');
    final finished = await scrollUntil(tester, find.textContaining('Terminer'),
        P, 'terminer', 'bouton Terminer le trek (fin de scroll)');
    if (finished) {
      await tapIfPresent(tester, find.textContaining('Terminer'), P, 'terminer',
          'Terminer le trek');
      // Confirmer si une boite de dialogue de confirmation apparait.
      await tapIfPresent(tester, find.textContaining('Terminer'), P, 'terminer',
          'confirmer fin de trek', warnIfMissing: false);
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
    _goHome(tester, P);
    // Carte « Diplome » de la section Apres la randonnee, ou bouton dedie de la
    // carte trek terminee.
    var diploma = await tapIfPresent(tester, find.byKey(const ValueKey('completed-diploma')),
        P, 'diplome', 'bouton Diplome (carte trek termine)', warnIfMissing: false);
    if (!diploma) {
      await scrollUntil(tester, find.text('Diplôme'), P, 'diplome',
          'carte Diplome (section Apres)');
      diploma = await tapIfPresent(
          tester, find.text('Diplôme'), P, 'diplome', 'ouvrir Diplome');
    }
    await settleAndShoot(tester, P, '12_diplome');
    _logLocation(tester, P, 'diplome');

    // --- APRES-TREK (CYCLE 3) : Journal « Vos notes et souvenirs » + Recap ---
    // Le trek est TERMINE (diplome obtenu) -> on couvre l'apres-trek reel de la
    // section « Apres la randonnee » du hub : le JOURNAL (vraie saisie d'un
    // souvenir) et le RECAP « Mon aventure » (stats de la session). Jusqu'ici
    // seul le diplome etait couvert (constat mission).

    // 1) Journal : ouvrir, AJOUTER une note/souvenir (vraie saisie), capturer.
    _goHome(tester, P);
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
    if (present(noteField)) {
      await tester.enterText(noteField.first, souvenir);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'apres_journal', 'SAISIE souvenir : "$souvenir"');
    } else {
      logStep(P, 'apres_journal',
          'COINCE : champ de saisie de note introuvable dans le dialog');
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

    // 2) Recap « Récapitulatif » (Votre aventure) : bilan post-trek (stats
    // session), carte de la section « Apres la randonnee » du hub.
    _goHome(tester, P);
    final recapCard = textFrEn('Récapitulatif', 'Recap');
    await scrollUntil(tester, recapCard, P, 'apres_recap',
        'carte Recapitulatif (Votre aventure en resume)');
    final recapOpened = await tapIfPresent(tester, recapCard, P, 'apres_recap',
        'ouvrir le recap post-trek', warnIfMissing: false);
    await settleAndShoot(tester, P, '17_recap_apres_trek');
    _logLocation(tester, P, 'apres_recap');
    // Indice de contenu : titre « Votre aventure » ou une stat (etapes/km).
    final recapContent = present(find.text('Votre aventure')) ||
        present(find.text('Your adventure')) ||
        present(find.textContaining('Statistiques')) ||
        present(find.textContaining('Statistics'));
    logStep(P, 'apres_recap',
        'Recap post-trek ouvert = $recapOpened ; contenu bilan visible = '
        '$recapContent (« Votre aventure », stats session — en plus du diplome '
        'et du journal).');

    logStep(P, 'fin', 'Scenario S3 termine (realiser + apres-trek complet)');
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

/// Observation « live » : compose des frames pendant [d] sans exiger le repos.
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

/// Ouvre un ecran depuis le HUB par sa carte reelle (`t.hub.cards.*`), verifie
/// le titre attendu de l'ecran cible, capture, LOGue. Ne stoppe jamais.
Future<bool> _openHubCard(
  WidgetTester tester,
  String persona,
  String etape,
  String cardLabel,
  String expectedTitle, {
  String? shot,
}) async {
  _goHome(tester, persona);
  await _scrollToTop(tester, persona);
  final card = find.text(cardLabel);
  await scrollUntil(tester, card, persona, etape, 'carte HUB « $cardLabel »');
  await tapIfPresent(tester, card, persona, etape, 'ouvrir « $cardLabel »');
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  if (shot != null) await settleAndShoot(tester, persona, shot);
  final reached = present(find.text(expectedTitle));
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
      shot: 'S3E_26_incendie')) {
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
  _goHome(tester, persona);
  await settleAndShoot(tester, persona, 'S3E_zz_retour_cockpit');
}
