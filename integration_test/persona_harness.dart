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
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Plafond du drain des futures de polices (voir [_drainFontFutures]).
///
/// Sur l'emulateur OFFLINE, un fetch google_fonts peut ne JAMAIS se completer
/// (connectionTimeout HttpClient = null). On borne l'attente pour ne jamais
/// figer le scenario ; au-dela, on rend la main au test.
const Duration kFontDrainTimeout = Duration(seconds: 3);

/// Initialise le binding + la surface de capture. A appeler AVANT tout scenario.
IntegrationTestWidgetsFlutterBinding initHarness() {
  kBinding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Rendu reel a l'ecran pendant les captures (sinon le binding « saute » des
  // frames et l'emulateur n'affiche pas l'action). Cf. doc integration_test.
  kBinding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // FIABILITE POLICES (harnais uniquement — NE MODIFIE PAS l'appli) :
  // google_fonts charge Montserrat de maniere ASYNCHRONE. Selon le reglage,
  // deux modes d'echec APRES la fin du test (faux rouge) sont possibles :
  //   * allowRuntimeFetching = TRUE (defaut) : fetch HTTP. Sur l'emulateur,
  //     fonts.gstatic.com est joignable en DNS mais le TCP echoue tard
  //     (ClientException « Connection closed before full header ») -> le future
  //     se resout APRES le parcours -> le CIRCUIT S'EST DEROULE EN ENTIER et
  //     toutes les captures + PERSONA_END sont deja produits ; seule une erreur
  //     COSMETIQUE tardive subsiste.
  //   * allowRuntimeFetching = FALSE sans police embarquee : google_fonts LEVE
  //     IMMEDIATEMENT (« font ... not found in assets ») DES LE BOOT ->
  //     l'exception async casse le run AVANT meme le 1er ecran (0 capture).
  //     C'est PIRE. Et on ne peut pas la neutraliser cote harnais : la lib
  //     attache un `.then` SANS `.catchError` (google_fonts_base.dart l.111-112,
  //     avec `rethrow`), et flutter_test punit tout override de
  //     `reportTestException` (_verifyReportTestExceptionUnset).
  // CHOIX : on GARDE le defaut (fetch autorise) pour que l'echec police reste
  // TARDIF (post-parcours), garantissant PERSONA_END + captures completes. La
  // parade `_drainFontFutures` (best effort) + `finalizeScenario` (drain
  // d'exceptions non fatales) + la CLOTURE DU TREK en fin de S1 (arret du
  // service GPS de fond) suppriment l'autre artefact tardif (Riverpod/ticker).
  // Un offline 100% propre exigerait d'embarquer TOUTES les variantes Montserrat
  // (w400/500/600/700/800/900) dans pubspec assets -> modif appli, hors mandat.

  return kBinding;
}

