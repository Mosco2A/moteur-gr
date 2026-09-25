// ignore_for_file: avoid_print
//
// S11 — LES CINQ DEFAUTS QUE CHRIS A TROUVES EN SIX MINUTES (famille 4).
//
// POURQUOI CE FICHIER EXISTE. Le 25/09 au matin, un apk est parti chez Chris
// sur la foi de 2604 tests unitaires verts et d'un demarrage d'ecran. Il a
// trouve CINQ defauts en six minutes. Aucun n'etait cache : tous etaient ECRITS
// A L'ECRAN. Ce que les tests verifiaient, c'est qu'un widget EXISTE ; ce que
// Chris regardait, c'est ce que l'ecran DIT et dans quel ORDRE il le dit.
//
// CE SCENARIO REJOUE SES CINQ GESTES, DANS L'ORDRE OU IL LES A FAITS :
//   D1 — le mode sombre / clair ne bascule pas.
//   D2 — la carte Journal est posee AU-DESSUS de la section « Preparer ».
//   D3 — le curseur de jours pousse a fond, des repos ajoutes, et le verdict
//        reste rouge.
//   D4 — la carte de navigation n'a pas la forme du GR20 et sert un laius sur
//        les tirets.
//   D5 — la carte ne s'ouvre pas sur la premiere etape avec le trace visible.
//
// IL EST ECRIT POUR ECHOUER AUJOURD'HUI. C'est son role : la tache 558 corrige,
// ce fichier dit quand c'est vraiment corrige. Un scenario de famille 4 qui
// passerait du premier coup serait suspect, pas rassurant.
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF : il pilote l'UI reelle.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:moteur_gr/features/trek/presentation/map/layers/trace_layer.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S11_Chris';

/// Sentier de production (celui que Chris avait sous les yeux).
const String kTrailId = 'mare-a-mare-centre';

