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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logger/logger.dart';

import 'package:drift/drift.dart' show Value;

import 'package:moteur_gr/core/analytics/screen_breadcrumb.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/onboarding/presentation/onboarding_screen.dart';

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
///
/// PORTE DE 700 A 3000 ms A LA TACHE 665, ET VOICI LE CHIFFRE QUI LE JUSTIFIE.
/// Un `adb exec-out screencap` mesure sur l'emulateur coute 327 ms en median et
/// jusqu'a 764 ms en pointe (run S5 du 03/10) — et bien plus quand la carte GL
/// occupe le GPU. A 700 ms, l'intervalle entre deux marqueurs (kObserve 900 +
/// kShotWait 700 = 1,6 s) laissait moins du double du cout d'une capture : le
/// moindre ralentissement faisait partir la capture APRES que le harnais avait
/// rendu la main, et l'image montrait L'ECRAN SUIVANT. C'est le defaut trouve au
/// lot 645-05b (memoire #101082), ou plusieurs captures d'ecrans differents
/// portaient le meme contenu. A 3000 ms, l'intervalle est de 3,9 s, soit cinq
/// fois le cout de pointe mesure. Le prix est du temps de run (3 s par capture,
/// soit ~2 min de plus sur les 52 captures de S1) ; il est paye volontiers pour
/// des images qui disent la verite.
const Duration kShotWait = Duration(milliseconds: 3000);

/// Plafond du drain des futures de polices (voir [_drainFontFutures]).
///
/// Sur l'emulateur OFFLINE, un fetch google_fonts peut ne JAMAIS se completer
/// (connectionTimeout HttpClient = null). On borne l'attente pour ne jamais
/// figer le scenario ; au-dela, on rend la main au test.
const Duration kFontDrainTimeout = Duration(seconds: 3);

/// Budget de BASE d'attente du premier ecran (voir [attendreAccueilOuCockpit]).
///
/// Il n'y a plus de delai fixe au boot : ce budget est le PLANCHER, et il
/// s'etend jusqu'a [kBudgetPremierEcranMax] tant que le demarrage PROGRESSE.
const Duration kBudgetPremierEcranBase = Duration(seconds: 20);

/// Plafond d'attente du premier ecran sur INSTALLATION VIERGE (tache 685).
///
/// CE CHIFFRE EST UNE MESURE, PAS UNE MARGE DE CONFORT (kaizen #101252).
/// Le 05/10, sur un run joue apres desinstallation du paquet, `app.main()` est
/// parti a 07:56:59.158 et le harnais a declare « Onboarding absent (deja
/// complete) » a 07:57:12.972 — 13,8 s plus tard, c'est-a-dire a l'expiration
/// de son ancien delai FIXE de 10 s. La miette `screen:onboarding` de
/// l'observabilite (lot 645-09) est partie APRES, et la porte de consentement
/// de la sauvegarde a ete rencontree a 07:57:25.677 : l'accueil etait donc bel
/// et bien la, entre 13,8 s et 26,5 s apres le lancement. Le harnais a joue
/// toute la route DERRIERE le carrousel, et deux runs ont ete perdus sur
/// chaque arbre de la QA du 645-05c. 60 s, c'est plus du double du pire
/// premier affichage mesure.
const Duration kBudgetPremierEcranMax = Duration(seconds: 60);

/// CE QUE LE HARNAIS A TROUVE AU BOOT (tache 685).
enum EtatAuPremierEcran {
  /// L'accueil (carrousel d'onboarding) est a l'ecran.
  accueil,

  /// L'application est DEJA passee a la suite (cockpit, catalogue, mes treks) :
  /// l'onboarding a ete franchi lors d'une installation precedente.
  cockpit,

  /// NI l'un NI l'autre dans le budget. Jamais un « absent » par defaut.
  rien,
}

/// LES MIETTES D'ECRAN POSEES PAR L'APPLICATION, VUES DEPUIS LE HARNAIS
/// (observabilite du lot 645-09, lecture ajoutee a la tache 685).
///
/// `AnalyticsService.enterScreen` journalise `screen:<nom>` a CHAQUE entree
/// d'ecran, et le fait AVANT de regarder si Firebase est joignable : la miette
/// part donc meme sur un emulateur sans services Google. C'est l'etat REEL de
/// l'application, dit par l'application elle-meme — pas une interpretation de
/// l'arbre de widgets.
final List<String> kMiettesEcran = <String>[];

/// Vrai si l'ecoute des miettes est deja posee (le `Logger` est global).
bool _ecouteDesMiettesPosee = false;

