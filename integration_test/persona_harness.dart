// ignore_for_file: avoid_print
//
// Harnais commun des tests PERSONAS joues EN DIRECT sur l'emulateur (tache 518).
//
// Ce fichier NE MODIFIE PAS le code applicatif : il ne fait que PILOTER l'UI
// reelle (taps, saisies, navigation) et CAPTURER l'ecran a chaque etape. Chaque
// scenario lance la VRAIE application (`app.main()`), observe ce qui s'affiche,
// et LOGue precisement OU CA COINCE (widget introuvable, ecran faux, blocage) —
// c'est le signal QA attendu par la mission.
//
// Principes :
//  * Resilience : les helpers `tapIfPresent` / `scrollUntil` ne FONT PAS ECHOUER
//    le scenario si une cible manque — ils l'enregistrent comme un COINCEMENT et
//    laissent le scenario continuer (la mission : « joue ce que tu peux, decris
//    le reste »).
//  * Observabilite : `settleAndShoot` compose des frames + capture PNG (dossier
//    data/captures_personas/) + laisse un temps de pause pour que Chris voie
//    l'action a l'ecran.
//  * Journalisation : chaque pas ecrit une ligne structuree (persona/etape) que
//    le rapport agrege.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Journal partage des scenarios (une ligne par pas).
///
/// IMPORTANT : le code du test s'execute SUR L APPAREIL (emulateur), pas sur
/// l'hote. On ne peut donc PAS ecrire dans un chemin Windows depuis ici. Le
/// journal est donc IMPRIME (visible dans la sortie `flutter drive`/`test`) et
/// aussi RENVOYE au driver host-side (`kBinding.reportData`) qui, lui, ecrit sur
/// le disque de l'hote (captures + journal). Les CAPTURES suivent le meme
/// chemin : `takeScreenshot` enregistre l'image, le driver la persiste en PNG.
final List<String> kJournal = <String>[];

/// Binding d'integration (permet la capture d'ecran + le renvoi de donnees).
late IntegrationTestWidgetsFlutterBinding kBinding;

/// Delai d'observation apres chaque capture (Chris regarde en direct).
const Duration kObserve = Duration(milliseconds: 900);

/// Delai laisse au DEMON host-side pour faire `adb screencap` apres le marqueur.
const Duration kShotWait = Duration(milliseconds: 700);

/// Initialise le binding + la surface de capture. A appeler AVANT tout scenario.
IntegrationTestWidgetsFlutterBinding initHarness() {
  kBinding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Rendu reel a l'ecran pendant les captures (sinon le binding « saute » des
  // frames et l'emulateur n'affiche pas l'action). Cf. doc integration_test.
  kBinding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  return kBinding;
}

/// Ajoute une ligne au journal + l'imprime (visible dans la sortie du test).
void logStep(String persona, String etape, String message) {
  final ts = DateTime.now().toIso8601String();
  final line = '[$ts] [$persona/$etape] $message';
  kJournal.add(line);
  print('PERSONA_LOG $line');
}

/// Compose les frames puis SIGNALE une capture au demon host-side.
///
/// POURQUOI PAS `takeScreenshot`/driver : quand un trek est actif, l'app demarre
/// un isolate de fond (flutter_background_service) qui garde le moteur vivant ->
/// `flutter drive` ne se DECONNECTE jamais proprement et les captures (ecrites a
/// la sortie du driver) sont PERDUES (timeout kill). On decouple donc la capture
/// du driver : on IMPRIME un marqueur unique dans logcat (`SHOT|<fichier>`) et un
/// DEMON host-side (`adb logcat` -> `adb exec-out screencap`) ecrit le PNG en
/// direct. Robuste pour TOUS les ecrans, y compris la carte GL et trek actif.
Future<void> settleAndShoot(
  WidgetTester tester,
  String persona,
  String name, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  await pumpAndSettleTolerant(tester, timeout: timeout);
  await Future<void>.delayed(kObserve);
  final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final fileName = '${persona}_$safe';
  // Marqueur machine pour le demon host-side (screencap).
  print('PERSONA_SHOT|$fileName');
  logStep(persona, 'capture', 'capture demandee : $fileName');
  // Laisse le temps au demon de declencher `adb screencap` sur l'ecran courant.
  await Future<void>.delayed(kShotWait);
}