void main() {
  initHarness();

  testWidgets('S11 — les cinq defauts trouves par Chris en six minutes',
      (tester) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main()');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 15));
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_onboarding');

    // =====================================================================
    // PREALABLE — UN PROFIL REEL, SINON D3 NE VEUT RIEN DIRE.
    // =====================================================================
    // Le verdict de faisabilite n'existe que si l'appli connait le randonneur.
    // Chris avait le sien. On saisit donc une morphologie et une rando passee
    // AU DOIGT, par les memes ecrans que lui, avant de toucher au curseur.
    await _remplirFicheInfo(tester);
    await _ajouterUneRandoPassee(tester);
    await settleAndShoot(tester, P, '03_profil_pret');

    // =====================================================================
    // D3 — LE CURSEUR DE JOURS ET LE VERDICT QUI NE BOUGE PAS (le majeur).
    // =====================================================================
    // Geste de Chris, mot pour mot : « il pousse le curseur de jours jusqu'a
    // 20, ajoute des jours de repos, et le verdict reste rouge ».
    await _aller(tester, '/trail/$kTrailId/planning');
    await settleAndShoot(tester, P, '10_programme_depart');
    logEcran(P, 'programme');

    exige(P, 'D3', present(find.byType(Slider)),
        'le programme porte bien un CURSEUR de nombre de jours');

    final verdictDepart = _pastilleVerdict();
    final joursDepart = _grandCompteurJours();
    logStep(P, 'D3',
        'ETAT DE DEPART — pastille lue = "${verdictDepart ?? "(aucune)"}", '
        'compteur de jours lu = "${joursDepart ?? "(aucun)"}"');

    // --- Geste 1 : pousser le curseur a fond, comme lui ---
    await _pousserLeCurseurAFond(tester);
    await settleAndShoot(tester, P, '11_curseur_a_fond');
    final verdictApresCurseur = _pastilleVerdict();
    final joursApresCurseur = _grandCompteurJours();
    logStep(P, 'D3',
        'APRES LE CURSEUR POUSSE A FOND — pastille lue = '
        '"${verdictApresCurseur ?? "(aucune)"}", compteur de jours lu = '
        '"${joursApresCurseur ?? "(aucun)"}"');

    exige(P, 'D3', joursApresCurseur != joursDepart,
        'pousser le curseur a fond CHANGE le nombre de jours affiche '
        '(lu avant = "$joursDepart", lu apres = "$joursApresCurseur")');

    // --- Geste 2 : ajouter des jours de repos, comme lui ---
    final reposAjoutes = await _ajouterDesRepos(tester, 3);
    await settleAndShoot(tester, P, '12_repos_ajoutes');
    final verdictFinal = _pastilleVerdict();
    final joursFinal = _grandCompteurJours();
    logStep(P, 'D3',
        'APRES $reposAjoutes JOUR(S) DE REPOS AJOUTE(S) — pastille lue = '
        '"${verdictFinal ?? "(aucune)"}", compteur de jours lu = '
        '"${joursFinal ?? "(aucun)"}"');

    exige(P, 'D3', reposAjoutes > 0,
        'des jours de repos peuvent etre ajoutes au doigt depuis le programme');
    exige(P, 'D3', joursFinal != joursApresCurseur,
        'ajouter des jours de repos CHANGE le nombre de jours affiche '
        '(lu avant = "$joursApresCurseur", lu apres = "$joursFinal")');

    // LE COEUR DU DEFAUT. Un randonneur qui s'accorde le maximum de jours ET
    // des repos doit voir le verdict se detendre. Qu'il reste identique — et
    // surtout qu'il reste « trop serre » — c'est ce que Chris a vu.
    final tv = t.feasibility.formula.verdicts;
    exige(
        P,
        'D3',
        verdictFinal != null && verdictFinal != tv.red,
        'LE VERDICT SE DETEND quand on pousse le curseur a fond ET qu on '
        'ajoute des repos : il ne doit plus dire « ${tv.red} ». '
        'Pastille reellement lue a l ecran = "${verdictFinal ?? "(aucune)"}"');
    exige(
        P,
        'D3',
        verdictDepart != null && verdictFinal != null &&
            verdictFinal != verdictDepart,
        'LE VERDICT BOUGE entre le depart et le programme le plus genereux '
        '(lu au depart = "$verdictDepart", lu a la fin = "$verdictFinal")');
    exigeAucuneAbsurdite(P, 'D3');

    // =====================================================================
    // D1 — LE MODE SOMBRE / CLAIR QUI NE BASCULE PAS.
    // =====================================================================
    await _aller(tester, '/settings');
    await settleAndShoot(tester, P, '20_reglages');
    final avant = luminositeAlEcran(tester);
    logStep(P, 'D1', 'LUMINOSITE REELLE AVANT bascule = ${avant?.name}');
    exige(P, 'D1', present(find.text(t.settings.light)),
        'les reglages proposent bien un theme « ${t.settings.light} »');

    await exigeTap(tester, find.text(t.settings.light), P, 'D1',
        'choix du theme « ${t.settings.light} » dans les reglages');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
    await settleAndShoot(tester, P, '21_reglages_theme_clair');
    final apres = luminositeAlEcran(tester);
    logStep(P, 'D1', 'LUMINOSITE REELLE APRES bascule = ${apres?.name}');

    exige(P, 'D1', apres == Brightness.light,
        'choisir « ${t.settings.light} » eclaircit REELLEMENT l ecran '
        '(luminosite lue avant = ${avant?.name}, apres = ${apres?.name})');

    // Contre-preuve : le choix doit aussi tenir sur un AUTRE ecran, sinon il
    // n'est qu'un reglage decoratif sur sa propre page.
    await _aller(tester, '/home');
    await settleAndShoot(tester, P, '22_cockpit_en_clair');
    final ailleurs = luminositeAlEcran(tester);
    logStep(P, 'D1', 'LUMINOSITE REELLE sur le cockpit = ${ailleurs?.name}');
    exige(P, 'D1', ailleurs == Brightness.light,
        'le theme clair choisi s applique AUSSI aux autres ecrans '
        '(luminosite lue sur le cockpit = ${ailleurs?.name})');

    // On remet en sombre pour la suite (et on verifie que le retour marche).
    await _aller(tester, '/settings');
    await tapIfPresent(tester, find.text(t.settings.dark), P, 'D1',
        'retour au theme « ${t.settings.dark} »', warnIfMissing: false);
    await pumpAndSettleTolerant(tester);

    // =====================================================================
    // D2 — LE JOURNAL POSE AU-DESSUS DE « PREPARER ».
    // =====================================================================
    await _aller(tester, '/home');
    await _remonterEnHaut(tester);
    await settleAndShoot(tester, P, '30_cockpit_ordre');
    logEcran(P, 'D2');

    final yPreparer = hauteurDe(tester, find.text(t.hub.sections.prepare));
    final yJournal = hauteurDe(tester, find.text(t.hub.cards.journal));
    logStep(P, 'D2',
        'POSITIONS LUES A L ECRAN — « ${t.hub.sections.prepare} » a y=$yPreparer, '
        'carte « ${t.hub.cards.journal} » a y=$yJournal');

    exige(P, 'D2', yPreparer != null,
        'la section « ${t.hub.sections.prepare} » est visible sur l accueil');
    exige(P, 'D2', yJournal != null,
        'la carte « ${t.hub.cards.journal} » est visible sur l accueil');
    exige(
        P,
        'D2',
        yPreparer != null && yJournal != null && yPreparer < yJournal,
        'on prepare AVANT de tenir un journal : la section '
        '« ${t.hub.sections.prepare} » doit etre AU-DESSUS de la carte '
        '« ${t.hub.cards.journal} » (lu : preparer y=$yPreparer, '
        'journal y=$yJournal)');

    // =====================================================================
    // D4 + D5 — LA CARTE DE NAVIGATION.
    // =====================================================================
    await _aller(tester, '/map');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 12));
    await settleAndShoot(tester, P, '40_carte_navigation',
        timeout: const Duration(seconds: 12));
    logEcran(P, 'D4');

    // D5-a : le trace doit etre LA, pas un ecran de chargement ni un « aucun
    // trace disponible ».
    exige(P, 'D5', present(find.byType(TraceLayer)),
        'le TRACE du sentier est REELLEMENT dessine sur la carte');
    exige(P, 'D5', !present(find.text(t.map.noTrack)),
        'la carte ne dit PAS « ${t.map.noTrack} »');
    exige(P, 'D5', !present(find.text(t.map.loading)),
        'la carte n est PAS restee sur « ${t.map.loading} »');

    // D4 : le laius sur les tirets. Chris l'a vu et l'a nomme. Une carte de
    // navigation n'explique pas ses tirets : elle montre le chemin.
    final laius = texteContenant('tirets');
    logStep(P, 'D4',
        'TEXTE EXPLICATIF SUR LES TIRETS lu a l ecran = '
        '"${laius ?? "(aucun)"}"');
    exige(P, 'D4', laius == null,
        'la carte de navigation ne sert AUCUN laius sur les tirets '
        '(lu : "${laius ?? "(aucun)"}")');

    // D5-b : l'ouverture doit cadrer la PREMIERE ETAPE, pas tout le sentier.
    // On lit la camera REELLE de la carte apres stabilisation et on mesure la
    // diagonale de ce qu'elle montre. Un sentier entier, c'est des dizaines de
    // kilometres dans le champ ; une etape, c'est une poignee.
    final diagonaleKm = _diagonaleVisibleKm(tester);
    logStep(P, 'D5',
        'CHAMP REELLEMENT VISIBLE A L OUVERTURE = '
        '${diagonaleKm?.toStringAsFixed(1) ?? "(non lisible)"} km de diagonale');
    exige(P, 'D5', diagonaleKm != null,
        'la camera de la carte est lisible (la carte est bien montee)');
    exige(P, 'D5', diagonaleKm != null && diagonaleKm < 25,
        'la carte s ouvre CADREE SUR LA PREMIERE ETAPE, pas sur le sentier '
        'entier (diagonale visible lue = '
        '${diagonaleKm?.toStringAsFixed(1) ?? "?"} km, attendu < 25 km)');
    exigeAucuneAbsurdite(P, 'D5');

    // =====================================================================
    // CLOTURE
    // =====================================================================
    exige(P, 'ecran_systeme', ecransSystemeBloquants().isEmpty,
        'aucune fenetre systeme n a recouvert l application '
        '(bloquants : ${ecransSystemeBloquants().join(", ")})');
    poigneeSemantique.dispose();
    retirerVeilleEcranSysteme();
    verdictPersona(P, minimumExigences: 20);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