/// POSE L'ECOUTE DES MIETTES D'ECRAN. Appelee par [initHarness], donc AVANT
/// `app.main()` : aucune miette du boot ne peut etre manquee.
///
/// `Logger.addLogListener` est appele pour CHAQUE evenement, et AVANT le filtre
/// de niveau : la miette de niveau `trace` arrive donc ici quel que soit le
/// reglage de journalisation. Le harnais NE MODIFIE RIEN de l'application : il
/// ecoute.
void poserLEcouteDesMiettesDEcran() {
  if (_ecouteDesMiettesPosee) return;
  _ecouteDesMiettesPosee = true;
  Logger.addLogListener((evenement) {
    final message = evenement.message;
    if (message is! String) return;
    if (!message.startsWith('screen:')) return;
    kMiettesEcran.add(message.substring('screen:'.length).trim());
  });
}

/// Remet le releve des miettes a zero (a appeler en tete de scenario).
void reinitialiserLesMiettesDEcran() => kMiettesEcran.clear();

/// Vrai si l'application a pose la miette de [ecran] depuis le debut du run.
bool mietteDEcranVue(ScreenBreadcrumb ecran) =>
    kMiettesEcran.contains(ecran.name);

/// Le chemin d'ecrans parcouru, tel qu'il part au journal du run.
String miettesLisibles() =>
    kMiettesEcran.isEmpty ? 'AUCUNE' : kMiettesEcran.join(' > ');

/// LES ECRANS QUI PROUVENT QUE L'ACCUEIL EST DEJA PASSE.
///
/// Ce sont les quatre portes d'entree possibles apres l'onboarding : le hub
/// (cockpit) quand un trek est en cours, le catalogue quand il faut encore
/// telecharger un sentier, « mes treks », et le mur affiche quand l'appareil
/// n'a aucune donnee. Une miette de l'une d'elles signifie que le carrousel
/// n'a RIEN a montrer — c'est une PREUVE, pas une absence de preuve.
const List<ScreenBreadcrumb> kEcransApresLAccueil = <ScreenBreadcrumb>[
  ScreenBreadcrumb.hub,
  ScreenBreadcrumb.trailCatalog,
  ScreenBreadcrumb.myTreks,
  ScreenBreadcrumb.noData,
];

/// Initialise le binding + la surface de capture. A appeler AVANT tout scenario.
IntegrationTestWidgetsFlutterBinding initHarness() {
  // L'ECOUTE DES MIETTES EST POSEE EN PREMIER : avant `app.main()`, donc avant
  // la premiere entree d'ecran. Une ecoute posee plus tard raterait le boot,
  // c'est-a-dire exactement le moment qu'on cherche a mesurer.
  poserLEcouteDesMiettesDEcran();
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
  // La porte de consentement de la sauvegarde systeme (tache 617) s'ouvre en
  // POST-FRAME : elle peut donc surgir a n'importe quelle capture, pas seulement
  // au boot. On la franchit ici aussi, exactement comme la pub.
  await dismissBackupConsentIfPresent(tester, persona);
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
    logStep(
      persona,
      etape,
      'COINCE : cible presente mais NON atteignable (hit-test vide) -> $quoi',
    );
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
  logStep(
    persona,
    etape,
    'COINCE : cible non atteinte apres defilement -> $quoi',
  );
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

/// LA PORTE DE CONSENTEMENT DE LA SAUVEGARDE SYSTEME (tache 617, mesuree le
/// 30/09 par la campagne 650).
///
/// CE QUE LA MESURE A MONTRE, ET POURQUOI CE HELPER EXISTE. Au premier
/// lancement du build 8, juste apres l'onboarding, l'application pose une
/// question de protection des donnees : « Tes donnees restent sur ce telephone »
/// ([BackupConsentGate] -> [RefusSauvegardeSystemeDialog]). C'est un
/// dialogue MODAL, et il recouvre tout. Le harnais ne le connaissait pas : il
/// tapait « Passer » sur l'onboarding, le dialogue s'ouvrait par-dessus, et la
/// route restait `/onboarding` pour le reste du scenario. TOUTE la campagne
/// tombait ensuite — catalogue introuvable, cockpit introuvable, faisabilite
/// introuvable — pour UNE seule cause, et cette cause n'etait pas un defaut du
/// produit : c'etait un ecran que le harnais ne savait pas franchir.
///
/// CE QU'ON FAIT, ET CE QU'ON NE FAIT PAS. On VALIDE la question telle qu'elle
/// se presente, sans toucher a la case : la case est cochee d'avance (le REFUS
/// de la sauvegarde cloud est le defaut) et c'est le choix le plus protecteur.
/// On ne decoche donc rien — un harnais qui changerait un consentement au
/// passage fausserait tous les scenarios RGPD qui suivent. On se contente de
/// REPONDRE, et on le journalise.
///
/// Best effort : ne casse rien si la question n'est pas posee (elle ne l'est
/// qu'une fois par installation).
Future<bool> dismissBackupConsentIfPresent(
  WidgetTester tester,
  String persona,
) async {
  final valider = find.byKey(
    const ValueKey('refus-sauvegarde-systeme-valider'),
  );
  if (valider.evaluate().isEmpty) return false;
  logStep(
    persona,
    'consent_sauvegarde',
    'Porte de consentement de la sauvegarde systeme (tache 617) presente — '
        'on VALIDE sans toucher a la case (le refus est le defaut).',
  );
  await tapIfPresent(
    tester,
    valider,
    persona,
    'consent_sauvegarde',
    'bouton de validation de la porte de consentement',
    warnIfMissing: false,
  );
  await pumpAndSettleTolerant(tester);
  return true;
}

/// Ferme le formulaire de consentement pub (UMP/AdMob « Publisher Test Ads »)
/// s'il s'affiche au 1er lancement (surtout en ligne). On refuse le consentement
/// (« Do not consent / Ne pas consentir ») — c'est neutre pour la demo et ca
/// debloque l'ecran. Best effort, ne casse rien s'il est absent.
Future<bool> dismissAdsConsentIfPresent(
  WidgetTester tester,
  String persona,
) async {
  final refuse = find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data == 'Do not consent' ||
            w.data == 'Ne pas consentir' ||
            w.data == 'Gérer les options' ||
            w.data == 'Manage options'),
  );
  final consent = find.byWidgetPredicate(
    (w) => w is Text && (w.data == 'Consent' || w.data == 'Consentir'),
  );
  if (present(refuse) || present(consent)) {
    logStep(
      persona,
      'consent',
      'Formulaire consentement pub (UMP) present — on refuse pour debloquer',
    );
    if (!await tapIfPresent(
      tester,
      refuse,
      persona,
      'consent',
      'Ne pas consentir/Do not consent',
      warnIfMissing: false,
    )) {
      await tapIfPresent(
        tester,
        consent,
        persona,
        'consent',
        'Consent (repli)',
        warnIfMissing: false,
      );
    }
    await pumpAndSettleTolerant(tester);
    return true;
  }
  return false;
}