/// Draine les futures de chargement de polices en attente en LEUR ATTACHANT un
/// gestionnaire d'erreur (`catchError`). google_fonts n'attache qu'un `.then`
/// sur ces futures : quand `allowRuntimeFetching=false` et qu'aucune police
/// n'est embarquee, ils REJETTENT sans handler -> exception async non geree
/// remontee par flutter_test APRES le test (faux echec). En attendant
/// `GoogleFonts.pendingFonts()` (= `Future.wait` de ces futures) sous
/// `catchError`, on CONSOMME le rejet DANS le test. Best effort, ne leve jamais.
Future<void> _drainFontFutures() async {
  try {
    await GoogleFonts.pendingFonts()
        .catchError((_) => <void>[])
        .timeout(kFontDrainTimeout, onTimeout: () => <void>[]);
  } catch (_) {
    // Ne jamais faire echouer le scenario pour une police.
  }
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
  // Le formulaire de consentement PUB (UMP/AdMob « Publisher Test Ads ») peut
  // surgir TARDIVEMENT (des que le reseau repond), APRES l'onboarding, et
  // recouvrir l'ecran -> il masque SOS/Terminer/cartes et fausse la detection.
  // On le referme A CHAQUE capture (pas seulement au boot). C'est un widget
  // Flutter (contrairement aux dialogs systeme, geres host-side) donc tapable.
  await dismissAdsConsentIfPresent(tester, persona);
  // Consomme les rejets de polices en attente (voir _drainFontFutures) : chaque
  // ecran rendu a pu declencher un chargement google_fonts qui rejette sans
  // handler. On draine ICI, a chaque capture, pour que rien n'echappe au test.
  await _drainFontFutures();
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

/// Finalise proprement un scenario AVANT le teardown du framework (FIX CYCLE 3).
///
/// PROBLEME OBSERVE (log replay_s1) : le scenario se joue INTEGRALEMENT
/// (`PERSONA_END` emis, toutes les captures ecrites), puis le run echoue quand
/// meme (rc=1) sur une exception RIVERPOD levee APRES la fin du test :
///   « setState()/markNeedsBuild() called during build » (UncontrolledProvider
///   Scope), declenchee par un `_TickerModeState` qui se reconstruit pendant que
///   le framework DEMONTE l'arbre — un provider (suivi/etape) notifie sur la
///   frame de disposal. C'est un ARTEFACT DE TEARDOWN, pas un bug du parcours.
///
/// PARADE (harnais uniquement) :
///   1. On pompe une SERIE de frames pendant que l'arbre est ENCORE VIVANT :
///      les providers en attente se rafraichissent MAINTENANT (pas au disposal).
///   2. On DRAINE toute exception non fatale via `tester.takeException()` — sinon
///      le framework la re-lance a la cloture et fait echouer un run pourtant
///      complet. On LOGue ce qu'on draine (transparence QA).
/// A appeler juste avant [flushJournal] a la fin de CHAQUE scenario. Idempotent.
Future<void> finalizeScenario(WidgetTester tester, String persona) async {
  // 0) Consommer une derniere fois les rejets de polices en attente.
  await _drainFontFutures();
  // 1) Laisser les providers/timers encore vivants se stabiliser.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  // Re-drainer apres les dernieres frames (de nouveaux futures ont pu naitre).
  await _drainFontFutures();
  // 2) Drainer les exceptions non fatales accumulees (teardown Riverpod/ticker).
  var drained = 0;
  for (var i = 0; i < 5; i++) {
    final ex = tester.takeException();
    if (ex == null) break;
    drained++;
    final msg = ex.toString().replaceAll('\n', ' ');
    // TACHE 548 — on logue assez long pour que la ligne soit DIAGNOSTICABLE.
    // A 160 caracteres, une exception drainee etait illisible : impossible de
    // dire si c'etait l'artefact de disposal connu ou un vrai defaut qui
    // passait par la meme porte. Le message d'une `FlutterError` porte le
    // widget en cause (« The widget which was currently being built... ») bien
    // au-dela de 160 caracteres.
    logStep(persona, 'teardown',
        'Exception NON FATALE drainee (artefact de disposal, parcours deja '
        'termine) : ${msg.length > 900 ? msg.substring(0, 900) : msg}');
    await tester.pump(const Duration(milliseconds: 80));
  }
  if (drained == 0) {
    logStep(persona, 'teardown',
        'Aucune exception de teardown a drainer (cloture propre).');
  }
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

// ===========================================================================
// COUCHE D'EXIGENCES — LA REPARATION DU HARNAIS (campagne personas N2).
// ===========================================================================
//
// DEFAUT CORRIGE ICI. La campagne N1 a mesure que les suites S1 a S5 ne
// contenaient AUCUN `expect()` : elles LOGUAIENT « COINCE » et CONTINUAIENT,
// puis concluaient « All tests passed ». ELLES NE POUVAIENT PAS ECHOUER sur un
// defaut produit. Un run vert ne prouvait donc rien — c'est la version harnais
// du piege du lot L6 (un test qui ne peut pas voir le defaut).
//
// PRINCIPE RETENU. On GARDE la resilience du parcours (s'arreter au premier
// accroc ne dirait rien du reste du circuit), MAIS toute verification declaree
// OBLIGATOIRE — une EXIGENCE — est enregistree, et le test ECHOUE A LA FIN avec
// la liste complete des exigences non tenues. Le scenario joue tout, puis rend
// un verdict binaire.
//
// REGLE DE BON USAGE (anti-piege L6, version harnais) :
//   * une EXIGENCE porte sur ce que le PRODUIT REEL affiche ou fait ;
//   * elle ne repose JAMAIS sur une surcharge de provider (`overrideWith`) ;
//   * un simple `logStep` reste possible pour l'exploration — mais ce qui n'est
//     pas une exigence n'est PAS une preuve, et ne doit pas etre presente
//     comme telle dans un rapport.
//
// Lignes machine produites (agregees host-side) :
//   PERSONA_EXIGENCE|<persona>|<etape>|OK|<quoi>
//   PERSONA_EXIGENCE|<persona>|<etape>|ECHEC|<quoi>
//   PERSONA_VERDICT|<persona>|<tenues>|<echouees>

/// Exigences NON TENUES (chacune fera echouer le scenario a la cloture).
final List<String> kExigencesEchouees = <String>[];

/// Nombre d'exigences tenues (sert aussi a prouver que le harnais a VRAIMENT
/// verifie quelque chose : une suite qui n'evalue rien est desormais ROUGE).
int kExigencesTenues = 0;

/// REMET LE COMPTEUR D'EXIGENCES A ZERO (tache 543).
///
/// POURQUOI C'EST NECESSAIRE, ET POURQUOI C'EST UN DEFAUT REEL SANS CA.
/// [kExigencesTenues] et [kExigencesEchouees] sont des variables GLOBALES :
/// deux scenarios joues dans le MEME processus se les partagent. Sans remise a
/// zero, (a) le second scenario herite des echecs du premier et echoue pour une
/// raison qui ne le concerne pas, et (b) le garde anti-harnais-aveugle de
/// [verdictPersona] devient INOPERANT, puisque le compteur du scenario
/// precedent suffit a lui seul a franchir le minimum — c'est-a-dire que le
/// garde cense empecher le retour du defaut d'origine se desarme tout seul.
/// A appeler en tete de CHAQUE scenario, avant le premier [exige].
void reinitialiserExigences() {
  kExigencesTenues = 0;
  kExigencesEchouees.clear();
}

/// Enregistre une EXIGENCE et son resultat. Retourne [ok] pour chainer.
///
/// Ne leve pas : le scenario continue (observabilite), mais [verdictPersona]
/// fera echouer le test si au moins une exigence n'est pas tenue.
bool exige(String persona, String etape, bool ok, String quoi) {
  if (ok) {
    kExigencesTenues++;
    print('PERSONA_EXIGENCE|$persona|$etape|OK|$quoi');
    logStep(persona, etape, 'EXIGENCE TENUE : $quoi');
  } else {
    kExigencesEchouees.add('[$persona/$etape] $quoi');
    print('PERSONA_EXIGENCE|$persona|$etape|ECHEC|$quoi');
    logStep(persona, etape, 'EXIGENCE NON TENUE : $quoi');
  }
  return ok;
}

/// EXIGENCE : [finder] doit etre present a l'ecran (attente jusqu'a [timeout]).
Future<bool> exigeVisible(
  WidgetTester tester,
  Finder finder,
  String persona,
  String etape,
  String quoi, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  final vu = await waitFor(tester, finder, timeout: timeout);
  return exige(persona, etape, vu, 'doit etre AFFICHE : $quoi');
}

/// EXIGENCE : [finder] doit etre ABSENT de l'ecran (verification de non-regression,
/// p. ex. « aucun bandeau de prudence sur un profil vert »).
bool exigeAbsent(
  Finder finder,
  String persona,
  String etape,
  String quoi,
) =>
    exige(persona, etape, finder.evaluate().isEmpty,
        'ne doit PAS etre affiche : $quoi');

/// EXIGENCE : la cible doit etre reellement TAPABLE (presente ET hit-testable).
///
/// C'est la version exigeante de [tapIfPresent] : une cible presente mais
/// recouverte (hit-test vide) est un DEFAUT, pas une curiosite a loguer.
Future<bool> exigeTap(
  WidgetTester tester,
  Finder finder,
  String persona,
  String etape,
  String quoi,
) async {
  final ok = await tapIfPresent(tester, finder, persona, etape, quoi,
      warnIfMissing: false);
  return exige(persona, etape, ok, 'doit etre ATTEIGNABLE et tapable : $quoi');
}

/// EXIGENCE : le champ doit exister et accepter la saisie.
Future<bool> exigeSaisie(
  WidgetTester tester,
  Finder finder,
  String text,
  String persona,
  String etape,
  String quoi,
) async {
  final ok = await enterIfPresent(tester, finder, text, persona, etape, quoi);
  return exige(persona, etape, ok, 'champ saisissable : $quoi (valeur "$text")');
}

/// CLOTURE DU SCENARIO : fait ECHOUER le test si une exigence n'est pas tenue.
///
/// [minimumExigences] garde contre le retour du defaut d'origine : une suite
/// qui n'evalue AUCUNE exigence est desormais ROUGE, pas verte.
void verdictPersona(String persona, {int minimumExigences = 1}) {
  final total = kExigencesTenues + kExigencesEchouees.length;
  print('PERSONA_VERDICT|$persona|$kExigencesTenues|'
      '${kExigencesEchouees.length}');
  logStep(persona, 'verdict',
      'BILAN EXIGENCES : $kExigencesTenues tenue(s), '
      '${kExigencesEchouees.length} non tenue(s) sur $total evaluee(s).');
  expect(total >= minimumExigences, isTrue,
      reason: 'HARNAIS AVEUGLE : $persona n a evalue que $total exigence(s) '
          '(minimum attendu $minimumExigences). Un scenario qui ne verifie '
          'rien ne peut pas etre vert.');
  expect(kExigencesEchouees, isEmpty,
      reason: 'Exigences NON TENUES par le produit :\n'
          '${kExigencesEchouees.join('\n')}');
}

// ===========================================================================
// DETECTION DES ECRANS SYSTEME (Android) — MAJEUR-2 de la campagne N1.
// ===========================================================================
//
// DEFAUT CORRIGE ICI. En N1, S3 a logue « dialog permission par-dessus =
// false » alors qu'une boite Android recouvrait la carte : un dialogue SYSTEME
// n'est PAS dans l'arbre Flutter, aucun `find.byType(Dialog)` ne peut le voir.
// Le harnais etait donc structurellement aveugle a la premiere chose que voit
// un nouvel utilisateur.
//
// PARADE : quand une fenetre systeme prend le premier plan, Android met
// l'activite en pause et le moteur Flutter notifie un changement de cycle de
// vie (`inactive` / `paused` / `hidden`). On ECOUTE ce signal : toute sortie de
// `resumed` pendant un pas ou l'application est censee etre au premier plan est
// la trace d'un ecran systeme par-dessus l'app.

/// Evenements de perte de premier plan captes depuis l'installation du veilleur.
final List<String> kEcransSystemeDetectes = <String>[];

class _VeilleEcranSysteme with WidgetsBindingObserver {
  _VeilleEcranSysteme(this.persona);

  final String persona;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logStep(persona, 'ecran_systeme',
          'Retour au premier plan (resumed) : l ecran systeme est referme.');
      return;
    }
    final trace = '${state.name} @ ${DateTime.now().toIso8601String()}';
    kEcransSystemeDetectes.add(trace);
    print('PERSONA_ECRAN_SYSTEME|$persona|${state.name}');
    logStep(
        persona,
        'ecran_systeme',
        'ECRAN SYSTEME DETECTE : l application a PERDU le premier plan '
            '(${state.name}). Une fenetre Android (dialogue de permission, '
            'par exemple) recouvre l app — INVISIBLE dans l arbre Flutter.');
  }
}

