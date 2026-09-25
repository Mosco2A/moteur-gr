// ignore_for_file: avoid_print
//
// S8 — LE PARCOURS PASSANT COMPLET D'UNE UTILISATRICE NEUVE (famille 1).
//
// CLAIRE, 29 ans, vient d'installer l'application. Elle ne sait rien du produit
// et ne lira aucune documentation. Elle ouvre, elle regarde, elle touche. Ce
// scenario fait EXACTEMENT ce qu'elle fait, dans l'ordre : premiere ouverture,
// catalogue, entree dans le sentier, fiche d'info (age, taille, poids, pays),
// test de marche, interview de ses randos passees, verdict de faisabilite,
// choix du nombre de jours, programme, calendrier, nuitees, sac, et enfin
// demarrage de la rando.
//
// LA REGLE DE CE FICHIER, ET C'EST CELLE QUI A MANQUE LE 25/09 AU MATIN :
// a chaque ecran, on ne demande pas « le widget existe-t-il ? » mais « ce qui
// est ecrit a-t-il un SENS pour un humain ? ». Chaque pas LIT l'ecran
// (`logEcran`, preuve citable) et refuse ce qu'un humain ne doit jamais lire :
// une cle de traduction brute, un gabarit `{count}` non remplace, un `null`,
// un `NaN`. Un widget present qui affiche une absurdite est un ECHEC.
//
// CE FICHIER NE MODIFIE AUCUN CODE APPLICATIF : il pilote l'UI reelle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/main.dart' as app;

import 'persona_harness.dart';

const String P = 'S8_Claire';
const String kTrailId = 'mare-a-mare-centre';