/// L'ACCUEIL EST-IL A L'ECRAN ? Trois signaux, lus dans cet ordre.
///
/// 1. LE CARROUSEL LUI-MEME ([OnboardingScreen]) : le signal le plus direct,
///    et il ne depend d'aucun libelle. C'est le widget de l'accueil, pas une
///    chaine de caracteres qu'un renommage pourrait emporter.
/// 2. LA MIETTE `screen:onboarding` : l'application dit elle-meme qu'elle est
///    entree sur l'accueil. Elle reste vraie meme si le carrousel est, a cet
///    instant precis, recouvert par la porte de consentement.
/// 3. LES LIBELLES bilingues « Passer/Skip » et « Suivant/Next », conserves en
///    dernier recours pour les montages ou le widget n'est pas celui du
///    produit (harnais jetables de QA).
bool accueilPresent() =>
    present(find.byType(OnboardingScreen)) ||
    mietteDEcranVue(ScreenBreadcrumb.onboarding) ||
    present(textFrEn('Passer', 'Skip')) ||
    present(textFrEn('Suivant', 'Next'));

/// L'APPLICATION EST-ELLE DEJA PASSEE A LA SUITE ? Prouve par une miette de
/// [kEcransApresLAccueil] — jamais par l'absence de l'accueil.
bool cockpitAtteint() => kEcransApresLAccueil.any(mietteDEcranVue);

