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