void main() {
  initHarness();

  testWidgets('S8 — Claire, premiere ouverture jusqu au depart en rando',
      (tester) async {
    reinitialiserExigences();
    final poigneeSemantique = tester.ensureSemantics();

    // =====================================================================
    // 1 — PREMIERE OUVERTURE
    // =====================================================================
    logStep(P, 'boot', 'Lancement de app.main() — premiere ouverture');
    installerVeilleEcranSysteme(P);
    app.main();
    await settleAndShoot(tester, P, '01_premiere_ouverture',
        timeout: const Duration(seconds: 15));
    logEcran(P, 'boot');
    exigeAucuneAbsurdite(P, 'boot');

    await completeOnboardingIfPresent(tester, P);
    await settleAndShoot(tester, P, '02_apres_onboarding');
    logEcran(P, 'onboarding');
    exigeAucuneAbsurdite(P, 'onboarding');

    // =====================================================================
    // 2 — LE CATALOGUE : elle doit pouvoir CHOISIR un sentier
    // =====================================================================
    final catalogue = textFrEn('Catalogue des sentiers', 'Trail catalog');
    if (!present(catalogue)) {
      await tapIfPresent(tester, find.text(t.hub.cards.offline), P, 'catalogue',
          'Decouvrir des sentiers', warnIfMissing: false);
    }
    await settleAndShoot(tester, P, '03_catalogue');
    logEcran(P, 'catalogue');
    final entrer = textFrEn('Entrer', 'Enter');
    exige(P, 'catalogue', present(catalogue) || present(entrer),
        'le catalogue des sentiers est atteint');
    exige(P, 'catalogue', entrer.evaluate().isNotEmpty,
        'au moins un sentier propose « Entrer » — sans cela, tout le reste du '
        'parcours est sans objet');
    exigeAucuneAbsurdite(P, 'catalogue');

    // =====================================================================
    // 3 — ENTREE DANS LE SENTIER -> COCKPIT DE PREPARATION
    // =====================================================================
    if (!await tapIfPresent(
        tester,
        find.byKey(const ValueKey('catalog-enter-$kTrailId')),
        P,
        'cockpit',
        'Entrer dans le sentier vitrine',
        warnIfMissing: false)) {
      await exigeTap(tester, entrer, P, 'cockpit', 'Entrer (1er sentier)');
    }
    await settleAndShoot(tester, P, '04_cockpit');
    logEcran(P, 'cockpit');
    exige(P, 'cockpit', present(find.text(t.hub.sections.prepare)),
        'le cockpit affiche la section « ${t.hub.sections.prepare} »');
    exigeAucuneAbsurdite(P, 'cockpit');

    // =====================================================================
    // 4 — LA FICHE D'INFO : age, taille, poids, pays
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    await settleAndShoot(tester, P, '05_fiche_info');
    logEcran(P, 'fiche_info');
    exige(P, 'fiche_info', present(find.text(t.hikerProfile.privacyBanner)),
        'la fiche dit A QUOI SERT la morphologie et OU elle reste — une donnee '
        'de sante ne se demande pas sans le dire');

    await exigeSaisie(tester, _champ('Âge'), '29', P, 'fiche_info', 'age');
    await exigeSaisie(
        tester, _champ('Taille'), '168', P, 'fiche_info', 'taille');
    await exigeSaisie(tester, _champ('Poids'), '61', P, 'fiche_info', 'poids');
    final accord = await _accepterConsentementMorpho(tester);
    exige(P, 'fiche_info', accord,
        'l accord morphologie est REELLEMENT coche avant d enregistrer — sans '
        'lui rien ne s enregistre, et tout le reste du parcours est fausse');
    await settleAndShoot(tester, P, '06_fiche_remplie');
    exigeAucuneAbsurdite(P, 'fiche_info');

    await exigeTap(tester, find.text(t.hikerProfile.save), P, 'fiche_info',
        'enregistrer la fiche d info');
    await pumpAndSettleTolerant(tester);
    exige(P, 'fiche_info', !present(find.text(t.hikerProfile.errorEmpty)),
        'une fiche CORRECTEMENT renseignee n est pas refusee');
    await settleAndShoot(tester, P, '07_fiche_enregistree');

    // LE PAYS SE CHOISIT MAINTENANT, ET C EST UN DEPLACEMENT VOLONTAIRE.
    // Le rouge « France » — la feuille de selection qui ne se referme pas —
    // ne se contente pas de rater son exigence : tant qu elle reste montee,
    // elle COUVRE la bascule de consentement et le bouton Enregistrer, qui
    // deviennent inatteignables. Mesure du 26/09 : l accord ne pouvait plus
    // etre coche, la fiche ne partait pas, et le scenario concluait « aucun
    // verdict » dix pas plus loin. En choisissant le pays APRES l
    // enregistrement, le rouge reste mesure mais il ne fait plus tomber le
    // reste du parcours. On ne masque rien : on empeche une defaillance
    // connue du harnais d en fabriquer d autres.
    await _aller(tester, '/trail/$kTrailId/hiker-profile');
    final pays = await _choisirPays(tester, 'France');
    exige(P, 'fiche_info', pays,
        'le pays se choisit au doigt dans le selecteur');
    if (pays) {
      exige(P, 'fiche_info', present(find.text('France')),
          'le pays choisi s affiche par son NOM (« France »), pas par un code');
    }
    await settleAndShoot(tester, P, '07b_pays_choisi');

    // =====================================================================
    // 5 — LE TEST DE MARCHE : on l'ouvre et on le demarre (pas 6 minutes)
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/walk-test');
    await settleAndShoot(tester, P, '08_test_marche');
    logEcran(P, 'test_marche');
    exige(P, 'test_marche',
        present(textFrEn('Démarrer le test', 'Start the test')),
        'le test de marche propose un bouton pour le DEMARRER');
    await tapIfPresent(tester, textFrEn('Démarrer le test', 'Start the test'),
        P, 'test_marche', 'demarrer le test de marche', warnIfMissing: false);
    await settleAndShoot(tester, P, '09_test_marche_demarre');
    exigeAucuneAbsurdite(P, 'test_marche');
    logStep(P, 'test_marche',
        'Test de marche OUVERT et DEMARRE (compte a rebours observe). NON joue '
        'en entier : c est un chrono reel de 6:00 sans mode accelere — le dire '
        'plutot que de pretendre l avoir passe.');

    // =====================================================================
    // 6 — L'INTERVIEW DES RANDOS PASSEES
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/past-hikes');
    await settleAndShoot(tester, P, '10_randos_passees');
    logEcran(P, 'randos');
    final tph = t.pastHikes;
    exige(P, 'randos', present(find.text(tph.empty)),
        'avant saisie, la liste declare qu aucune rando n est enregistree');
    final rando1 = await _ajouterRando(tester, jours: '2', heures: '5',
        denivele: '650', distance: '15');
    exige(P, 'randos', rando1, 'une rando passee peut etre saisie et sauvee');
    exige(P, 'randos', !present(find.text(tph.empty)),
        'APRES enregistrement, la liste ne declare PLUS etre vide — la rando '
        'existe vraiment');
    await settleAndShoot(tester, P, '11_rando_saisie');
    exigeAucuneAbsurdite(P, 'randos');

    // =====================================================================
    // 7 — LE VERDICT DE FAISABILITE
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/feasibility');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    await settleAndShoot(tester, P, '12_faisabilite');
    logEcran(P, 'faisabilite', max: 60);
    final tv = t.feasibility.formula.verdicts;
    final verdict = _verdictLu();
    logStep(P, 'faisabilite',
        'VERDICT REELLEMENT LU A L ECRAN = "${verdict ?? "(aucun)"}"');
    exige(P, 'faisabilite', verdict != null,
        'avec une fiche complete et une rando passee, l ecran DONNE un verdict '
        '(${tv.green} / ${tv.orange} / ${tv.red}) — lu : '
        '"${verdict ?? "(aucun)"}"');
    exige(P, 'faisabilite',
        present(find.text(t.feasibility.formula.adviceTitle)),
        'le verdict est accompagne de CONSEILS — un feu rouge sans conseil ne '
        'sert a rien a un randonneur');
    exigeAucuneAbsurdite(P, 'faisabilite');

    // =====================================================================
    // 7bis — L'ITINERAIRE : le deroule des etapes et le sens de marche
    // =====================================================================
    // Il fait partie du parcours de Claire (carte « Itineraire » de la section
    // Preparer) ET il conditionne le depart : la porte du cockpit exige
    // Itineraire + Date + Programme.
    await _aller(tester, '/trail/$kTrailId/itinerary');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '12b_itineraire');
    logEcran(P, 'itineraire', max: 40);
    exige(P, 'itineraire', present(find.text(t.itinerary.direction.title)),
        'l itineraire dit dans quel SENS la rando se marche');
    exige(P, 'itineraire', !present(find.text(t.itinerary.empty)),
        'l itineraire n est PAS vide (il ne dit pas « ${t.itinerary.empty} »)');
    exigeAucuneAbsurdite(P, 'itineraire');

    // =====================================================================
    // 8 — LE NOMBRE DE JOURS ET LE PROGRAMME
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/planning');
    await settleAndShoot(tester, P, '13_programme');
    logEcran(P, 'programme', max: 60);
    exige(P, 'programme', present(find.byType(Slider)),
        'le programme laisse CHOISIR le nombre de jours (curseur)');
    final jours = _compteurJours();
    logStep(P, 'programme',
        'COMPTEUR DE JOURS lu a l ecran = "${jours ?? "(aucun)"}"');
    exige(P, 'programme', jours != null,
        'le nombre de jours du programme est LISIBLE (ex. « 9 j ») — lu : '
        '"${jours ?? "(aucun)"}"');
    exige(P, 'programme', find.text(t.programme.restDay).evaluate().isNotEmpty
            || find.textContaining('J').evaluate().isNotEmpty,
        'le programme liste des journees');
    exigeAucuneAbsurdite(P, 'programme');

    // Le bouton de validation porte DEUX libelles selon l'etat de l'ecran
    // (« ${t.programme.validate} » ou « ${t.programme.validateNext} ») : on
    // cherche les deux, sinon on accuse l appli d un bouton absent qui est la.
    final validerProgramme = find.byWidgetPredicate((w) =>
        w is Text &&
        (w.data == t.programme.validate || w.data == t.programme.validateNext));
    await scrollUntil(tester, validerProgramme, P, 'programme',
        'bouton de validation du programme');
    await exigeTap(tester, validerProgramme, P, 'programme',
        'valider le programme');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '14_programme_valide');

    // =====================================================================
    // 9 — LE CALENDRIER : choisir la date de depart
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/calendar');
    await settleAndShoot(tester, P, '15_calendrier');
    logEcran(P, 'calendrier', max: 60);
    exigeAucuneAbsurdite(P, 'calendrier');
    final dateChoisie = await _choisirUneDate(tester);
    await settleAndShoot(tester, P, '16_date_choisie');
    exige(P, 'calendrier', dateChoisie,
        'une date de depart peut etre choisie au doigt dans le calendrier');
    exige(P, 'calendrier', !present(find.text(t.settings.noDateChosen)),
        'apres le choix, l appli ne dit plus « ${t.settings.noDateChosen} »');

    // =====================================================================
    // 10 — LES NUITEES
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/nuitees');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
    await settleAndShoot(tester, P, '17_nuitees');
    logEcran(P, 'nuitees', max: 60);
    exige(P, 'nuitees', !present(find.text(t.nuitees.empty.title)),
        'l itineraire etant configure, l ecran des nuitees n est PAS vide '
        '(il ne dit pas « ${t.nuitees.empty.title} »)');
    // C'est ICI que se voient les gabarits non remplis : « J{n} »,
    // « {count} hebergements disponibles »... Un humain lit ces accolades.
    exigeAucuneAbsurdite(P, 'nuitees');

    // =====================================================================
    // 11 — LE SAC
    // =====================================================================
    await _aller(tester, '/trail/$kTrailId/checklist');
    await settleAndShoot(tester, P, '18_sac');
    logEcran(P, 'sac', max: 60);
    exige(P, 'sac', present(find.text(t.checklist.categories.carrying)),
        'le sac est organise par categories (« '
        '${t.checklist.categories.carrying} »)');
    // LIBELLE REEL DE L ECRAN, releve le 25/09 : « 0 / 84 articles cochés »
    // (et non le « préparés » de la cle i18n `checklist.progress`). On lit ce
    // que l ecran ecrit, pas ce que la cle laisse croire.
    final avancementAvant = texteContenant('articles cochés');
    logStep(P, 'sac',
        'AVANCEMENT DU SAC lu avant de cocher = '
        '"${avancementAvant ?? "(aucun)"}"');
    exige(P, 'sac', avancementAvant != null,
        'l avancement du sac est LISIBLE (ex. « 0 / 84 articles cochés ») — lu : '
        '"${avancementAvant ?? "(aucun)"}"');
    final coche = await _cocherUnObjet(tester);
    await settleAndShoot(tester, P, '19_sac_coche');
    final avancementApres = texteContenant('articles cochés');
    logStep(P, 'sac',
        'AVANCEMENT DU SAC lu apres avoir coche = '
        '"${avancementApres ?? "(aucun)"}"');
    exige(P, 'sac', coche, 'un objet du sac peut etre coche au doigt');
    exige(P, 'sac', avancementApres != null &&
            avancementApres != avancementAvant,
        'cocher un objet FAIT BOUGER l avancement affiche '
        '(avant "$avancementAvant", apres "$avancementApres")');
    exigeAucuneAbsurdite(P, 'sac');

    // =====================================================================
    // 12 — LE DEPART
    // =====================================================================
    await _aller(tester, '/home');
    await settleAndShoot(tester, P, '20_cockpit_avant_depart');
    logEcran(P, 'depart', max: 60);
    final cta = find.text(t.hub.startCta);
    await scrollUntil(tester, cta, P, 'depart',
        'bouton « ${t.hub.startCta} » du cockpit');
    exige(P, 'depart', present(cta),
        'le cockpit propose « ${t.hub.startCta} » une fois la preparation faite');
    final blocage = texteContenant('Complète d');
    logStep(P, 'depart',
        'MESSAGE DE BLOCAGE lu au-dessus du bouton = "${blocage ?? "(aucun)"}"');
    exige(P, 'depart', blocage == null,
        'la preparation etant faite, l appli ne retient PLUS le depart '
        '(lu : "${blocage ?? "(aucun)"}")');

    final parti = await exigeTap(
        tester, cta, P, 'depart', 'demarrer la randonnee');
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    // DERNIERE PORTE AVANT LE DEPART, RELEVEE LE 25/09 : sans position GPS,
    // l'appli demande confirmation (« Position indisponible. Demarrer quand
    // meme ? »). C'est le cas de l'emulateur sans fix GPS, et c'est aussi le
    // cas d'un randonneur sous couvert forestier : la question est legitime,
    // on y repond comme un humain plutot que de la contourner.
    final confirmation = texteContenant('Position indisponible');
    if (confirmation != null) {
      logStep(P, 'depart',
          'CONFIRMATION DEMANDEE AVANT LE DEPART, lue a l ecran : '
          '"$confirmation" — on confirme.');
      await tapIfPresent(tester, textFrEn('Démarrer quand même', 'Start anyway'),
          P, 'depart', 'confirmer le depart sans position GPS',
          warnIfMissing: false);
    }
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    // DEUXIEME PORTE, RELEVEE LE 25/09 SUR LA BRANCHE CORRIGEE : une fois la
    // position confirmee, l appli explique pourquoi elle va demander la
    // localisation « Toujours » (« Suivre ta trace meme ecran eteint ») et
    // laisse le choix « Plus tard » / « Voir la demande ». Tant qu on n y
    // repond pas, LA RANDO NE DEMARRE PAS — le cockpit reste en preparation.
    // Claire n a pas envie d une permission de fond : elle repousse.
    final prevol = texteContenant('Suivre ta trace');
    if (prevol != null) {
      logStep(P, 'depart',
          'EXPLICATION DE PERMISSION LUE AVANT LE DEPART : "$prevol" — on '
          'repond « Plus tard », comme une randonneuse pressee.');
      await tapIfPresent(tester, textFrEn('Plus tard', 'Later'), P, 'depart',
          'repousser la permission de localisation de fond',
          warnIfMissing: false);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    }
    await settleAndShoot(tester, P, '21_apres_depart',
        timeout: const Duration(seconds: 12));
    logEcran(P, 'depart_apres', max: 60);
    if (parti) {
      exige(P, 'depart', !present(find.text(t.hub.startCta)),
          'apres le depart, l appli ne propose plus de « ${t.hub.startCta} » : '
          'la rando a REELLEMENT commence');
    }
    exigeAucuneAbsurdite(P, 'depart_apres');

    // LE JOURNAL EN RANDO (regle revue par la tache 558). Il doit etre ABSENT
    // de la preparation — c est verifie par S12 — et PRESENT une fois partie,
    // UNE SEULE FOIS. Un carnet qu on ecrit ne se cherche pas, et il ne doit
    // pas non plus apparaitre deux fois sur le meme ecran.
    await _aller(tester, '/home');
    await _remonterEnHaut(tester);
    // ON DESCEND LE CHERCHER, ET C EST INDISPENSABLE : le cockpit est une liste
    // paresseuse. Compter les cartes sans defiler ne mesure que ce que Flutter
    // a bien voulu construire — on conclurait « absente » sur une carte qui est
    // simplement plus bas. On defile donc jusqu a elle avant de compter.
    await scrollUntil(tester, find.text(t.hub.cards.journal), P, 'journal',
        'carte « ${t.hub.cards.journal} » en phase rando');
    await settleAndShoot(tester, P, '21b_journal_en_rando');
    logEcran(P, 'journal_rando', max: 60);
    final journauxEnRando = find.text(t.hub.cards.journal).evaluate().length;
    logStep(P, 'journal',
        'EN RANDO — cartes « ${t.hub.cards.journal} » comptees a l ecran = '
        '$journauxEnRando');
    exige(P, 'journal', journauxEnRando == 1,
        'une fois la rando commencee, la carte « ${t.hub.cards.journal} » est '
        'presente UNE SEULE FOIS (comptee $journauxEnRando)');

    // =====================================================================
    // CLOTURE — on termine le trek (sinon le service de fond reste vivant)
    // =====================================================================
    await _aller(tester, '/home');
    await scrollUntil(tester, find.text(t.hub.finishTrek.action), P, 'fin',
        'bouton « ${t.hub.finishTrek.action} »');
    if (await tapIfPresent(tester, find.text(t.hub.finishTrek.action), P, 'fin',
        'terminer le trek', warnIfMissing: false)) {
      await tapIfPresent(tester, find.text(t.hub.finishTrek.confirm), P, 'fin',
          'confirmer la fin du trek', warnIfMissing: false);
      await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 8));
    }
    await settleAndShoot(tester, P, '22_trek_termine');
    // L APPLI PREND LA MAIN A LA FIN DU TREK, ET C EST NORMAL : elle ouvre
    // d elle-meme le recapitulatif (« Mon aventure », « Voir mon journal »).
    // Mesure du 25/09 : compter les cartes du cockpit sans revenir dessus
    // revenait a mesurer un AUTRE ecran et a conclure « Journal absent » sur
    // un ecran qui, justement, propose le journal. On revient donc au cockpit
    // avant de compter.
    logEcran(P, 'ecran_fin_trek', max: 40);
    await _aller(tester, '/home');
    await _remonterEnHaut(tester);
    await scrollUntil(tester, find.text(t.hub.cards.journal), P, 'journal',
        'carte « ${t.hub.cards.journal} » apres le trek');
    await settleAndShoot(tester, P, '22b_journal_apres_trek');
    logEcran(P, 'journal_apres', max: 60);
    final journauxApres = find.text(t.hub.cards.journal).evaluate().length;
    logStep(P, 'journal',
        'APRES LE TREK — cartes « ${t.hub.cards.journal} » comptees a l ecran '
        '= $journauxApres');
    exige(P, 'journal', journauxApres == 1,
        'le trek termine, la carte « ${t.hub.cards.journal} » est toujours la, '
        'UNE SEULE FOIS (comptee $journauxApres)');

    exige(P, 'ecran_systeme', ecransSystemeBloquants().isEmpty,
        'aucune fenetre systeme n a recouvert l application '
        '(bloquants : ${ecransSystemeBloquants().join(", ")})');
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