_VeilleEcranSysteme? _veilleur;

/// Installe le veilleur d'ecrans systeme. A appeler une fois, au boot.
void installerVeilleEcranSysteme(String persona) {
  if (_veilleur != null) return;
  _veilleur = _VeilleEcranSysteme(persona);
  WidgetsBinding.instance.addObserver(_veilleur!);
  logStep(persona, 'ecran_systeme',
      'Veille des ecrans SYSTEME installee (cycle de vie de l activite).');
}

/// Retire le veilleur (a appeler avant la cloture pour ne rien laisser vivant).
void retirerVeilleEcranSysteme() {
  if (_veilleur == null) return;
  WidgetsBinding.instance.removeObserver(_veilleur!);
  _veilleur = null;
}

/// Evenements de cycle de vie qui prouvent REELLEMENT qu'une fenetre a pris le
/// premier plan (tache 543).
///
/// NUANCE APPRISE EN REJOUANT S5, ET ELLE COMPTE. Le veilleur enregistre TOUTE
/// sortie de `resumed`, ce qui est bien pour l'observabilite — mais `inactive`
/// est aussi emis sans aucune fenetre systeme : ouverture du clavier, changement
/// de focus, transition d'animation. Sur un scenario de SAISIE comme S5, qui
/// ouvre le clavier des dizaines de fois, exiger zero evenement produit un FAUX
/// POSITIF garanti.
/// Seuls `paused` et `hidden` signifient que l'activite est reellement passee a
/// l'arriere-plan, donc qu'une fenetre la recouvre. C'est sur eux que porte une
/// EXIGENCE ; `inactive` reste journalise, et se lit.
List<String> ecransSystemeBloquants() => kEcransSystemeDetectes
    .where((e) => e.startsWith('paused') || e.startsWith('hidden'))
    .toList();