/// `pumpAndSettle` TOLERANT : compose des frames jusqu'a [timeout] sans lever si
/// l'arbre ne se stabilise jamais (spinner/carte/pub). Retourne quand l'arbre
/// est au repos OU que le temps est ecoule.
Future<void> pumpAndSettleTolerant(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 120),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) break;
  }
}

/// Tape sur le premier widget correspondant a [finder] s'il existe.
///
/// Retourne true si le tap a eu lieu. Sinon, LOGue un COINCEMENT (widget
/// introuvable = signal QA) et retourne false — SANS faire echouer le scenario.
Future<bool> tapIfPresent(
  WidgetTester tester,
  Finder finder,
  String persona,
  String etape,
  String quoi, {
  bool warnIfMissing = true,
}) async {
  // 1) Deja hit-testable a l'ecran : tap direct.
  var f = finder.hitTestable();
  if (f.evaluate().isNotEmpty) {
    await tester.tap(f.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
    logStep(persona, etape, 'TAP OK : $quoi');
    return true;
  }
  // 2) Present dans l'arbre mais hors ecran : tenter de le rendre visible
  //    (ensureVisible) puis retester le hit-test — un tap honnete uniquement si
  //    la cible est reellement atteignable.
  if (finder.evaluate().isNotEmpty) {
    try {
      await tester.ensureVisible(finder.first);
      await pumpAndSettleTolerant(tester);
    } catch (_) {
      // ensureVisible echoue s'il n'y a pas de Scrollable ancetre : on continue.
    }
    f = finder.hitTestable();
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(persona, etape, 'TAP OK (apres ensureVisible) : $quoi');
      return true;
    }
    // Present mais NON atteignable (recouvert/hors zone) : signal QA honnete.
    logStep(persona, etape,
        'COINCE : cible presente mais NON atteignable (hit-test vide) -> $quoi');
    return false;
  }
  if (warnIfMissing) {
    logStep(persona, etape, 'COINCE : cible introuvable -> $quoi');
  }
  return false;
}

/// Fait defiler jusqu'a rendre [target] visible (max [maxScrolls]).
///
/// Retourne true si la cible est trouvee. Sinon LOGue un COINCEMENT. Ne leve pas.
Future<bool> scrollUntil(
  WidgetTester tester,
  Finder target,
  String persona,
  String etape,
  String quoi, {
  Finder? scrollable,
  double delta = 320,
  int maxScrolls = 12,
}) async {
  if (target.evaluate().isNotEmpty) return true;
  Finder scroller;
  if (scrollable != null) {
    scroller = scrollable;
  } else if (find.byType(Scrollable).evaluate().isNotEmpty) {
    scroller = find.byType(Scrollable).first;
  } else {
    logStep(persona, etape, 'COINCE : aucun Scrollable pour atteindre $quoi');
    return false;
  }
  for (var i = 0; i < maxScrolls; i++) {
    if (scroller.evaluate().isEmpty) break;
    await tester.drag(scroller, Offset(0, -delta));
    await pumpAndSettleTolerant(tester);
    if (target.evaluate().isNotEmpty) {
      logStep(persona, etape, 'SCROLL -> visible : $quoi (apres ${i + 1})');
      return true;
    }
  }
  logStep(persona, etape,
      'COINCE : cible non atteinte apres defilement -> $quoi');
  return false;
}

/// Saisit [text] dans le premier champ de [finder] s'il existe.
Future<bool> enterIfPresent(
  WidgetTester tester,
  Finder finder,
  String text,
  String persona,
  String etape,
  String quoi,
) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.enterText(finder.first, text);
    await pumpAndSettleTolerant(tester);
    logStep(persona, etape, 'SAISIE "$text" : $quoi');
    return true;
  }
  logStep(persona, etape, 'COINCE : champ introuvable -> $quoi');
  return false;
}

/// Vrai si un widget correspondant a [finder] est actuellement present.
bool present(Finder finder) => finder.evaluate().isNotEmpty;

/// Finder BILINGUE (FR + EN) sur du texte exact — l'emulateur peut demarrer en
/// anglais (locale en-US) alors que le PLAN vise le francais. On cherche l'un OU
/// l'autre libelle pour rester robuste quelle que soit la langue detectee.
Finder textFrEn(String fr, String en) =>
    find.byWidgetPredicate((w) => w is Text && (w.data == fr || w.data == en));