/// Remonte en haut de la page courante (le cockpit defile).
Future<void> _remonterEnHaut(WidgetTester tester) async {
  final scroll = find.byType(Scrollable);
  if (scroll.evaluate().isEmpty) return;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scroll.first, const Offset(0, 400));
    await pumpAndSettleTolerant(tester);
  }
}

Finder _champ(String libelle) => find.widgetWithText(TextFormField, libelle);

/// Le verdict du feu tricolore, tel qu'il est ECRIT a l'ecran.
String? _verdictLu() {
  final v = t.feasibility.formula.verdicts;
  for (final texte in textesAlEcran()) {
    if (texte == v.green || texte == v.orange || texte == v.red) return texte;
  }
  return null;
}

/// Le grand compteur de jours du programme (« 9 j », « 12 j (dont 2 repos) »).
String? _compteurJours() {
  final motif = RegExp(r'^\d+\s*j( \(dont \d+ repos\))?$');
  for (final texte in textesAlEcran()) {
    if (motif.hasMatch(texte)) return texte;
  }
  return null;
}

Future<bool> _choisirPays(WidgetTester tester, String nom) async {
  // Nombre de champs de saisie AVANT d'ouvrir le selecteur. La fiche en porte
  // deja (age, taille, poids) : compter « un TextField existe » ne dit donc
  // rien. C'est l'AUGMENTATION du nombre qui trahit la feuille de selection
  // ouverte — sans cette nuance, on referme la fiche elle-meme et on croit
  // ensuite que le pays ne s'affiche pas.
  final champsAvant = find.byType(TextField).evaluate().length;
  if (!await tapIfPresent(
      tester,
      find.byKey(const ValueKey('hiker-profile-country-field')),
      P,
      'pays',
      'ligne Pays (ouvre le selecteur)',
      warnIfMissing: false)) {
    return false;
  }
  await pumpAndSettleTolerant(tester);
  final recherche = find.byType(TextField);
  if (recherche.evaluate().isNotEmpty) {
    await tester.enterText(recherche.last, nom);
    await pumpAndSettleTolerant(tester);
  }
  final resultat = find.text(nom).hitTestable();
  if (resultat.evaluate().isEmpty) return false;
  await tester.tap(resultat.first, warnIfMissed: false);
  await pumpAndSettleTolerant(tester);
  // LE SELECTEUR DOIT AVOIR DISPARU. Mesure du 25/09 : tant qu'il reste
  // monte, sa barriere avale les taps et le bouton « Enregistrer » de la
  // fiche devient present mais INATTEIGNABLE — on croit alors a un defaut de
  // l ecran alors que c est la feuille de selection qui n est pas refermee.
  // On le constate, on le dit, et on referme au besoin.
  // LE REPLI QUI FAISAIT PLUS DE MAL QUE DE BIEN, ET C EST L ECART DE HARNAIS
  // QUE JE CHERCHAIS DEPUIS DEUX PASSES. Quand la feuille de selection semblait
  // rester ouverte, on faisait un `maybePop()` — mais si elle s etait en
  // realite deja refermee, ce pop refermait LA FICHE. Le scenario continuait
  // alors a taper « Enregistrer » sur un ecran quitte : la fiche n etait pas
  // enregistree, et DIX PAS PLUS LOIN l ecran de faisabilite disait « 1/3
  // etapes remplies — ta fiche d info complete ». J ai failli rendre cela
  // comme un defaut du moteur de faisabilite. On ne referme plus rien : on
  // CONSTATE, on le dit, et on laisse le rouge « France » isole plutot que de
  // le laisser contaminer la suite du parcours.
  if (find.byType(TextField).evaluate().length > champsAvant) {
    logStep(P, 'pays',
        'CONSTAT : le selecteur de pays semble encore ouvert apres le choix '
        '(${find.byType(TextField).evaluate().length} champs contre '
        '$champsAvant avant ouverture). On NE referme rien : un pop de repli '
        'refermerait la fiche et fausserait tout ce qui suit.');
  }
  return true;
}