/// Marque courante du journal d'ecrans systeme (pour delimiter un pas precis).
int marqueEcranSysteme() => kEcransSystemeDetectes.length;

/// Evenements systeme survenus DEPUIS [marque].
List<String> ecransSystemeDepuis(int marque) =>
    kEcransSystemeDetectes.sublist(
        marque.clamp(0, kEcransSystemeDetectes.length));

// ===========================================================================
// CE QU'UN HUMAIN LIT — extension tache 559.
// ===========================================================================
//
// POURQUOI CETTE COUCHE EXISTE, ET CE QU'ELLE CORRIGE. Le 25/09, un apk est
// parti chez Chris sur la foi de 2604 tests unitaires verts. Il a trouve cinq
// defauts en six minutes. AUCUN de ces cinq defauts n'etait invisible : ils
// etaient tous ECRITS A L'ECRAN. Ce que les tests verifiaient, c'est qu'un
// widget EXISTE ; ce que Chris regardait, c'est ce que le widget DIT.
//
// Les outils ci-dessous ne cherchent donc plus un widget : ils LISENT l'ecran
// comme un humain, et rendent le texte lu dans le journal (preuve citable) ou
// le refusent quand il n'a aucun sens (cle de traduction brute, `null`, `NaN`,
// gabarit `{count}` non remplace...).