// ===========================================================================
// OUTILS DU SCENARIO
// ===========================================================================

/// Navigue par le routeur (on ne teste pas ici le chemin d'acces, mais l'ecran).
Future<void> _aller(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator).first);
  GoRouter.of(ctx).go(route);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  await dismissAdsConsentIfPresent(tester, P);
}

/// Remonte en haut de la page courante (le cockpit defile).
Future<void> _remonterEnHaut(WidgetTester tester) async {
  final scroll = find.byType(Scrollable);
  if (scroll.evaluate().isEmpty) return;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scroll.first, const Offset(0, 400));
    await pumpAndSettleTolerant(tester);
  }
}

/// La PASTILLE de verdict affichee a cote du curseur de jours — c'est le mot
/// que le randonneur lit pour savoir si son programme tient.
String? _pastilleVerdict() {
  final v = t.feasibility.formula.verdicts;
  for (final texte in textesAlEcran()) {
    if (texte == v.green || texte == v.orange || texte == v.red) return texte;
  }
  // Repli : quand aucun verdict n'est calculable, l'appli montre le niveau de
  // difficulte (ratio etapes/jour). On le lit aussi, et on le dit.
  final d = t.programme.duration.difficulty;
  for (final texte in textesAlEcran()) {
    if (texte == d.comfortable ||
        texte == d.standard ||
        texte == d.sporty ||
        texte == d.demanding) {
      return texte;
    }
  }
  return null;
}