/// Coche l accord morphologie, et VERIFIE qu il a bascule.
///
/// LE PIEGE, MESURE LE 25/09 : un `tap` brut sur une bascule que le clavier ou
/// un message d aide a poussee hors de portee part dans le vide, en silence.
/// Le consentement restait donc refuse, la fiche n etait pas enregistree, et
/// dix pas plus loin le scenario concluait « aucun verdict » — en accusant le
/// moteur de faisabilite d un defaut qui n etait pas le sien. On rend la
/// bascule visible, on la tape, et ON RELIT son etat.
Future<bool> _accepterConsentementMorpho(WidgetTester tester) async {
  // ON FERME LE CLAVIER D ABORD, ET C EST LA DIFFERENCE AVEC S13. Ici trois
  // champs viennent d etre saisis : le clavier reel de l appareil est encore
  // leve et recouvre le bas de la fiche, ou vit justement la bascule. Sans ce
  // geste, le tap tombe sur le clavier, la bascule reste a refuse, la fiche ne
  // part pas — et le scenario accuse le moteur de faisabilite dix pas plus
  // loin. Un humain, lui, referme le clavier sans y penser.
  FocusManager.instance.primaryFocus?.unfocus();
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 3));
  await scrollUntil(tester, find.byType(SwitchListTile), P, 'fiche_info',
      'bascule de consentement morphologie');
  for (var essai = 0; essai < 2; essai++) {
    final consent = find.byType(SwitchListTile);
    if (consent.evaluate().isEmpty) {
      logStep(P, 'fiche_info', 'COINCE : consentement morphologie introuvable');
      return false;
    }
    if (tester.widget<SwitchListTile>(consent.first).value == true) return true;
    await tapIfPresent(tester, consent.first, P, 'fiche_info',
        'cocher l accord morphologie (essai ${essai + 1})',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 3));
  }
  final reste = find.byType(SwitchListTile);
  final valeur = reste.evaluate().isEmpty
      ? null
      : tester.widget<SwitchListTile>(reste.first).value;
  logStep(P, 'fiche_info', 'Accord morphologie apres deux essais = $valeur');
  return valeur == true;
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
    if (champ.evaluate().isEmpty) {
      logStep(P, 'randos', 'COINCE : champ « ${e.key} » introuvable');
      continue;
    }
    await tester.enterText(champ.first, e.value);
    await pumpAndSettleTolerant(tester);
  }
  final sauve = await tapIfPresent(tester, find.text(tph.save), P, 'randos',
      'enregistrer la rando', warnIfMissing: false);
  await pumpAndSettleTolerant(tester);
  return sauve;
}