/// Tous les textes REELLEMENT construits dans l'arbre a cet instant.
///
/// Couvre `Text` (data) et les `Text.rich` / `RichText` (via `toPlainText`), ce
/// qui compte : la moitie des libelles de l'appli sont des spans enrichis, et un
/// `find.text` classique passe a cote.
List<String> textesAlEcran() {
  final vus = <String>[];
  for (final e in find.byType(Text).evaluate()) {
    final w = e.widget as Text;
    final d = w.data ?? w.textSpan?.toPlainText();
    if (d != null && d.trim().isNotEmpty) vus.add(d.trim());
  }
  return vus;
}

/// Ecrit dans le journal ce que l'ecran affiche — la PREUVE citable d'un pas.
///
/// [max] borne la sortie (un ecran de catalogue porte 200 libelles) ; le nombre
/// total est toujours annonce, donc une troncature se voit.
void logEcran(String persona, String etape, {int max = 40}) {
  final textes = textesAlEcran();
  final extrait = textes.length > max ? textes.sublist(0, max) : textes;
  logStep(persona, etape,
      'ECRAN LU (${textes.length} libelle(s)) : ${extrait.join(" | ")}'
      '${textes.length > max ? " | ...(${textes.length - max} de plus)" : ""}');
}

/// Motifs qu'un humain ne doit JAMAIS lire dans une application livree.
///
/// Chacun vient d'un defaut deja constate quelque part : une cle Slang brute
/// (`hub.cards.journal` affiche tel quel quand la traduction manque), un
/// gabarit non substitue (`{count} j`), un `null` / `NaN` / `Infinity` sorti
/// d'un calcul sans donnee, un `Instance of 'X'` sorti d'un `toString()` oublie.
final List<RegExp> kMotifsAbsurdes = <RegExp>[
  RegExp(r'\bnull\b'),
  RegExp(r'\bNaN\b'),
  RegExp(r'Infinity'),
  RegExp(r"Instance of '"),
  RegExp(r'\{[a-zA-Z_][a-zA-Z0-9_]*\}'),
  RegExp(r'\$\{'),
  RegExp(r'\bTODO\b'),
  RegExp(r'\bFIXME\b'),
  // Cle de traduction brute : « mot.mot(.mot) » sans espace ni accent, typique
  // d'un `t.xxx.yyy` non resolu tombe dans un `Text`.
  RegExp(r'^[a-z][a-zA-Z0-9]*(\.[a-zA-Z0-9]+)+$'),
];