/// ATTEND L'ETAT REEL DU PREMIER ECRAN, AU LIEU DE DORMIR UN DELAI FIXE
/// (tache 685, kaizen #101252).
///
/// CE QUI EXISTAIT AVANT, ET CE QU'IL A COUTE. [completeOnboardingIfPresent]
/// donnait 10 SECONDES FIXES au libelle « Passer » pour apparaitre ; passe ce
/// delai, il journalisait « Onboarding absent (deja complete) » et rendait
/// `false`. Sur une INSTALLATION VIERGE — c'est-a-dire le cas normal de la
/// recette depuis la tache 676, qui desinstalle le paquet avant chaque run —
/// le premier affichage peut demander plus de 20 s. Le harnais concluait alors
/// a un onboarding absent AU MOMENT MEME ou l'application posait sa miette
/// `screen:onboarding`, et jouait tout le scenario DERRIERE le carrousel : deux
/// runs perdus sur chaque arbre de la QA du 645-05c (mesure du 05/10).
///
/// CE QU'ON FAIT A LA PLACE. On interroge l'ETAT, pas l'horloge :
///   * SORTIE ANTICIPEE des que l'accueil OU la suite est detectee — un
///     appareil rapide ne paie plus l'attente du plus lent ;
///   * BUDGET ADAPTATIF : [kBudgetPremierEcranBase] au plancher, etendu
///     jusqu'a [kBudgetPremierEcranMax] TANT QUE LE DEMARRAGE PROGRESSE (une
///     nouvelle miette d'ecran, un arbre de widgets qui change, ou une frame
///     encore programmee). Un boot qui avance obtient du temps ; un boot mort
///     ne fait pas attendre une minute pour rien ;
///   * ECHEC FRANC si rien n'apparait : [EtatAuPremierEcran.rien], que
///     l'appelant transforme en run ROUGE avec capture. Jamais un « absent
///     (deja complete) » par defaut.
Future<EtatAuPremierEcran> attendreAccueilOuCockpit(
  WidgetTester tester,
  String persona, {
  Duration budgetBase = kBudgetPremierEcranBase,
  Duration budgetMax = kBudgetPremierEcranMax,
  Duration pas = const Duration(milliseconds: 250),
}) async {
  final debut = DateTime.now();
  var echeance = debut.add(budgetBase);
  final plafond = debut.add(budgetMax);
  var miettesVues = kMiettesEcran.length;
  var tailleArbre = -1;

  while (DateTime.now().isBefore(echeance)) {
    await tester.pump(pas);

    if (accueilPresent()) {
      final ms = DateTime.now().difference(debut).inMilliseconds;
      logStep(
        persona,
        'onboarding',
        'Accueil DETECTE apres $ms ms (carrousel ou miette '
            'screen:onboarding). Miettes vues : ${miettesLisibles()}',
      );
      return EtatAuPremierEcran.accueil;
    }
    if (cockpitAtteint()) {
      final ms = DateTime.now().difference(debut).inMilliseconds;
      logStep(
        persona,
        'onboarding',
        'Accueil DEJA PASSE, et c est PROUVE : la miette '
            '${kMiettesEcran.last} est posee apres $ms ms. '
            'Miettes vues : ${miettesLisibles()}',
      );
      return EtatAuPremierEcran.cockpit;
    }

    // LE BOOT PROGRESSE-T-IL ? Trois signes, n'importe lequel suffit.
    final nbMiettes = kMiettesEcran.length;
    final nbWidgets = tester.allWidgets.length;
    final progresse =
        nbMiettes != miettesVues ||
        nbWidgets != tailleArbre ||
        tester.binding.hasScheduledFrame;
    miettesVues = nbMiettes;
    tailleArbre = nbWidgets;
    if (progresse) {
      final etendue = DateTime.now().add(budgetBase);
      echeance = etendue.isAfter(plafond) ? plafond : etendue;
    }
  }

  final ms = DateTime.now().difference(debut).inMilliseconds;
  logStep(
    persona,
    'onboarding',
    'NI accueil NI suite apres $ms ms (budget ${budgetMax.inSeconds} s). '
        'Miettes vues : ${miettesLisibles()}',
  );
  return EtatAuPremierEcran.rien;
}