/// Choisit une date de depart, en suivant le vrai chemin de l'ecran :
/// « ${t.calendar.chooseDateAction} » -> selection d'un jour -> OK ->
/// « ${t.calendar.validate} ».
Future<bool> _choisirUneDate(WidgetTester tester) async {
  await tapIfPresent(tester, find.text(t.calendar.chooseDateAction), P,
      'calendrier', 'ouvrir le choix de la date de depart',
      warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));

  // Selecteur Material : on vise un jour du milieu de mois, present partout.
  var choisi = false;
  for (final jour in <String>['15', '16', '17', '18', '20']) {
    final case_ = find.text(jour).hitTestable();
    if (case_.evaluate().isEmpty) continue;
    await tester.tap(case_.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
    logStep(P, 'calendrier', 'Jour touche dans le selecteur : le $jour');
    choisi = true;
    break;
  }
  // Le selecteur Material se ferme par OK.
  await tapIfPresent(tester, textFrEn('OK', 'OK'), P, 'calendrier',
      'confirmer la date dans le selecteur', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));

  // Puis la page elle-meme se valide.
  final valide = await tapIfPresent(tester, find.text(t.calendar.validate), P,
      'calendrier', 'valider les dates', warnIfMissing: false);
  await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 6));
  logStep(P, 'calendrier',
      'Date choisie = $choisi ; dates validees = $valide');
  return choisi || valide;
}