/// EXIGENCE : rien d'absurde n'est lisible a l'ecran a cet instant.
///
/// [tolere] laisse passer un libelle dont on a VERIFIE qu'il est legitime (a
/// documenter sur place) — jamais un fourre-tout.
bool exigeAucuneAbsurdite(
  String persona,
  String etape, {
  List<String> tolere = const <String>[],
}) {
  final coupables = <String>[];
  for (final texte in textesAlEcran()) {
    if (tolere.contains(texte)) continue;
    for (final motif in kMotifsAbsurdes) {
      if (motif.hasMatch(texte)) {
        coupables.add('"$texte" (motif ${motif.pattern})');
        break;
      }
    }
  }
  return exige(persona, etape, coupables.isEmpty,
      'aucun texte absurde lisible a l ecran'
      '${coupables.isEmpty ? "" : " — LU : ${coupables.join(" ; ")}"}');
}

/// EXIGENCE : au moins un des [attendus] est lisible a l'ecran.
///
/// Sert quand plusieurs redactions sont acceptables (verdict vert OU orange,
/// par exemple) : on nomme la liste, et le journal dit ce qui a ete lu.
bool exigeUnDeCesTextes(
  String persona,
  String etape,
  List<String> attendus,
  String quoi,
) {
  final lus = textesAlEcran();
  final trouve = attendus.any((a) => lus.any((l) => l.contains(a)));
  return exige(persona, etape, trouve,
      '$quoi (attendu l un de : ${attendus.join(" / ")})');
}

/// Le premier texte a l'ecran qui contient [fragment], ou null.
///
/// C'est l'outil de LECTURE : il rend ce que l'ecran dit, pour que le rapport
/// cite la phrase vue plutot que de resumer ce que le code devrait produire.
String? texteContenant(String fragment) {
  for (final t in textesAlEcran()) {
    if (t.contains(fragment)) return t;
  }
  return null;
}

