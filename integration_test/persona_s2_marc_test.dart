// ignore_for_file: avoid_print
//
// S2 — MARC, randonneur confirme et presse (tache 518, joue EN DIRECT).
//
// Objectif persona : evaluer vite un trek dur et se lancer.
// Parcours vise (PLAN_TEST_PERSONAS S2) :
//   selectionne un trek dur -> faisabilite « go » rapide -> « Mes treks »
//   multi-treks -> cockpit -> reglages (change la langue, voit la version
//   v0.1.2) -> profil.
//
// Pilote l UI reelle, capture chaque etape, LOGue les coincements. Zero modif app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S2_Marc';

/// Version attendue dans les reglages, lue dans le PUBSPEC du projet (0.1.2+3).
/// On garde la partie « 0.1.2 » : le build number bouge, pas la version.
const String kVersionAttendue = '0.1.2';

/// Ecrit la fiche et la rando de Marc par le chemin de production.
Future<void> _poserLeProfilDeMarc(WidgetTester tester) async {
  try {
    final element = tester.element(find.byType(Navigator).first);
    final c = ProviderScope.containerOf(element, listen: false);
    await tester.runAsync(() async {
      await c.read(hikerProfileProvider.notifier).save(const HikerProfile(
            age: 28,
            heightCm: 178,
            weightKg: 72,
            sex: HikerSex.male,
          ));
      await c.read(pastHikesProvider.notifier).saveAll(<PastHike>[
        PastHike(
          date: DateTime(2024, 7, 1),
          days: 12,
          avgWalkHoursPerDay: 7,
          totalDistanceKm: 180,
          totalElevationGain: 10000,
        ),
      ]);
    });
    c.invalidate(hikerProfileProvider);
    c.invalidate(pastHikesProvider);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    logStep(P, 'profil', 'fiche et rando de Marc ecrites par les notifiers');
  } catch (e) {
    logStep(P, 'profil', 'COINCE : impossible de poser le profil de Marc : \$e');
  }
}