/// Le GRAND COMPTEUR de jours au-dessus du curseur (« 12 j », « 15 j (dont
/// 3 repos) ») — ce que le randonneur lit comme duree de sa rando.
String? _grandCompteurJours() {
  final motif = RegExp(r'^\d+\s*j( \(dont \d+ repos\))?$');
  for (final texte in textesAlEcran()) {
    if (motif.hasMatch(texte)) return texte;
  }
  return null;
}

/// Pousse le curseur de duree a fond a droite, comme un pouce sur l'ecran.
Future<void> _pousserLeCurseurAFond(WidgetTester tester) async {
  final slider = find.byType(Slider);
  if (slider.evaluate().isEmpty) {
    logStep(P, 'D3', 'COINCE : aucun curseur de duree a pousser');
    return;
  }
  // Deux poussees larges : la premiere saisit le pouce, la seconde sature.
  for (var i = 0; i < 2; i++) {
    await tester.drag(slider.first, const Offset(600, 0));
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  }
  logStep(P, 'D3', 'CURSEUR pousse a fond a droite (2 glissees de 600 px)');
}

/// Ajoute [combien] jours de repos en touchant la puce « Repos » d'un jour.
///
/// Retourne le nombre de repos REELLEMENT ajoutes (constate par le compteur de
/// cartes de repos, pas par le nombre de taps).
Future<int> _ajouterDesRepos(WidgetTester tester, int combien) async {
  var ajoutes = 0;
  for (var i = 0; i < combien; i++) {
    final puce = find.text(t.programme.actions.rest);
    if (puce.evaluate().isEmpty) {
      logStep(P, 'D3', 'COINCE : puce « ${t.programme.actions.rest} » absente');
      break;
    }
    final avant = find.text(t.programme.restDay).evaluate().length;
    await tester.tap(puce.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    final apres = find.text(t.programme.restDay).evaluate().length;
    if (apres > avant) ajoutes++;
    logStep(P, 'D3',
        'Repos ${i + 1} : cartes « ${t.programme.restDay} » visibles '
        '$avant -> $apres');
  }
  return ajoutes;
}

/// Diagonale, en kilometres, de ce que la carte montre REELLEMENT a l'ecran.
double? _diagonaleVisibleKm(WidgetTester tester) {
  final ancre = find.byType(TraceLayer);
  if (ancre.evaluate().isEmpty) return null;
  try {
    final camera = MapCamera.maybeOf(tester.element(ancre.first));
    if (camera == null) return null;
    final b = camera.visibleBounds;
    return const Distance().as(
      LengthUnit.Kilometer,
      LatLng(b.south, b.west),
      LatLng(b.north, b.east),
    );
  } catch (e) {
    logStep(P, 'D5', 'Camera de la carte illisible : $e');
    return null;
  }
}

/// Remplit la fiche d'info (age / taille / poids + consentement) AU DOIGT.
Future<void> _remplirFicheInfo(WidgetTester tester) async {
  await _aller(tester, '/trail/$kTrailId/hiker-profile');
  final champs = <String, String>{'Âge': '45', 'Taille': '175', 'Poids': '78'};
  var remplis = 0;
  for (final e in champs.entries) {
    final champ = find.widgetWithText(TextFormField, e.key);
    if (champ.evaluate().isNotEmpty) {
      await tester.enterText(champ.first, e.value);
      await pumpAndSettleTolerant(tester);
      remplis++;
    }
  }
  if (remplis < 3) {
    final tous = find.byType(TextFormField);
    const ordre = ['45', '175', '78'];
    final n = tous.evaluate().length;
    for (var i = 0; i < n && i < ordre.length; i++) {
      await tester.enterText(tous.at(i), ordre[i]);
      await pumpAndSettleTolerant(tester);
    }
  }
  final consent = find.byType(SwitchListTile);
  if (consent.evaluate().isNotEmpty) {
    final tuile = tester.widget<SwitchListTile>(consent.first);
    if (tuile.value != true) {
      await tester.tap(consent.first, warnIfMissed: false);
      await pumpAndSettleTolerant(tester);
    }
  }
  await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'profil',
      'enregistrer la fiche d info', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  logStep(P, 'profil', 'Fiche d info renseignee : 45 ans, 175 cm, 78 kg');
}

/// Ajoute une rando passee AU DOIGT (sans elle, aucun verdict n'est calcule).
Future<void> _ajouterUneRandoPassee(WidgetTester tester) async {
  await _aller(tester, '/trail/$kTrailId/past-hikes');
  final tph = t.pastHikes;
  if (!await tapIfPresent(tester, find.text(tph.addHike), P, 'randos',
      'ouvrir le formulaire de rando passee', warnIfMissing: false)) {
    return;
  }
  final saisies = <String, String>{
    tph.fieldDays: '2',
    tph.fieldAvgHours: '5',
    tph.fieldElevation: '700',
    tph.fieldDistance: '16',
  };
  for (final e in saisies.entries) {
    final champ = find.ancestor(
      of: find.text(e.key),
      matching: find.byType(TextFormField),
    );
    if (champ.evaluate().isNotEmpty) {
      await tester.enterText(champ.first, e.value);
      await pumpAndSettleTolerant(tester);
    }
  }
  await tapIfPresent(tester, find.text(tph.save), P, 'randos',
      'enregistrer la rando passee', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  logStep(P, 'randos',
      'Rando passee saisie : 2 jours, 5 h/jour, 700 m D+, 16 km');
}
