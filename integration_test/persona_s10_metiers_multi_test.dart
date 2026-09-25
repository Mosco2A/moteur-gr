// ignore_for_file: avoid_print
//
// S10 — SOPHIE CHANGE D'AVIS (famille 3 : multi-reponses et cas metiers).
//
// Elle ne remplit pas un formulaire une fois pour toutes : elle repond, elle se
// contredit, elle revient en arriere, elle bouge son programme apres avoir vu
// le verdict, elle ajoute des repos puis les retire, elle decoupe une etape
// puis la refusionne, elle change la langue en cours de route et elle inverse
// le sens de marche. C'est le comportement REEL d'une randonneuse qui prepare
// sa rando sur trois semaines — et c'est exactement ce qu'aucun test unitaire
// ne joue.
//
// CE QUE CE SCENARIO MESURE, ET C'EST TOUJOURS LA MEME QUESTION :
// QUAND SOPHIE CHANGE QUELQUE CHOSE, EST-CE QUE CE QUE L'APPLI DIT CHANGE ?
// Une valeur saisie qui n'a aucun effet visible est pire qu'un champ absent :
// elle fait croire a la randonneuse qu'elle a ete entendue.
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF : il pilote l'UI reelle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S10_Sophie';
const String kTrailId = 'mare-a-mare-centre';

/// Les cinq langues livrees, avec le titre des reglages dans CHACUNE : c'est le
/// mot que Sophie doit voir apparaitre quand elle bascule.
const Map<String, (String, String)> kLangues = <String, (String, String)>{
  'fr': ('Français', 'Paramètres'),
  'en': ('English', 'Settings'),
  'de': ('Deutsch', 'Einstellungen'),
  'it': ('Italiano', 'Impostazioni'),
  'es': ('Español', 'Ajustes'),
};

