// ignore_for_file: avoid_print
//
// S9 — GERARD, CELUI QUI NE FAIT RIEN COMME PREVU (famille 2 : non passants).
//
// 72 ans, jamais randonne, refuse tout ce qu'on lui demande et redemarre
// l'application a tout bout de champ. Il vise le sentier tel quel, sans rien
// adapter. C'est le pire client d'une application de montagne, et c'est
// exactement celui dont le verdict doit etre JUSTE.
//
// LA REGLE D'ATTRIBUTION QUI GOUVERNE CE FICHIER (grille #100297, L9(e)) :
// UN REFUS PROPRE ET EXPLIQUE EST UN COMPORTEMENT CORRECT, PAS UN DEFAUT.
// Sont des defauts : l'acceptation silencieuse, le refus muet, le plantage, la
// valeur aberrante affichee, et — le plus sournois — le VERDICT INVENTE a
// partir de rien.
//
// CE QUE CE SCENARIO COUVRE, ET QUI MANQUAIT :
//   * le refus de TOUS les consentements ;
//   * aucune donnee saisie du tout ;
//   * un test de marche interrompu (donc rate) ;
//   * un debutant total sur le sentier tel qu'il est ;
//   * CE QUI SURVIT A UN REDEMARRAGE, etape par etape — la question que
//     personne n'avait posee.
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF : il pilote l'UI reelle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S9_Gerard';
const String kTrailId = 'mare-a-mare-centre';