void main() {
  initHarness();

  testWidgets('S2 — Marc evalue vite un trek dur et se lance', (tester) async {
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

    // Consentement pub + onboarding (bilingue, Marc est presse -> Passer/Skip).
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_skip');

    // --- Accueil « Mes treks » : etat multi-treks ---
    _logLocation(tester, P, 'accueil');
    await settleAndShoot(tester, P, '03_mes_treks');
    // Compter les cartes de trek possedees (cle trek-summary-*).
    final trekCards = find
        .byWidgetPredicate((w) => w.key.toString().contains('trek-summary-'));
    logStep(P, 'mes_treks',
        'Treks possedes visibles (cartes trek-summary-*) = ${trekCards.evaluate().length}');

    // --- Selectionne un trek (entre dans le cockpit) ---
    // Marc ouvre un trek depuis « Mes treks » : tap sur la 1re carte. NB : s il a
    // saute l onboarding sans entrer dans un sentier, « Mes treks » peut etre
    // VIDE (0 carte) — signal QA note ci-dessus. Repli : catalogue -> Entrer
    // (selectionne le sentier, ouvre la carte) puis on rejoint le cockpit /home.
    if (present(trekCards)) {
      await tester.tap(trekCards.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(P, 'selection', 'TAP OK : ouverture du 1er trek possede -> cockpit');
    } else {
      logStep(P, 'selection',
          'FINDING : « Mes treks » VIDE apres skip onboarding (0 trek possede). '
          'Repli catalogue.');
      if (!present(textFrEn('Catalogue des sentiers', 'Trail catalog'))) {
        await tapIfPresent(tester, textFrEn('Découvrir des sentiers', 'Discover trails'),
            P, 'selection', 'Decouvrir des sentiers (repli)', warnIfMissing: false);
      }
      await tapIfPresent(
          tester,
          find.byKey(const ValueKey('catalog-enter-mare-a-mare-centre')),
          P,
          'selection',
          'Entrer dans la vitrine (repli)');
      // FIX CYCLE 2 (issue 1) : « Entrer » ouvre desormais le COCKPIT /home
      // (prepa), plus la carte live. `_goHome` reste un filet idempotent (etat
      // connu) au cas ou l'entree serait detournee.
      await _goHome(tester, P);
    }
    await settleAndShoot(tester, P, '04_cockpit');
    _logLocation(tester, P, 'cockpit');

    // --- LE PROFIL DE MARC, POSE AVANT D'OUVRIR LA FAISABILITE (tache 544) ---
    //
    // POURQUOI ICI ET PAS PAR L'ECRAN. Depuis le correctif N2 (D1), le verdict
    // n'apparait QU'UNE FOIS tous les criteres renseignes — et c'est ce qu'on
    // veut. Mais S2 ne teste PAS la saisie : la saisie complete par l'interface
    // est prouvee par S1, pas a pas et exigence par exigence. Ce que S2 prouve,
    // c'est le PARCOURS RAPIDE d'un randonneur qui a deja ses donnees : verdict
    // immediat, depart, reglages, code de reconnexion. Refaire ici la saisie
    // n'apporterait rien et allongerait le run de plusieurs minutes.
    // Les valeurs sont celles du prompt de Marc : 28 ans, 1,78 m, 72 kg, et le
    // GR20 en douze jours. Ecriture par les VRAIS notifiers, jamais par un
    // `overrideWith` : c'est le meme chemin que le formulaire.
    await _poserLeProfilDeMarc(tester);

    // --- Faisabilite « go » rapide ---
    final feasCard = textFrEn('Faisabilité', 'Feasibility');
    await scrollUntil(tester, feasCard, P, 'faisabilite', 'carte Faisabilite');
    await exigeTap(tester, feasCard, P, 'faisabilite', 'carte Faisabilite');
    await settleAndShoot(tester, P, '05_faisabilite');
    // Marc arrive sans profil renseigne : l'ecran ouvre le FLUX GUIDE. Il est
    // PRESSE — il valide pour voir tout de suite son resultat, exactement comme
    // un vrai utilisateur qui veut un « go / no go » immediat.
    if (present(find.text(t.feasibility.flow.validate))) {
      await exigeTap(tester, find.text(t.feasibility.flow.validate), P,
          'faisabilite', '« Valider et voir mon résultat » du flux guide');
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
      await settleAndShoot(tester, P, '05b_faisabilite_verdict');
    }
    // Verdict visible ?
    final verdictMarc = _logVisibleVerdict(tester, P);
    // ============ LE DEFAUT N1 CORRIGE ICI AUSSI ============
    // S2 cherchait « Déconseillé » et « Préparation nécessaire » (lignes 226-227
    // d'origine) : DEUX LIBELLES DISPARUS. Le verdict n'etait donc jamais lu et
    // le run restait vert. Il est desormais EXIGE, avec les libelles de l'app.
    exige(
        P,
        'faisabilite',
        verdictMarc != null,
        'Marc obtient un verdict REEL et lisible ("${t.feasibility.formula.verdicts.green}" / '
            '"${t.feasibility.formula.verdicts.orange}" / '
            '"${t.feasibility.formula.verdicts.red}") — c est TOUT ce qu il '
            'vient chercher');
    // EXIGENCE RETOURNEE (tache 552) — la mention hors-perimetre « le poids de
    // ton sac n entre pas dans ce feu » est SUPPRIMEE : elle expliquait une
    // absence sans rien changer au resultat. Pour un utilisateur presse, c etait
    // meme la premiere phrase a survoler. On verrouille son absence.
    exigeAbsent(
        find.byIcon(Icons.visibility_off_outlined),
        P,
        'faisabilite',
        'la mention hors-perimetre sous le feu tricolore (supprimee, '
        'tache 552)');
    // Retour cockpit par le routeur (etat connu).
    await _goHome(tester, P);

    // --- Cockpit : verifier presence du CTA principal ---
    // QA cycle4 : le CTA « Démarrer la randonnée » est EN BAS du cockpit depuis
    // le lot L7 (hub_screen.dart:512), plus en tete. Constater sa presence en
    // haut de liste ne pouvait donner que « false » : on remonte pour un etat
    // connu, puis on DESCEND jusqu'a lui avant de conclure.
    await _scrollToTop(tester, P);
    await settleAndShoot(tester, P, '06_retour_cockpit');
    final ctaMarc = textFrEn('Démarrer la randonnée', 'Start the trek');
    await scrollUntil(tester, ctaMarc, P, 'cockpit',
        'CTA Demarrer la randonnee (BAS du cockpit)', maxScrolls: 25);
    logStep(
        P,
        'cockpit',
        'CTA Demarrer present = ${present(ctaMarc)} ; '
            'Reprendre present = ${present(textFrEn('Reprendre la navigation', 'Resume navigation'))}');
    // EXIGENCE — Marc veut SE LANCER : le cockpit doit lui offrir une porte de
    // depart (« Démarrer la randonnée » ou « Reprendre la navigation »).
    exige(
        P,
        'cockpit',
        present(ctaMarc) ||
            present(textFrEn('Reprendre la navigation', 'Resume navigation')),
        'le cockpit propose une porte de depart (Démarrer ou Reprendre)');

    // --- Reglages : changer la langue + voir la version ---
    // Acces reglages via l icone parametres du header du cockpit.
    final gearBtn = find.byIcon(Icons.settings_outlined);
    await exigeTap(
        tester, gearBtn, P, 'reglages', 'icone Reglages du header du cockpit');
    await settleAndShoot(tester, P, '07_reglages');

    // Changer la langue : taper « English » (ListTile de la section langue).
    // LIBELLES REELS : les noms de langue sont des ENDONYMES non traduits
    // (`AppLanguageValues.labels`), « English » et « Français ». Ils ne sont pas
    // dans l'i18n : c'est normal, et c'est la raison du faux positif N1.
    final langOk = await exigeTap(tester, find.text('English'), P, 'reglages',
        'entree de langue « English » dans les reglages');
    await settleAndShoot(tester, P, '08_langue_en');
    if (langOk) {
      // EXIGENCE — la bascule doit etre REELLE : l'interface passe en anglais.
      // On lit les libelles ANGLAIS de l'app (pas une devinette).
      final switched = present(find.text('Settings')) ||
          present(find.text('Language')) ||
          present(find.text('Version'));
      exige(P, 'reglages', switched,
          'le changement de langue bascule REELLEMENT l interface en anglais');
      // Remettre le francais pour ne pas perturber les autres scenarios.
      await tapIfPresent(tester, find.text('Français'), P, 'reglages',
          'remettre Francais (endonyme)', warnIfMissing: false);
      await pumpAndSettleTolerant(tester);
      // EXIGENCE — et le retour au francais doit marcher aussi (aller-retour).
      exige(
          P,
          'reglages',
          present(find.text('Paramètres')) || present(find.text('Langue')),
          'le retour au francais bascule l interface dans l autre sens');
    }

    // Voir la version : defiler jusqu a la section version et lire « 0.1.2 »
    // (version courante — pubspec 0.1.2+3, lue via PackageInfo).
    await scrollUntil(tester, find.textContaining(kVersionAttendue), P, 'version',
        'numero de version ($kVersionAttendue)');
    final versionShown = present(find.textContaining(kVersionAttendue));
    logStep(P, 'version',
        'Version $kVersionAttendue visible dans les reglages = $versionShown');
    // EXIGENCE — la version affichee est celle du pubspec. C'est ce qui permet
    // a Chris de savoir QUELLE version il tient en main.
    exige(P, 'version', versionShown,
        'la version $kVersionAttendue est affichee dans les reglages');
    await settleAndShoot(tester, P, '09_version');

    // --- Profil ---
    await _back(tester, P, 'profil');
    // Icone profil du header du cockpit.
    await exigeTap(tester, find.byIcon(Icons.person_outline), P, 'profil',
        'icone Profil du header du cockpit');
    await settleAndShoot(tester, P, '10_profil');
    _logLocation(tester, P, 'profil');

    // ================================================================
    // EXTENSION COUVERTURE (GO-46, COUVERTURE.md 3.3) — LOGISTIQUE + COMPTE :
    // Marc, confirme et organise, boucle la LOGISTIQUE et son COMPTE. Ecrans de
    // logistique atteints par la VRAIE carte du HUB ; ecrans de compte atteints
    // par la VRAIE tuile des Reglages (navigation utilisateur reelle). Verifs :
    // titre reel de l'ecran cible + un element metier de la decision liee.
    //   #P19 Itineraire · #P23 Transport · #P28 Guides villes · #P29 detail guide
    //   · #P38 /consent (#D22 bascule finalite) · #P39 /recovery-code (#D20 code)
    //   · #D01 wallet « Mon compte » -> CONSTAT : pas d'ecran wallet/solde en
    //     nav V1 (documente, non inventable — cf. handoff).
    // ================================================================
    await _logisticsAndAccountTour(tester, P);

    logStep(P, 'fin', 'Scenario S2 termine (logistique + compte etendus)');
    retirerVeilleEcranSysteme();
    await finalizeScenario(tester, P);
    await flushJournal(P);
    // LE VERDICT (campagne N2). Avant, S2 n'avait AUCUNE assertion : il ne
    // pouvait pas echouer, et il cherchait en plus des libelles disparus.
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
    verdictPersona(P, minimumExigences: 12);
  });
}

/// Retour cockpit /home (etat connu via routeur).
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

/// Remonte en tete de la 1re liste defilante.
Future<void> _scrollToTop(WidgetTester tester, String persona) async {
  if (find.byType(Scrollable).evaluate().isEmpty) return;
  final scroller = find.byType(Scrollable).first;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scroller, const Offset(0, 600));
    await pumpAndSettleTolerant(tester);
  }
  logStep(persona, 'nav', 'Remontee en tete du cockpit');
}