void main() {
  initHarness();

  testWidgets('S10 — Sophie se contredit, revient en arriere et change tout',
      (tester) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main()');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 15));
    await completeOnboardingIfPresent(tester, P);

    // =====================================================================
    // 1 — DES RANDOS PASSEES QUI SE CONTREDISENT
    // =====================================================================
    // Sophie declare une traversee de huit jours ET une balade d'une heure.
    // Les deux sont vraies. L'appli doit en tirer quelque chose de SENSE, sans
    // retenir seulement la derniere saisie ni seulement la plus flatteuse.
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await _remplirMorpho(tester, age: '38', taille: '170', poids: '64');
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'profil',
        'enregistrer la fiche', warnIfMissing: false);
    await pumpAndSettleTolerant(tester);
    await settleAndShoot(tester, P, '02_profil');

    await _aller(tester, '/trail/$kTrailId/past-hikes');
    final grosse = await _ajouterRando(tester,
        jours: '8', heures: '9', denivele: '1900', distance: '28');
    final minuscule = await _ajouterRando(tester,
        jours: '1', heures: '1', denivele: '40', distance: '3');
    await settleAndShoot(tester, P, '03_randos_contradictoires');
    logEcran(P, 'contradiction', max: 50);
    exige(P, 'contradiction', grosse && minuscule,
        'DEUX randos contradictoires peuvent coexister (une traversee de 8 '
        'jours ET une balade d une heure)');
    exige(P, 'contradiction', !present(find.text(t.pastHikes.empty)),
        'les deux randos sont bien enregistrees');
    exigeAucuneAbsurdite(P, 'contradiction');

    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '04_verdict_contradictoire');
    logEcran(P, 'verdict_contradiction', max: 70);
    final verdictContradictoire = _verdictLu();
    final plafondContradictoire = texteContenant('km-énergie/jour');
    logStep(P, 'contradiction',
        'VERDICT LU sur profil contradictoire = '
        '"${verdictContradictoire ?? "(aucun)"}" ; PLAFOND LU = '
        '"${plafondContradictoire ?? "(aucun)"}"');
    exige(P, 'contradiction', verdictContradictoire != null,
        'des reponses contradictoires produisent tout de meme UN verdict '
        'lisible (lu : "${verdictContradictoire ?? "(aucun)"}")');
    exige(P, 'contradiction', plafondContradictoire != null,
        'le plafond d effort conseille est CHIFFRE et lisible (lu : '
        '"${plafondContradictoire ?? "(aucun)"}")');
    exigeAucuneAbsurdite(P, 'verdict_contradiction');

    // =====================================================================
    // 2 — LE PROFIL MODIFIE APRES COUP
    // =====================================================================
    // Elle s'est trompee : elle a 68 ans, pas 38. Le verdict doit en tenir
    // compte, sinon la correction n'a servi a rien.
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await _remplirMorpho(tester, age: '68', taille: '170', poids: '92');
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'profil',
        'enregistrer le profil corrige', warnIfMissing: false);
    await pumpAndSettleTolerant(tester);
    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '05_verdict_apres_correction');
    final plafondCorrige = texteContenant('km-énergie/jour');
    final verdictCorrige = _verdictLu();
    logStep(P, 'profil_modifie',
        'APRES correction du profil (38 -> 68 ans, 64 -> 92 kg) : PLAFOND LU = '
        '"${plafondCorrige ?? "(aucun)"}" (avant : '
        '"${plafondContradictoire ?? "(aucun)"}") ; VERDICT LU = '
        '"${verdictCorrige ?? "(aucun)"}" (avant : '
        '"${verdictContradictoire ?? "(aucun)"}")');
    exige(P, 'profil_modifie', plafondCorrige != plafondContradictoire,
        'corriger le profil CHANGE le plafond d effort conseille — sinon la '
        'correction n a servi a rien (avant "$plafondContradictoire", apres '
        '"$plafondCorrige")');

    // =====================================================================
    // 3 — LE PROGRAMME MODIFIE APRES LA FAISABILITE
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/planning');
    await settleAndShoot(tester, P, '06_programme_initial');
    final joursInitial = _compteurJours();
    logStep(P, 'programme', 'COMPTEUR DE JOURS initial = "$joursInitial"');

    // 3a — repos ajoutes PUIS retires : on doit revenir au point de depart.
    final reposAjoutes = await _ajouterDesRepos(tester, 2);
    await settleAndShoot(tester, P, '07_repos_ajoutes');
    final joursAvecRepos = _compteurJours();
    logStep(P, 'repos', 'Apres $reposAjoutes repos ajoute(s) = "$joursAvecRepos"');
    exige(P, 'repos', reposAjoutes > 0,
        'des jours de repos peuvent etre ajoutes au doigt');
    exige(P, 'repos', joursAvecRepos != joursInitial,
        'ajouter des repos CHANGE le nombre de jours affiche (avant '
        '"$joursInitial", apres "$joursAvecRepos")');

    final reposRetires = await _retirerLesRepos(tester, reposAjoutes);
    await settleAndShoot(tester, P, '08_repos_retires');
    final joursApresRetrait = _compteurJours();
    logStep(P, 'repos',
        'Apres $reposRetires repos retire(s) = "$joursApresRetrait" '
        '(depart : "$joursInitial")');
    exige(P, 'repos', reposRetires > 0,
        'un jour de repos peut aussi etre RETIRE au doigt');
    exige(P, 'repos', joursApresRetrait == joursInitial,
        'repos ajoutes PUIS retires : le programme REVIENT a son etat de '
        'depart (depart "$joursInitial", apres aller-retour '
        '"$joursApresRetrait")');

    // 3b — une etape separee PUIS refusionnee : meme exigence d'aller-retour.
    final separee = await _separerUneEtape(tester);
    await settleAndShoot(tester, P, '09_etape_separee');
    final joursApresSplit = _compteurJours();
    logStep(P, 'decoupage',
        'Apres separation d une etape = "$joursApresSplit" (avant : '
        '"$joursApresRetrait")');
    exige(P, 'decoupage', separee,
        'une etape peut etre SEPAREE au doigt (« ${t.programme.actions.split} »)');
    if (separee) {
      exige(P, 'decoupage', joursApresSplit != joursApresRetrait,
          'separer une etape CHANGE le nombre de jours affiche (avant '
          '"$joursApresRetrait", apres "$joursApresSplit")');
    }
    final refusionnee = await _regrouperUneEtape(tester);
    await settleAndShoot(tester, P, '10_etape_refusionnee');
    final joursApresMerge = _compteurJours();
    logStep(P, 'decoupage',
        'Apres regroupement = "$joursApresMerge" (depart : "$joursApresRetrait")');
    exige(P, 'decoupage', refusionnee,
        'une etape separee peut etre REGROUPEE au doigt '
        '(« ${t.programme.actions.merge} »)');
    if (separee && refusionnee) {
      exige(P, 'decoupage', joursApresMerge == joursApresRetrait,
          'separee PUIS regroupee : le programme REVIENT a son etat de depart '
          '(depart "$joursApresRetrait", apres aller-retour "$joursApresMerge")');
    }
    exigeAucuneAbsurdite(P, 'decoupage');

    // 3c — le verdict de faisabilite doit SUIVRE le programme reel.
    final reposFinaux = await _ajouterDesRepos(tester, 3);
    await settleAndShoot(tester, P, '11_programme_detendu');
    final joursDetendu = _compteurJours();
    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '12_verdict_apres_modif_programme');
    final verdictDetendu = _verdictLu();
    logStep(P, 'verdict_suit',
        'PROGRAMME DETENDU ($reposFinaux repos, "$joursDetendu") -> VERDICT LU '
        '= "${verdictDetendu ?? "(aucun)"}" (verdict avant modification du '
        'programme : "${verdictCorrige ?? "(aucun)"}")');
    exige(P, 'verdict_suit', verdictDetendu != null,
        'apres modification du programme, la faisabilite rend toujours un '
        'verdict lisible');
    exige(P, 'verdict_suit', verdictDetendu != verdictCorrige,
        'LE VERDICT SUIT LE PROGRAMME REEL : detendre le programme (repos '
        'ajoutes) change ce que la faisabilite annonce (avant '
        '"$verdictCorrige", apres "$verdictDetendu")');

    // =====================================================================
    // 4 — LE CHANGEMENT DE LANGUE EN COURS DE ROUTE (5 langues)
    // =====================================================================
    for (final entree in kLangues.entries) {
      final code = entree.key;
      final (libelle, titreAttendu) = entree.value;
      await _aller(tester, '/settings');
      final bascule = await tapIfPresent(tester, find.text(libelle), P, 'langue',
          'choisir la langue « $libelle »', warnIfMissing: false);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
      await settleAndShoot(tester, P, '13_langue_$code');
      logEcran(P, 'langue_$code', max: 25);
      exige(P, 'langue', bascule,
          'la langue « $libelle » est proposee et selectionnable');
      exige(P, 'langue', present(find.text(titreAttendu)),
          'en « $libelle », l ecran des reglages s intitule « $titreAttendu »');
      exigeAucuneAbsurdite(P, 'langue_$code');

      // Le changement doit tenir AILLEURS que sur l'ecran des reglages.
      await _aller(tester, '/home');
      await settleAndShoot(tester, P, '14_cockpit_$code');
      logEcran(P, 'cockpit_$code', max: 25);
      exigeAucuneAbsurdite(P, 'cockpit_$code');
    }
    // Retour au francais pour la suite.
    await _aller(tester, '/settings');
    await tapIfPresent(tester, find.text('Français'), P, 'langue',
        'revenir au francais', warnIfMissing: false);
    await pumpAndSettleTolerant(tester);

    // =====================================================================
    // 5 — LE CHANGEMENT DE SENS DE MARCHE
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/itinerary');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '15_itineraire');
    logEcran(P, 'sens', max: 50);
    final inverser = find.text(t.itinerary.direction.reverse);
    exige(P, 'sens', present(inverser),
        'l itineraire propose « ${t.itinerary.direction.reverse} »');
    final avantInversion = textesAlEcran().take(25).join(' | ');
    logStep(P, 'sens', 'ECRAN AVANT inversion : $avantInversion');
    final inverse = await tapIfPresent(tester, inverser, P, 'sens',
        'inverser le sens de marche', warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '16_sens_inverse');
    final apresInversion = textesAlEcran().take(25).join(' | ');
    logStep(P, 'sens', 'ECRAN APRES inversion : $apresInversion');
    exige(P, 'sens', inverse, 'le sens de marche peut etre inverse au doigt');
    if (inverse) {
      exige(P, 'sens', apresInversion != avantInversion,
          'inverser le sens CHANGE ce qui est affiche — sinon le bouton ne '
          'fait rien');
    }
    exigeAucuneAbsurdite(P, 'sens');

    // =====================================================================
    // CLOTURE
    // =====================================================================
    poigneeSemantique.dispose();
    retirerVeilleEcranSysteme();
    verdictPersona(P, minimumExigences: 30);
    await finalizeScenario(tester, P);
    await flushJournal(P);
  });
}