/// Attend l'apparition de [finder] jusqu'a [timeout] (utile au boot : bootstrap
/// + seed + pub peuvent retarder le 1er ecran interactif). Retourne true si vu.
Future<bool> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 12),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return finder.evaluate().isNotEmpty;
}

/// Ferme le formulaire de consentement pub (UMP/AdMob « Publisher Test Ads »)
/// s'il s'affiche au 1er lancement (surtout en ligne). On refuse le consentement
/// (« Do not consent / Ne pas consentir ») — c'est neutre pour la demo et ca
/// debloque l'ecran. Best effort, ne casse rien s'il est absent.
Future<bool> dismissAdsConsentIfPresent(
  WidgetTester tester,
  String persona,
) async {
  final refuse = find.byWidgetPredicate((w) =>
      w is Text &&
      (w.data == 'Do not consent' ||
          w.data == 'Ne pas consentir' ||
          w.data == 'Gérer les options' ||
          w.data == 'Manage options'));
  final consent = find.byWidgetPredicate((w) =>
      w is Text && (w.data == 'Consent' || w.data == 'Consentir'));
  if (present(refuse) || present(consent)) {
    logStep(persona, 'consent',
        'Formulaire consentement pub (UMP) present — on refuse pour debloquer');
    if (!await tapIfPresent(tester, refuse, persona, 'consent',
        'Ne pas consentir/Do not consent', warnIfMissing: false)) {
      await tapIfPresent(tester, consent, persona, 'consent',
          'Consent (repli)', warnIfMissing: false);
    }
    await pumpAndSettleTolerant(tester);
    return true;
  }
  return false;
}

/// Termine l'onboarding s'il est present (bilingue). Attend d'abord qu'il
/// apparaisse (le boot est lent) ; s'il n'apparait pas, considere qu'il est deja
/// passe. Ferme d'abord un eventuel consentement pub. Tape « Passer/Skip »
/// (raccourci) puis, en repli, enchaine les « Suivant/Next » et « Commencer ».
///
/// Retourne true si un onboarding a ete traite, false s'il etait absent.
Future<bool> completeOnboardingIfPresent(
  WidgetTester tester,
  String persona,
) async {
  // Le consentement pub peut recouvrir l'onboarding : le fermer d'abord.
  await dismissAdsConsentIfPresent(tester, persona);
  final skip = textFrEn('Passer', 'Skip');
  final next = textFrEn('Suivant', 'Next');
  final start = textFrEn('Commencer', 'Get started');
  // Laisse le boot poser l'onboarding (ou le catalogue/mes-treks) a l'ecran.
  final appeared = await waitFor(tester, skip, timeout: const Duration(seconds: 10));
  if (!appeared && !present(next)) {
    logStep(persona, 'onboarding', 'Onboarding absent (deja complete)');
    return false;
  }
  logStep(persona, 'onboarding', 'Onboarding present — completion (bilingue)');
  // Voie rapide : « Passer / Skip ».
  if (await tapIfPresent(tester, skip, persona, 'onboarding', 'Passer/Skip',
      warnIfMissing: false)) {
    await pumpAndSettleTolerant(tester);
    return true;
  }
  // Repli : enchainer Suivant/Next (max 4) puis Commencer/Get started.
  for (var i = 0; i < 4; i++) {
    if (!await tapIfPresent(tester, next, persona, 'onboarding',
        'Suivant/Next (${i + 1})', warnIfMissing: false)) {
      break;
    }
  }
  await tapIfPresent(tester, start, persona, 'onboarding',
      'Commencer/Get started', warnIfMissing: false);
  return true;
}

/// Cloture le journal. Le contenu est deja integralement dans les lignes
/// `PERSONA_LOG` de la sortie du run (reconstruit host-side depuis le log) ; on
/// renvoie AUSSI via `reportData` au cas ou le driver sortirait proprement
/// (scenarios sans trek actif), et on imprime un marqueur de fin.
Future<void> flushJournal(String persona) async {
  final existing = kBinding.reportData ?? <String, dynamic>{};
  kBinding.reportData = <String, dynamic>{
    ...existing,
    'journal_$persona': kJournal.join('\n'),
  };
  print('PERSONA_END|$persona|${kJournal.length} lignes');
}