/// Coche le premier objet du sac atteignable.
///
/// LE SAC S'OUVRE FERME, ET C'EST NORMAL : les categories (« Sac & portage »,
/// « Couchage »...) sont des panneaux replies ; aucun objet n'est visible tant
/// qu'on n'en a pas ouvert un. Mesure du 25/09 : sans ce depliage, le scenario
/// concluait « aucun objet cochable » — un faux defaut produit par le test.
Future<bool> _cocherUnObjet(WidgetTester tester) async {
  if (find.byType(Checkbox).hitTestable().evaluate().isEmpty &&
      find.byType(CheckboxListTile).hitTestable().evaluate().isEmpty) {
    await tapIfPresent(tester, find.text(t.checklist.categories.carrying), P,
        'sac', 'deplier la categorie « ${t.checklist.categories.carrying} »',
        warnIfMissing: false);
    await pumpAndSettleTolerant(tester, timeout: const Duration(seconds: 4));
  }
  final cases = find.byType(Checkbox).hitTestable();
  if (cases.evaluate().isNotEmpty) {
    await tester.tap(cases.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
    return true;
  }
  final tuiles = find.byType(CheckboxListTile).hitTestable();
  if (tuiles.evaluate().isNotEmpty) {
    await tester.tap(tuiles.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
    return true;
  }
  final objet = find.text(t.checklist.items.backpack).hitTestable();
  if (objet.evaluate().isNotEmpty) {
    await tester.tap(objet.first, warnIfMissed: false);
    await pumpAndSettleTolerant(tester);
    return true;
  }
  logStep(P, 'sac', 'COINCE : aucun objet du sac n est cochable au doigt');
  return false;
}