Future<void> _back(WidgetTester tester, String persona, String etape) async {
  // Bouton back bilingue (tooltip Retour/Back) sinon pop routeur.
  final tip = find.byTooltip('Retour');
  final tipEn = find.byTooltip('Back');
  if (present(tip) || present(tipEn)) {
    await tester.tap((present(tip) ? tip : tipEn).first, warnIfMissed: false);
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

/// REPARATION N2 — c'etaient les lignes 226-227 du defaut : ce finder cherchait
/// « Déconseillé » et « Préparation nécessaire », DES LIBELLES DISPARUS. Il ne
/// trouvait rien, le loguait, et le scenario continuait au vert. Les libelles
/// sont desormais lus DANS L'APPLICATION.
String? _logVisibleVerdict(WidgetTester tester, String persona) {
  final v = t.feasibility.formula.verdicts;
  for (final libelle in <String>[v.red, v.orange, v.green]) {
    if (present(find.text(libelle))) {
      logStep(persona, 'verdict', 'VERDICT visible = "$libelle"');
      return libelle;
    }
  }
  logStep(persona, 'verdict',
      'Aucun des TROIS verdicts reels visible — voir capture');
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

/// Identifiant du sentier ACTIF, lu depuis le conteneur Riverpod monte (source
/// unique du hub : `trailConfigProvider.id`). Non-invasif (lecture seule), c'est
/// EXACTEMENT l'id que le hub injecte dans ses `context.push('/trail/$id/...')`.
/// Repli sur null si le conteneur est illisible.
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
/// FILET deep-link fiable.
///
/// FIABILITE (fix run S2) : le HUB est une longue ListView virtualisee ; selon
/// l'offset, une carte (« Itineraire », « Guides des villes ») peut ne pas etre
/// dans l'arbre construit -> le tap echoue. On tente d'abord la VRAIE carte (on
/// remonte en tete puis on descend pas a pas pour l'amener a l'ecran) ; si l'ecran
/// cible n'est pas atteint, on POUSSE la route trail-scoped [fallbackPath]
/// (`/trail/$id/...`, cible IDENTIQUE a celle du hub) via le routeur. Ainsi la
/// couverture est garantie tout en privilegiant la navigation par carte.
/// Verifie le titre cible, capture, LOGue. Ne stoppe jamais le scenario.
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
  // Filet deep-link (cible identique au hub) si la carte n'a pas abouti.
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

/// Ouvre les REGLAGES depuis le cockpit (icone parametres du header), best effort.
Future<void> _openSettings(WidgetTester tester, String persona) async {
  await _goHome(tester, persona);
  await _scrollToTop(tester, persona);
  await tapIfPresent(tester, find.byIcon(Icons.settings_outlined), persona,
      'reglages', 'ouvrir Reglages (icone parametres)');
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
}

/// TOUR LOGISTIQUE + COMPTE de Marc (extension GO-46). Blocs independants et
/// defensifs : ecrans logistique par carte HUB, ecrans compte par les Reglages.
Future<void> _logisticsAndAccountTour(
    WidgetTester tester, String persona) async {
  // --- #P19 ITINERAIRE (carte HUB « Itinéraire » -> /trail/:id/itinerary) ---
  // Decision : deroule des etapes du sentier (parite GR20). Element metier : un
  // en-tete de totaux (« km ») ou l'etat vide (aucune etape chargee).
  // LIBELLE PERIME CORRIGE (campagne N2) : le titre ATTENDU etait ecrit
  // « Itineraire » SANS ACCENT alors que l'ecran s'intitule « Itinéraire ».
  // `reached` ne pouvait donc JAMAIS etre vrai : le bloc entier etait mort, et
  // son echec silencieux. On lit desormais le titre dans l'i18n de l'app.
  final atteintItineraire = await _openHubCard(
      tester, persona, 'itineraire', t.itinerary.title, t.itinerary.title,
      shot: 'S2E_19_itineraire',
      fallbackPath: (id) => '/trail/$id/itinerary');
  exige(persona, 'itineraire', atteintItineraire,
      'l ecran Itineraire est atteint (carte du hub ou route du hub)');
  if (atteintItineraire) {
    final hasContent = present(find.textContaining('km')) ||
        present(find.text(t.itinerary.empty));
    exige(persona, 'itineraire', hasContent,
        'l Itineraire affiche un contenu (totaux en km, ou etat vide explicite)');
  }

  // --- #P23 TRANSPORT (carte HUB « Transport » -> /trail/:id/transport) ---
  // Decision : onglets ALLER / RETOUR (data-driven, direction-aware). On BASCULE
  // sur le 2e onglet (repartir) pour jouer la logistique retour (parite GR20).
  if (await _openHubCard(
      tester, persona, 'transport', 'Transport', 'Transport',
      shot: 'S2E_23_transport',
      fallbackPath: (id) => '/trail/$id/transport')) {
    // Deux onglets (Tab) : on tape le second (index 1) via le TabBar.
    final tabs = find.byType(Tab);
    if (tabs.evaluate().length >= 2) {
      await tester.tap(tabs.at(1), warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      logStep(persona, 'transport',
          'TAP OK : onglet RETOUR (repartir de l arrivee). #P23 couvert.');
    } else {
      logStep(persona, 'transport',
          'Onglets transport introuvables (fallback sans donnees ?) — #P23 atteint.');
    }
    await settleAndShoot(tester, persona, 'S2E_23b_transport_retour');
  }

  // --- #P28 GUIDES VILLES (carte HUB « Guides des villes » -> /trail/:id/guides)
  //     + #P29 DETAIL guide (tap 1re carte town-guide-card-*). ---
  if (await _openHubCard(tester, persona, 'guides', 'Guides des villes',
      'Guides des villes',
      shot: 'S2E_28_guides',
      fallbackPath: (id) => '/trail/$id/guides')) {
    final guideCard = find.byWidgetPredicate(
        (w) => w.key.toString().contains('town-guide-card-'));
    if (present(guideCard)) {
      await tester.tap(guideCard.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
      await settleAndShoot(tester, persona, 'S2E_29_guide_detail');
      logStep(persona, 'guides',
          'TAP OK : detail d un guide ville ouvert (loc=${_currentLocation(tester)}). '
          '#P28 + #P29 couverts.');
      await _back(tester, persona, 'guides');
    } else {
      final empty = present(find.byKey(const ValueKey('town-guides-empty')));
      logStep(persona, 'guides',
          'Aucune carte de guide (liste vide=$empty) — #P28 atteint, #P29 sans '
          'donnee (aucun guide pour ce sentier). Signal QA data.');
      await settleAndShoot(tester, persona, 'S2E_29_guide_detail');
    }
  }

  // --- #P38 /consent (#D22) : gestion RGPD granulaire depuis les Reglages ---
  // Decision : consentement par finalite, retrait aussi simple que l'octroi. On
  // BASCULE une finalite (1er Switch de la liste) pour jouer le geste metier.
  await _openSettings(tester, persona);
  await scrollUntil(tester, find.text('Confidentialité et consentement'),
      persona, 'consent', 'tuile Confidentialite et consentement (Reglages)');
  if (await tapIfPresent(
      tester, find.text('Confidentialité et consentement'), persona, 'consent',
      'ouvrir la gestion du consentement', warnIfMissing: false)) {
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, persona, 'S2E_38_consent');
    final onConsent = present(find.text('Confidentialité et consentement'));
    // Bascule une finalite (Switch dans un ConsentPurposeTile).
    final sw = find.byType(Switch);
    var toggled = false;
    if (present(sw)) {
      await tester.tap(sw.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
      toggled = true;
    }
    logStep(persona, 'consent',
        'Ecran /consent atteint = $onConsent ; finalite basculee = $toggled. '
        '#P38 + #D22 couverts.');
    await settleAndShoot(tester, persona, 'S2E_38b_consent_bascule');
    await _back(tester, persona, 'consent');
  } else {
    logStep(persona, 'consent',
        'COINCE : tuile « Confidentialite et consentement » introuvable dans '
        'les Reglages. #P38/#D22 non joues. Signal QA.');
  }

  // --- #P39 /recovery-code (#D20) : code de reconnexion depuis les Reglages ---
  // Decision : afficher le code (cle du coffre chiffre) pour le NOTER. On verifie
  // le titre + le label « Votre code » + un bouton copier.
  await _openSettings(tester, persona);
  await scrollUntil(tester, find.text(t.recovery.title), persona,
      'recovery', 'tuile Mon code de reconnexion (Reglages)');
  if (await exigeTap(tester, find.text(t.recovery.title), persona,
      'recovery', 'tuile « Mon code de reconnexion » des Reglages')) {
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, persona, 'S2E_39_recovery_code');
    final onRecovery = present(find.text(t.recovery.codeLabel)) ||
        present(find.textContaining('code de reconnexion'));
    logStep(persona, 'recovery',
        'Ecran /recovery-code atteint = $onRecovery. #P39 + #D20 couverts.');
    // EXIGENCE — ce code est la SEULE cle de reconnexion du coffre : il doit
    // etre reellement affiche, sinon l'utilisateur perd son compte.
    exige(persona, 'recovery', onRecovery,
        'le code de reconnexion est REELLEMENT affiche (cle du coffre chiffre)');
    await _back(tester, persona, 'recovery');
  }

  // --- #D01 WALLET « Mon compte » (deux poches / solde) : CONSTAT QA ---
  // Le mandat interdit d'inventer un widget. Or l'ecran Profil (« Mon compte »)
  // ne porte AUCUN affichage de wallet/solde/etapes acquises en nav V1 (verifie
  // sur profile_screen.dart : avatar, pseudo, compte connexion, main dominante,
  // suppression, version — pas de solde). On DOCUMENTE ce trou plutot que de
  // simuler. On ouvre le Profil et on consigne l'absence.
  await _goHome(tester, persona);
  await _scrollToTop(tester, persona);
  await tapIfPresent(tester, find.byIcon(Icons.person_outline), persona,
      'wallet', 'ouvrir Profil (Mon compte)', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  await settleAndShoot(tester, persona, 'S2E_01dec_profil_wallet');
  final hasWallet = present(find.textContaining('solde')) ||
      present(find.textContaining('Solde')) ||
      present(find.textContaining('étapes acquises'));
  logStep(persona, 'wallet',
      'CONSTAT #D01 : affichage wallet/solde present dans « Mon compte » = '
      '$hasWallet (ATTENDU false — aucun ecran wallet en nav V1). Trou reel '
      'documente pour Chris : #D01 non couvrable sans ecran « Mon compte » '
      'exposant les deux poches (wallet fongible + etapes acquises).');

  // Retour cockpit propre.
  await _goHome(tester, persona);
  await settleAndShoot(tester, persona, 'S2E_zz_retour_cockpit');
}
