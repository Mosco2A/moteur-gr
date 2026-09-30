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
// NB ACHAT (corrige — tache 650) : IL N'Y A PLUS AUCUN SENTIER GRATUIT au
//   catalogue depuis le lot 638 (decision de Christophe du 29/09 14:17). Ines
//   ACHETE donc son sentier par le chemin de production AVANT la coupure, et ce
//   que ce scenario prouve devient exactement sa promesse : le PAYEUR n'est
//   jamais bloque hors-ligne. L'abonnement n'entre pas ici — il ne donne aucun
//   droit sur un sentier (regle de Christophe du 30/09 16:20).
//
// Pilote l UI reelle, capture chaque etape, LOGue les coincements. Zero modif app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S4_Ines';

void main() {
  initHarness();

  testWidgets('S4 — Ines accede a son premium hors-ligne', (tester) async {
    // Compteurs d'exigences remis a zero (tache 543) : ils sont GLOBAUX,
    // et sans cela un scenario herite des echecs du precedent et le garde
    // anti-harnais-aveugle se desarme tout seul.
    reinitialiserExigences();
    // POIGNEE DE SEMANTIQUE EQUILIBREE (tache 544). Un greffon active la
    // semantique pendant la phase carte et ne la rend pas : flutter_test
    // echoue alors A LA CLOTURE sur « A SemanticsHandle was active at the end
    // of the test », alors que TOUTES les exigences du parcours sont tenues.
    // L'echec est INTERMITTENT, ce qui est pire qu'un echec franc. On prend
    // une poignee et on la rend, pour que le compteur soit equilibre.
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main()');
    installerVeilleEcranSysteme(P);
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
      // TACHE 650 — « PREPARER » remplace « Entrer » (lot 639) ; cle inchangee.
      await tapIfPresent(tester, boutonPreparer(kSentierDeProduction), P,
          'entree', '« Préparer » le sentier de production');
      await _goHome(tester, P);
    }
    await settleAndShoot(tester, P, '03_cockpit');
    _logLocation(tester, P, 'cockpit');

    // ================================================================
    // INES ACHETE — ELLE EST LA PAYEUSE, ET IL N'Y A PLUS RIEN D'OFFERT
    // (tache 650)
    // ================================================================
    //
    // CE QUI ETAIT ECRIT ICI, ET QUI EST FAUX DEPUIS LE 29/09 : « la vitrine est
    // deja debloquee (jouable sans achat) ». Le lot 638 a retire tout sentier
    // gratuit du catalogue. Ce scenario mesurait donc la non-regression
    // hors-ligne d'un contenu que personne n'avait paye — c'est-a-dire pas le
    // cas d'Ines. LA PREMISSE CORRIGEE REND LE SCENARIO PLUS JUSTE, PAS PLUS
    // FAIBLE : Ines PAIE, puis on coupe le reseau, et son droit doit tenir.
    //
    // L'achat emprunte le SERVICE DE PRODUCTION (portefeuille + `buyTrail`) :
    // aucune surcharge de provider, le droit obtenu est le vrai `owned`, stocke
    // en local (Drift) — et c'est justement ce stockage local qui doit resister
    // a la coupure reseau.
    final possede =
        await acheterLeSentierPourDeVrai(tester, kSentierDeProduction, P);
    exige(P, 'achat', possede,
        'Ines POSSEDE le sentier apres son achat (c est le droit qui devra '
        'survivre a la coupure reseau)');
    await _goHome(tester, P);
    await settleAndShoot(tester, P, '03b_apres_achat');

    // --- FENETRE ONLINE : verifier l acces AVANT coupure ---
    // Entrainement (contenu premium).
    final trainingCard = textFrEn('Préparation physique', 'Physical prep');
    await _scrollToTop(tester, P);
    await scrollUntil(tester, trainingCard, P,
        'entrainement_online', 'carte Preparation physique');
    await tapIfPresent(tester, trainingCard, P,
        'entrainement_online', 'ouvrir Preparation physique (ONLINE)');
    await settleAndShoot(tester, P, '04_entrainement_online');
    final unlockOnline = present(find.textContaining('Débloquer'));
    final sessionsOnline = present(find.byWidgetPredicate(
        (w) => w.key.toString().contains('training-session-')));
    // TROISIEME ETAT LISIBLE, MESURE LE 30/09 : l'ecran invite a POSER LA DATE
    // DE DEPART (« Sans date de depart, ce plan n'a pas de fin »). Ines a
    // achete son sentier mais n'a pas encore de date : elle ne voit donc ni
    // teaser d'achat, ni seances, et pourtant l'ecran DIT quelque chose de
    // clair. Le detecteur n'en connaissait que deux etats et rapportait un
    // ecran muet la ou l'application parle.
    final inviteDateOnline = present(find.text(t.training.inviteSetDate));
    logStep(P, 'entrainement_online',
        'Paywall « Débloquer » visible ONLINE = $unlockOnline ; '
        'seances presentes ONLINE = $sessionsOnline ; invitation a poser la '
        'date ONLINE = $inviteDateOnline');
    // EXIGENCE — l'ecran doit dire quelque chose de LISIBLE en ligne : soit le
    // plan (debloque), soit le teaser d'achat. C'est l'etat de REFERENCE auquel
    // on comparera l'etat hors-ligne : sans reference, « rien n'a change » ne
    // veut rien dire.
    exige(P, 'entrainement_online',
        unlockOnline || sessionsOnline || inviteDateOnline,
        'EN LIGNE, l Entrainement affiche un etat lisible (plan debloque, '
        'teaser d achat, ou invitation a poser la date de depart)');
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
    await _goHome(tester, P);
    await _scrollToTop(tester, P);
    await scrollUntil(tester, trainingCard, P,
        'entrainement_offline', 'carte Preparation physique (OFFLINE)');
    await tapIfPresent(tester, trainingCard, P,
        'entrainement_offline', 'ouvrir Preparation physique (OFFLINE)');
    await settleAndShoot(tester, P, '08_entrainement_offline');
    final blockedOffline = present(find.textContaining('Débloquer'));
    final sessionsOffline = present(find
        .byWidgetPredicate((w) => w.key.toString().contains('training-session-')));
    final inviteDateOffline = present(find.text(t.training.inviteSetDate));
    logStep(
        P,
        'entrainement_offline',
        'PAYWALL hors-ligne = $blockedOffline ; seances presentes hors-ligne = '
            '$sessionsOffline. C EST LE POINT SENSIBLE : le payeur ne doit '
            'JAMAIS etre bloque hors-ligne.');
    // ============== LE POINT SENSIBLE, DEVENU UNE EXIGENCE ==============
    // La bonne formulation n'est pas « aucun paywall hors-ligne » (en demo la
    // vitrine affiche legitimement le teaser MEME EN LIGNE) mais : couper le
    // reseau NE DOIT RIEN CHANGER. Le droit d'acces est local (Drift), il ne
    // depend pas du reseau. On compare donc a l'etat de reference mesure juste
    // avant la coupure.
    exige(
        P,
        'entrainement_offline',
        sessionsOffline == sessionsOnline &&
            blockedOffline == unlockOnline &&
            inviteDateOffline == inviteDateOnline,
        'couper le reseau NE CHANGE RIEN a l acces a l Entrainement '
            '(en ligne : seances=$sessionsOnline paywall=$unlockOnline '
            'invite-date=$inviteDateOnline ; hors ligne : '
            'seances=$sessionsOffline paywall=$blockedOffline '
            'invite-date=$inviteDateOffline)');
    await _back(tester, P, 'entrainement_offline');

    // 2) Carte offline : le fond OSM (reseau) peut ne pas charger, mais l ecran
    //    et le trace local doivent rester accessibles (pas d ecran bloquant).
    _goMap(tester, P);
    await settleAndShoot(tester, P, '09_carte_offline');
    final mapErrorOffline = present(find.textContaining('impossible')) ||
        present(find.textContaining('Impossible')) ||
        present(find.textContaining('introuvable'));
    final carteRendueOffline = present(find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'FlutterMap'));
    logStep(
        P,
        'carte_offline',
        'Carte OFFLINE : ecran d erreur bloquant visible = $mapErrorOffline ; '
            'FlutterMap present = $carteRendueOffline '
            '(le fond OSM en ligne peut manquer, mais l ecran ne doit pas etre bloque).');
    // EXIGENCE — hors-ligne, la carte reste RENDUE et sans ecran d'erreur
    // bloquant. Une randonneuse qui a paye et qui est sans reseau en montagne
    // doit garder sa carte.
    exige(P, 'carte_offline', carteRendueOffline,
        'la carte reste RENDUE hors-ligne (moteur de carte monte)');
    exige(P, 'carte_offline', !mapErrorOffline,
        'aucun ecran d erreur bloquant ne remplace la carte hors-ligne');
    await _back(tester, P, 'carte_offline');

    // 3) Cockpit toujours navigable hors-ligne ?
    await _goHome(tester, P);
    await settleAndShoot(tester, P, '10_cockpit_offline');
    final cockpitOffline = present(find.byType(Scaffold));
    final preparerVisible = present(textFrEn('Préparer', 'Prepare'));
    logStep(P, 'cockpit_offline',
        'Cockpit accessible hors-ligne = $cockpitOffline ; '
        'sections Preparer visibles = $preparerVisible');
    exige(P, 'cockpit_offline', cockpitOffline && preparerVisible,
        'le cockpit reste navigable hors-ligne, sections comprises '
        '(cockpit=$cockpitOffline, Preparer=$preparerVisible)');

    // ================================================================
    // EXTENSION COUVERTURE (GO-46, COUVERTURE.md 3.3) — ACHAT + TRACE OFFLINE :
    // Ines paye et exige l'offline. On renforce le point sensible + on couvre le
    // VRAI flux d'achat sur un trek NON POSSEDE (la vitrine etant deja debloquee).
    //   #D36 trace LOCALE offline (pas seulement absence d'erreur) ·
    //   #P45 bascule multi-sentiers (/trail-selection) · #D02/#D03 flux d'achat
    //   (trek non possede -> paywall wallet/store) · #D06/#D07 banniere/rewarded
    //   (constat sous consentement refuse en test).
    // Place en FIN de scenario (apres les assertions offline). Tout est LOCAL
    // (Drift) -> jouable meme reseau coupe ; on restaure la vitrine a la fin.
    // ================================================================
    await _paymentAndOfflineTrace(tester, P);

    logStep(
        P,
        'fin',
        'Scenario S4 termine (offline + trace locale + flux achat trek non '
            'possede). L hote peut retablir le reseau. Verdicts consignes dans '
            'les logs entrainement_offline/carte_offline/trace_offline/achat.');
    retirerVeilleEcranSysteme();
    await finalizeScenario(tester, P);
    await flushJournal(P);
    // LE VERDICT (campagne N2). S4 est le POINT SENSIBLE : un payeur bloque
    // hors-ligne doit rendre ce scenario ROUGE, plus seulement bavard.
    // RUN VALIDE OU RUN COUVERT ? (tache 544)
    // Une fenetre systeme Android — dialogue de permission, formulaire de
    // consentement publicitaire — n'est PAS dans l'arbre Flutter : aucun finder
    // ne la voit. Un run qu'elle recouvre produit des echecs qui ressemblent a
    // des defauts produit mais n'en sont pas : c'est ce qui vient d'arriver
    // (4 echecs S1 dus a un dialogue de localisation par-dessus l'ecran
    // Faisabilite, capture 12c a l'appui). On EXIGE donc que le run n'ait pas
    // ete couvert : ainsi un run invalide se declare invalide, au lieu de se
    // faire passer pour un rapport de defauts.
    exige(P, 'run_valide', ecransSystemeBloquants().isEmpty,
        'aucune fenetre systeme n a recouvert l application pendant le run '
        '(sinon le run est INVALIDE, pas le produit — relancer avec les demons '
        'persona_perm_granter et persona_dialog_dismisser). Bloquants vus : '
        '${ecransSystemeBloquants().join(", ")}');
    poigneeSemantique.dispose();
    verdictPersona(P, minimumExigences: 7);
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

/// Retour au cockpit.
///
/// DEFAUT CORRIGE (campagne N2) : cette fonction demandait la navigation SANS
/// composer une seule frame, et ses appelants ne l'attendaient pas : les
/// recherches qui suivaient se faisaient sur l'ECRAN PRECEDENT, encore monte.
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

/// Vrai si un widget dont le type runtime porte [typeName] est present (sans
/// importer les internes de l'app — meme technique que la detection FlutterMap).
bool _hasWidgetTypeNamed(String typeName) => present(
    find.byWidgetPredicate((w) => w.runtimeType.toString() == typeName));

/// ACHAT (trek non possede) + TRACE OFFLINE de Ines (extension GO-46).
///
/// Blocs independants et defensifs. Tout est LOCAL (Drift) -> jouable meme
/// reseau coupe. On restaure la vitrine (mare-a-mare-centre) a la fin pour ne
/// pas perturber d'eventuels scenarios suivants.
Future<void> _paymentAndOfflineTrace(WidgetTester tester, String persona) async {
  // --- #D36 TRACE LOCALE OFFLINE (pas seulement absence d'erreur) ---
  // Le point sensible S4 verifiait deja que la carte offline n'est pas bloquante.
  // On RENFORCE : on rouvre la carte et on cherche le CALQUE DE TRACE local
  // (TraceLayer -> PolylineLayer) : le trace embarque doit s'afficher meme si le
  // fond OSM (reseau) manque. C'est la preuve du contenu offline (E7/#D36).
  _goMap(tester, persona);
  await _observe(tester, const Duration(seconds: 2));
  await settleAndShoot(tester, persona, 'S4E_36_trace_offline');
  final hasMap = _hasWidgetTypeNamed('FlutterMap');
  final hasTrace =
      _hasWidgetTypeNamed('TraceLayer') || _hasWidgetTypeNamed('PolylineLayer');
  logStep(
      persona,
      'trace_offline',
      'Carte offline : FlutterMap present = $hasMap ; CALQUE DE TRACE local '
          '(TraceLayer/PolylineLayer) present = $hasTrace. #D36.');
  // EXIGENCE #D36 — la preuve du contenu OFFLINE n'est pas « pas d'erreur »
  // mais « le trace embarque s'affiche ». Sans reseau, c'est ce calque local
  // qui garde Ines sur le sentier.
  exige(persona, 'trace_offline', hasMap && hasTrace,
      'le CALQUE DE TRACE local est affiche hors-ligne, sans fond OSM '
      '(carte=$hasMap, trace=$hasTrace)');
  await _back(tester, persona, 'trace_offline');

  // --- #P45 BASCULE MULTI-SENTIERS + #D02/#D03 FLUX D'ACHAT (trek non possede) ---
  // La vitrine (mare-a-mare-centre) etant deja debloquee, le vrai flux d'achat
  // (wallet d'abord, complement store) exige un trek NON POSSEDE. On BASCULE sur
  // le sentier Pyrenees (gr-pyrenees, NON vitrine) via /trail-selection (ecran
  // reel #P45), puis on ouvre son Entrainement : il doit etre VERROUILLE
  // (isDemoMode=true) avec « Debloquer » -> paywall (wallet/store).
  _push(tester, '/trail-selection', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  await settleAndShoot(tester, persona, 'S4E_45_trail_selection');
  final onSelection = present(find.byKey(const ValueKey('trail-selection-list')));
  final switched = await tapIfPresent(
      tester, find.byKey(const ValueKey('trail-select-gr-pyrenees')), persona,
      'achat', 'basculer sur le sentier Pyrenees (non possede)',
      warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  logStep(persona, 'achat',
      'Ecran /trail-selection atteint = $onSelection ; bascule vers gr-pyrenees '
      '(non possede) = $switched. #P45 couvert.');
  await settleAndShoot(tester, persona, 'S4E_45b_pyrenees_actif');

  if (switched) {
    // Ouvrir l'Entrainement du trek NON possede -> etat VERROUILLE attendu.
    _push(tester, '/training', persona);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, persona, 'S4E_02_entrainement_verrouille');
    final unlockCta = present(find.textContaining('Débloquer'));
    final blurredLock = present(find.byIcon(Icons.lock_outline)) ||
        present(find.byIcon(Icons.lock));
    logStep(
        persona,
        'achat',
        'Entrainement (trek NON possede) : CTA « Débloquer » visible = '
            '$unlockCta ; apercu verrouille (cadenas) = $blurredLock '
            '(ATTENDU true — trek a la carte non achete). #D02/#D03 : la prepa '
            'premium exige l\'achat pour un trek non possede.');
    // EXIGENCE (contre-preuve du point sensible) : le verrou DOIT exister sur
    // un trek NON possede. Sans cela, « rien n'est bloque hors-ligne » serait
    // vrai pour la mauvaise raison — tout serait ouvert a tout le monde.
    exige(persona, 'achat', unlockCta,
        'un trek NON POSSEDE presente bien son verrou d achat '
        '(contre-preuve : l acces premium n est pas ouvert a tous)');

    // Ouvrir le PAYWALL (wallet d'abord, complement store) et VERIFIER son
    // contenu (bouton d'achat + avantages). #D06/#D07 : le CTA rewarded
    // (« sans pub 24 h ») n'apparait QUE si le consentement pub est obtenu ;
    // en test il est REFUSE -> on documente son absence (pas un defaut).
    if (unlockCta) {
      await tapIfPresent(tester, find.textContaining('Débloquer'), persona,
          'achat', 'ouvrir le paywall (Debloquer)', warnIfMissing: false);
      await tapIfPresent(tester, find.text('Debloquer'), persona, 'achat',
          'ouvrir le paywall (Debloquer sans accent)', warnIfMissing: false);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
      await settleAndShoot(tester, persona, 'S4E_03_paywall');
      final onPaywall = present(find.byKey(const Key('paywall-buy-button'))) ||
          present(find.textContaining('Débloquez cette randonnée'));
      final rewardedBtn =
          present(find.byKey(const Key('paywall-rewarded-button')));
      logStep(
          persona,
          'achat',
          'Paywall ouvert = $onPaywall (bouton d\'achat present -> wallet '
              'd\'abord puis complement store, #D02/#D03). CTA rewarded « sans '
              'pub 24 h » present = $rewardedBtn (ATTENDU false en test : '
              'consentement pub REFUSE -> pas de banniere/rewarded. #D06/#D07 '
              'documente comme non jouable sans consentement UMP).');
      // Fermer le paywall SANS acheter (pas d'achat reel en test) : glisser le
      // sheet vers le bas ou taper hors du sheet.
      await tester.tapAt(const Offset(20, 20));
      await pumpAndSettleTolerant(tester);
      await settleAndShoot(tester, persona, 'S4E_03b_paywall_ferme');
    }
  } else {
    logStep(persona, 'achat',
        'COINCE : bascule vers gr-pyrenees impossible (bouton introuvable) -> '
        '#D02/#D03 non joues (pas de trek non possede atteignable). Signal QA.');
  }

  // --- #D06/#D07 BANNIERE gratuit : constat sur l'entrainement libre ---
  // La banniere AdMob (gratuit) ne se rend que si le consentement UMP est
  // obtenu. En test il est refuse (dismissAdsConsentIfPresent) -> aucune
  // banniere. On CONSTATE (aucun AdWidget/banniere) pour documenter #D06/#D07.
  final hasAdBanner = _hasWidgetTypeNamed('AdWidget') ||
      present(find.textContaining('Publisher Test Ads'));
  logStep(persona, 'ads',
      'CONSTAT #D06/#D07 : banniere pub visible = $hasAdBanner (ATTENDU false '
      'sous consentement refuse en test). La regle d\'or sans-pub (reward 24 h) '
      'et la banniere gratuit exigent le consentement UMP -> non jouables en '
      'rejeu automatise (documente pour Chris, pas un defaut app).');

  // --- Restauration : revenir a la VITRINE (mare-a-mare-centre) ---
  // On remet le sentier vitrine actif pour laisser un etat propre (le reste des
  // scenarios/relances suppose la vitrine debloquee).
  _push(tester, '/trail-selection', persona);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  await tapIfPresent(
      tester, find.byKey(const ValueKey('trail-select-mare-a-mare-centre')),
      persona, 'restore', 'restaurer la vitrine mare-a-mare-centre',
      warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  logStep(persona, 'restore',
      'Vitrine mare-a-mare-centre restauree comme sentier actif '
      '(loc=${_currentLocation(tester)}). Etat propre pour la suite.');
  await _goHome(tester, persona);
  await settleAndShoot(tester, persona, 'S4E_zz_retour_cockpit');
}