/// Termine l'onboarding s'il est present (bilingue). Attend d'abord l'ETAT REEL
/// du premier ecran ([attendreAccueilOuCockpit]) : jamais un delai fixe. Ferme
/// d'abord un eventuel consentement pub. Tape « Passer/Skip » (raccourci) puis,
/// en repli, enchaine les « Suivant/Next » et « Commencer ».
///
/// Retourne true si un onboarding a ete traite, false s'il etait DEJA PASSE —
/// et ce `false` est desormais PROUVE par une miette d'ecran de la suite. Si ni
/// l'accueil ni la suite n'apparait dans le budget, le run ECHOUE FRANCHEMENT,
/// capture a l'appui : un scenario joue derriere un carrousel invisible ne
/// prouve rien, et c'est ce silence-la qui a coute quatre runs le 05/10.
Future<bool> completeOnboardingIfPresent(
  WidgetTester tester,
  String persona,
) async {
  // Le consentement pub peut recouvrir l'onboarding : le fermer d'abord.
  await dismissAdsConsentIfPresent(tester, persona);
  final skip = textFrEn('Passer', 'Skip');
  final next = textFrEn('Suivant', 'Next');
  final start = textFrEn('Commencer', 'Get started');
  // L'ETAT REEL, PAS L'HORLOGE (tache 685).
  final etat = await attendreAccueilOuCockpit(tester, persona);
  if (etat == EtatAuPremierEcran.cockpit) {
    logStep(
      persona,
      'onboarding',
      'Onboarding deja complete (miette de la suite posee) — rien a franchir.',
    );
    return false;
  }
  if (etat == EtatAuPremierEcran.rien) {
    // LA CAPTURE D'ABORD : c'est elle qui dira ce que l'ecran montrait.
    await settleAndShoot(tester, persona, '00_accueil_introuvable');
    fail(
      'PREMIER ECRAN INTROUVABLE : ni l accueil (carrousel ou miette '
      'screen:onboarding) ni la suite '
      '(${kEcransApresLAccueil.map((e) => e.name).join(", ")}) apres '
      '${kBudgetPremierEcranMax.inSeconds} s. '
      'Miettes vues : ${miettesLisibles()}. '
      'Le run est REFUSE ici : jouer la suite derriere un carrousel invisible '
      'rendrait un rapport de defauts qui n en est pas un (kaizen #101252). '
      'Voir la capture ${persona}_00_accueil_introuvable.png.',
    );
  }
  logStep(persona, 'onboarding', 'Onboarding present — completion (bilingue)');
  // ===================================================================
  // ON REPOND A LA QUESTION AVANT DE TOUCHER A L'ONBOARDING (tache 650)
  // ===================================================================
  //
  // L'ORDRE N'EST PAS UN DETAIL, ET C'EST UNE MESURE, PAS UNE PRECAUTION.
  // La porte de consentement de la sauvegarde (tache 617) s'ouvre en post-frame
  // juste apres l'affichage de l'onboarding. Deux ordres sont possibles, et ils
  // ne donnent PAS le meme resultat :
  //   * la question est DEJA la quand on appuie sur « Passer » : l'appui est
  //     absorbe par la barriere modale, on repond, on reappuie, tout va bien —
  //     c'est ce qu'on a observe sur S2 et S8 ;
  //   * l'appui passe JUSTE AVANT l'ouverture de la question : il declenche
  //     `_finish()` (ecriture du drapeau puis navigation) pendant que le
  //     dialogue s'installe — et la, sur C1 et N2, l'onboarding n'est plus
  //     jamais reparti, meme apres quatre appuis et un vrai appui `adb`.
  //
  // Le harnais choisit donc l'ordre du randonneur attentif : on laisse la
  // question s'ouvrir, on y REPOND, et seulement ensuite on appuie sur
  // « Passer ». Cela rend la campagne DETERMINISTE. La course, elle, reste un
  // defaut produit a part entiere : elle est rapportee, pas masquee.
  await attendreEtFranchirLaPorteDeConsentement(
    tester,
    persona,
    timeout: const Duration(seconds: 8),
  );
  // Voie rapide : « Passer / Skip ».
  if (await tapIfPresent(
    tester,
    skip,
    persona,
    'onboarding',
    'Passer/Skip',
    warnIfMissing: false,
  )) {
    await pumpAndSettleTolerant(tester);
    // LA QUESTION QUI ATTEND DERRIERE L'ONBOARDING (tache 617). Elle s'ouvre en
    // post-frame juste apres la sortie : sans cette reponse, la route reste
    // `/onboarding` et le scenario entier se joue derriere un dialogue modal.
    await attendreEtFranchirLaPorteDeConsentement(tester, persona);
    await _sortirVraimentDeLOnboarding(tester, persona);
    return true;
  }
  // Repli : enchainer Suivant/Next (max 4) puis Commencer/Get started.
  for (var i = 0; i < 4; i++) {
    if (!await tapIfPresent(
      tester,
      next,
      persona,
      'onboarding',
      'Suivant/Next (${i + 1})',
      warnIfMissing: false,
    )) {
      break;
    }
  }
  await tapIfPresent(
    tester,
    start,
    persona,
    'onboarding',
    'Commencer/Get started',
    warnIfMissing: false,
  );
  await attendreEtFranchirLaPorteDeConsentement(tester, persona);
  await _sortirVraimentDeLOnboarding(tester, persona);
  return true;
}