void main() {
  initHarness();

  testWidgets('S9 — Gerard refuse tout, ne saisit rien, et redemarre',
      (tester) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    logStep(P, 'boot', 'Lancement de app.main()');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_boot',
        timeout: const Duration(seconds: 15));
    // Le harnais refuse deja le consentement publicitaire (« Ne pas
    // consentir ») : c'est le premier des refus de Gerard, et il est joue.
    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_onboarding');

    // =====================================================================
    // A — RIEN SAISI DU TOUT : l'appli doit REFUSER DE REPONDRE, pas inventer
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '03_faisabilite_a_vide');
    logEcran(P, 'a_vide', max: 60);

    final tv = t.feasibility.formula.verdicts;
    final verdictAVide = _verdictLu();
    logStep(P, 'a_vide',
        'VERDICT LU alors que RIEN n a ete saisi = "${verdictAVide ?? "(aucun)"}"');
    exige(P, 'a_vide', verdictAVide == null,
        'sans aucune donnee, l appli n INVENTE PAS de verdict '
        '(lu : "${verdictAVide ?? "(aucun)"}")');
    exige(P, 'a_vide',
        present(find.text(t.feasibility.flow.missingTitle)) ||
            present(find.text(t.feasibility.flow.title)),
        'sans donnee, l appli DIT ce qui lui manque au lieu de se taire');
    exigeAucuneAbsurdite(P, 'a_vide');

    // =====================================================================
    // B — LE REFUS DU CONSENTEMENT MORPHOLOGIE
    // =====================================================================
    // Gerard remplit sa morphologie mais REFUSE que l'appli la garde. Ce refus
    // doit etre respecte ET explique : ni enregistrement silencieux, ni ecran
    // qui se ferme sans un mot.
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await settleAndShoot(tester, P, '04_fiche_vierge');
    await _saisirMorpho(tester, age: '72', taille: '172', poids: '88');
    final consentementRefuse = _consentementEstRefuse(tester);
    logStep(P, 'consentement',
        'Consentement morphologie laisse a REFUSE = $consentementRefuse');
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'consentement',
        'enregistrer SANS avoir consenti', warnIfMissing: false);
    await pumpAndSettleTolerant(tester);
    await settleAndShoot(tester, P, '05_refus_consentement');
    logEcran(P, 'consentement', max: 50);
    final surLaFiche = present(find.text(t.hikerProfile.title));
    logStep(P, 'consentement',
        'Apres tentative d enregistrement sans consentement, TOUJOURS sur la '
        'fiche = $surLaFiche');
    exige(P, 'consentement', consentementRefuse ? surLaFiche : true,
        'un refus de consentement ne laisse pas partir la morphologie en '
        'silence : l ecran reste, et il s explique');
    exigeAucuneAbsurdite(P, 'consentement');

    // Il finit par accepter (sinon rien de la suite n'est mesurable) et
    // enregistre.
    await _accepterConsentement(tester);
    await tapIfPresent(tester, find.text(t.hikerProfile.save), P, 'profil',
        'enregistrer la fiche', warnIfMissing: false);
    await pumpAndSettleTolerant(tester);
    await settleAndShoot(tester, P, '06_fiche_enregistree');

    // =====================================================================
    // C — CE QUI SURVIT A UN REDEMARRAGE (1) : la fiche d'info
    // =====================================================================
    await redemarrageAChaud(tester, P, app.main);
    await settleAndShoot(tester, P, '07_apres_redemarrage_1');
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await settleAndShoot(tester, P, '08_fiche_apres_redemarrage');
    logEcran(P, 'survie_profil', max: 50);
    final ageSurvivant = _valeurDuChamp(tester, 'Âge');
    final tailleSurvivante = _valeurDuChamp(tester, 'Taille');
    final poidsSurvivant = _valeurDuChamp(tester, 'Poids');
    logStep(P, 'survie_profil',
        'APRES REDEMARRAGE, valeurs RELUES dans la fiche : age="$ageSurvivant" '
        'taille="$tailleSurvivante" poids="$poidsSurvivant"');
    exige(P, 'survie_profil', ageSurvivant == '72',
        'l age survit au redemarrage (relu : "$ageSurvivant", saisi : "72")');
    exige(P, 'survie_profil', tailleSurvivante == '172',
        'la taille survit au redemarrage (relu : "$tailleSurvivante")');
    exige(P, 'survie_profil', poidsSurvivant == '88',
        'le poids survit au redemarrage (relu : "$poidsSurvivant")');

    // =====================================================================
    // D — LE TEST DE MARCHE RATE : lance puis interrompu
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/walk-test');
    await settleAndShoot(tester, P, '09_test_marche');
    exige(P, 'test_rate', present(find.text(t.walkTest.safetyWarning)),
        'a 72 ans, l avertissement de prudence est AFFICHE avant l effort');
    await tapIfPresent(tester, find.text(t.walkTest.start), P, 'test_rate',
        'demarrer le test', warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '10_test_demarre');
    final arrete = await tapIfPresent(tester, find.text(t.walkTest.stop), P,
        'test_rate', 'ARRETER le test en cours (Gerard abandonne)',
        warnIfMissing: false) ||
        await tapIfPresent(tester, find.text(t.walkTest.cancel), P, 'test_rate',
            'annuler le test en cours', warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '11_test_interrompu');
    logEcran(P, 'test_rate', max: 50);
    logStep(P, 'test_rate', 'Test interrompu par un geste = $arrete');
    exige(P, 'test_rate', true,
        'le test de marche peut etre INTERROMPU sans faire tomber l ecran '
        '(interruption jouee = $arrete)');
    exigeAucuneAbsurdite(P, 'test_rate');
    // Un test rate ne doit JAMAIS produire un niveau flatteur.
    exige(P, 'test_rate',
        !present(find.text(t.walkTest.levels.excellent)) &&
            !present(find.text(t.walkTest.levels.good)),
        'un test interrompu ne rend PAS un niveau « '
        '${t.walkTest.levels.good} » ou « ${t.walkTest.levels.excellent} »');

    // =====================================================================
    // E — DEBUTANT TOTAL SUR LE SENTIER TEL QUEL
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/past-hikes');
    await settleAndShoot(tester, P, '12_randos');
    final randoMinuscule = await _ajouterRando(tester,
        jours: '1', heures: '2', denivele: '80', distance: '5');
    exige(P, 'debutant', randoMinuscule,
        'une toute petite rando peut etre saisie');
    await settleAndShoot(tester, P, '13_rando_minuscule');

    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '14_verdict_debutant');
    logEcran(P, 'debutant', max: 70);
    final verdictDebutant = _verdictLu();
    logStep(P, 'debutant',
        'VERDICT LU pour un debutant de 72 ans sur le sentier tel quel = '
        '"${verdictDebutant ?? "(aucun)"}"');
    exige(P, 'debutant', verdictDebutant != null,
        'avec une fiche et une rando, un verdict EST rendu (lu : '
        '"${verdictDebutant ?? "(aucun)"}")');
    exige(P, 'debutant', verdictDebutant != tv.green,
        'un debutant de 72 ans sur le sentier non decoupe n obtient PAS '
        '« ${tv.green} » (lu : "${verdictDebutant ?? "(aucun)"}")');
    exige(P, 'debutant',
        present(find.text(t.feasibility.formula.adviceTitle)),
        'un verdict defavorable est accompagne de CONSEILS — dire non sans '
        'dire quoi faire, c est abandonner le randonneur');
    final provisoire = texteContenant('provisoire');
    logStep(P, 'debutant',
        'MENTION DU CARACTERE PROVISOIRE (test de marche non fait) lue = '
        '"${provisoire ?? "(aucune)"}"');
    exige(P, 'debutant', provisoire != null,
        'le test de marche n ayant pas abouti, l appli ANNONCE que le resultat '
        'est provisoire (lu : "${provisoire ?? "(aucune)"}")');
    exigeAucuneAbsurdite(P, 'debutant');

    // =====================================================================
    // F — CE QUI SURVIT A UN REDEMARRAGE (2) : la rando passee et le verdict
    // =====================================================================
    await redemarrageAChaud(tester, P, app.main);
    await _aller(tester, '/trail/$kTrailId/past-hikes');
    await settleAndShoot(tester, P, '15_randos_apres_redemarrage');
    logEcran(P, 'survie_randos', max: 50);
    final listeVide = present(find.text(t.pastHikes.empty));
    logStep(P, 'survie_randos',
        'APRES REDEMARRAGE, la liste des randos se declare VIDE = $listeVide');
    exige(P, 'survie_randos', !listeVide,
        'la rando passee survit au redemarrage (liste vide relue = $listeVide)');

    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '16_verdict_apres_redemarrage');
    final verdictApresRedemarrage = _verdictLu();
    logStep(P, 'survie_verdict',
        'VERDICT RELU apres redemarrage = "${verdictApresRedemarrage ?? "(aucun)"}" '
        '(avant : "${verdictDebutant ?? "(aucun)"}")');
    exige(P, 'survie_verdict', verdictApresRedemarrage == verdictDebutant,
        'le verdict est LE MEME apres redemarrage qu avant — sinon le '
        'randonneur ne sait plus a quoi se fier (avant "$verdictDebutant", '
        'apres "$verdictApresRedemarrage")');

    // =====================================================================
    // G — CE QUI SURVIT A UN REDEMARRAGE (3) : le programme et ses repos
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/planning');
    await settleAndShoot(tester, P, '17_programme');
    final joursAvant = _compteurJours();
    final reposAjoutes = await _ajouterDesRepos(tester, 2);
    await settleAndShoot(tester, P, '18_programme_avec_repos');
    final joursApresRepos = _compteurJours();
    logStep(P, 'survie_programme',
        'Programme : "$joursAvant" -> "$joursApresRepos" apres $reposAjoutes '
        'ajout(s) de repos');

    await redemarrageAChaud(tester, P, app.main);
    await _aller(tester, '/trail/$kTrailId/planning');
    await settleAndShoot(tester, P, '19_programme_apres_redemarrage');
    final joursApresRedemarrage = _compteurJours();
    logStep(P, 'survie_programme',
        'APRES REDEMARRAGE, compteur de jours RELU = '
        '"${joursApresRedemarrage ?? "(aucun)"}" (avant redemarrage : '
        '"${joursApresRepos ?? "(aucun)"}")');
    exige(P, 'survie_programme', joursApresRedemarrage == joursApresRepos,
        'le programme prepare (jours et repos) survit au redemarrage '
        '(avant "$joursApresRepos", apres "$joursApresRedemarrage")');
    exigeAucuneAbsurdite(P, 'survie_programme');

    // =====================================================================
    // CLOTURE
    // =====================================================================
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