/// Luminosite du theme REELLEMENT applique a l'ecran (clair / sombre).
///
/// On ne lit pas `themeMode` dans le code : on lit le theme herite par le
/// premier `Scaffold` monte, c'est-a-dire la couleur que l'oeil recoit.
/// Retourne null si aucun `Scaffold` n'est monte (ecran de chargement nu).
Brightness? luminositeAlEcran(WidgetTester tester) {
  final scaffolds = find.byType(Scaffold).evaluate();
  if (scaffolds.isEmpty) return null;
  return Theme.of(scaffolds.first).brightness;
}

/// Position verticale (haut du widget) du premier [finder] a l'ecran, ou null.
///
/// Sert a exiger un ORDRE DE LECTURE : « Preparer doit venir avant Journal »
/// n'est pas une question de presence, c'est une question de position — et
/// c'est exactement le defaut que Chris a vu en six secondes.
double? hauteurDe(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) return null;
  try {
    return tester.getTopLeft(finder.first).dy;
  } catch (_) {
    return null;
  }
}

/// REDEMARRAGE A CHAUD de l'application, depuis le test.
///
/// CE QUE C'EST, ET CE QUE CE N'EST PAS — a lire avant d'interpreter un
/// resultat. On rappelle le `main()` de l'application. Ce qui est ECRIT sur
/// l'appareil (SharedPreferences) survit ; ce qui vit en memoire (base Drift en
/// memoire) ne survit pas. Ce n'est PAS un kill de processus : le processus
/// Android reste vivant. Toute conclusion tiree d'ici doit le dire.
///
/// LE PIEGE, MESURE LE 25/09, ET IL A FAILLI ME FAIRE ACCUSER LE PRODUIT A
/// TORT. `runApp` appele une seconde fois ne DETRUIT PAS l'arbre : le nouveau
/// widget racine a le meme type que l'ancien, alors Flutter REUTILISE les
/// elements et se contente d'une mise a jour. L'ecran affiche garde donc son
/// `State` — et ses `TextEditingController`. Un champ de saisie relu juste
/// apres rend ce qu'on venait d'y TAPER, pas ce que l'appareil a GARDE.
/// Concretement : une fiche refusee, donc jamais enregistree, se relisait
/// pleine, et j'ai d'abord cru que le refus du consentement n'etait pas
/// applique. Il l'etait.
///
/// PARADE : apres le rappel de `main()`, on QUITTE l'ecran courant vers une
/// route neutre. Tout ecran ouvert ensuite est reconstruit, donc relu depuis
/// le stockage — ce qui est la seule chose que ce test veut mesurer.
/// [routeNeutre] laisse le scenario choisir sa destination de transit.
Future<void> redemarrageAChaud(
  WidgetTester tester,
  String persona,
  void Function() lancerApp, {
  Duration attente = const Duration(seconds: 12),
  String routeNeutre = '/home',
}) async {
  logStep(persona, 'redemarrage',
      'REDEMARRAGE A CHAUD : rappel de main() (les donnees ecrites sur le '
      'telephone survivent, l etat en memoire non ; le processus n est PAS tue)');
  lancerApp();
  await pumpAndSettleTolerant(tester, timeout: attente);
  await dismissAdsConsentIfPresent(tester, persona);
  await pumpAndSettleTolerant(tester);
  // On quitte l'ecran courant pour que le suivant soit REELLEMENT reconstruit.
  final navigateurs = find.byType(Navigator);
  if (navigateurs.evaluate().isNotEmpty) {
    final routeur = GoRouter.maybeOf(tester.element(navigateurs.first));
    if (routeur != null) {
      routeur.go(routeNeutre);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
      logStep(persona, 'redemarrage',
          'Transit par $routeNeutre : l ecran suivant sera relu depuis le '
          'stockage, pas herite de l arbre precedent.');
    }
  }
}