/// VERIFIE QU'ON EST VRAIMENT SORTI DE L'ONBOARDING, ET REESSAIE SINON.
///
/// CE QUI A ETE MESURE LE 30/09 (tache 650), ET C'EST UNE COURSE, PAS UNE
/// SUPPOSITION. Le premier appui sur « Passer » declenche `_finish()` :
/// `await completeOnboarding(ref)` (ecriture SharedPreferences) PUIS
/// `context.go('/catalog')`. Au meme instant, la porte de consentement de la
/// sauvegarde (tache 617) s'ouvre en post-frame par-dessus. Resultat mesure sur
/// l'emulateur : apres avoir repondu a la question, l'application est REVENUE
/// sur la page 1 de l'onboarding, et la route est restee `/onboarding` — donc
/// le drapeau n'avait pas ete pose et la garde du routeur renvoyait l'ecran.
///
/// CE QU'ON FAIT ICI, ET POURQUOI CE N'EST PAS UN CONTOURNEMENT. On refait le
/// geste qu'un randonneur referait de lui-meme : reappuyer sur « Passer », une
/// fois la question fermee. Chaque tentative est JOURNALISEE, et le nombre
/// d'appuis necessaires est dit — si le premier appui ne suffit jamais, ca se
/// lit dans le journal au lieu de se perdre dans une cascade d'exigences
/// rouges sans rapport.
Future<void> _sortirVraimentDeLOnboarding(
  WidgetTester tester,
  String persona, {
  int essais = 4,
}) async {
  final skip = textFrEn('Passer', 'Skip');
  for (var i = 0; i < essais; i++) {
    // 1. LA QUESTION PASSE D'ABORD. Tant que le dialogue modal est la, le
    //    bouton « Passer » est couvert et l'appui est absorbe par la barriere.
    await dismissBackupConsentIfPresent(tester, persona);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 2));
    if (!present(skip)) {
      if (i > 0) {
        logStep(
          persona,
          'onboarding',
          'Sortie de l onboarding obtenue apres ${i + 1} appui(s) sur '
              '« Passer ».',
        );
      }
      return;
    }
    if (i > 0) {
      logStep(
        persona,
        'onboarding',
        'L onboarding est TOUJOURS a l ecran : nouvel appui sur « Passer » '
            '(essai ${i + 1}).',
      );
    }
    await tapIfPresent(
      tester,
      skip,
      persona,
      'onboarding',
      'Passer/Skip (essai ${i + 1})',
      warnIfMissing: false,
    );
    // 2. ON LAISSE DU TEMPS REEL A L'ECRITURE, ET C'EST LE POINT DELICAT.
    //    `_finish()` de l'onboarding fait `await completeOnboarding(ref)` —
    //    une ecriture SharedPreferences, donc un aller-retour de canal de
    //    plateforme — AVANT de naviguer. Pomper « jusqu'au repos de l'arbre »
    //    ne suffit pas : l'arbre se repose des la fin de l'animation du
    //    bouton, bien avant la reponse du canal, et le scenario repartait en
    //    croyant l'onboarding ferme. On pompe donc en continu jusqu'a ce que
    //    l'ecran disparaisse VRAIMENT.
    if (await _attendreDisparition(tester, skip, const Duration(seconds: 8))) {
      logStep(
        persona,
        'onboarding',
        'Onboarding ferme (appui ${i + 1}) — la navigation a suivi '
            'l ecriture du drapeau.',
      );
      return;
    }
  }
  if (present(skip)) {
    logStep(
      persona,
      'onboarding',
      'COINCE : l onboarding ne se ferme pas apres $essais appuis sur '
          '« Passer » — A RAPPORTER, ce n est plus une course.',
    );
  }
}

/// Pompe EN CONTINU jusqu'a ce que [finder] disparaisse, ou jusqu'a [timeout].
///
/// Contrairement a `pumpAndSettleTolerant`, on ne s'arrete PAS au repos de
/// l'arbre : on attend un EVENEMENT (la disparition), qui peut venir d'un
/// aller-retour de canal de plateforme pendant lequel aucune frame n'est
/// programmee.
Future<bool> _attendreDisparition(
  WidgetTester tester,
  Finder finder,
  Duration timeout, {
  Duration pas = const Duration(milliseconds: 200),
}) async {
  final fin = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(fin)) {
    await tester.pump(pas);
    if (finder.evaluate().isEmpty) return true;
  }
  return finder.evaluate().isEmpty;
}