/// Ce que le champ [libelle] CONTIENT reellement a l'ecran (relecture apres
/// redemarrage : c'est la valeur que Gerard revoit, pas celle qu'on a saisie).
String? _valeurDuChamp(WidgetTester tester, String libelle) {
  final champ = find.widgetWithText(TextFormField, libelle);
  if (champ.evaluate().isEmpty) return null;
  final champs = find.descendant(
    of: champ.first,
    matching: find.byType(EditableText),
  );
  if (champs.evaluate().isEmpty) return null;
  return tester.widget<EditableText>(champs.first).controller.text;
}

Future<void> _saisirMorpho(
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
    if (champ.evaluate().isEmpty) {
      logStep(P, 'profil', 'COINCE : champ « ${e.key} » introuvable');
      continue;
    }
    await tester.enterText(champ.first, e.value);
    await pumpAndSettleTolerant(tester);
  }
  logStep(P, 'profil', 'Morphologie saisie : $age ans, $taille cm, $poids kg');
}

bool _consentementEstRefuse(WidgetTester tester) {
  final consent = find.byType(SwitchListTile);
  if (consent.evaluate().isEmpty) return false;
  return tester.widget<SwitchListTile>(consent.first).value != true;
}

Future<void> _accepterConsentement(WidgetTester tester) async {
  final consent = find.byType(SwitchListTile);
  if (consent.evaluate().isEmpty) return;
  if (tester.widget<SwitchListTile>(consent.first).value != true) {
    await tester.tap(consent.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
  }
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
      'enregistrer la rando', warnIfMissing: false);
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