// ===========================================================================
// OUTILS DU SCENARIO
// ===========================================================================

Future<void> _aller(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator).first);
  GoRouter.of(ctx).go(route);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
  await dismissAdsConsentIfPresent(tester, P);
}

String? _verdictLu() {
  final v = t.feasibility.formula.verdicts;
  for (final texte in textesAlEcran()) {
    if (texte == v.green || texte == v.orange || texte == v.red) return texte;
  }
  return null;
}

String? _compteurJours() {
  final motif = RegExp(r'^\d+\s*j( \(dont \d+ repos\))?$');
  for (final texte in textesAlEcran()) {
    if (motif.hasMatch(texte)) return texte;
  }
  return null;
}

Future<void> _remplirMorpho(
  WidgetTester tester, {
  required String age,
  required String taille,
  required String poids,
}) async {
  final valeurs = <String, String>{
    'Âge': age,
    'Taille': taille,
    'Poids': poids,
  };
  for (final e in valeurs.entries) {
    final champ = find.widgetWithText(TextFormField, e.key);
    if (champ.evaluate().isEmpty) continue;
    await tester.enterText(champ.first, e.value);
    await pumpAndSettleTolerant(tester);
  }
  final consent = find.byType(SwitchListTile);
  if (consent.evaluate().isNotEmpty &&
      tester.widget<SwitchListTile>(consent.first).value != true) {
    await tester.tap(consent.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
  }
  logStep(P, 'profil', 'Morphologie saisie : $age ans, $taille cm, $poids kg');
}

Future<bool> _ajouterRando(
  WidgetTester tester, {
  required String jours,
  required String heures,
  required String denivele,
  required String distance,
}) async {
  final tph = t.pastHikes;
  if (!await tapIfPresent(tester, find.text(tph.addHike), P, 'randos',
      'ouvrir le formulaire de rando', warnIfMissing: false)) {
    return false;
  }
  final valeurs = <String, String>{
    tph.fieldDays: jours,
    tph.fieldAvgHours: heures,
    tph.fieldElevation: denivele,
    tph.fieldDistance: distance,
  };
  for (final e in valeurs.entries) {
    final champ = find.ancestor(
      of: find.text(e.key),
      matching: find.byType(TextFormField),
    );
    if (champ.evaluate().isEmpty) continue;
    await tester.enterText(champ.first, e.value);
    await pumpAndSettleTolerant(tester);
  }
  final sauve = await tapIfPresent(tester, find.text(tph.save), P, 'randos',
      'enregistrer la rando ($jours j / $distance km)', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  return sauve;
}

Future<int> _ajouterDesRepos(WidgetTester tester, int combien) async {
  var ajoutes = 0;
  for (var i = 0; i < combien; i++) {
    final puce = find.text(t.programme.actions.rest);
    if (puce.evaluate().isEmpty) break;
    final avant = _compteurJours();
    await tester.tap(puce.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    if (_compteurJours() != avant) ajoutes++;
  }
  return ajoutes;
}

/// Retire les jours de repos par leur bouton dedie (icone « supprimer ce jour
/// de repos », portee par sa bulle d'aide).
Future<int> _retirerLesRepos(WidgetTester tester, int combien) async {
  var retires = 0;
  for (var i = 0; i < combien; i++) {
    final bouton =
        find.byTooltip(t.programme.actions.removeRest).hitTestable();
    if (bouton.evaluate().isEmpty) {
      logStep(P, 'repos',
          'COINCE : bouton « ${t.programme.actions.removeRest} » introuvable '
          'au tour ${i + 1}');
      break;
    }
    final avant = _compteurJours();
    await tester.tap(bouton.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    if (_compteurJours() != avant) retires++;
  }
  return retires;
}

Future<bool> _separerUneEtape(WidgetTester tester) async {
  final puce = find.text(t.programme.actions.split);
  if (puce.evaluate().isEmpty) return false;
  final avant = _compteurJours();
  await tester.tap(puce.first, warnIfMissed: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  return _compteurJours() != avant;
}

Future<bool> _regrouperUneEtape(WidgetTester tester) async {
  final puce = find.text(t.programme.actions.merge);
  if (puce.evaluate().isEmpty) return false;
  final avant = _compteurJours();
  await tester.tap(puce.first, warnIfMissed: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  return _compteurJours() != avant;
}