/// ATTEND que la porte de consentement de la sauvegarde s'ouvre (elle arrive en
/// POST-FRAME, donc quelques centaines de millisecondes apres la sortie de
/// l'onboarding) puis la franchit. Sans l'attente, on la manquerait d'un cheveu
/// et le scenario reprendrait derriere un dialogue modal — c'est exactement ce
/// que la mesure du 30/09 a constate.
Future<bool> attendreEtFranchirLaPorteDeConsentement(
  WidgetTester tester,
  String persona, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  final valider = find.byKey(
    const ValueKey('refus-sauvegarde-systeme-valider'),
  );
  await waitFor(tester, valider, timeout: timeout);
  return dismissBackupConsentIfPresent(tester, persona);
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
    logStep(
      persona,
      'teardown',
      'Exception NON FATALE drainee (artefact de disposal, parcours deja '
          'termine) : ${msg.length > 900 ? msg.substring(0, 900) : msg}',
    );
    await tester.pump(const Duration(milliseconds: 80));
  }
  if (drained == 0) {
    logStep(
      persona,
      'teardown',
      'Aucune exception de teardown a drainer (cloture propre).',
    );
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
///
/// LES MIETTES D'ECRAN SONT REMISES A ZERO ICI AUSSI (tache 685), et pour la
/// meme raison exactement : [kMiettesEcran] est globale, si bien qu'un second
/// scenario joue dans le meme processus heriterait des miettes du premier et
/// conclurait « accueil deja passe » sur la preuve d'un run precedent.
void reinitialiserExigences() {
  kExigencesTenues = 0;
  kExigencesEchouees.clear();
  reinitialiserLesMiettesDEcran();
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
bool exigeAbsent(Finder finder, String persona, String etape, String quoi) =>
    exige(
      persona,
      etape,
      finder.evaluate().isEmpty,
      'ne doit PAS etre affiche : $quoi',
    );

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
  final ok = await tapIfPresent(
    tester,
    finder,
    persona,
    etape,
    quoi,
    warnIfMissing: false,
  );
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
  return exige(
    persona,
    etape,
    ok,
    'champ saisissable : $quoi (valeur "$text")',
  );
}

/// CLOTURE DU SCENARIO : fait ECHOUER le test si une exigence n'est pas tenue.
///
/// [minimumExigences] garde contre le retour du defaut d'origine : une suite
/// qui n'evalue AUCUNE exigence est desormais ROUGE, pas verte.
void verdictPersona(String persona, {int minimumExigences = 1}) {
  final total = kExigencesTenues + kExigencesEchouees.length;
  print(
    'PERSONA_VERDICT|$persona|$kExigencesTenues|'
    '${kExigencesEchouees.length}',
  );
  logStep(
    persona,
    'verdict',
    'BILAN EXIGENCES : $kExigencesTenues tenue(s), '
        '${kExigencesEchouees.length} non tenue(s) sur $total evaluee(s).',
  );
  expect(
    total >= minimumExigences,
    isTrue,
    reason:
        'HARNAIS AVEUGLE : $persona n a evalue que $total exigence(s) '
        '(minimum attendu $minimumExigences). Un scenario qui ne verifie '
        'rien ne peut pas etre vert.',
  );
  expect(
    kExigencesEchouees,
    isEmpty,
    reason:
        'Exigences NON TENUES par le produit :\n'
        '${kExigencesEchouees.join('\n')}',
  );
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
      logStep(
        persona,
        'ecran_systeme',
        'Retour au premier plan (resumed) : l ecran systeme est referme.',
      );
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
          'par exemple) recouvre l app — INVISIBLE dans l arbre Flutter.',
    );
  }
}

_VeilleEcranSysteme? _veilleur;

/// Installe le veilleur d'ecrans systeme. A appeler une fois, au boot.
void installerVeilleEcranSysteme(String persona) {
  if (_veilleur != null) return;
  _veilleur = _VeilleEcranSysteme(persona);
  WidgetsBinding.instance.addObserver(_veilleur!);
  logStep(
    persona,
    'ecran_systeme',
    'Veille des ecrans SYSTEME installee (cycle de vie de l activite).',
  );
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
List<String> ecransSystemeDepuis(int marque) => kEcransSystemeDetectes.sublist(
  marque.clamp(0, kEcransSystemeDetectes.length),
);

// ===========================================================================
// LE MONDE DU BUILD 8 : PLUS DE SENTIER GRATUIT, UNE DEMO, ET UN MUR PAYANT
// (tache 650 — remise en accord des attentes avec les decisions du 29-30/09).
// ===========================================================================
//
// CE QUI A CHANGE, ET CE QUI N'A PAS CHANGE. La campagne posait en premisse,
// depuis la tache 518, que « la vitrine (mare-a-mare-centre) est jouable sans
// achat ». Cette premisse est MORTE le 29/09 a 14:17, sur une phrase de
// Christophe : « la prochaine fois que j'ouvre l'application je n'ai droit a
// rien ». Le lot 638 a donc retire TOUT sentier gratuit du catalogue, et le lot
// 639 a renomme le bouton « Entrer » en « Preparer » (avec « Acheter » a cote).
//
// CE QUE LA CAMPAGNE DOIT VERIFIER MAINTENANT, ET C'EST PLUS EXIGEANT QU'AVANT :
//   * la PREPARATION reste gratuite, avec publicite (decision du 30/09 12:41) ;
//   * la REALISATION est refusee sans achat, et le refus DIT pourquoi et ou
//     acheter ([murDeRealisation], lot 594) ;
//   * la DEMO montre l'application de A a Z sur le VRAI sentier, sans rien
//     debloquer et sans rien ecrire (lots 634/638) ;
//   * l'ABONNEMENT ne donne AUCUN droit sur un sentier — pub et cagnotte
//     seulement (regle de Christophe du 30/09 16:20, base #100945).
//
// Les finders ci-dessous s'appuient sur les CLES du produit, pas sur les
// libelles : un renommage de libelle ne doit plus rendre la campagne aveugle,
// c'est precisement ce qui vient de se passer avec « Entrer ».

/// Le sentier de production, et le seul du catalogue qui soit payant.
const String kSentierDeProduction = 'mare-a-mare-centre';

/// Le bouton « Préparer » d'un sentier du catalogue (ex-« Entrer », lot 639).
/// Il ouvre le cockpit de preparation, achat ou pas.
Finder boutonPreparer(String trailId) =>
    find.byKey(ValueKey('catalog-enter-$trailId'));

/// Le bouton « Acheter <prix> » d'un sentier encore a vendre (lot 639).
Finder boutonAcheter(String trailId) =>
    find.byKey(ValueKey('catalog-buy-$trailId'));

/// La carte d'un sentier au catalogue.
Finder carteSentier(String trailId) =>
    find.byKey(ValueKey('catalog-trail-$trailId'));

/// Le bouton orange « Essayer la démo », en tete du catalogue (lots 634/638).
Finder get boutonDemo => find.byKey(const ValueKey('catalog-demo-button'));

/// Le bandeau orange « MODE DÉMO » qui POUSSE l'ecran (lot 649).
Finder get bandeauDemo => find.byKey(const ValueKey('demo-bandeau'));

/// Le « Quitter » du bandeau de demo : un seul appui suffit (lot 649).
Finder get sortieDemo => find.byKey(const ValueKey('demo-sortie'));

/// Le bouton « Simuler l'étape suivante / l'arrivée » (lot 638), visible
/// uniquement en demo et uniquement quand une rando simulee est en cours.
Finder get simulerDemo => find.byKey(const ValueKey('demo-simuler'));

/// La phrase qui dit que le depart est SIMULE (lot 638).
Finder get departSimule => find.byKey(const ValueKey('demo-depart-simule'));

/// LE MUR PAYANT DE LA REALISATION (lot 594) : le refus qui dit pourquoi et ou
/// acheter, pose quand on appuie sur « Démarrer » sans posseder le sentier.
Finder get murDeRealisation =>
    find.byKey(const ValueKey('realisation-verrouillee'));

/// ACQUIERT LE SENTIER — LE DROIT REEL, ECRIT LA OU UN ACHAT L'ECRIT.
///
/// POURQUOI PAS LE GESTE D'ACHAT DE L'ECRAN, ET C'EST MESURE. Le chemin d'achat
/// passe par la boutique du telephone (`rechargeWallet` -> `buyCredits` ->
/// in_app_purchase). Sur l'emulateur, aucune boutique ne repond : le premier
/// appel casse meme sur une assertion de `wallet_iap_service.dart`
/// (« productId recharge inconnu ») des qu'on invente un identifiant de
/// produit. Aucun scenario ne peut donc PAYER pour de bon ici.
///
/// CE QU'ON FAIT A LA PLACE. On ecrit le DROIT, dans la table que l'achat
/// confirme ecrit lui-meme (`trek_entitlements`, ce que fait `_markOwned` a la
/// fin de `buyTrail`), par le DAO de production — la meme porte que le service.
/// Ce n'est PAS une surcharge de provider : rien n'est remplace par une
/// doublure. Tout ce qui suit lit ce droit par le VRAI service
/// ([MonetizationService.ownsTrail], `canRealizeTrail`), et c'est bien lui qui
/// decide. C'est exactement ce que font les tests de comportement du lot 647.
///
/// CE QUE CELA NE PROUVE PAS, ET IL FAUT LE DIRE : le parcours de PAIEMENT
/// lui-meme (boutique, prix, complement store) n'est pas joue ici. Il est
/// couvert par `test/comportement/achat_et_video_614_test.dart`.
///
/// Retourne vrai si le sentier est bien possede a la sortie, lu sur le service.
Future<bool> acheterLeSentierPourDeVrai(
  WidgetTester tester,
  String trailId,
  String persona,
) async {
  try {
    final element = tester.element(find.byType(Navigator).first);
    final c = ProviderScope.containerOf(element, listen: false);
    final stages = TrailCatalog.byId(trailId)?.totalStages ?? 0;
    await c
        .read(databaseProvider)
        .trekEntitlementsDao
        .upsert(
          TrekEntitlementsCompanion.insert(
            trailId: trailId,
            owned: const Value(true),
            acquiredStages: Value(stages),
            totalStages: Value(stages),
            updatedAt: DateTime.now(),
          ),
        );
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    final service = await c
        .read(monetizationReadyProvider.future)
        .timeout(const Duration(seconds: 20));
    final possede = await service.ownsTrail(trailId);
    logStep(
      persona,
      'achat',
      'Droit d acquisition ecrit pour $trailId ($stages etapes) ; '
          'le service de production repond possede = $possede',
    );
    return possede;
  } catch (e) {
    logStep(persona, 'achat', 'COINCE : acquisition impossible : $e');
    return false;
  }
}

/// Vrai si [trailId] est POSSEDE, lu sur le service de production.
Future<bool> sentierPossede(WidgetTester tester, String trailId) async {
  try {
    final element = tester.element(find.byType(Navigator).first);
    final c = ProviderScope.containerOf(element, listen: false);
    final service = await c
        .read(monetizationReadyProvider.future)
        .timeout(const Duration(seconds: 15));
    return service.ownsTrail(trailId);
  } catch (_) {
    return false;
  }
}
